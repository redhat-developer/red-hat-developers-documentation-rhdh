/**
 * CQA-12: Grammar and style (Vale)
 *
 * Detection: uses shared Vale cache (populated once by index.js) or falls back
 * to running Vale with .vale.ini + --filter.
 * Filters out AsciiDocDITA.* (CQA-01) and DeveloperHub.ProductNames (CQA-16).
 * Only errors cause failures; warnings and suggestions are informational.
 * All violations are MANUAL — Vale --fix is not yet supported for these rules.
 */

import { existsSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { execFileSync } from 'node:child_process';
import { VALE } from '../lib/bin.js';
import { Checker, manual } from '../lib/checker.js';
import { repoRoot, collectTitle } from '../lib/asciidoc.js';
import { hasValeCache, getCachedIssues } from '../lib/vale.js';

// Filter for fallback mode (Vale --filter syntax)
const VALE_FILTER = String.raw`.Name != "DeveloperHub.ProductNames" and .Name not matches "^AsciiDocDITA\\."`;


export default class Cqa12Grammar extends Checker {
  id = '12';
  name = 'Verify grammar and style (Vale)';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const adocFiles = files
      .filter(f => f.endsWith('.adoc') && basename(f) !== 'attributes.adoc');

    if (adocFiles.length === 0) return [];

    if (hasValeCache()) {
      return collectCachedGrammarIssues(adocFiles);
    }

    // Fallback: run Vale directly with --filter
    const valeConfig = resolve(root, '.vale.ini');
    if (!existsSync(valeConfig)) return [manual(masterAdocPath, '.vale.ini not found')];
    const absFiles = adocFiles.map(f => resolve(root, f)).filter(f => existsSync(f));
    if (absFiles.length === 0) return [];
    return runValeAndClassify(root, valeConfig, absFiles);
  }

  // No fix() — all CQA-12 issues are manual
}

function isGrammarRelevantError(iss) {
  return iss.Severity === 'error' &&
         !iss.Check.startsWith('AsciiDocDITA.') &&
         iss.Check !== 'DeveloperHub.ProductNames';
}

function collectCachedGrammarIssues(adocFiles) {
  const issues = [];
  for (const f of adocFiles) {
    for (const iss of getCachedIssues(f)) {
      if (!isGrammarRelevantError(iss)) continue;
      issues.push(manual(f, `${iss.Check}: ${iss.Message}`, iss.Line));
    }
  }
  return issues;
}

function runValeAndClassify(root, configPath, files) {
  let jsonStr;
  try {
    jsonStr = execFileSync(VALE, [
      '--config', configPath,
      '--filter', VALE_FILTER,
      '--output', 'JSON',
      ...files,
    ], { cwd: root, encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
  } catch (err) {
    jsonStr = err.stdout || '';
  }

  let data;
  try {
    data = JSON.parse(jsonStr);
  } catch {
    return [];
  }

  const issues = [];
  for (const [file, fileIssues] of Object.entries(data)) {
    const relPath = file.startsWith(root) ? file.slice(root.length + 1) : file;
    for (const iss of fileIssues) {
      if (iss.Severity !== 'error') continue;
      issues.push(manual(relPath, `${iss.Check}: ${iss.Message}`, iss.Line));
    }
  }

  return issues;
}
