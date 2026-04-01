/**
 * CQA-00a: Orphaned modules
 *
 * Finds .adoc files in artifacts/, assemblies/, modules/ not referenced by
 * any include:: directive anywhere in the repo, and image files in images/
 * not referenced by any .adoc file.
 *
 * Scope: entire repo (ignores title path arg, always scans everything).
 * Fix: git rm (if tracked) or rm. Cleans empty image dirs after deletion.
 */

import { readdirSync, existsSync, rmSync, readFileSync } from 'node:fs';
import { resolve, basename, join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { GIT } from '../lib/bin.js';
import { Checker, autofix } from '../lib/checker.js';
import { repoRoot, repoRelative } from '../lib/asciidoc.js';

const IMAGE_RE = /image::?([^[\s]+)\[/g;

export default class Cqa00aOrphaned extends Checker {
  id = '00a';
  name = 'Orphaned modules';

  check(_masterAdocPath) {
    const root = repoRoot();
    const { includedBasenames, includedPatterns } = collectIncludes(root);
    const referencedImages = collectImageRefs(root);
    return [
      ...checkAdocFiles(root, includedBasenames, includedPatterns),
      ...checkImageFiles(root, referencedImages),
    ];
  }

  fix(_masterAdocPath, issues) {
    const root = repoRoot();
    let deletedAny = false;

    for (const iss of issues) {
      const abs = resolve(root, iss.file);
      if (!existsSync(abs)) continue;
      try {
        execFileSync(GIT, ['rm', '-q', abs], { cwd: root, stdio: 'pipe' });
      } catch {
        rmSync(abs);
      }
      deletedAny = true;
    }

    if (deletedAny) {
      const imagesDir = resolve(root, 'images');
      if (existsSync(imagesDir)) removeEmptyDirs(imagesDir);
    }
  }
}

// ── Detection helpers ─────────────────────────────────────────────────────────

function checkAdocFiles(root, includedBasenames, includedPatterns) {
  const issues = [];
  for (const dir of ['artifacts', 'assemblies', 'modules']) {
    const abs = resolve(root, dir);
    if (!existsSync(abs)) continue;
    for (const file of walkAdoc(abs)) {
      if (file.endsWith('.template.adoc')) continue;
      if (!isIncluded(basename(file), includedBasenames, includedPatterns)) {
        issues.push(autofix(repoRelative(file), 'Orphaned .adoc file (not included anywhere)'));
      }
    }
  }
  return issues;
}

function checkImageFiles(root, referencedImages) {
  const issues = [];
  const imagesDir = resolve(root, 'images');
  if (!existsSync(imagesDir)) return issues;
  for (const file of walkFiles(imagesDir)) {
    if (!referencedImages.has(basename(file))) {
      issues.push(autofix(repoRelative(file), 'Orphaned image (not referenced by any .adoc file)'));
    }
  }
  return issues;
}

function collectIncludes(root) {
  const includedBasenames = new Set();
  const includedPatterns = [];

  for (const file of walkAdoc(root)) {
    for (const line of readLines(file)) {
      if (!line.startsWith('include::')) continue;
      const raw = line.slice('include::'.length);
      const bracketIdx = raw.indexOf('[');
      const path = (bracketIdx >= 0 ? raw.slice(0, bracketIdx) : raw).trim();
      const bn = basename(path);
      if (bn.includes('{')) {
        includedPatterns.push(patternToGlob(bn));
      } else {
        includedBasenames.add(bn);
      }
    }
  }

  return { includedBasenames, includedPatterns };
}

function collectImageRefs(root) {
  const referenced = new Set();
  for (const dir of ['titles', 'modules', 'assemblies']) {
    const abs = resolve(root, dir);
    if (!existsSync(abs)) continue;
    for (const file of walkAdoc(abs)) {
      collectImageRefsFromFile(file, referenced);
    }
  }
  return referenced;
}

function collectImageRefsFromFile(file, referenced) {
  for (const line of readLines(file)) {
    for (const m of line.matchAll(IMAGE_RE)) {
      const ref = m[1];
      if (!ref.startsWith('http://') && !ref.startsWith('https://')) {
        referenced.add(basename(ref));
      }
    }
  }
}

// ── Pure utilities ────────────────────────────────────────────────────────────

function patternToGlob(bn) {
  // Split on {attr} placeholders, returning fixed segments
  const segments = [];
  let pos = 0;
  let open = bn.indexOf('{', pos);
  while (open >= 0) {
    segments.push(bn.slice(pos, open));
    const close = bn.indexOf('}', open + 1);
    pos = close >= 0 ? close + 1 : bn.length;
    open = bn.indexOf('{', pos);
  }
  segments.push(bn.slice(pos));
  return segments;
}

function isIncluded(bn, basenames, patterns) {
  if (basenames.has(bn)) return true;
  return patterns.some(segments => {
    if (segments.length <= 1) return bn === (segments[0] || '');
    // Check that bn starts with first segment, ends with last, and contains middle segments in order
    if (!bn.startsWith(segments[0])) return false;
    if (!bn.endsWith(segments[segments.length - 1])) return false;
    let pos = segments[0].length;
    for (let i = 1; i < segments.length - 1; i++) {
      const idx = bn.indexOf(segments[i], pos);
      if (idx < 0) return false;
      pos = idx + segments[i].length;
    }
    return true;
  });
}

function* walkAdoc(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) yield* walkAdoc(full);
    else if (entry.isFile() && entry.name.endsWith('.adoc')) yield full;
  }
}

function* walkFiles(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) yield* walkFiles(full);
    else if (entry.isFile()) yield full;
  }
}

function readLines(file) {
  try {
    return readFileSync(file, 'utf8').split('\n');
  } catch { return []; }
}

function removeEmptyDirs(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) removeEmptyDirs(join(dir, entry.name));
  }
  if (readdirSync(dir).length === 0) rmSync(dir, { recursive: true });
}
