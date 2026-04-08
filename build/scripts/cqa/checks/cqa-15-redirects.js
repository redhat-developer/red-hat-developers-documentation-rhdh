/**
 * CQA-15: Redirects
 *
 * Detects cases where redirects may be needed:
 *   - Deleted title master.adoc files (title removed)
 *   - Changed :title: in master.adoc (title renamed)
 *
 * Uses git diff to detect changes against the base branch (CQA_BASE_REF env var)
 * or HEAD~5 as a fallback for local runs.
 * All violations are MANUAL — redirect implementation is platform-dependent.
 */

import { execFileSync } from 'node:child_process';
import { GIT } from '../lib/bin.js';
import { basename } from 'node:path';
import { Checker, manual } from '../lib/checker.js';
import { repoRoot } from '../lib/asciidoc.js';

export default class Cqa15Redirects extends Checker {
  id = '15';
  name = 'Check redirects';

  check(masterAdocPath) {
    const root = repoRoot();
    const issues = [];

    if (basename(masterAdocPath) !== 'master.adoc') return issues;

    // Check if this specific master.adoc was deleted (only on the current branch)
    const deleted = gitDiff(root, '--name-status', '--diff-filter=D', '--', masterAdocPath);
    if (deleted.length > 0) {
      const dir = masterAdocPath.replace(/\/master\.adoc$/, '');
      issues.push(manual(masterAdocPath, `Title removed: ${dir} -- needs redirect`));
    }

    // Check if :title: changed in this master.adoc
    const diff = gitDiff(root, '--', masterAdocPath);
    const titleChanges = diff.filter(l => /^[-+]:title:/.test(l) && !/^[-+][-+][-+]/.test(l));
    const oldTitle = titleChanges.find(l => l.startsWith('-:title:'))?.replace(/^-:title:\s*/, '');
    const newTitle = titleChanges.find(l => l.startsWith('+:title:'))?.replace(/^\+:title:\s*/, '');

    if (oldTitle && newTitle && oldTitle !== newTitle) {
      issues.push(manual(masterAdocPath, `Title changed: '${oldTitle}' -> '${newTitle}' -- may need redirect`));
    }

    return issues;
  }

  // No fix() — all CQA-15 issues are manual
}

function gitDiff(root, ...args) {
  const baseRef = process.env.CQA_BASE_REF || 'HEAD~5';
  try {
    const output = execFileSync(GIT, ['diff', `${baseRef}..HEAD`, ...args], {
      cwd: root,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe'],
    });
    return output.trim().split('\n').filter(Boolean);
  } catch {
    return [];
  }
}
