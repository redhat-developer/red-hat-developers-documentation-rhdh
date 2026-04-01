/**
 * CQA-08: Verify short description content quality
 *
 * For each .adoc (skip attributes.adoc, master.adoc, SNIPPET):
 *   - Must have [role="_abstract"] marker → delegates to CQA-09 if missing
 *   - Abstract text (line after marker) must not be empty → MANUAL
 *   - Abstract must not contain self-referential language → AUTOFIX if prefix
 *     is removable, MANUAL otherwise
 *
 * Fix: remove self-referential prefix, capitalize remainder
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, autofix, manual, delegate } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

const SELF_REF_PATTERNS = [
  'This section', 'This document', 'This chapter', 'This guide',
  'This module', 'This assembly', 'This topic',
  'The following section', 'The following document',
  'Here we', 'Here you will',
  'In this section', 'In this document',
];

const SELF_REF_REMOVABLE = [
  'This section describes ', 'This section explains ', 'This section provides ',
  'This document describes ', 'This document explains ',
  'This topic describes ', 'This topic explains ',
  'In this section, you ', 'In this section, we ',
];

export default class Cqa08ShortDescriptionContent extends Checker {
  id = '08';
  name = 'Verify short description content quality';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      const bn = basename(file);
      if (bn === 'attributes.adoc' || bn === 'master.adoc') continue;
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
    return [delegate(file, '09', 'Missing [role="_abstract"] marker')];
  }

  const abstractText = lines[abstractIdx + 1] ?? '';
  const abstractLine = abstractIdx + 2; // 1-based

  if (!abstractText.trim()) {
    return [manual(file, 'Empty abstract (no text after [role="_abstract"])', abstractLine)];
  }

  const lower = abstractText.toLowerCase();
  const issues = [];

  for (const pattern of SELF_REF_PATTERNS) {
    if (!lower.includes(pattern.toLowerCase())) continue;

    const removable = SELF_REF_REMOVABLE.find(r => lower.startsWith(r.toLowerCase()));
    if (removable) {
      issues.push(autofix(file, `Self-referential language in abstract: "${pattern}"`, abstractLine));
    } else {
      issues.push(manual(file, `Self-referential language in abstract: "${pattern}" -- rewrite needed`, abstractLine));
    }
    break; // Only report the first match per file (matches bash behavior)
  }

  return issues;
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  const lines = readFileSync(abs, 'utf8').split('\n').map(l => l.trimEnd());
  const abstractIdx = lines.indexOf('[role="_abstract"]');
  if (abstractIdx === -1) return;

  const abstractText = lines[abstractIdx + 1] ?? '';
  const lower = abstractText.toLowerCase();
  const removable = SELF_REF_REMOVABLE.find(r => lower.startsWith(r.toLowerCase()));
  if (!removable) return;

  const remainder = abstractText.slice(removable.length);
  lines[abstractIdx + 1] = remainder[0] ? remainder[0].toUpperCase() + remainder.slice(1) : remainder;

  writeFileSync(abs, lines.join('\n'), 'utf8');
}
