/**
 * CQA-01: Vale AsciiDoc DITA compliance
 *
 * Detection: uses shared Vale cache (populated once by index.js) or falls back
 * to running Vale with .vale-dita-only.ini. Filters for AsciiDocDITA.* rules.
 *
 * Delegates:
 *   - ShortDescription → CQA-08
 *   - DocumentId → CQA-10
 *
 * Manual-only rules:
 *   DocumentTitle, TaskTitle, ConceptLink, AssemblyContents,
 *   RelatedLinks, ExampleBlock
 *
 * Autofixable rules:
 *   - AuthorLine: insert blank line after title
 *   - CalloutList: convert <N> text → <N>:: text
 *   - BlockTitle: convert .Title → Title: (skip if before block element)
 *   - TaskContents: insert .Procedure before first numbered list
 *   - TaskStep: fix blank lines between steps
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { execFileSync } from 'node:child_process';
import { VALE } from '../lib/bin.js';
import { Checker, autofix, manual, delegate } from '../lib/checker.js';
import { repoRoot, collectTitle, invalidateCache } from '../lib/asciidoc.js';
import { hasValeCache, getCachedIssues } from '../lib/vale.js';

const MANUAL_ONLY_CHECKS = new Set([
  'AsciiDocDITA.DocumentTitle',
  'AsciiDocDITA.TaskTitle',
  'AsciiDocDITA.ConceptLink',
  'AsciiDocDITA.AssemblyContents',
  'AsciiDocDITA.RelatedLinks',
  'AsciiDocDITA.ExampleBlock',
]);

export default class Cqa01ValeDita extends Checker {
  id = '01';
  name = 'Vale AsciiDoc DITA compliance';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const adocFiles = files
      .filter(f => f.endsWith('.adoc') && basename(f) !== 'attributes.adoc');

    if (adocFiles.length === 0) return [];

    let valeIssues;
    if (hasValeCache()) {
      valeIssues = collectCachedDitaIssues(adocFiles);
    } else {
      // Fallback: run Vale directly
      const valeConfig = resolve(root, '.vale-dita-only.ini');
      if (!existsSync(valeConfig)) return [manual(masterAdocPath, '.vale-dita-only.ini not found')];
      const absFiles = adocFiles.map(f => resolve(root, f)).filter(f => existsSync(f));
      if (absFiles.length === 0) return [];
      valeIssues = runVale(root, valeConfig, absFiles);
    }

    return classifyIssues(valeIssues);
  }

  fix(masterAdocPath, issues) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const absFiles = files
      .filter(f => f.endsWith('.adoc') && basename(f) !== 'attributes.adoc')
      .map(f => resolve(root, f))
      .filter(f => existsSync(f));

    if (absFiles.length === 0) return;

    const valeConfig = resolve(root, '.vale-dita-only.ini');
    if (!existsSync(valeConfig)) return;

    // Always run Vale directly for fix (cache may be stale after edits)
    const valeIssues = runVale(root, valeConfig, absFiles);
    applyFixes(root, valeIssues);
  }
}

// ── Cache helpers ───────────────────────────────────────────────────────────

function collectCachedDitaIssues(adocFiles) {
  const valeIssues = [];
  for (const f of adocFiles) {
    for (const iss of getCachedIssues(f)) {
      if (!iss.Check.startsWith('AsciiDocDITA.')) continue;
      valeIssues.push({ file: f, line: iss.Line, check: iss.Check, message: iss.Message });
    }
  }
  return valeIssues;
}

// ── Vale invocation (fallback / fix mode) ───────────────────────────────────

function runVale(root, configPath, files) {
  try {
    const output = execFileSync(VALE, [
      '--config', configPath,
      '--output', 'JSON',
      ...files,
    ], { cwd: root, encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
    return parseValeJson(root, output);
  } catch (err) {
    if (err.stdout) return parseValeJson(root, err.stdout);
    return [];
  }
}

function parseValeJson(root, jsonStr) {
  try {
    const data = JSON.parse(jsonStr);
    const results = [];
    for (const [file, issues] of Object.entries(data)) {
      const relPath = file.startsWith(root) ? file.slice(root.length + 1) : file;
      for (const iss of issues) {
        results.push({ file: relPath, line: iss.Line, check: iss.Check, message: iss.Message });
      }
    }
    return results;
  } catch {
    return [];
  }
}

// ── Issue classification ─────────────────────────────────────────────────────

function classifyIssues(valeIssues) {
  const issues = [];
  for (const vi of valeIssues) {
    const msg = `${vi.check}: ${vi.message}`;
    if (vi.check.includes('ShortDescription')) {
      issues.push(delegate(vi.file, '08', msg, vi.line, false));
    } else if (vi.check.includes('DocumentId')) {
      issues.push(delegate(vi.file, '10', msg, vi.line, false));
    } else if (MANUAL_ONLY_CHECKS.has(vi.check)) {
      issues.push(manual(vi.file, msg, vi.line));
    } else {
      issues.push(autofix(vi.file, msg, vi.line));
    }
  }
  return issues;
}

// ── Fixes ────────────────────────────────────────────────────────────────────

function applyFixes(root, valeIssues) {
  const byFile = new Map();
  for (const vi of valeIssues) {
    if (!byFile.has(vi.file)) byFile.set(vi.file, []);
    byFile.get(vi.file).push(vi);
  }

  for (const [file, fileIssues] of byFile) {
    const abs = resolve(root, file);
    if (!existsSync(abs)) continue;

    let lines = readFileSync(abs, 'utf8').split('\n');
    let modified = false;

    const sorted = [...fileIssues].sort((a, b) => b.line - a.line);
    for (const vi of sorted) {
      switch (vi.check) {
        case 'AsciiDocDITA.AuthorLine':
          modified = fixAuthorLine(lines, vi.line) || modified;
          break;
        case 'AsciiDocDITA.CalloutList':
          modified = fixCalloutList(lines, vi.line) || modified;
          break;
        case 'AsciiDocDITA.BlockTitle':
          modified = fixBlockTitle(lines, vi.line) || modified;
          break;
        case 'AsciiDocDITA.TaskContents':
          modified = fixTaskContents(lines, vi.line) || modified;
          break;
        case 'AsciiDocDITA.TaskStep':
          modified = fixTaskStep(lines, vi.line) || modified;
          break;
      }
    }

    if (modified) {
      writeFileSync(abs, lines.join('\n'), 'utf8');
      invalidateCache(file);
    }
  }
}

function fixAuthorLine(lines, valeLine) {
  const titleIdx = valeLine - 2;
  if (titleIdx < 0 || !lines[titleIdx]?.startsWith('= ')) return false;
  lines.splice(titleIdx + 1, 0, '');
  return true;
}

function fixCalloutList(lines, valeLine) {
  const idx = valeLine - 1;
  const line = lines[idx];
  const match = line?.match(/^<(\d+)>\s(.*)$/);
  if (!match) return false;
  lines[idx] = `<${match[1]}>:: ${match[2]}`;
  return true;
}

function fixBlockTitle(lines, valeLine) {
  const idx = valeLine - 1;
  const line = lines[idx];
  if (!line?.startsWith('.')) return false;
  const nextLine = lines[idx + 1] ?? '';
  if (nextLine.startsWith('|===') || nextLine.startsWith('====') ||
      nextLine.startsWith('----') || nextLine.startsWith('[source') ||
      nextLine.startsWith('image::')) {
    return false;
  }
  const titleText = line.slice(1);
  lines[idx] = `${titleText}:`;
  return true;
}

function fixTaskContents(lines, _valeLine) {
  const firstOl = lines.findIndex(l => l.startsWith('. '));
  if (firstOl === -1) return false;
  lines.splice(firstOl, 0, '.Procedure');
  return true;
}

function fixTaskStep(lines, valeLine) {
  const idx = valeLine - 1;
  const prevIdx = idx - 1;
  if (prevIdx < 0) return false;
  if (lines[prevIdx]?.trim() === '') {
    const prevPrevLine = lines[prevIdx - 1] ?? '';
    if (prevPrevLine === '.Procedure') {
      lines.splice(prevIdx, 1);
    } else {
      lines[prevIdx] = '+';
    }
    return true;
  }
  return false;
}
