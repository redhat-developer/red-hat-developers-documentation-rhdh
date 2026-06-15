/**
 * CQA-14b: Inbound link stability — refuse ID changes for existing files
 *
 * Protects URLs generated from document IDs by detecting when an [id="..."]
 * attribute has been changed in a file that already exists in the base branch.
 * New files (not present in the base branch) are allowed to have any ID.
 *
 * This is the complement of CQA-14 (no broken links): CQA-14 checks that
 * internal and outbound links resolve; CQA-14b checks that inbound links
 * from the outside are not broken by ID changes.
 *
 * Detection:
 *   - For each .adoc file in the title, extract the current [id="..."] value
 *   - Retrieve the same file from the merge-base (common ancestor with main)
 *   - If the file existed and the base ID changed, flag as MANUAL
 *   - New files and unchanged IDs pass silently
 *
 * Fix: none (manual only — revert the ID change)
 */

import { existsSync, readFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { execFileSync } from 'node:child_process';
import { GIT } from '../lib/bin.js';
import { Checker, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getLines } from '../lib/asciidoc.js';

// ── ID extraction ────────────────────────────────────────────────────────────

const ID_RE = /\[id=["']([^"']+)["']\]/;

/**
 * Extract the base document ID (without _{context} suffix) from file lines.
 * @param {string[]} lines
 * @returns {string | null}
 */
function extractBaseId(lines) {
  for (const line of lines) {
    const m = ID_RE.exec(line);
    if (m) {
      // Strip _{context} or _<literal-context> suffix
      return m[1].replace(/_{[^}]+}$/, '').replace(/_[a-z][a-z0-9-]*$/, '');
    }
  }
  return null;
}

// ── Git helpers ──────────────────────────────────────────────────────────────

let _mergeBase = undefined; // undefined = not yet computed, null = not available

/**
 * Find the merge-base commit between HEAD and the default branch.
 * Tries main, then master. Returns null if no merge base is found
 * (e.g., shallow clone, detached HEAD with no upstream).
 */
function getMergeBase(root) {
  if (_mergeBase !== undefined) return _mergeBase;

  for (const branch of ['origin/main', 'origin/master', 'main', 'master']) {
    try {
      _mergeBase = execFileSync(GIT, ['merge-base', 'HEAD', branch], {
        cwd: root, encoding: 'utf8',
      }).trim();
      return _mergeBase;
    } catch {
      // Branch not found or no common ancestor — try next
    }
  }

  _mergeBase = null;
  return null;
}

/**
 * Retrieve file content from the merge-base commit.
 * @returns {string | null}  File content, or null if file didn't exist.
 */
function getFileAtBase(root, repoRelPath) {
  const base = getMergeBase(root);
  if (!base) return null;

  try {
    return execFileSync(GIT, ['show', `${base}:${repoRelPath}`], {
      cwd: root, encoding: 'utf8',
    });
  } catch {
    // File didn't exist at the merge-base commit
    return null;
  }
}

// ── Checker ──────────────────────────────────────────────────────────────────

export default class Cqa14bInboundLinkStability extends Checker {
  id = '14b';
  name = 'Inbound link stability (no ID changes for existing files)';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    // If we can't find a merge base, skip the check silently.
    // This happens in shallow clones or when there's no upstream branch.
    if (!getMergeBase(root)) return issues;

    for (const file of files) {
      const bn = basename(file);
      if (bn === 'attributes.adoc' || bn === 'master.adoc') continue;
      if (!existsSync(resolve(root, file))) continue;

      const issue = checkFile(root, file);
      if (issue) issues.push(issue);
    }

    return issues;
  }

  // No fix — ID changes must be reverted manually
}

function checkFile(root, file) {
  // Get the current ID
  const currentLines = getLines(file);
  const currentId = extractBaseId(currentLines);
  if (!currentId) return null; // No ID in current file — nothing to protect

  // Get the file content from the merge-base
  const baseContent = getFileAtBase(root, file);
  if (!baseContent) return null; // New file — any ID is acceptable

  // Extract the ID from the base version
  const baseLines = baseContent.split('\n');
  const baseId = extractBaseId(baseLines);
  if (!baseId) return null; // File existed but had no ID — nothing to compare

  // Compare IDs
  if (currentId !== baseId) {
    return manual(
      file,
      `ID changed: "${baseId}" -> "${currentId}" — ` +
      `reverting to "${baseId}" is required to preserve inbound URLs. ` +
      `If this is intentional, a redirect must be set up.`
    );
  }

  return null;
}
