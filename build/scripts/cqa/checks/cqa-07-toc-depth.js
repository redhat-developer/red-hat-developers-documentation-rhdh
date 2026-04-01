/**
 * CQA-07: Verify TOC depth (max 3 levels)
 *
 * For all .adoc files (skip attributes.adoc):
 *   - Level 4+ headings (==== or deeper, outside code blocks) → AUTOFIX
 *
 * Fix: promote level 4+ to === when there are ≤ 3 violations per file.
 *      Files with > 3 violations need manual review.
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, autofix } from '../lib/checker.js';
import { repoRoot, collectTitle, getLines } from '../lib/asciidoc.js';

const BLOCK_DELIM_RE = /^(-{4,}|\.{4,}|\+{4,})$/;

function buildBlockSet(lines) {
  const inBlock = new Set();
  let blockStart = -1;
  for (let i = 0; i < lines.length; i++) {
    if (BLOCK_DELIM_RE.test(lines[i])) {
      if (blockStart === -1) {
        blockStart = i;
      } else {
        for (let j = blockStart + 1; j < i; j++) inBlock.add(j);
        blockStart = -1;
      }
    }
  }
  return inBlock;
}

export default class Cqa07TocDepth extends Checker {
  id = '07';
  name = 'Verify TOC depth (max 3 levels)';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      if (basename(file) === 'attributes.adoc') continue;
      if (!existsSync(resolve(root, file))) continue;
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
  const inBlock = buildBlockSet(lines);
  const issues = [];

  for (let i = 0; i < lines.length; i++) {
    if (inBlock.has(i)) continue;
    const match = /^(=+) /.exec(lines[i]);
    if (!match) continue;
    const depth = match[1].length;
    if (depth > 3) {
      issues.push(autofix(file, `Level ${depth}: ${lines[i]}`, i + 1));
    }
  }

  return issues;
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  const rawLines = readFileSync(abs, 'utf8').split('\n');
  const lines = rawLines.map(l => l.trimEnd());
  const inBlock = buildBlockSet(lines);

  const violations = [];
  for (let i = 0; i < lines.length; i++) {
    if (!inBlock.has(i) && /^={4,} /.test(lines[i])) {
      violations.push(i);
    }
  }

  if (violations.length > 3) return;

  for (const i of violations) {
    rawLines[i] = rawLines[i].replace(/^={4,}( )/, '===$1');
  }
  writeFileSync(abs, rawLines.join('\n'), 'utf8');
}
