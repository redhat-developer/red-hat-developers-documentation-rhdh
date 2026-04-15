#!/usr/bin/env node
/**
 * index.js — CQA CLI entry point
 *
 * Usage:
 *   node build/scripts/cqa/index.js titles/<title>/master.adoc
 *   node build/scripts/cqa/index.js --fix titles/<title>/master.adoc
 *   node build/scripts/cqa/index.js --all
 *   node build/scripts/cqa/index.js --fix --all
 *   node build/scripts/cqa/index.js --check 03 titles/<title>/master.adoc
 */

import { existsSync, readdirSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';
import { execFileSync } from 'node:child_process';
import { GIT } from './lib/bin.js';
import { repoRoot, repoRelative, setRepoRoot, collectTitle } from './lib/asciidoc.js';
import { preRunVale, preRunValeAsync, clearValeCache } from './lib/vale.js';
import { renderCheckHeader, renderFileHeader, renderIssue, renderSummary } from './lib/output.js';

// ── Load all checks in workflow order ───────────────────────────────────────

const CHECKS_IN_ORDER = [
  'cqa-00a-orphaned.js',
  'cqa-00b-directory-structure.js',
  'cqa-03-modularization.js',
  'cqa-13-content-type.js',
  'cqa-10-titles.js',
  'cqa-08-short-description-content.js',
  'cqa-09-short-description-format.js',
  'cqa-11-prerequisites.js',
  'cqa-02-assembly-structure.js',
  'cqa-05-modular-elements-checklist.js',
  'cqa-04-module-templates.js',
  'cqa-06-assembly-scope.js',
  'cqa-07-toc-depth.js',
  'cqa-16-product-names.js',
  'cqa-01-vale-dita.js',
  'cqa-12-grammar.js',
  'cqa-17-disclaimers.js',
  'cqa-14-no-broken-links.js',
  'cqa-15-redirects.js',
];

const VALE_CHECK_IDS = new Set(['01', '12', '16']);

async function loadChecks(onlyId) {
  const checks = [];
  const checksDir = new URL('./checks/', import.meta.url);
  for (const file of CHECKS_IN_ORDER) {
    const mod = new URL(file, checksDir);
    if (!existsSync(mod)) continue;
    const { default: CheckClass } = await import(mod);
    const checker = new CheckClass();
    if (onlyId && checker.id !== onlyId) continue;
    checks.push(checker);
  }
  return checks;
}

// ── Title discovery ──────────────────────────────────────────────────────────

function findAllMasterAdocs() {
  const titlesDir = resolve(repoRoot(), 'titles');
  if (!existsSync(titlesDir)) return [];
  return readdirSync(titlesDir)
    .sort()
    .map(d => resolve(titlesDir, d, 'master.adoc'))
    .filter(f => existsSync(f))
    .map(f => repoRelative(f));
}

// ── Run a single check against a title (single-title mode) ────────────────

function runCheckSingle(checker, masterAdocPath, fixMode) {
  const issues = checker.check(masterAdocPath);
  if (issues.length === 0) return;

  console.log(renderCheckHeader(checker.id, checker.name, masterAdocPath));

  const byFile = new Map();
  for (const iss of issues) {
    if (!byFile.has(iss.file)) byFile.set(iss.file, []);
    byFile.get(iss.file).push(iss);
  }

  let autofixable = 0, manualCount = 0, delegated = 0;
  const fixedIssues = [];

  if (fixMode) {
    const fixable = issues.filter(i => i.fixable && !i.delegateTo);
    if (fixable.length > 0) {
      checker.fix(masterAdocPath, fixable);
      fixedIssues.push(...fixable);
    }
  }

  for (const [file, fileIssues] of byFile) {
    console.log(renderFileHeader(file));
    for (const iss of fileIssues) {
      const wasFixed = fixedIssues.includes(iss);
      console.log(renderIssue(iss, wasFixed));
      if (iss.delegateTo) delegated++;
      else if (wasFixed || iss.fixable) autofixable++;
      else manualCount++;
    }
  }

  console.log(renderSummary({
    filesChecked: byFile.size,
    filesWithIssues: byFile.size,
    autofixable,
    manual: manualCount,
    delegated,
    fixMode,
  }));
}

// ── Collect issues for a check across all titles (deduped) ──────────────────

function collectCheckIssues(checker, titles) {
  const allIssues = [];
  const seen = new Set();
  for (const title of titles) {
    for (const iss of checker.check(title)) {
      const key = `${iss.file}:${iss.line}:${iss.message}`;
      if (seen.has(key)) continue;
      seen.add(key);
      allIssues.push(iss);
    }
  }
  return allIssues;
}

// ── Run all checks across all titles (--all mode) ─────────────────────────

async function runAllChecks(checks, titles, fixMode) {
  const results = await collectAllResults(checks, titles, fixMode);

  // Output in alphabetical order by check ID
  const sortedChecks = [...checks].sort((a, b) => a.id.localeCompare(b.id));
  return printAllChecksReport(sortedChecks, results, fixMode);
}

async function collectAllResults(checks, titles, fixMode) {
  const root = repoRoot();

  // Split checks into Vale-based and non-Vale
  const valeChecks = checks.filter(c => VALE_CHECK_IDS.has(c.id));
  const nonValeChecks = checks.filter(c => !VALE_CHECK_IDS.has(c.id));

  // Start Vale asynchronously (optimization 1: single run)
  const valeTargets = [resolve(root, 'assemblies'), ...titles.map(t => resolve(root, t))];
  const valePromise = valeChecks.length > 0
    ? preRunValeAsync(valeTargets)
    : Promise.resolve();

  // Run non-Vale checks while Vale runs in background (optimization 5: overlap)
  const results = new Map();
  for (const checker of nonValeChecks) {
    const allIssues = collectCheckIssues(checker, titles);
    const fixedIssues = applyFixesIfNeeded(checker, titles, allIssues, fixMode);
    results.set(checker.id, { allIssues, fixedIssues });
  }

  // Wait for Vale to finish
  await valePromise;

  // Run Vale checks using cache
  for (const checker of valeChecks) {
    const allIssues = collectCheckIssues(checker, titles);
    const fixedIssues = applyFixesIfNeeded(checker, titles, allIssues, fixMode);
    results.set(checker.id, { allIssues, fixedIssues });
  }

  clearValeCache();
  return results;
}

function classifyIssues(allIssues) {
  let autofixable = 0, manualCount = 0, delegated = 0;
  for (const iss of allIssues) {
    if (iss.delegateTo) delegated++;
    else if (iss.fixable) autofixable++;
    else manualCount++;
  }
  return { autofixable, manualCount, delegated };
}

function printCheckResult(checker, allIssues, fixedIssues) {
  const nonDelegatedIssues = allIssues.filter(i => !i.delegateTo);
  const pass = nonDelegatedIssues.length === 0;

  if (pass) {
    console.log(`- [x] **CQA-${checker.id}:** ${checker.name}`);
    return true;
  }

  console.log(`- [ ] **CQA-${checker.id}:** ${checker.name} (${nonDelegatedIssues.length} issues)`);

  const byFile = new Map();
  for (const iss of nonDelegatedIssues) {
    if (!byFile.has(iss.file)) byFile.set(iss.file, []);
    byFile.get(iss.file).push(iss);
  }

  for (const [, fileIssues] of byFile) {
    for (const iss of fileIssues) {
      const wasFixed = fixedIssues.some(f => f.file === iss.file && f.message === iss.message);
      console.log(`  ${renderIssue(iss, wasFixed)}`);
    }
  }
  return false;
}

function printAllChecksReport(sortedChecks, results, fixMode) {
  console.log('# CQA Report\n');

  let totalAutofixable = 0, totalManual = 0, totalDelegated = 0, totalFixed = 0;
  let checksPass = 0, checksFail = 0;

  for (const checker of sortedChecks) {
    const { allIssues, fixedIssues } = results.get(checker.id);
    const { autofixable, manualCount, delegated } = classifyIssues(allIssues);

    if (printCheckResult(checker, allIssues, fixedIssues)) {
      checksPass++;
    } else {
      checksFail++;
    }

    totalAutofixable += autofixable;
    totalManual += manualCount;
    totalDelegated += delegated;
    totalFixed += fixedIssues.length;
  }

  printFinalSummary({ checksPass, checksFail, totalAutofixable, totalManual, totalDelegated, totalFixed, fixMode });
  return { checksPass, checksFail };
}

function printFinalSummary({ checksPass, checksFail, totalAutofixable, totalManual, totalDelegated, totalFixed, fixMode }) {
  console.log('\n---\n');
  console.log(`## Summary\n`);
  console.log(`Checks: ${checksPass + checksFail} total, ${checksPass} pass, ${checksFail} fail`);
  const totalIssues = totalAutofixable + totalManual;
  if (totalIssues > 0) {
    console.log(`Issues: ${totalIssues} total (${totalAutofixable} autofixable, ${totalManual} manual, ${totalDelegated} delegated)`);
  }
  if (fixMode) {
    if (totalFixed > 0) {
      console.log(`Fixed: ${totalFixed}`);
    }
  } else if (totalAutofixable > 0) {
    console.log(`Run \`node build/scripts/cqa/index.js --fix --all\` to auto-resolve ${totalAutofixable} issue${totalAutofixable === 1 ? '' : 's'}.`);
  }
}

function applyFixesIfNeeded(checker, titles, allIssues, fixMode) {
  const fixedIssues = [];
  if (!fixMode) return fixedIssues;
  for (const title of titles) {
    const issues = checker.check(title);
    const fixable = issues.filter(i => i.fixable && !i.delegateTo);
    if (fixable.length > 0) {
      checker.fix(title, fixable);
      fixedIssues.push(...fixable);
    }
  }
  return fixedIssues;
}

// ── Main ─────────────────────────────────────────────────────────────────────

function printHelp() {
  console.log(`Usage: node build/scripts/cqa/index.js [OPTIONS] [titles/<title>/master.adoc ...]

Content Quality Assessment for Red Hat Developer Hub documentation.
Runs 19 automated checks for modular docs compliance.

Options:
  --all          Run all checks against all titles in the repository
  --fix          Auto-fix issues where possible (AUTOFIX markers)
  --check ID     Run only the check with the given ID (e.g., 03, 16)
  --help         Show this help message

Examples:
  node build/scripts/cqa/index.js titles/configure_configuring-rhdh/master.adoc
  node build/scripts/cqa/index.js --fix titles/configure_configuring-rhdh/master.adoc
  node build/scripts/cqa/index.js --all
  node build/scripts/cqa/index.js --fix --all
  node build/scripts/cqa/index.js --check 16 titles/configure_configuring-rhdh/master.adoc

Checks (in workflow order):
  00a  Orphaned modules              08  Short description content
  00b  Directory structure           09  Short description format
  03   Content type metadata         11  Procedure prerequisites
  13   Content matches declared type 02  Assembly structure
  10   Titles                        05  Required modular elements
  04   Module templates              06  Assembly scope (one user story)
  07   TOC depth (max 3 levels)      16  Official product names
  01   Vale AsciiDoc DITA            12  Grammar and style (Vale)
  17   Legal disclaimers             14  No broken links
  15   Redirects

Output markers:
  [AUTOFIX]       Auto-fixable with --fix
  [FIXED]         Fixed by --fix in this run
  [MANUAL]        Requires manual intervention
  [-> CQA-NN]     Delegated to another check`);
}

function parseArgs(args) {
  let fixMode = false;
  let allMode = false;
  let onlyCheck = null;
  const positional = [];

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--help' || args[i] === '-h') { printHelp(); process.exit(0); }
    else if (args[i] === '--fix') { fixMode = true; }
    else if (args[i] === '--all') { allMode = true; }
    else if (args[i] === '--check') { onlyCheck = args[++i]; }
    else if (!args[i].startsWith('--')) { positional.push(args[i]); }
  }

  return { fixMode, allMode, onlyCheck, positional };
}

function initRepoRoot(positional) {
  const firstTitle = positional[0];
  if (firstTitle) {
    const absTitle = resolve(firstTitle);
    const gitRoot = execFileSync(GIT, ['-C', dirname(absTitle), 'rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
    setRepoRoot(gitRoot);
  } else {
    // When using --all without positional args, detect repo root from cwd
    // so the CLI works correctly when run from a worktree
    const cwdRoot = execFileSync(GIT, ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
    setRepoRoot(cwdRoot);
  }
}

function preRunValeForTitle(title, checks) {
  const hasValeChecks = checks.some(c => VALE_CHECK_IDS.has(c.id));
  if (!hasValeChecks) return;

  const root = repoRoot();
  const files = collectTitle(resolve(root, title));
  const valeFiles = files
    .filter(f => f.endsWith('.adoc') && basename(f) !== 'attributes.adoc')
    .map(f => resolve(root, f))
    .filter(f => existsSync(f));
  if (valeFiles.length > 0) preRunVale(valeFiles);
}

function runPerTitleMode(checks, titles, fixMode) {
  for (const title of titles) {
    preRunValeForTitle(title, checks);
    for (const checker of checks) {
      runCheckSingle(checker, title, fixMode);
    }
    clearValeCache();
  }
}

async function main() {
  const { fixMode, allMode, onlyCheck, positional } = parseArgs(process.argv.slice(2));

  initRepoRoot(positional);

  const checks = await loadChecks(onlyCheck);

  if (checks.length === 0) {
    const suffix = onlyCheck ? ` for id "${onlyCheck}"` : ' (checks/ directory may be empty)';
    console.error(`No checks found${suffix}`);
    process.exit(1);
  }

  const titles = allMode ? findAllMasterAdocs() : positional;

  if (titles.length === 0) {
    printHelp();
    process.exit(1);
  }

  if (allMode) {
    const { checksFail } = await runAllChecks(checks, titles, fixMode);
    process.exit(checksFail > 0 ? 1 : 0);
  } else {
    runPerTitleMode(checks, titles, fixMode);
  }
}

await main();
