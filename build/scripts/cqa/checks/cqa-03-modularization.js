/**
 * CQA-03: Modularization
 *
 * Every .adoc file must have :_mod-docs-content-type: on line 1.
 * The declared type must match the detected type.
 * PROCEDURE files must have correct list formatting in .Procedure and .Verification sections.
 *
 * Skips: attributes.adoc
 * Fix: correct/add content type on line 1; normalize list formatting.
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, autofix, manual } from '../lib/checker.js';
import { repoRoot, collectTitle } from '../lib/asciidoc.js';

const PROC_MODULE_RE = /include::.*\/(proc-|ref-|con-)/;
const CONTENT_TYPE_ATTR = ':_mod-docs-content-type:';
const SECTION_STOP_RE = /^\.(Prerequisites|Procedure|Verification|Troubleshooting|Next steps|Additional)/;
const BLOCK_DELIM_RE = /^(-{4,}|\.{4,}|\+{4,})$/;

export default class Cqa03Modularization extends Checker {
  id = '03';
  name = 'Verify content type metadata';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      if (basename(file) === 'attributes.adoc') continue;
      const abs = resolve(root, file);
      if (!existsSync(abs)) continue;

      const lines = readLines(abs);
      const detected = detectContentType(lines, basename(file));
      if (!detected) continue;

      const { current, occurrences, onFirstLine } = readContentTypeInfo(lines);
      issues.push(...checkContentType(file, detected, current, occurrences, onFirstLine));

      if (detected === 'PROCEDURE') {
        issues.push(
          ...checkSectionLists(file, lines, 'Procedure'),
          ...checkSectionLists(file, lines, 'Verification'),
          ...checkProcedureStructure(file, lines),
        );
      }
    }

    return issues;
  }

  fix(masterAdocPath, issues) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const fixedFiles = new Set(issues.map(i => i.file));

    for (const file of files) {
      if (!fixedFiles.has(file)) continue;
      const abs = resolve(root, file);
      if (!existsSync(abs)) continue;

      const lines = readLines(abs);
      const detected = detectContentType(lines, basename(file));
      if (!detected) continue;

      fixContentType(abs, lines, detected);
      const newLines = readLines(abs);
      fixSectionLists(abs, newLines, 'Procedure');
      fixSectionLists(abs, readLines(abs), 'Verification');
    }
  }
}

// ── Content type detection ────────────────────────────────────────────────────

function detectContentType(lines, bn) {
  const stem = bn.replace(/\.adoc$/, '');

  // Content-based: includes proc-/ref-/con- → ASSEMBLY
  const hasIncludes = lines.some(l => l.startsWith('include::'));
  if (hasIncludes && lines.some(l => PROC_MODULE_RE.test(l))) return 'ASSEMBLY';

  // Content-based: has .Procedure → PROCEDURE
  if (lines.includes('.Procedure')) return 'PROCEDURE';

  // Filename-based
  if (stem.startsWith('assembly-') || stem === 'master') return 'ASSEMBLY';
  if (stem.startsWith('proc-')) return 'PROCEDURE';
  if (stem.startsWith('con-')) return 'CONCEPT';
  if (stem.startsWith('ref-')) return 'REFERENCE';
  if (stem.startsWith('snip-') || stem === 'attributes') return 'SNIPPET';

  return null;
}

function readContentTypeInfo(lines) {
  let current = null;
  let occurrences = 0;
  let onFirstLine = false;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.startsWith(CONTENT_TYPE_ATTR)) {
      occurrences++;
      const val = line.slice(CONTENT_TYPE_ATTR.length).trim();
      if (!current) {
        current = val;
        onFirstLine = (i === 0);
      }
    }
  }
  return { current, occurrences, onFirstLine };
}

function checkContentType(file, detected, current, occurrences, onFirstLine) {
  const issues = [];

  if (!current && occurrences === 0) {
    issues.push(autofix(file, `Missing ${CONTENT_TYPE_ATTR} -- add ${detected}`, 1));
  } else if (!onFirstLine) {
    issues.push(autofix(file, `Content type not on first line -- move to line 1`, 1));
  } else if (current !== detected) {
    issues.push(autofix(file, `Content type: ${current} -> ${detected}`, 1));
  }

  if (occurrences > 1) {
    issues.push(autofix(file, `Content type appears ${occurrences} times -- remove duplicates`));
  }

  return issues;
}

// ── Section list checks ───────────────────────────────────────────────────────

function extractSectionContent(lines, sectionName) {
  let inSection = false;
  let inBlock = false;
  let inOpenBlock = false;
  const content = [];

  for (const line of lines) {
    if (!inSection) {
      if (line === `.${sectionName}`) inSection = true;
      continue;
    }
    if (SECTION_STOP_RE.test(line)) break;

    if (BLOCK_DELIM_RE.test(line)) { inBlock = !inBlock; continue; }
    if (line === '--') { inOpenBlock = !inOpenBlock; continue; }
    if (!inBlock && !inOpenBlock) content.push(line);
  }

  return content;
}

function checkSectionLists(file, lines, sectionName) {
  if (!lines.includes(`.${sectionName}`)) return [];

  const content = extractSectionContent(lines, sectionName);
  if (content.some(l => l.startsWith('include::'))) return [];

  const numbered = content.filter(l => /^\.+ /.test(l)).length;
  const unnumbered = content.filter(l => l.startsWith('* ')).length;
  const nested = content.filter(l => l.startsWith('** ')).length;

  const sectionLine = lines.indexOf(`.${sectionName}`) + 1;

  if (numbered === 1 && unnumbered === 0) {
    return [autofix(file, `Single numbered step in .${sectionName} -- convert to unnumbered`, sectionLine)];
  }
  if (unnumbered >= 1 && numbered >= 1 && nested === 0) {
    return [autofix(file, `Mixed list in .${sectionName} -- convert to numbered`, sectionLine)];
  }
  if (unnumbered >= 2 && numbered === 0 && nested === 0) {
    return [autofix(file, `Multiple unnumbered items in .${sectionName} -- convert to numbered`, sectionLine)];
  }
  return [];
}

function checkProcedureStructure(file, lines) {
  if (!lines.includes('.Procedure')) return [];

  const content = extractSectionContent(lines, 'Procedure');
  if (content.some(l => l.startsWith('include::'))) return [];

  const numbered = content.filter(l => /^\.+ /.test(l)).length;
  const unnumbered = content.filter(l => l.startsWith('* ')).length;

  if (numbered === 1 && unnumbered === 0) {
    const ln = lines.indexOf('.Procedure') + 1;
    return [manual(file, '.Procedure has only 1 numbered step (should be multiple or 1 unnumbered)', ln)];
  }
  return [];
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixContentType(abs, lines, detected) {
  const filtered = lines.filter(l => !l.startsWith(CONTENT_TYPE_ATTR));
  // Remove leading blank lines that were part of the old header
  while (filtered.length > 0 && filtered[0] === '') filtered.shift();
  const newContent = [`${CONTENT_TYPE_ATTR} ${detected}`, '', ...filtered].join('\n');
  writeFileSync(abs, newContent, 'utf8');
}

function fixSectionLists(abs, lines, sectionName) {
  if (!lines.includes(`.${sectionName}`)) return;

  const content = extractSectionContent(lines, sectionName);
  if (content.some(l => l.startsWith('include::'))) return;

  const numbered = content.filter(l => /^\.+ /.test(l)).length;
  const unnumbered = content.filter(l => l.startsWith('* ')).length;
  const nested = content.filter(l => l.startsWith('** ')).length;

  let text = readFileSync(abs, 'utf8');

  if (numbered === 1 && unnumbered === 0) {
    // Single numbered → unnumbered: replace `. ` with `* ` within section
    text = replaceSectionList(text, sectionName, /^\. /gm, '* ');
  } else if ((unnumbered >= 1 && numbered >= 1 && nested === 0) ||
             (unnumbered >= 2 && numbered === 0 && nested === 0)) {
    // Convert all * to . within section
    text = replaceSectionList(text, sectionName, /^\* /gm, '. ');
  }

  writeFileSync(abs, text, 'utf8');
}

function replaceSectionList(text, sectionName, pattern, replacement) {
  // Replace list markers within the section only
  const sectionStart = new RegExp(String.raw`^\.(${sectionName})$`, 'm');
  const match = sectionStart.exec(text);
  if (!match) return text;

  const before = text.slice(0, match.index + match[0].length);
  let after = text.slice(match.index + match[0].length);

  // Find end of section (next section marker or EOF)
  const stopMatch = SECTION_STOP_RE.exec(after.slice(1));
  if (stopMatch) {
    const sectionBody = after.slice(1, stopMatch.index + 1);
    const rest = after.slice(stopMatch.index + 1);
    return before + '\n' + sectionBody.replace(pattern, replacement) + rest;
  }
  return before + after.replace(pattern, replacement);
}

// ── Utilities ─────────────────────────────────────────────────────────────────

function readLines(file) {
  try { return readFileSync(file, 'utf8').split('\n').map(l => l.trimEnd()); } catch { return []; }
}
