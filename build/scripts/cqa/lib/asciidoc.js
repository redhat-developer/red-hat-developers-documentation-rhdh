/**
 * asciidoc.js — AsciiDoc file loading and shared utilities
 *
 * Key exports:
 *   collectTitle(masterAdocPath) → string[]   ordered file list for a title
 *   getContentType(filePath) → string | null  ASSEMBLY | PROCEDURE | CONCEPT | REFERENCE | SNIPPET
 *   getLines(filePath) → string[]             raw lines (cached)
 *   repoRoot() → string                       absolute repo root path
 *   setRepoRoot(path) → void                  override root (for worktree testing)
 */

import { readFileSync, existsSync, realpathSync } from 'node:fs';
import { resolve, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
let _repoRoot = resolve(__dirname, '../../../..');

/** @returns {string} absolute repo root */
export function repoRoot() {
  return _repoRoot;
}

/** Override repo root (for testing against a worktree) */
export function setRepoRoot(path) {
  _repoRoot = resolve(path);
  _lineCache.clear();
  _titleCache.clear();
}

/** @returns {string} repo-relative path */
export function repoRelative(absPath) {
  return relative(_repoRoot, absPath);
}

// ── Line cache ──────────────────────────────────────────────────────────────

const _lineCache = new Map();

/**
 * @param {string} filePath  absolute or repo-relative path
 * @returns {string[]}
 */
export function getLines(filePath) {
  const abs = resolve(_repoRoot, filePath);
  if (!_lineCache.has(abs)) {
    const text = existsSync(abs) ? readFileSync(abs, 'utf8') : '';
    _lineCache.set(abs, text.split('\n').map(l => l.trimEnd()));
  }
  return _lineCache.get(abs);
}

/** Invalidate cache for a file (call after fixing it) */
export function invalidateCache(filePath) {
  _lineCache.delete(resolve(_repoRoot, filePath));
}

// ── Title collection ────────────────────────────────────────────────────────

const INCLUDE_RE = /^include::([^[]+)\[/;
const _titleCache = new Map();

function tryRealpath(p) {
  try { return realpathSync(p); } catch { return p; }
}

/**
 * Collect all .adoc files included by masterAdocPath (recursive, deduped).
 * Results are cached for repeated calls with the same path.
 * @param {string} masterAdocPath  absolute or repo-relative path to master.adoc
 * @returns {string[]}  ordered array of repo-relative paths (master first)
 */
export function collectTitle(masterAdocPath) {
  const abs = resolve(_repoRoot, masterAdocPath);
  if (_titleCache.has(abs)) return _titleCache.get(abs);

  const seen = new Set();
  const result = [];

  function visit(filePath) {
    const real = tryRealpath(resolve(filePath));
    if (seen.has(real)) return;
    seen.add(real);
    result.push(repoRelative(real));

    if (!existsSync(real)) return;
    const lines = readFileSync(real, 'utf8').split('\n');
    for (const line of lines) {
      const m = INCLUDE_RE.exec(line);
      if (!m) continue;
      const includePath = m[1].trim();
      if (includePath.includes('{')) continue;
      // Resolve relative to real (symlink-resolved) directory so ../path works correctly
      const target = resolve(dirname(real), includePath);
      if (target.endsWith('.adoc')) visit(target);
    }
  }

  visit(abs);
  _titleCache.set(abs, result);
  return result;
}

// ── Content type ────────────────────────────────────────────────────────────

const CONTENT_TYPE_RE = /^:_mod-docs-content-type:\s*(\S+)/;
const VALID_TYPES = new Set(['ASSEMBLY', 'PROCEDURE', 'CONCEPT', 'REFERENCE', 'SNIPPET']);

/**
 * @param {string} filePath  absolute or repo-relative
 * @returns {string | null}
 */
export function getContentType(filePath) {
  const lines = getLines(filePath);
  for (const line of lines.slice(0, 5)) {
    const m = CONTENT_TYPE_RE.exec(line);
    if (m && VALID_TYPES.has(m[1].toUpperCase())) return m[1].toUpperCase();
  }
  return null;
}

// ── Block range detection ───────────────────────────────────────────────────

const BLOCK_DELIMITERS = new Set(['----', '....', '++++', '====', '|===']);

/**
 * Compute line ranges (1-based, inclusive) of source/listing/literal blocks.
 * Use this to skip pattern matching inside code examples.
 *
 * @param {string} filePath
 * @returns {Array<{start: number, end: number, delim: string}>}
 */
export function computeBlockRanges(filePath) {
  const lines = getLines(filePath);
  const ranges = [];
  let openDelim = null;
  let openLine = -1;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trimEnd();
    if (openDelim === null) {
      if (BLOCK_DELIMITERS.has(line)) {
        openDelim = line;
        openLine = i + 1; // 1-based
      }
    } else if (line === openDelim) {
      ranges.push({ start: openLine, end: i + 1, delim: openDelim });
      openDelim = null;
      openLine = -1;
    }
  }
  return ranges;
}

/**
 * @param {Array<{start: number, end: number}>} ranges
 * @param {number} lineNum  1-based
 * @returns {boolean}
 */
export function isInBlock(ranges, lineNum) {
  return ranges.some(r => lineNum >= r.start && lineNum <= r.end);
}
