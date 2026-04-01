/**
 * CQA-04: Verify module templates
 *
 * For PROCEDURE/CONCEPT/REFERENCE modules (skip ASSEMBLY, SNIPPET, master.adoc, attributes.adoc):
 *   1. PROCEDURE: no level-3+ subheadings (=== outside code blocks) → MANUAL
 *   2. PROCEDURE: must have .Procedure section → AUTOFIX (insert before first numbered list)
 *   3. PROCEDURE: .Prerequisite (singular) → .Prerequisites → AUTOFIX
 *   4. All: must have [role="_abstract"] intro paragraph → delegate to CQA-09
 *   5. CONCEPT: must not have .Procedure section → MANUAL
 *
 * Fix: .Prerequisite → .Prerequisites, insert .Procedure before first numbered list item
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, autofix, manual, delegate } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

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

export default class Cqa04ModuleTemplates extends Checker {
  id = '04';
  name = 'Verify module templates';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      const bn = basename(file);
      if (bn === 'attributes.adoc' || bn === 'master.adoc') continue;
      if (!existsSync(resolve(root, file))) continue;

      const contentType = getContentType(file);
      if (!contentType || contentType === 'ASSEMBLY' || contentType === 'SNIPPET') continue;

      issues.push(...checkFile(file, contentType));
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

function checkFile(file, contentType) {
  const lines = getLines(file);
  const issues = [];

  if (contentType === 'PROCEDURE') {
    issues.push(...checkProcedure(file, lines));
  }

  if (!lines.includes('[role="_abstract"]')) {
    issues.push(delegate(file, '09', 'Missing [role="_abstract"] intro paragraph', null, true));
  }

  if (contentType === 'CONCEPT' && lines.includes('.Procedure')) {
    issues.push(manual(file, 'CONCEPT module has .Procedure section (move to a PROCEDURE module)'));
  }

  return issues;
}

function checkProcedure(file, lines) {
  const issues = [];
  const inBlock = buildBlockSet(lines);

  for (let i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('=== ') && !inBlock.has(i)) {
      issues.push(manual(file, `Custom subheading in PROCEDURE: ${lines[i]} -- extract to separate module`, i + 1));
    }
  }

  if (!lines.some(l => l.startsWith('.Procedure'))) {
    issues.push(autofix(file, 'Missing .Procedure section'));
  }

  for (let i = 0; i < lines.length; i++) {
    if (lines[i] === '.Prerequisite' && !inBlock.has(i)) {
      issues.push(autofix(file, '.Prerequisite should be .Prerequisites (plural)', i + 1));
    }
  }

  return issues;
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  let rawLines = readFileSync(abs, 'utf8').split('\n');
  const lines = rawLines.map(l => l.trimEnd());

  // Fix .Prerequisite → .Prerequisites
  rawLines = rawLines.map((l, i) => (lines[i] === '.Prerequisite' ? '.Prerequisites' : l));

  // Insert .Procedure before first numbered list item if missing
  const updatedLines = rawLines.map(l => l.trimEnd());
  if (!updatedLines.some(l => l.startsWith('.Procedure'))) {
    const firstOlIdx = updatedLines.findIndex(l => l.startsWith('. '));
    if (firstOlIdx !== -1) {
      rawLines.splice(firstOlIdx, 0, '.Procedure');
    }
  }

  writeFileSync(abs, rawLines.join('\n'), 'utf8');
}
