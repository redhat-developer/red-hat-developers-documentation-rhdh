/**
 * vale.js — Shared Vale runner with result caching
 *
 * In --all mode, Vale runs once against assemblies/ and title master.adoc files.
 * In per-title mode, Vale runs once per title.
 * Results are cached and dispatched to CQA-01, CQA-12, CQA-16 by check name.
 */

import { existsSync, realpathSync } from 'node:fs';
import { resolve, relative } from 'node:path';
import { execFileSync, execFile } from 'node:child_process';
import { VALE } from './bin.js';
import { repoRoot } from './asciidoc.js';

// Cache: Map<relPath, Array<{Check, Message, Line, Severity, ...}>>
let _cache = null;

/**
 * Run Vale synchronously and populate cache.
 * @param {string[]} targets  directories or files to scan
 */
export function preRunVale(targets) {
  const root = repoRoot();
  const valeConfig = resolve(root, '.vale.ini');
  if (!existsSync(valeConfig)) { _cache = new Map(); return; }

  let jsonStr;
  try {
    jsonStr = execFileSync(VALE, [
      '--config', valeConfig,
      '--output', 'JSON',
      ...targets,
    ], { cwd: root, encoding: 'utf8', maxBuffer: 20 * 1024 * 1024 });
  } catch (err) {
    jsonStr = err.stdout || '';
  }

  populateCache(root, jsonStr);
}

/**
 * Run Vale asynchronously and populate cache.
 * Returns a promise that resolves when Vale finishes.
 * @param {string[]} targets  directories or files to scan
 * @returns {Promise<void>}
 */
export function preRunValeAsync(targets) {
  const root = repoRoot();
  const valeConfig = resolve(root, '.vale.ini');
  if (!existsSync(valeConfig)) { _cache = new Map(); return Promise.resolve(); }

  return new Promise((res) => {
    execFile(VALE, [
      '--config', valeConfig,
      '--output', 'JSON',
      ...targets,
    ], { cwd: root, encoding: 'utf8', maxBuffer: 20 * 1024 * 1024 }, (err, stdout) => {
      const jsonStr = err ? (err.stdout || stdout || '') : stdout;
      populateCache(root, jsonStr);
      res();
    });
  });
}

function populateCache(root, jsonStr) {
  try {
    const data = JSON.parse(jsonStr);
    _cache = new Map();
    for (const [file, issues] of Object.entries(data)) {
      const absPath = file.startsWith('/') ? file : resolve(root, file);
      // Resolve symlinks so cache keys match collectTitle() output
      let realPath;
      try { realPath = realpathSync(absPath); } catch { realPath = absPath; }
      const relPath = relative(root, realPath);
      // Merge if same real file reached via multiple symlinks
      if (_cache.has(relPath)) continue; // same content, same issues
      _cache.set(relPath, issues);
    }
  } catch {
    _cache = new Map();
  }
}

/** @returns {boolean} */
export function hasValeCache() {
  return _cache !== null;
}

/**
 * Get cached Vale issues for a file.
 * @param {string} relPath  repo-relative path
 * @returns {Array}  empty if file not in cache
 */
export function getCachedIssues(relPath) {
  if (!_cache) return [];
  return _cache.get(relPath) || [];
}

/** Clear the Vale cache. */
export function clearValeCache() {
  _cache = null;
}
