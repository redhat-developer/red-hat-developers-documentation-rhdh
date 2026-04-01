/**
 * CQA-06: Verify assemblies follow official template (one user story)
 *
 * For ASSEMBLY files only (skip attributes.adoc, non-ASSEMBLY content types):
 *   1. Non-master: more than 3 nested assembly includes → MANUAL
 *   2. Non-master: more than 15 total includes → MANUAL
 *   3. All: missing assembly title (= Title) → MANUAL
 *
 * No autofixes — splitting assemblies requires human judgment.
 */

import { existsSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

export default class Cqa06AssemblyScope extends Checker {
  id = '06';
  name = 'Verify assemblies follow official template (one user story)';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      if (basename(file) === 'attributes.adoc') continue;
      if (!existsSync(resolve(root, file))) continue;

      const contentType = getContentType(file);
      if (!contentType || contentType !== 'ASSEMBLY') continue;

      issues.push(...checkFile(file));
    }

    return issues;
  }
}

// ── Per-file check ────────────────────────────────────────────────────────────

function checkFile(file) {
  const lines = getLines(file);
  const isMaster = basename(file) === 'master.adoc';
  const issues = [];

  if (!isMaster) {
    const assemblyIncludes = lines.filter(l => l.startsWith('include::') && l.includes('assembly-')).length;
    if (assemblyIncludes > 3) {
      issues.push(manual(file, `Has ${assemblyIncludes} nested assembly includes (may cover multiple user stories, max 3)`));
    }

    const totalIncludes = lines.filter(l => l.startsWith('include::')).length;
    if (totalIncludes > 15) {
      issues.push(manual(file, `Has ${totalIncludes} includes (consider splitting -- may cover multiple user stories, max 15)`));
    }
  }

  if (!lines.some(l => l.startsWith('= '))) {
    issues.push(manual(file, 'Missing assembly title (= Title)'));
  }

  return issues;
}
