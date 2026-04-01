/**
 * CQA-09: Verify short description format
 *
 * For each .adoc (skip SNIPPET):
 *   - Must have [role="_abstract"] marker → AUTOFIX: insert before first paragraph
 *   - No empty line after marker → AUTOFIX: remove blank line
 *   - Abstract length: 50–300 chars → MANUAL if out of range
 *
 * Fix: insert [role="_abstract"] / remove blank line after it
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { Checker, autofix, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

export default class Cqa09ShortDescriptionFormat extends Checker {
  id = '09';
  name = 'Verify short description format';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      if (!existsSync(resolve(root, file))) continue;

      const contentType = getContentType(file);
      if (!contentType || contentType === 'SNIPPET') continue;

      issues.push(...checkFile(file));
    }

    return issues;
  }

  fix(masterAdocPath, issues) {
    const root = repoRoot();
    const fixedFiles = new Set(issues.map(i => i.file));

    for (const file of fixedFiles) {
      fixFile(root, file);
    }
  }
}

// ── Per-file check ────────────────────────────────────────────────────────────

function checkFile(file) {
  const lines = getLines(file);
  const abstractIdx = lines.indexOf('[role="_abstract"]');

  if (abstractIdx === -1) {
    return [autofix(file, 'Missing [role="_abstract"] marker')];
  }

  const nextLine = lines[abstractIdx + 1] ?? '';
  const abstractLineNum = abstractIdx + 2; // 1-based

  if (!nextLine) {
    return [autofix(file, 'Empty line after [role="_abstract"] (abstract must start on next line)', abstractLineNum)];
  }

  // Collect abstract text (stop at blank line, section marker, or include)
  let abstractText = '';
  for (let i = abstractIdx + 1; i < lines.length; i++) {
    const l = lines[i];
    if (!l || l.startsWith('.') || l.startsWith('include::')) break;
    abstractText += l + ' ';
  }
  abstractText = abstractText.trim().replaceAll(/\s+/g, ' ');

  // Resolve single attribute reference like {abstract}
  if (/^\{[a-z][-a-z0-9]*\}$/.test(abstractText)) {
    const attrName = abstractText.slice(1, -1);
    const attrRe = new RegExp(String.raw`^:${attrName}:\s*(.*)`);
    const resolved = lines.map(l => attrRe.exec(l)?.[1]).find(Boolean);
    if (resolved) abstractText = resolved;
  }

  const len = abstractText.length;
  if (len < 50) {
    return [manual(file, `Abstract too short (${len} chars, minimum 50)`, abstractLineNum)];
  }
  if (len > 300) {
    return [manual(file, `Abstract too long (${len} chars, maximum 300)`, abstractLineNum)];
  }
  return [];
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  const rawLines = readFileSync(abs, 'utf8').split('\n');
  const lines = rawLines.map(l => l.trimEnd());

  const abstractIdx = lines.indexOf('[role="_abstract"]');

  if (abstractIdx === -1) {
    insertAbstractMarker(abs, rawLines, lines);
  } else if (!lines[abstractIdx + 1]) {
    rawLines.splice(abstractIdx + 1, 1);
    writeFileSync(abs, rawLines.join('\n'), 'utf8');
  }
}

function insertAbstractMarker(abs, rawLines, lines) {
  const titleIdx = lines.findIndex(l => l.startsWith('= '));
  if (titleIdx === -1) return;

  let insertIdx = titleIdx + 1;
  while (insertIdx < lines.length) {
    const l = lines[insertIdx];
    if (!l || l.startsWith(':') || l.startsWith('[id=') || l.startsWith('ifdef::')) {
      insertIdx++;
    } else {
      break;
    }
  }

  rawLines.splice(insertIdx, 0, '[role="_abstract"]');
  writeFileSync(abs, rawLines.join('\n'), 'utf8');
}
