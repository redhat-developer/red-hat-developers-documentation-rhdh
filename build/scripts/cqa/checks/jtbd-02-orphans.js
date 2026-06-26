/**
 * JTBD-02: Modules not yet wired into product_product
 *
 * Lists proc-*, con-*, and ref-* modules under modules/ that are NOT included
 * in the product_product title (the new JTBD structure). Snippets (snip-*) are
 * excluded because they are included transitively from within other modules.
 *
 * This check is purely informational — it always passes.
 * Output is a collapsible report grouped by module subdirectory, appended
 * after the CQA checklist via the getReport() method.
 */

import { existsSync, readdirSync } from 'node:fs';
import { resolve, basename, join } from 'node:path';
import { Checker } from '../lib/checker.js';
import { repoRoot, repoRelative, collectTitle } from '../lib/asciidoc.js';

const PRODUCT_TITLE = 'titles/product_product/master.adoc';
const MODULE_PREFIXES = ['proc-', 'con-', 'ref-'];

export default class Jtbd02Orphans extends Checker {
  id = 'jtbd-02';
  name = 'Modules not yet in product_product (informational)';

  /** Always passes — no issues returned. */
  check(_masterAdocPath) {
    return [];
  }

  /**
   * Build a markdown report listing modules not included in product_product.
   * Called by index.js after the checklist is printed.
   * @returns {string} markdown report (empty string if nothing to report)
   */
  getReport() {
    const root = repoRoot();
    const masterPath = resolve(root, PRODUCT_TITLE);
    if (!existsSync(masterPath)) return '';

    const includedFiles = new Set(collectTitle(PRODUCT_TITLE));
    const { orphansBySubdir, totalOrphans } = collectOrphans(root, includedFiles);

    if (totalOrphans === 0) return '';
    return formatReport(orphansBySubdir, totalOrphans);
  }
}

/**
 * Collect orphaned modules grouped by subdirectory.
 * @param {string} root - absolute repo root
 * @param {Set<string>} includedFiles - repo-relative paths included in product_product
 * @returns {{ orphansBySubdir: Map<string, string[]>, totalOrphans: number }}
 */
function collectOrphans(root, includedFiles) {
  const modulesDir = resolve(root, 'modules');
  const orphansBySubdir = new Map();
  let totalOrphans = 0;

  if (!existsSync(modulesDir)) return { orphansBySubdir, totalOrphans };

  for (const subdir of readdirSync(modulesDir, { withFileTypes: true })) {
    if (!subdir.isDirectory()) continue;
    const orphans = findOrphansInSubdir(join(modulesDir, subdir.name), includedFiles);

    if (orphans.length > 0) {
      orphansBySubdir.set(subdir.name, orphans);
      totalOrphans += orphans.length;
    }
  }

  return { orphansBySubdir, totalOrphans };
}

/**
 * Find orphaned proc-/con-/ref- modules in a single subdirectory.
 * @param {string} subdirPath - absolute path to the subdirectory
 * @param {Set<string>} includedFiles - repo-relative paths included in product_product
 * @returns {string[]} sorted repo-relative paths of orphaned modules
 */
function findOrphansInSubdir(subdirPath, includedFiles) {
  const orphans = [];
  for (const file of walkAdocFiles(subdirPath)) {
    const bn = basename(file);
    if (!MODULE_PREFIXES.some(p => bn.startsWith(p))) continue;
    if (bn.endsWith('.template.adoc')) continue;

    const relPath = repoRelative(file);
    if (!includedFiles.has(relPath)) {
      orphans.push(relPath);
    }
  }
  return orphans.sort((a, b) => a.localeCompare(b));
}

/**
 * Format the orphan report as a markdown string.
 * @param {Map<string, string[]>} orphansBySubdir
 * @param {number} totalOrphans
 * @returns {string}
 */
function formatReport(orphansBySubdir, totalOrphans) {
  const lines = [
    `\n## Modules not yet in product_product\n`,
    `${totalOrphans} modules (proc, con, ref) are not yet included in the \`product_product\` title.\n`,
  ];

  const sortedSubdirs = [...orphansBySubdir.keys()].sort((a, b) => a.localeCompare(b));
  for (const subdir of sortedSubdirs) {
    const orphans = orphansBySubdir.get(subdir);
    lines.push(
      `<details>`,
      `<summary><code>modules/${subdir}/</code> (${orphans.length})</summary>\n`,
      ...orphans.map(file => `- ${file}`),
      `\n</details>\n`,
    );
  }

  return lines.join('\n');
}

/** Recursively yield all .adoc files under a directory. */
function* walkAdocFiles(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) yield* walkAdocFiles(full);
    else if (entry.isFile() && entry.name.endsWith('.adoc')) yield full;
  }
}
