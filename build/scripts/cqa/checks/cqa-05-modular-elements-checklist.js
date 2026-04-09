/**
 * CQA-05: Verify required modular elements
 *
 * Checks assemblies/, modules/, and titles/*\/master.adoc files:
 *   1. Content type metadata → delegate to CQA-03
 *   2. Topic ID with {context} → AUTOFIX or MANUAL; master.adoc → delegate to CQA-02
 *   3. Single H1 title → MANUAL
 *   4. Short introduction [role="_abstract"] → delegate to CQA-09
 *   5. Blank line after H1 → AUTOFIX
 *   6. Image alt text → MANUAL
 *   7. No admonition titles (.NOTE etc.) → AUTOFIX
 *   8. Nested assembly context save/restore → delegate to CQA-02
 *   9. ASSEMBLY: no level 3+ subheadings, no non-additional-resources block titles
 *  10. CONCEPT/REFERENCE: no level 3+ subheadings, no non-standard block titles
 *  11. PROCEDURE: no subheadings, has .Procedure, no non-standard block titles
 *
 * Fix: ID suffix, blank line after H1, remove admonition titles
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, autofix, manual, delegate } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

const BLOCK_TITLE_RE = /^\.[A-Z]/;
const ADMONITION_PREFIXES = ['.NOTE', '.WARNING', '.IMPORTANT', '.TIP', '.CAUTION'];
const PROC_ALLOWED_BLOCKS = new Set([
  '.Prerequisites', '.Prerequisite', '.Procedure', '.Verification',
  '.Results', '.Result', '.Troubleshooting', '.Troubleshooting steps',
  '.Troubleshooting step', '.Next steps', '.Next step', '.Additional resources',
]);

function isTargetFile(file) {
  return file.includes('assemblies/') || file.includes('modules/') || basename(file) === 'master.adoc';
}

function isAdmonitionTitle(line) {
  return ADMONITION_PREFIXES.some(p => line.startsWith(p));
}

export default class Cqa05ModularElementsChecklist extends Checker {
  id = '05';
  name = 'Verify required modular elements';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      if (!isTargetFile(file)) continue;
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

function checkSnippet(file, lines) {
  const issues = [];
  const titleLine = lines.find(l => l.startsWith('= '));
  if (titleLine) {
    const title = titleLine.slice(2).trim();
    issues.push(manual(file, `Snippet has title '= ${title}' -- remove from snippet and add to including files`));
  }
  const blockTitle = lines.find(l => BLOCK_TITLE_RE.test(l));
  if (blockTitle) {
    issues.push(manual(file, `Snippet has block title '${blockTitle}' -- move to including files`));
  }
  return issues;
}

function checkTopicId(file, lines, isMaster) {
  if (isMaster) {
    const hasCtxId = lines.some(l => l === '[id="{context}"]' || l === "[id='{context}']");
    if (!hasCtxId) {
      return [delegate(file, '02', 'Missing or incorrect topic ID (master.adoc should use [id="{context}"])', null, true)];
    }
    return [];
  }
  const hasCtxId = lines.some(l => /\[id=".*_\{context\}"\]/.test(l) || /\[id='.*_\{context\}'\]/.test(l));
  if (hasCtxId) return [];
  const hasId = lines.some(l => l.startsWith('[id="') || l.startsWith("[id='"));
  if (hasId) return [autofix(file, 'Topic ID missing _{context} suffix')];
  return [manual(file, 'Missing [id="..._{context}"] topic ID')];
}

function checkBlankAfterH1(file, lines) {
  const titleIdx = lines.findIndex(l => l.startsWith('= '));
  if (titleIdx === -1) return [];
  let checkIdx = titleIdx + 1;
  while (checkIdx < lines.length && lines[checkIdx].startsWith(':')) {
    checkIdx++;
  }
  if (checkIdx < lines.length && lines[checkIdx] !== '') {
    return [autofix(file, 'Missing blank line after H1 title', checkIdx + 1)];
  }
  return [];
}

function checkNestedAssembly(file, lines) {
  const issues = [];
  const SAVE = 'ifdef::context[:parent-context: {context}]';
  const RESTORE_1 = 'ifdef::parent-context[:context: {parent-context}]';
  const RESTORE_2 = 'ifndef::parent-context[:!context:]';

  if (!lines.includes(SAVE)) {
    issues.push(delegate(file, '02', 'Nested assembly missing parent-context preservation at top', null, true));
  }
  if (!lines.includes(RESTORE_1) || !lines.includes(RESTORE_2)) {
    issues.push(delegate(file, '02', 'Nested assembly missing context restoration at bottom', null, true));
  }
  if (!lines.some(l => l.startsWith(':context: '))) {
    issues.push(delegate(file, '02', 'Nested assembly missing :context: declaration', null, true));
  }
  return issues;
}

function checkGeneral(file, lines, isMaster, contentType) {
  const issues = [];

  if (!contentType) {
    issues.push(delegate(file, '03', 'Missing :_mod-docs-content-type: metadata', null, true));
  }

  issues.push(...checkTopicId(file, lines, isMaster));

  const h1Count = lines.filter(l => l.startsWith('= ')).length;
  if (h1Count !== 1) {
    issues.push(manual(file, `Has ${h1Count} H1 titles (should be exactly 1)`));
  }

  if (!lines.includes('[role="_abstract"]')) {
    issues.push(delegate(file, '09', 'Missing [role="_abstract"] short introduction', null, true));
  }

  issues.push(...checkBlankAfterH1(file, lines));

  const imageMissing = lines.find(l => l.startsWith('image::') && !l.includes('["'));
  if (imageMissing) {
    issues.push(manual(file, 'Image(s) missing alt text in quotes', lines.indexOf(imageMissing) + 1));
  }

  const admonitionIdx = lines.findIndex(isAdmonitionTitle);
  if (admonitionIdx !== -1) {
    issues.push(autofix(file, 'Admonition has title (should not have title)', admonitionIdx + 1));
  }

  const isNestedAssembly = contentType === 'ASSEMBLY' &&
    lines.some(l => l.startsWith('ifdef::context[:parent-context:'));
  if (isNestedAssembly) {
    issues.push(...checkNestedAssembly(file, lines));
  }

  return issues;
}

function checkAssembly(file, lines) {
  const issues = [];
  const level3Idx = lines.findIndex(l => l.startsWith('=== '));
  if (level3Idx !== -1) {
    issues.push(manual(file, 'Assembly contains level 2+ subheadings (=== or deeper)'));
  }
  const blockTitle = lines.find(l => BLOCK_TITLE_RE.test(l) && l !== '.Additional resources');
  if (blockTitle) {
    issues.push(delegate(file, '02', 'Assembly contains block titles (only .Additional resources allowed)'));
  }
  return issues;
}

function checkConceptReference(file, lines, contentType) {
  const issues = [];
  const level3Idx = lines.findIndex(l => l.startsWith('=== '));
  if (level3Idx !== -1) {
    issues.push(manual(file, `${contentType} contains level 3+ subheadings (=== or deeper) -- only == (H2) subheadings allowed`, level3Idx + 1));
  }
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    if (BLOCK_TITLE_RE.test(l) && l !== '.Additional resources' && l !== '.Next steps') {
      issues.push(manual(file, `Non-standard block title: ${l}`, i + 1));
    }
  }
  return issues;
}

function checkProcedure(file, lines) {
  const issues = [];

  const subheadingIdx = lines.findIndex(l => l.startsWith('== '));
  if (subheadingIdx !== -1) {
    issues.push(manual(file, 'Procedure contains subheadings (== or deeper) -- procedures must not have subheadings', subheadingIdx + 1));
  }

  const hasProcedureExact = lines.includes('.Procedure');
  if (hasProcedureExact) {
    const procCount = lines.filter(l => l === '.Procedure' || l.startsWith('.Procedure ')).length;
    if (procCount > 1) {
      issues.push(manual(file, `Has ${procCount} .Procedure block titles (should be exactly 1)`));
    }
    if (lines.some(l => l.startsWith('.Procedure '))) {
      issues.push(manual(file, ".Procedure block title has embellishments (should be just '.Procedure')"));
    }
  } else {
    issues.push(delegate(file, '04', 'Missing .Procedure block title', null, true));
  }

  for (const l of lines) {
    if (BLOCK_TITLE_RE.test(l) && !PROC_ALLOWED_BLOCKS.has(l)) {
      issues.push(manual(file, `Non-standard block title: ${l}`));
    }
  }

  return issues;
}

function checkFile(file) {
  const lines = getLines(file);
  const contentType = getContentType(file);
  const isMaster = basename(file) === 'master.adoc';

  if (contentType === 'SNIPPET') return checkSnippet(file, lines);

  const issues = checkGeneral(file, lines, isMaster, contentType);

  if (contentType === 'ASSEMBLY') {
    issues.push(...checkAssembly(file, lines));
  } else if (contentType === 'CONCEPT' || contentType === 'REFERENCE') {
    issues.push(...checkConceptReference(file, lines, contentType));
  } else if (contentType === 'PROCEDURE') {
    issues.push(...checkProcedure(file, lines));
  }

  return issues;
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixIdSuffix(rawLines) {
  return rawLines.map(l => {
    if (/^\[id="[^"]*"\]/.test(l) && !l.includes('_{context}')) {
      return l.replace(/\[id="([^"]+)"\]/, '[id="$1_{context}"]');
    }
    return l;
  });
}

function fixBlankAfterH1(rawLines) {
  const lines = rawLines.map(l => l.trimEnd());
  const titleIdx = lines.findIndex(l => l.startsWith('= '));
  if (titleIdx === -1) return rawLines;
  let checkIdx = titleIdx + 1;
  while (checkIdx < lines.length && lines[checkIdx].startsWith(':')) {
    checkIdx++;
  }
  if (checkIdx < lines.length && lines[checkIdx] !== '') {
    rawLines.splice(checkIdx, 0, '');
  }
  return rawLines;
}

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  let rawLines = readFileSync(abs, 'utf8').split('\n');
  rawLines = fixIdSuffix(rawLines);
  rawLines = fixBlankAfterH1(rawLines);
  rawLines = rawLines.filter(l => !isAdmonitionTitle(l.trimEnd()));

  writeFileSync(abs, rawLines.join('\n'), 'utf8');
}
