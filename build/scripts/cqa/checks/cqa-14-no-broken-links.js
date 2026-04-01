/**
 * CQA-14: No broken links
 *
 * For each .adoc file:
 *   - include:: targets must resolve to existing files
 *   - image:: references must resolve to existing files
 *   - Skip paths with attribute substitutions ({attr})
 *
 * All violations are MANUAL — fixing broken links requires human judgment.
 */

import { existsSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';
import { Checker, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getLines } from '../lib/asciidoc.js';

const INCLUDE_RE = /^include::([^[]+)\[/;
const IMAGE_BLOCK_RE = /image::([^[]+)\[/;

export default class Cqa14NoBrokenLinks extends Checker {
  id = '14';
  name = 'Verify no broken links';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    // Resolve :imagesdir:
    const imagesdir = resolveImagesdir(root, masterAdocPath);

    for (const file of files) {
      if (!file.endsWith('.adoc')) continue;
      if (!existsSync(resolve(root, file))) continue;

      issues.push(...checkFile(root, file, imagesdir));
    }

    return issues;
  }

  // No fix() — all CQA-14 issues are manual
}

function resolveImagesdir(root, masterAdocPath) {
  const masterLines = getLines(masterAdocPath);
  for (const line of masterLines) {
    const m = line.match(/^:imagesdir:\s*(.+)/);
    if (m) return m[1].trim();
  }

  const attrsPath = 'artifacts/attributes.adoc';
  if (existsSync(resolve(root, attrsPath))) {
    const attrLines = getLines(attrsPath);
    for (const line of attrLines) {
      const m = line.match(/^:imagesdir:\s*(.+)/);
      if (m) return m[1].trim();
    }
  }

  return '';
}

function checkFile(root, file, imagesdir) {
  const lines = getLines(file);
  const fileDir = dirname(resolve(root, file));
  const issues = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    // Check include:: references
    const includeMatch = INCLUDE_RE.exec(line);
    if (includeMatch) {
      const includePath = includeMatch[1].trim();
      if (!includePath.includes('{')) {
        const resolved = resolve(fileDir, includePath);
        if (!existsSync(resolved)) {
          issues.push(manual(file, `Broken include: ${includePath}`, lineNum));
        }
      }
    }

    // Check image:: references
    const imageMatch = IMAGE_BLOCK_RE.exec(line);
    if (imageMatch) {
      const imagePath = imageMatch[1].trim();
      // Skip attribute substitutions, URLs, empty, paths with spaces/quotes
      if (imagePath.includes('{') || imagePath.includes('://') ||
          imagePath.includes(' ') || imagePath.includes("'") ||
          !imagePath) continue;

      const found = (imagesdir && existsSync(resolve(root, imagesdir, imagePath))) ||
                    existsSync(resolve(fileDir, imagePath)) ||
                    existsSync(resolve(root, imagePath));

      if (!found) {
        issues.push(manual(file, `Broken image: ${imagePath}`, lineNum));
      }
    }
  }

  return issues;
}
