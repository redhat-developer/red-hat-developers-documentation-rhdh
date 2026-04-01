/**
 * CQA-02: Verify assembly structure
 *
 * Only checks assembly files (assemblies/*.adoc and titles/*\/master.adoc).
 *
 * Checks:
 *   1. Content type ASSEMBLY on line 1 → AUTOFIX
 *   2. [role="_abstract"] present → delegate to CQA-09
 *   3. Introduction length 50-300 → delegate to CQA-09 (non-master)
 *   4. ID with _{context} suffix → AUTOFIX (non-master)
 *   5. :context: after title → AUTOFIX
 *   6. Context save (line 2) + restore (last 2 lines) → AUTOFIX (non-master)
 *   7. .Prerequisites block title → AUTOFIX: == heading
 *   8. Level 3+ subheadings → MANUAL
 *   9. Additional resources format → AUTOFIX
 *  10. No content between includes → MANUAL
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, autofix, manual, delegate } from '../lib/checker.js';
import { repoRoot, collectTitle, getLines } from '../lib/asciidoc.js';

const CONTENT_TYPE_ATTR = ':_mod-docs-content-type:';
const CONTEXT_SAVE = 'ifdef::context[:parent-context: {context}]';
const CONTEXT_RESTORE_1 = 'ifdef::parent-context[:context: {parent-context}]';
const CONTEXT_RESTORE_2 = 'ifndef::parent-context[:!context:]';

function isAssemblyFile(file) {
  return file.includes('assemblies/') || basename(file) === 'master.adoc';
}

export default class Cqa02AssemblyStructure extends Checker {
  id = '02';
  name = 'Verify assembly structure';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      if (!isAssemblyFile(file)) continue;
      if (!existsSync(resolve(root, file))) continue;
      issues.push(...checkFile(root, file));
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

function checkAbstractAndIntro(file, lines, isMaster) {
  if (!lines.includes('[role="_abstract"]')) {
    return [delegate(file, '09', 'Missing [role="_abstract"] introduction')];
  }
  if (isMaster) return [];
  const abstractIdx = lines.indexOf('[role="_abstract"]');
  const intro = lines[abstractIdx + 1] ?? '';
  const len = intro.length;
  if (len < 50) {
    return [delegate(file, '09', `Introduction too short (${len} chars, recommend 50-300)`, abstractIdx + 2, false)];
  }
  if (len > 300) {
    return [delegate(file, '09', `Introduction too long (${len} chars, recommend 50-300)`, abstractIdx + 2, false)];
  }
  return [];
}

function checkIdAndContext(file, lines) {
  const issues = [];
  const idLine = lines.find(l => l.startsWith('[id='));
  if (!idLine) {
    issues.push(manual(file, 'Missing [id="..._{context}"] attribute'));
  } else if (!/\[id="[^"]*_\{context\}"\]/.test(idLine)) {
    issues.push(autofix(file, 'ID missing _{context} suffix'));
  }
  const contextIdx = lines.findIndex(l => l.startsWith(':context:'));
  if (contextIdx === -1) {
    issues.push(autofix(file, 'Missing :context: attribute'));
  } else {
    const titleIdx = lines.findIndex(l => l.startsWith('= '));
    if (titleIdx !== -1 && contextIdx <= titleIdx) {
      issues.push(autofix(file, ':context: must appear after the title', contextIdx + 1));
    }
  }
  return issues;
}

function checkFile(root, file) {
  const lines = getLines(file);
  const isMaster = basename(file) === 'master.adoc';
  const issues = [];

  // 1. Content type on first line
  if (lines[0] !== `${CONTENT_TYPE_ATTR} ASSEMBLY`) {
    issues.push(autofix(file, 'Content type ASSEMBLY not on first line', 1));
  }
  const ctCount = lines.filter(l => l.startsWith(CONTENT_TYPE_ATTR)).length;
  if (ctCount > 1) {
    issues.push(autofix(file, `Content type appears ${ctCount} times`));
  }

  // 2-3. Abstract and intro length
  issues.push(...checkAbstractAndIntro(file, lines, isMaster));

  if (!isMaster) {
    // 4-5. ID and context attribute
    issues.push(
      ...checkIdAndContext(file, lines),
      // 6. Context save/restore
      ...checkContextSaveRestore(file, lines),
    );
  }

  // 7. .Prerequisites block title
  const prereqIdx = lines.indexOf('.Prerequisites');
  if (prereqIdx !== -1) {
    issues.push(autofix(file, 'Uses .Prerequisites block title instead of == heading', prereqIdx + 1));
  }

  // 8. Level 3+ subheadings
  const level3Idx = lines.findIndex(l => l.startsWith('=== '));
  if (level3Idx !== -1) {
    issues.push(manual(file, 'Contains level 3+ subheadings (=== or deeper)', level3Idx + 1));
  }

  // 9-10. Additional resources and content between includes
  issues.push(
    ...checkAdditionalResources(file, lines),
    ...checkContentBetweenIncludes(file, lines),
  );

  return issues;
}

function checkContextSaveRestore(file, lines) {
  const issues = [];

  if (lines[1] !== CONTEXT_SAVE) {
    issues.push(autofix(file, 'Missing context save on line 2', 2));
  }
  const saveCount = lines.filter(l => l.startsWith('ifdef::context[:parent-context')).length;
  if (saveCount > 1) {
    issues.push(autofix(file, `Context save appears ${saveCount} times`));
  }

  // Find last non-empty lines (ignore trailing blank from final newline)
  const nonEmpty = lines.filter(l => l !== '');
  const last = nonEmpty.at(-1);
  const penult = nonEmpty.at(-2);
  if (penult !== CONTEXT_RESTORE_1) {
    issues.push(autofix(file, 'Missing context restore (second-to-last line)'));
  }
  if (last !== CONTEXT_RESTORE_2) {
    issues.push(autofix(file, 'Missing context restore (last line)'));
  }

  return issues;
}

function checkAdditionalResources(file, lines) {
  const hasBlockTitle = lines.includes('.Additional resources');
  const hasHeading = lines.includes('== Additional resources');
  const hasRole = lines.includes('[role="_additional-resources"]');

  if (hasBlockTitle) {
    const idx = lines.indexOf('.Additional resources');
    return [autofix(file, 'Uses .Additional resources block title', idx + 1)];
  }
  if (hasHeading && !hasRole) {
    const idx = lines.indexOf('== Additional resources');
    return [autofix(file, 'Missing [role="_additional-resources"] attribute', idx + 1)];
  }
  return [];
}

function checkContentBetweenIncludes(file, lines) {
  const titleIdx = lines.findIndex(l => l.startsWith('= '));
  if (titleIdx === -1) return [];

  const includeIdxs = [];
  for (let i = titleIdx; i < lines.length; i++) {
    if (lines[i].startsWith('include::') && !lines[i].includes('artifacts/')) {
      includeIdxs.push(i);
    }
  }

  if (includeIdxs.length < 2) return [];

  const first = includeIdxs[0];
  const last = includeIdxs.at(-1);

  let contentLines = 0;
  for (let i = first + 1; i < last; i++) {
    const l = lines[i];
    if (!l || l.startsWith('include::') || l.startsWith('//') ||
        l.startsWith('ifdef::') || l.startsWith('ifndef::') || l.startsWith('endif::') ||
        l.startsWith('[role=') || l === '.Additional resources' || l.startsWith('== ')) {
      continue;
    }
    contentLines++;
  }

  if (contentLines > 0) {
    return [manual(file, `Content between include statements (${contentLines} lines)`, first + 1)];
  }
  return [];
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function fixContextRestore(rawLines) {
  let lines = rawLines.map(l => l.trimEnd());
  const last = lines.at(-1);
  const penult = lines.at(-2);
  if (penult === CONTEXT_RESTORE_1 && last === CONTEXT_RESTORE_2) return rawLines;

  while (lines.length > 0) {
    const tail = lines.at(-1);
    if (tail !== '' && tail !== CONTEXT_RESTORE_1 && tail !== CONTEXT_RESTORE_2) break;
    rawLines.pop();
    lines = rawLines.map(l => l.trimEnd());
  }
  rawLines.push('', CONTEXT_RESTORE_1, CONTEXT_RESTORE_2);
  return rawLines;
}

function fixAssemblyContextAndSave(rawLines) {
  // 4. Fix ID _{context}
  rawLines = rawLines.map(l => {
    if (/^\[id="[^"]*"\]/.test(l) && !l.includes('_{context}')) {
      return l.replace(/\[id="([^"]+)"\]/, '[id="$1_{context}"]');
    }
    return l;
  });
  let lines = rawLines.map(l => l.trimEnd());

  // 5. Fix :context: - move after title
  const titleIdx = lines.findIndex(l => l.startsWith('= '));
  if (titleIdx !== -1) {
    const ctxIdx = lines.findIndex(l => l.startsWith(':context:'));
    const idLine = lines.find(l => l.startsWith('[id='));
    const idValue = idLine ? (/\[id="([^"_]+)/.exec(idLine) ?? [])[1] : null;

    if (ctxIdx !== -1) rawLines.splice(ctxIdx, 1);
    lines = rawLines.map(l => l.trimEnd());
    const newTitleIdx = lines.findIndex(l => l.startsWith('= '));
    if (newTitleIdx !== -1 && idValue) {
      rawLines.splice(newTitleIdx + 1, 0, '', `:context: ${idValue}`);
    }
    lines = rawLines.map(l => l.trimEnd());
  }

  // 6. Fix context save (line 2)
  if (lines[1] !== CONTEXT_SAVE) {
    rawLines.splice(1, 0, CONTEXT_SAVE);
  }

  // Fix context restore (last 2 lines)
  return fixContextRestore(rawLines);
}

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  const isMaster = basename(file) === 'master.adoc';
  let rawLines = readFileSync(abs, 'utf8').split('\n');

  // 1. Fix content type on line 1
  rawLines = rawLines.filter(l => !l.trimEnd().startsWith(CONTENT_TYPE_ATTR));
  rawLines.unshift(`${CONTENT_TYPE_ATTR} ASSEMBLY`, '');

  if (!isMaster) {
    rawLines = fixAssemblyContextAndSave(rawLines);
  }

  // 7. Fix .Prerequisites → == Prerequisites
  rawLines = rawLines.map(l => l.trimEnd() === '.Prerequisites' ? '== Prerequisites' : l);

  // 9. Fix additional resources
  rawLines = fixAdditionalResources(rawLines);

  writeFileSync(abs, rawLines.join('\n'), 'utf8');
}

function fixAdditionalResources(rawLines) {
  const lines = rawLines.map(l => l.trimEnd());

  // .Additional resources → [role] + == heading
  const blockIdx = lines.indexOf('.Additional resources');
  if (blockIdx !== -1) {
    // Remove any preceding [role="_additional-resources"] if present
    const start = blockIdx > 0 && lines[blockIdx - 1] === '[role="_additional-resources"]'
      ? blockIdx - 1 : blockIdx;
    rawLines.splice(start, blockIdx - start + 1, '[role="_additional-resources"]', '== Additional resources');
    return rawLines;
  }

  // == Additional resources without role → add role before
  const headingIdx = lines.indexOf('== Additional resources');
  if (headingIdx !== -1 && !lines.includes('[role="_additional-resources"]')) {
    rawLines.splice(headingIdx, 0, '[role="_additional-resources"]');
  }

  return rawLines;
}
