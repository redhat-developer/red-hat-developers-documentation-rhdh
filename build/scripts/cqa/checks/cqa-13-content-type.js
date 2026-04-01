/**
 * CQA-13: Verify content matches declared type
 *
 * For each .adoc (skip attributes.adoc, master.adoc, SNIPPET):
 *   - PROCEDURE: must have .Procedure section (MANUAL if missing)
 *   - CONCEPT/REFERENCE: must NOT have .Procedure section (MANUAL if present)
 *   - ASSEMBLY: must have include:: (MANUAL if missing)
 *   - Filename prefix must match content type (AUTOFIX: git mv + update refs)
 *
 * Skips: attributes.adoc, master.adoc, SNIPPET
 */

import { existsSync, readFileSync, writeFileSync, readdirSync, statSync, renameSync } from 'node:fs';
import { resolve, basename, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';
import { GIT } from '../lib/bin.js';
import { Checker, autofix, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

const PREFIX = { PROCEDURE: 'proc-', CONCEPT: 'con-', REFERENCE: 'ref-', ASSEMBLY: 'assembly-' };

export default class Cqa13ContentType extends Checker {
  id = '13';
  name = 'Verify content matches declared type';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      issues.push(...checkFile(root, file));
    }

    return issues;
  }

  fix(masterAdocPath, issues) {
    const root = repoRoot();

    for (const issue of issues) {
      fixPrefixMismatch(root, issue.file);
    }
  }
}

// ── Per-file check ────────────────────────────────────────────────────────────

function checkFile(root, file) {
  const bn = basename(file);
  if (bn === 'attributes.adoc' || bn === 'master.adoc') return [];
  if (!existsSync(resolve(root, file))) return [];

  const contentType = getContentType(file);
  if (!contentType || contentType === 'SNIPPET') return [];

  const lines = getLines(file);
  const issues = [];

  issues.push(
    ...checkContentStructure(file, contentType, lines),
    ...checkFilenamePrefix(file, contentType, bn),
  );

  return issues;
}

function checkContentStructure(file, contentType, lines) {
  const hasProcedure = lines.includes('.Procedure');
  const hasIncludes = lines.some(l => l.startsWith('include::'));

  switch (contentType) {
    case 'PROCEDURE':
      if (!hasProcedure)
        return [manual(file, 'PROCEDURE without .Procedure section')];
      break;
    case 'CONCEPT':
    case 'REFERENCE':
      if (hasProcedure)
        return [manual(file, `${contentType} has .Procedure section (should be PROCEDURE type or remove steps)`)];
      break;
    case 'ASSEMBLY':
      if (!hasIncludes)
        return [manual(file, 'ASSEMBLY has no include:: directives (should be CONCEPT, REFERENCE, or PROCEDURE)')];
      break;
  }
  return [];
}

function checkFilenamePrefix(file, contentType, bn) {
  const expected = PREFIX[contentType];
  if (!expected || bn.startsWith(expected)) return [];

  const stem = bn.replace(/\.adoc$/, '');
  const newStem = `${expected}${stem.replace(/^[^-]+-/, '')}`;
  return [autofix(file, `Filename prefix mismatch: expected ${expected} for ${contentType} (got: ${stem}) -- rename to ${newStem}.adoc`)];
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixPrefixMismatch(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  const bn = basename(file);
  const contentType = getContentType(file);
  if (!contentType) return;

  const expected = PREFIX[contentType];
  if (!expected || bn.startsWith(expected)) return;

  const stem = bn.replace(/\.adoc$/, '');
  const newBn = `${expected}${stem.replace(/^[^-]+-/, '')}.adoc`;
  const newAbs = resolve(dirname(abs), newBn);
  if (abs === newAbs) return;

  try {
    execFileSync(GIT, ['mv', abs, newAbs], { cwd: root });
  } catch {
    renameSync(abs, newAbs);
  }

  updateIncludes(root, bn, newBn);
}

function updateIncludes(root, oldBn, newBn) {
  for (const dir of ['assemblies', 'modules', 'titles', 'artifacts']) {
    const absDir = resolve(root, dir);
    if (!existsSync(absDir)) continue;
    for (const f of findAdocFiles(absDir)) {
      const text = readFileSync(f, 'utf8');
      if (!text.includes(oldBn)) continue;
      writeFileSync(f, text.replaceAll(oldBn, newBn), 'utf8');
    }
  }
}

function findAdocFiles(dir) {
  const result = [];
  for (const entry of readdirSync(dir)) {
    const abs = resolve(dir, entry);
    if (statSync(abs).isDirectory()) result.push(...findAdocFiles(abs));
    else if (entry.endsWith('.adoc')) result.push(abs);
  }
  return result;
}
