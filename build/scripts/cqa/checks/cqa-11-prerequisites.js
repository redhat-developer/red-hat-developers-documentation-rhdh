/**
 * CQA-11: Verify procedure prerequisites
 *
 * For PROCEDURE files only (skip attributes.adoc, master.adoc):
 *   - .Prerequisite (singular) → .Prerequisites → AUTOFIX
 *   - More than 10 prerequisites → MANUAL
 *   - Numbered prerequisites → bulleted → AUTOFIX
 *
 * Fix: rename .Prerequisite, convert numbered to bulleted in .Prerequisites section
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, autofix, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

const SECTION_STOP_RE = /^\.(Procedure|Verification|Troubleshooting|Next steps|Additional)/;

export default class Cqa11Prerequisites extends Checker {
  id = '11';
  name = 'Verify procedure prerequisites';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      const bn = basename(file);
      if (bn === 'attributes.adoc' || bn === 'master.adoc') continue;
      if (!existsSync(resolve(root, file))) continue;

      const contentType = getContentType(file);
      if (contentType !== 'PROCEDURE') continue;

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
  const issues = [];

  // Check 1: singular .Prerequisite
  const singularIdx = lines.indexOf('.Prerequisite');
  if (singularIdx !== -1) {
    issues.push(autofix(file, '.Prerequisite should be .Prerequisites (plural)', singularIdx + 1));
  }

  // Check 2 & 3: count items in .Prerequisites section
  const prereqIdx = lines.indexOf('.Prerequisites');
  if (prereqIdx !== -1) {
    const prereqLine = prereqIdx + 1;
    const { bulleted, numbered } = extractPrereqCounts(lines, prereqIdx);

    if (bulleted + numbered > 10) {
      issues.push(manual(file, `Too many prerequisites: ${bulleted + numbered} (max 10) -- combine or prioritize`));
    }

    if (numbered > 0) {
      issues.push(autofix(file, `Prerequisites use numbered list (${numbered} items) -- should use bullets (*)`, prereqLine));
    }
  }

  return issues;
}

function extractPrereqCounts(lines, prereqIdx) {
  let bulleted = 0;
  let numbered = 0;

  for (let i = prereqIdx + 1; i < lines.length; i++) {
    const l = lines[i];
    if (SECTION_STOP_RE.test(l)) break;
    if (l.startsWith('* ')) bulleted++;
    else if (l.startsWith('. ')) numbered++;
  }

  return { bulleted, numbered };
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  let text = readFileSync(abs, 'utf8');

  // Fix singular
  text = text.replaceAll(/^\.Prerequisite$/gm, '.Prerequisites');

  // Fix numbered → bulleted in .Prerequisites section
  text = fixNumberedInSection(text);

  writeFileSync(abs, text, 'utf8');
}

function fixNumberedInSection(text) {
  const sectionRe = /^\.Prerequisites$/m;
  const match = sectionRe.exec(text);
  if (!match) return text;

  const before = text.slice(0, match.index + match[0].length);
  const after = text.slice(match.index + match[0].length);

  const stopMatch = /^\.(Procedure|Verification|Troubleshooting|Next steps|Additional)/m.exec(after.slice(1));
  if (stopMatch) {
    const body = after.slice(1, stopMatch.index + 1);
    const rest = after.slice(stopMatch.index + 1);
    return before + '\n' + body.replaceAll(/^\. /gm, '* ') + rest;
  }
  return before + after.replaceAll(/^\. /gm, '* ');
}
