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
import { resolve, dirname } from 'node:path';
import { Checker, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getLines } from '../lib/asciidoc.js';

const INCLUDE_RE = /^include::([^[]+)\[/;
const IMAGE_BLOCK_RE = /image::([^[]+)\[/;
const IMAGESDIR_RE = /^:imagesdir:\s*(.+)/;

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

function findImagesdir(lines) {
  for (const line of lines) {
    const m = IMAGESDIR_RE.exec(line);
    if (m) return m[1].trim();
  }
  return null;
}

function resolveImagesdir(root, masterAdocPath) {
  const found = findImagesdir(getLines(masterAdocPath));
  if (found) return found;

  const attrsPath = 'artifacts/attributes.adoc';
  if (existsSync(resolve(root, attrsPath))) {
    const found2 = findImagesdir(getLines(attrsPath));
    if (found2) return found2;
  }

  return '';
}

function checkInclude(file, line, lineNum, fileDir) {
  const includeMatch = INCLUDE_RE.exec(line);
  if (!includeMatch) return null;
  const includePath = includeMatch[1].trim();
  if (includePath.includes('{')) return null;
  const resolved = resolve(fileDir, includePath);
  if (!existsSync(resolved)) {
    return manual(file, `Broken include: ${includePath}`, lineNum);
  }
  return null;
}

function isSkippableImagePath(imagePath) {
  return imagePath.includes('{') || imagePath.includes('://') ||
         imagePath.includes(' ') || imagePath.includes("'") ||
         !imagePath;
}

function checkImage(file, line, lineNum, root, fileDir, imagesdir) {
  const imageMatch = IMAGE_BLOCK_RE.exec(line);
  if (!imageMatch) return null;
  const imagePath = imageMatch[1].trim();
  if (isSkippableImagePath(imagePath)) return null;

  const found = (imagesdir && existsSync(resolve(root, imagesdir, imagePath))) ||
                existsSync(resolve(fileDir, imagePath)) ||
                existsSync(resolve(root, imagePath));

  if (!found) {
    return manual(file, `Broken image: ${imagePath}`, lineNum);
  }
  return null;
}

function checkFile(root, file, imagesdir) {
  const lines = getLines(file);
  const fileDir = dirname(resolve(root, file));
  const issues = [];

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    const includeIssue = checkInclude(file, line, lineNum, fileDir);
    if (includeIssue) issues.push(includeIssue);

    const imageIssue = checkImage(file, line, lineNum, root, fileDir, imagesdir);
    if (imageIssue) issues.push(imageIssue);
  }

  return issues;
}
