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
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
import { get as httpsGet } from 'node:https';
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load js-yaml from CQA's node_modules (no new dependencies)
const cqaRequire = createRequire(join(__dirname, 'cqa', 'package.json'));
const yaml = cqaRequire('js-yaml');

// ── Configuration ────────────────────────────────────────────────────────────

const EXCLUDED_TITLES = /rhdh-plugins-reference/;
const CCUTIL_IMAGE = 'quay.io/ivanhorvath/ccutil:amazing';
const HTMLTEST_IMAGE = 'docker.io/wjdp/htmltest:latest';
const PAGES_BASE = 'https://redhat-developer.github.io/red-hat-developers-documentation-rhdh';
const SAFE_PATH = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

// ── Argument parsing ─────────────────────────────────────────────────────────

function parseArgs(argv) {
  const args = { branch: 'main', verbose: false, jobs: cpus().length };
  for (let i = 2; i < argv.length; i++) {
    switch (argv[i]) {
      case '-b': args.branch = argv[++i]; break;
      case '--verbose': args.verbose = true; break;
      case '--jobs': args.jobs = parseInt(argv[++i], 10); break;
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
  const raw = readFileSync(patternsPath, 'utf8');
  const doc = yaml.load(raw);
  return (doc.patterns || []).map(p => ({
    ...p,
    compiled: new RegExp(p.regex, 'i'),
  }));
}

function classifyErrors(output, patterns) {
  const errors = [];
  const lines = output.split('\n');
  for (const line of lines) {
    for (const pattern of patterns) {
      const m = pattern.compiled.exec(line);
      if (m) {
        const matchVal = m[m.length > 1 ? 1 : 0];
        errors.push({
          line: line.trim(),
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

// ── Spawn helper (shared by buildTitle and runHtmltest) ─────────────────────

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

// ── htmltest ─────────────────────────────────────────────────────────────────

async function runHtmltest(repoRoot, verbose) {
  const { code, duration, output } = await spawnCapture('podman', [
    'run', '--rm',
    '--volume', `${repoRoot}:/test:z`,
    HTMLTEST_IMAGE,
    '-c', '.htmltest.yml',
  ], { cwd: repoRoot, verbose, groupName: 'htmltest' });

  return { status: code === 0 ? 'passed' : 'failed', duration, output };
}

// ── Index HTML generation ────────────────────────────────────────────────────

function generateBranchIndex(branch, results, repoRoot) {
  const indexDir = join(repoRoot, 'titles-generated', branch);
  mkdirSync(indexDir, { recursive: true });

  const passed = results.filter(r => r.status === 'passed');
  const links = passed.map(r =>
    `<li><a href="./${r.title}">${r.title}</a></li>`
  ).join('\n');

  const html = `<html><head><title>Red Hat Developer Hub Documentation Preview - ${branch}</title></head><body><ul>\n${links}\n</ul></body></html>`;
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

function printSummary(results, htmltestResult, patterns, totalDuration) {
  const passed = results.filter(r => r.status === 'passed').length;
  const failed = results.filter(r => r.status === 'failed').length;

  console.log('\n=== Build Summary ===');
  console.log(`${passed} passed | ${failed} failed | ${totalDuration}s total`);

  const failedResults = results.filter(r => r.status === 'failed');
  for (const r of failedResults) {
    console.log(`\nFAILED: ${r.title}`);
    if (r.errors.length > 0) {
      for (const e of r.errors) {
        console.log(`  Error: ${e.line}`);
        console.log(`  Cause: ${e.cause}`);
        console.log(`  Fix:   ${e.fix}`);
      }
    } else {
      // Show last few lines of output as fallback
      const lastLines = r.output.trim().split('\n').slice(-5).join('\n');
      console.log(`  Output (last 5 lines):\n${lastLines.split('\n').map(l => '    ' + l).join('\n')}`);
    }
  }

  if (htmltestResult) {
    console.log('\n=== Link Validation (htmltest) ===');
    if (htmltestResult.status === 'passed') {
      console.log('All links valid');
    } else {
      console.log('Link validation failed');
      if (htmltestResult.errors && htmltestResult.errors.length > 0) {
        for (const e of htmltestResult.errors) {
          console.log(`  ${e.line}`);
        }
      } else {
        const lastLines = htmltestResult.output.trim().split('\n').slice(-10).join('\n');
        console.log(lastLines.split('\n').map(l => '  ' + l).join('\n'));
      }
    }
  }
}

// ── JSON report ──────────────────────────────────────────────────────────────

function writeReport(branch, results, htmltestResult, concurrency, totalDuration, repoRoot) {
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
    htmltest: htmltestResult ? {
      status: htmltestResult.status,
      errors: htmltestResult.errors || [],
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
  const patternsPath = join(__dirname, 'error-patterns.yml');
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

  // Run htmltest
  console.log('\nRunning link validation (htmltest)...');
  const htmltestResult = await runHtmltest(repoRoot, args.verbose);
  htmltestResult.errors = classifyErrors(htmltestResult.output, patterns);

  const totalDuration = Math.round((Date.now() - totalStart) / 1000);

  // Print summary
  printSummary(buildResults, htmltestResult, patterns, totalDuration);

  // Write JSON report
  writeReport(args.branch, buildResults, htmltestResult, args.jobs, totalDuration, repoRoot);

  // Exit with error if any builds or htmltest failed
  const hasFailed = buildResults.some(r => r.status === 'failed') || htmltestResult.status === 'failed';
  process.exit(hasFailed ? 1 : 0);
}

main().catch(err => {
  console.error('Build orchestrator failed:', err);
  process.exit(1);
});
