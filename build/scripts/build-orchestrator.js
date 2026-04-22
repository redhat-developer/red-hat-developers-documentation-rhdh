#!/usr/bin/env node
/**
 * build-orchestrator.js — Parallel documentation build orchestrator
 *
 * Replaces the sequential build-ccutil.sh with parallel title builds,
 * filtered output, error classification, and JSON report generation.
 *
 * Usage:
 *   node build/scripts/build-orchestrator.js -b main
 *   node build/scripts/build-orchestrator.js -b pr-123 --verbose
 *   node build/scripts/build-orchestrator.js -b main --jobs 4
 */

import { existsSync, readFileSync, writeFileSync, mkdirSync, rmSync, readdirSync, renameSync, copyFileSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { spawn } from 'node:child_process';
import { cpus } from 'node:os';
import { fileURLToPath } from 'node:url';
import { get as httpsGet } from 'node:https';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// ── Configuration ────────────────────────────────────────────────────────────

const EXCLUDED_TITLES = /rhdh-plugins-reference/;
const CCUTIL_IMAGE = 'quay.io/ivanhorvath/ccutil:amazing';
const LYCHEE_VERSION = 'v0.23.0';
const PAGES_BASE = 'https://redhat-developer.github.io/red-hat-developers-documentation-rhdh';
const RELEASE_NOTES_BASE = 'https://red-hat-developers-documentation.pages.redhat.com/red-hat-developer-hub-release-notes';
const SAFE_PATH = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

// ── Argument parsing ─────────────────────────────────────────────────────────

function parseArgs(argv) {
  const args = { branch: 'main', verbose: false, jobs: cpus().length };
  for (let i = 2; i < argv.length; i++) {
    switch (argv[i]) {
      case '-b': args.branch = argv[++i]; break;
      case '--verbose': args.verbose = true; break;
      case '--jobs': args.jobs = Number.parseInt(argv[++i], 10); break;
    }
  }
  return args;
}

// ── Title discovery ──────────────────────────────────────────────────────────

function discoverTitles(repoRoot) {
  const titlesDir = join(repoRoot, 'titles');
  const titles = [];
  for (const entry of readdirSync(titlesDir, { withFileTypes: true })) {
    if (!entry.isDirectory()) continue;
    if (EXCLUDED_TITLES.test(entry.name)) continue;
    const masterAdoc = join(titlesDir, entry.name, 'master.adoc');
    if (existsSync(masterAdoc)) {
      titles.push({
        name: entry.name,
        dir: join('titles', entry.name),
        masterAdoc: join('titles', entry.name, 'master.adoc'),
      });
    }
  }
  return titles.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }));
}

// ── Error pattern loading ────────────────────────────────────────────────────

function loadErrorPatterns(patternsPath) {
  if (!existsSync(patternsPath)) {
    console.warn(`Warning: error patterns file not found: ${patternsPath}`);
    return [];
  }
  const doc = JSON.parse(readFileSync(patternsPath, 'utf8'));
  return (doc.patterns || []).map(p => ({
    ...p,
    compiled: new RegExp(p.regex, 'i'),
  }));
}

// eslint-disable-next-line no-control-regex
const ANSI_RE = /\x1b\[[0-9;]*m/g;

function classifyErrors(output, patterns) {
  const errors = [];
  const lines = output.split('\n');
  for (const line of lines) {
    const clean = line.replaceAll(ANSI_RE, '');
    for (const pattern of patterns) {
      const m = pattern.compiled.exec(clean);
      if (m) {
        const matchVal = m[m.length - 1];
        errors.push({
          line: clean.trim(),
          patternId: pattern.id,
          cause: pattern.cause.replace('{match}', matchVal),
          fix: pattern.fix.replace('{match}', matchVal),
        });
        break; // one classification per line
      }
    }
  }
  return errors;
}

// ── Semaphore for concurrency control ────────────────────────────────────────

class Semaphore {
  constructor(max) {
    this.max = max;
    this.current = 0;
    this.queue = [];
  }

  async acquire() {
    if (this.current < this.max) {
      this.current++;
      return;
    }
    return new Promise(resolve => this.queue.push(resolve));
  }

  release() {
    this.current--;
    if (this.queue.length > 0) {
      this.current++;
      this.queue.shift()();
    }
  }
}

// ── Spawn helper (shared by buildTitle and runLychee) ──────────────────────

function spawnCapture(command, args, { cwd, verbose, groupName }) {
  return new Promise((resolve) => {
    const start = Date.now();
    let output = '';

    if (verbose && groupName) {
      console.log(`::group::${groupName}`);
      console.log(`${command} ${args.join(' ')}`);
    }

    const proc = spawn(command, args, {
      cwd,
      env: { ...process.env, PATH: SAFE_PATH },
    });

    proc.stdout.on('data', (data) => {
      output += data.toString();
      if (verbose) process.stdout.write(data);
    });

    proc.stderr.on('data', (data) => {
      output += data.toString();
      if (verbose) process.stderr.write(data);
    });

    proc.on('close', (code) => {
      if (verbose && groupName) console.log('::endgroup::');
      const duration = Math.round((Date.now() - start) / 1000);
      resolve({ code, duration, output });
    });

    proc.on('error', (err) => {
      if (verbose && groupName) console.log('::endgroup::');
      const duration = Math.round((Date.now() - start) / 1000);
      resolve({ code: 1, duration, output: err.message });
    });
  });
}

// ── Single title build ───────────────────────────────────────────────────────

async function buildTitle(title, branch, repoRoot, verbose) {
  const dest = join('titles-generated', branch, title.name);

  // Clean previous build artifacts
  const buildDir = join(repoRoot, title.dir, 'build');
  try { rmSync(buildDir, { recursive: true, force: true }); } catch {}

  const podmanArgs = [
    'run', '--rm',
    '--volume', `${repoRoot}:/docs:z`,
    '--workdir', `/docs/${title.dir}`,
    CCUTIL_IMAGE,
    'ccutil', 'compile',
    '--format', 'html-single',
    '--lang', 'en-US',
    '--doctype', 'article',
  ];

  const { code, duration, output } = await spawnCapture('podman', podmanArgs, {
    cwd: repoRoot, verbose, groupName: title.name,
  });

  if (code !== 0) {
    return { title: title.name, status: 'failed', duration, output, errors: [] };
  }

  // Move compiled output to destination
  const srcDir = join(repoRoot, title.dir, 'build', 'tmp', 'en-US', 'html-single');
  const destDir = join(repoRoot, dest);
  try {
    rmSync(destDir, { recursive: true, force: true });
    renameSync(srcDir, destDir);
  } catch (err) {
    return { title: title.name, status: 'failed', duration, output: output + '\n' + err.message, errors: [] };
  }

  // Copy referenced images
  let finalOutput = output;
  try {
    copyImages(destDir, repoRoot);
  } catch (err) {
    finalOutput += `\nWarning: image copy issue: ${err.message}`;
  }

  return { title: title.name, status: 'passed', duration, output: finalOutput, errors: [] };
}

function copyImages(destDir, repoRoot) {
  const indexPath = join(destDir, 'index.html');
  if (!existsSync(indexPath)) return;

  const html = readFileSync(indexPath, 'utf8');
  const imageRefs = html.match(/images\/[^"]+/g) || [];
  const filtered = imageRefs.filter(ref =>
    !ref.includes('mask-image') &&
    !ref.includes('background') &&
    !ref.includes('fa-icons') &&
    !ref.includes('jupumbra')
  );

  for (const im of filtered) {
    const imDir = join(destDir, dirname(im));
    mkdirSync(imDir, { recursive: true });
    const srcImage = resolve(repoRoot, im);
    if (existsSync(srcImage)) {
      try {
        copyFileSync(srcImage, join(imDir, im.split('/').pop()));
      } catch {}
    }
  }
}

// ── lychee link checker ─────────────────────────────────────────────────────

async function ensureLychee(repoRoot) {
  // Check PATH first
  try {
    const { code } = await spawnCapture('lychee', ['--version'], { cwd: repoRoot, verbose: false });
    if (code === 0) return 'lychee';
  } catch {}

  // Download to local cache
  const cacheDir = join(repoRoot, 'build', '.cache');
  const lychee = join(cacheDir, 'lychee');
  if (existsSync(lychee)) return lychee;

  console.log('Downloading lychee...');
  mkdirSync(cacheDir, { recursive: true });
  const url = `https://github.com/lycheeverse/lychee/releases/download/lychee-${LYCHEE_VERSION}/lychee-x86_64-unknown-linux-gnu.tar.gz`;
  const dl = await spawnCapture('sh', ['-c', `curl -sSfL "${url}" | tar xz -C "${cacheDir}" lychee`],
    { cwd: repoRoot, verbose: false });
  if (dl.code !== 0 || !existsSync(lychee)) {
    throw new Error(`Failed to download lychee: ${dl.output}`);
  }
  return lychee;
}

// ── Cross-title link remapping ───────────────────────────────────────────────

function buildRemapArgs(repoRoot, branch) {
  const attrsPath = join(repoRoot, 'artifacts', 'attributes.adoc');
  if (!existsSync(attrsPath)) return [];

  const attrs = readFileSync(attrsPath, 'utf8');
  const generatedDir = join(repoRoot, 'titles-generated', branch);
  if (!existsSync(generatedDir)) return [];

  // Extract key-prefix -> slug from book-link attributes
  const bookLinks = {};
  const bookLinkRe = /^:([\w-]+)-book-link:\s+\{product-docs-link\}\/html-single\/([^/\s]+)\/index/gm;
  let m;
  while ((m = bookLinkRe.exec(attrs)) !== null) {
    bookLinks[m[1]] = m[2];
  }

  // For each title dir, read :title: to extract the book-title key prefix
  // Expects normalized titles: :title: {<name>-book-title}
  const titleDirs = readdirSync(generatedDir).filter(d =>
    existsSync(join(generatedDir, d, 'index.html'))
  );
  const remaps = [];
  for (const dir of titleDirs) {
    const masterPath = join(repoRoot, 'titles', dir, 'master.adoc');
    if (!existsSync(masterPath)) continue;
    const masterHead = readFileSync(masterPath, 'utf8').slice(0, 500);
    const titleMatch = masterHead.match(/^:title:\s+\{([\w-]+)-book-title\}$/m);
    if (!titleMatch) continue;
    const keyPrefix = titleMatch[1];
    const slug = bookLinks[keyPrefix];
    if (!slug) continue;
    const localUrl = `file://${join(generatedDir, dir, 'index.html')}`;
    remaps.push(String.raw`https://docs\.redhat\.com/en/documentation/red_hat_developer_hub/[^/]+/html-single/${slug}/index ${localUrl}`);
  }

  return remaps.flatMap(r => ['--remap', r]);
}

async function runLychee(repoRoot, branch, verbose) {
  const lycheeBin = await ensureLychee(repoRoot);
  const remapArgs = buildRemapArgs(repoRoot, branch);
  const { code, duration, output } = await spawnCapture(lycheeBin, [
    '--config', join(repoRoot, 'lychee.toml'),
    '--format', 'json',
    ...remapArgs,
    join(repoRoot, 'titles-generated'),
  ], { cwd: repoRoot, verbose, groupName: 'lychee' });

  let errors = [];
  let stats = { total: 0, successful: 0, errors: 0, excludes: 0, timeouts: 0 };
  try {
    // Extract JSON from output (stderr warnings may precede the JSON)
    const jsonStart = output.indexOf('{');
    const jsonStr = jsonStart >= 0 ? output.slice(jsonStart) : output;
    const report = JSON.parse(jsonStr);
    stats = {
      total: report.total || 0,
      successful: report.successful || 0,
      errors: report.errors || 0,
      excludes: report.excludes || 0,
      timeouts: report.timeouts || 0,
    };
    if (code !== 0 && report.error_map) {
      // Collect each broken URL per source file (no deduplication)
      const brokenEntries = [];
      for (const [htmlFile, details] of Object.entries(report.error_map)) {
        for (const d of details) {
          brokenEntries.push({ htmlFile, ...d });
        }
      }
      // Trace each broken URL back to .adoc source files
      errors = await Promise.all(brokenEntries.map(async (d) => {
        const status = typeof d.status === 'object' ? d.status.text : String(d.status);
        const statusCode = typeof d.status === 'object' && d.status.code ? `[${d.status.code}] ` : '';
        const sources = await traceUrlToSource(d.url, repoRoot);
        // Fall back to the HTML file path when .adoc tracing finds nothing
        if (sources.length === 0 && d.htmlFile) {
          sources.push(d.htmlFile.replace(repoRoot + '/', ''));
        }
        return {
          line: `${statusCode}${d.url}`,
          sources,
          patternId: 'lychee-broken-link',
          cause: `Link check failed: ${status}`,
          fix: 'Fix the broken link or add to .lycheeignore',
        };
      }));
    }
  } catch {
    // JSON parse failed — fall back to raw output
  }

  return { status: code === 0 ? 'passed' : 'failed', duration, output, errors, stats };
}

// ── Source tracing — find .adoc origin of broken URLs ───────────────────────

async function traceUrlToSource(url, repoRoot) {
  // Strip anchors and trailing slashes for grep
  let searchUrl = url;
  const hashIdx = searchUrl.indexOf('#');
  if (hashIdx >= 0) searchUrl = searchUrl.slice(0, hashIdx);
  if (searchUrl.endsWith('/')) searchUrl = searchUrl.slice(0, -1);
  const { code, output } = await spawnCapture('grep', [
    '-rn', '--include=*.adoc', '-l', searchUrl,
    join(repoRoot, 'modules'),
    join(repoRoot, 'assemblies'),
    join(repoRoot, 'artifacts'),
  ], { cwd: repoRoot, verbose: false });
  if (code !== 0 || !output.trim()) return [];
  return output.trim().split('\n').map(f => f.replace(repoRoot + '/', ''));
}

// ── CQA content quality assessment ─────────────────────────────────────────

async function runCqa(repoRoot, verbose) {
  const cqaScript = join(__dirname, 'cqa', 'index.js');
  const { code, duration, output } = await spawnCapture('node', [cqaScript, '--all'], {
    cwd: repoRoot, verbose, groupName: 'CQA',
  });

  // Parse summary line from output: "Checks: 19 total, 19 pass, 0 fail"
  let checksTotal = 0, checksPass = 0, checksFail = 0;
  const summaryMatch = output.match(/Checks:\s+(\d+)\s+total,\s+(\d+)\s+pass,\s+(\d+)\s+fail/);
  if (summaryMatch) {
    checksTotal = Number.parseInt(summaryMatch[1], 10);
    checksPass = Number.parseInt(summaryMatch[2], 10);
    checksFail = Number.parseInt(summaryMatch[3], 10);
  }

  return {
    status: code === 0 ? 'passed' : 'failed',
    duration,
    output,
    stats: { total: checksTotal, pass: checksPass, fail: checksFail },
  };
}

// ── Index HTML generation ────────────────────────────────────────────────────

function getReleaseNotesLink(branch) {
  if (branch === 'main') return `${RELEASE_NOTES_BASE}/main/index.html`;
  const match = branch.match(/^release-(\d+)\.(\d+)$/);
  if (match && (Number(match[1]) > 1 || Number(match[2]) >= 9)) {
    return `${RELEASE_NOTES_BASE}/release-${match[1]}-${match[2]}/index.html`;
  }
  return null;
}

function generateBranchIndex(branch, results, repoRoot) {
  const indexDir = join(repoRoot, 'titles-generated', branch);
  mkdirSync(indexDir, { recursive: true });

  const passed = results.filter(r => r.status === 'passed');
  const links = passed.map(r =>
    `<li><a href="./${r.title}">${r.title}</a></li>`
  ).join('\n');

  const rnUrl = getReleaseNotesLink(branch);
  const rnSection = rnUrl
    ? `\n<hr>\n<ul>\n<li><a href="${rnUrl}">Release Notes (external)</a></li>\n</ul>`
    : '';

  const html = `<html><head><title>Red Hat Developer Hub Documentation Preview - ${branch}</title></head><body><ul>\n${links}\n</ul>${rnSection}</body></html>`;
  writeFileSync(join(indexDir, 'index.html'), html);
}

function fetchUrl(url) {
  return new Promise((resolve, reject) => {
    httpsGet(url, (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        fetchUrl(res.headers.location).then(resolve, reject);
        return;
      }
      if (res.statusCode !== 200) {
        res.resume();
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => resolve(data));
      res.on('error', reject);
    }).on('error', reject);
  });
}

async function updateRootIndex(branch, repoRoot) {
  const isPR = branch.startsWith('pr-');
  const indexFile = isPR ? 'pulls.html' : 'index.html';
  const indexPath = join(repoRoot, 'titles-generated', indexFile);
  const url = `${PAGES_BASE}/${indexFile}`;

  // Fetch existing index from GitHub Pages
  try {
    const data = await fetchUrl(url);
    writeFileSync(indexPath, data);
  } catch {
    // If fetch fails, create a minimal file
    writeFileSync(indexPath, '<html><body><ul>\n</ul></body></html>');
  }

  const content = readFileSync(indexPath, 'utf8');
  const link = `./${branch}/index.html`;
  if (!content.includes(link)) {
    console.log(`Building root index for ${branch} in titles-generated/${indexFile} ...`);
    const entry = `<li><a href=${link}>${branch}</a></li>`;
    const updated = content.replace('</ul>', `${entry}\n</ul>`);
    writeFileSync(indexPath, updated);
  }
}

// ── Summary output ───────────────────────────────────────────────────────────

function printFailedTitle(r) {
  console.log(`\nFAILED: ${r.title}`);
  if (r.errors.length > 0) {
    for (const e of r.errors) {
      console.log(`  Error: ${e.line}`);
      console.log(`  Cause: ${e.cause}`);
      console.log(`  Fix:   ${e.fix}`);
    }
    return;
  }
  const lastLines = r.output.trim().split('\n').slice(-5);
  console.log(`  Output (last 5 lines):\n${lastLines.map(l => '    ' + l).join('\n')}`);
}

function printLycheeSummary(lycheeResult) {
  console.log('\n=== Link Validation (lychee) ===');
  const s = lycheeResult.stats || {};
  console.log(`Total: ${s.total} | OK: ${s.successful} | Errors: ${s.errors} | Excluded: ${s.excludes} | Timeouts: ${s.timeouts}`);
  if (lycheeResult.status === 'passed') {
    return;
  }
  console.log('Link validation failed');
  if (lycheeResult.errors && lycheeResult.errors.length > 0) {
    for (const e of lycheeResult.errors) {
      if (e.sources && e.sources.length > 0) {
        for (const s of e.sources) {
          console.log(`  - [ ] ${s} -> ${e.line}`);
        }
      } else {
        console.log(`  - [ ] ${e.line}`);
      }
    }
    return;
  }
  const lastLines = lycheeResult.output.trim().split('\n').slice(-10);
  console.log(lastLines.map(l => '  ' + l).join('\n'));
}

function printCqaSummary(cqaResult) {
  if (cqaResult.status === 'skipped') return;
  console.log('\n=== CQA (Content Quality Assessment) ===');
  const s = cqaResult.stats || {};
  console.log(`Checks: ${s.total} total, ${s.pass} pass, ${s.fail} fail`);
  if (cqaResult.status === 'failed') {
    if (cqaResult.output) {
      console.log(cqaResult.output);
    }
    console.log('CQA validation failed — run `node build/scripts/cqa/index.js --all` for details');
  }
}

function printSummary(results, lycheeResult, cqaResult, patterns, totalDuration) {
  const passed = results.filter(r => r.status === 'passed').length;
  const failed = results.filter(r => r.status === 'failed').length;

  console.log('\n=== Build Summary ===');
  console.log(`${passed} passed | ${failed} failed | ${totalDuration}s total`);

  for (const r of results.filter(r => r.status === 'failed')) {
    printFailedTitle(r);
  }

  if (lycheeResult) {
    printLycheeSummary(lycheeResult);
  }

  if (cqaResult) {
    printCqaSummary(cqaResult);
  }
}

// ── JSON report ──────────────────────────────────────────────────────────────

function writeReport(branch, results, lycheeResult, cqaResult, concurrency, totalDuration, repoRoot) {
  const passed = results.filter(r => r.status === 'passed').length;
  const failed = results.filter(r => r.status === 'failed').length;

  const report = {
    version: 1,
    branch,
    timestamp: new Date().toISOString(),
    duration: totalDuration,
    concurrency,
    titles: {
      total: results.length,
      passed,
      failed,
    },
    results: results.map(r => ({
      title: r.title,
      status: r.status,
      duration: r.duration,
      errors: r.errors,
    })),
    lychee: lycheeResult ? {
      status: lycheeResult.status,
      stats: lycheeResult.stats || {},
      errors: lycheeResult.errors || [],
    } : null,
    cqa: cqaResult ? {
      status: cqaResult.status,
      stats: cqaResult.stats || {},
      output: cqaResult.output || '',
    } : null,
  };

  const reportPath = join(repoRoot, 'build-report.json');
  writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(`\nReport written to ${reportPath}`);
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const args = parseArgs(process.argv);
  const repoRoot = resolve(__dirname, '..', '..');
  const totalStart = Date.now();

  // Discover titles
  const titles = discoverTitles(repoRoot);
  if (titles.length === 0) {
    console.error('No titles found to build');
    process.exit(1);
  }

  // Load error patterns
  const patternsPath = join(__dirname, 'error-patterns.json');
  const patterns = loadErrorPatterns(patternsPath);

  // Prepare output directory
  const outputDir = join(repoRoot, 'titles-generated');
  rmSync(outputDir, { recursive: true, force: true });
  mkdirSync(join(outputDir, args.branch), { recursive: true });

  const pad = Math.max(...titles.map(t => t.name.length));
  console.log(`Building ${titles.length} titles (${args.jobs} parallel)...`);

  // Run parallel builds with semaphore
  const sem = new Semaphore(args.jobs);
  const buildPromises = titles.map(async (title) => {
    await sem.acquire();
    try {
      const result = await buildTitle(title, args.branch, repoRoot, args.verbose);

      // Classify errors against patterns
      result.errors = classifyErrors(result.output, patterns);

      // Print completion line
      const tag = result.status === 'passed' ? '[OK]  ' : '[FAIL]';
      console.log(`${tag} ${result.title.padEnd(pad)}  (${result.duration}s)`);

      return result;
    } finally {
      sem.release();
    }
  });

  const results = await Promise.allSettled(buildPromises);
  const buildResults = results.map(r => r.status === 'fulfilled' ? r.value : {
    title: 'unknown',
    status: 'failed',
    duration: 0,
    output: r.reason?.message || 'Unknown error',
    errors: [],
  });

  // Generate branch index HTML (only for passed titles)
  generateBranchIndex(args.branch, buildResults, repoRoot);

  // Update root index
  await updateRootIndex(args.branch, repoRoot);

  // Run lychee link validation
  console.log('\nRunning link validation (lychee)...');
  const lycheeResult = await runLychee(repoRoot, args.branch, args.verbose);
  if (lycheeResult.errors.length === 0) {
    lycheeResult.errors = classifyErrors(lycheeResult.output, patterns);
  }

  // Run CQA content quality assessment
  // Skip when CQA_RUNNING env is set (CQA-14 recursion guard)
  const cqaResult = (process.env.CQA_RUNNING)
    ? { status: 'skipped', duration: 0, output: '', stats: { total: 0, pass: 0, fail: 0 } }
    : await (async () => {
        console.log('\nRunning CQA content quality assessment...');
        return runCqa(repoRoot, args.verbose);
      })();

  const totalDuration = Math.round((Date.now() - totalStart) / 1000);

  // Print summary
  printSummary(buildResults, lycheeResult, cqaResult, patterns, totalDuration);

  // Write JSON report
  writeReport(args.branch, buildResults, lycheeResult, cqaResult, args.jobs, totalDuration, repoRoot);

  // Exit with error if any builds, lychee, or CQA failed
  const hasFailed = buildResults.some(r => r.status === 'failed')
    || lycheeResult.status === 'failed'
    || cqaResult.status === 'failed';
  process.exit(hasFailed ? 1 : 0);
}

try {
  await main();
} catch (err) {
  console.error('Build orchestrator failed:', err);
  process.exit(1);
}
