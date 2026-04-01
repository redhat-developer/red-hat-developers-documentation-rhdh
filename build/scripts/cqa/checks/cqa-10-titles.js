/**
 * CQA-10: Verify titles are brief, complete, and descriptive
 *
 * For each .adoc (skip attributes.adoc, master.adoc):
 *   - PROCEDURE/ASSEMBLY(proc): title first word must be imperative (not gerund)
 *   - Gerunds after "and" are also fixed
 *   - ID must match title slug
 *   - Filename must match prefix+id
 *   - SNIPPET must not have a title
 *
 * Fix: update title, [id=], :context:, xrefs, include statements, git mv
 * Delegates to CQA-03 when no content type is found
 */

import { existsSync, readFileSync, writeFileSync, readdirSync, statSync, renameSync } from 'node:fs';
import { resolve, basename, dirname } from 'node:path';
import { execFileSync } from 'node:child_process';
import { GIT } from '../lib/bin.js';
import { Checker, autofix, manual, delegate } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

// ── Gerund → imperative lookup ────────────────────────────────────────────────

const GERUND_MAP = {
  running: 'run', setting: 'set', getting: 'get', putting: 'put', cutting: 'cut',
  stopping: 'stop', dropping: 'drop', mapping: 'map', planning: 'plan',
  scanning: 'scan', shipping: 'ship', shopping: 'shop', skipping: 'skip',
  snapping: 'snap', spinning: 'spin', splitting: 'split', stepping: 'step',
  stripping: 'strip', swapping: 'swap', tapping: 'tap', trimming: 'trim',
  wrapping: 'wrap', beginning: 'begin',
  configuring: 'configure', creating: 'create', enabling: 'enable',
  disabling: 'disable', managing: 'manage', upgrading: 'upgrade',
  updating: 'update', removing: 'remove', deleting: 'delete', editing: 'edit',
  resolving: 'resolve', authorizing: 'authorize', validating: 'validate',
  customizing: 'customize', integrating: 'integrate', migrating: 'migrate',
  generating: 'generate', defining: 'define', overriding: 'override',
  retrieving: 'retrieve', preparing: 'prepare', scaling: 'scale',
  securing: 'secure', authenticating: 'authenticate', automating: 'automate',
  bootstrapping: 'bootstrap', restoring: 'restore', replacing: 'replace',
  browsing: 'browse', closing: 'close', composing: 'compose',
  describing: 'describe', ensuring: 'ensure', using: 'use',
  including: 'include', invoking: 'invoke', providing: 'provide',
  producing: 'produce', reducing: 'reduce', releasing: 'release',
  requiring: 'require', subscribing: 'subscribe', changing: 'change',
  locating: 'locate', navigating: 'navigate', operating: 'operate',
  isolating: 'isolate', installing: 'install', deploying: 'deploy',
  building: 'build', adding: 'add', testing: 'test', monitoring: 'monitor',
  checking: 'check', importing: 'import', exporting: 'export',
  connecting: 'connect', disconnecting: 'disconnect', adjusting: 'adjust',
  restarting: 'restart', starting: 'start', registering: 'register',
  unregistering: 'unregister', assigning: 'assign', reviewing: 'review',
  accessing: 'access', fetching: 'fetch', searching: 'search',
  finding: 'find', provisioning: 'provision', encrypting: 'encrypt',
  mounting: 'mount', unmounting: 'unmount', attaching: 'attach',
  detaching: 'detach', extending: 'extend', limiting: 'limit',
  inspecting: 'inspect', triggering: 'trigger', troubleshooting: 'troubleshoot',
  understanding: 'understand', publishing: 'publish', selecting: 'select',
  tracking: 'track', transforming: 'transform', viewing: 'view',
  verifying: 'verify', modifying: 'modify', specifying: 'specify',
  applying: 'apply',
};

function gerundToImperative(word) {
  const lower = word.toLowerCase();
  if (GERUND_MAP[lower]) {
    const imp = GERUND_MAP[lower];
    return word[0] === word[0].toUpperCase() ? imp[0].toUpperCase() + imp.slice(1) : imp;
  }

  const stem = lower.endsWith('ing') ? lower.slice(0, -3) : lower;
  let result;

  const lastTwo = stem.slice(-2);
  const consonants = 'bcdfghjkmnpqrtvwxyz';
  if (stem.length >= 3 && lastTwo[0] === lastTwo[1] && consonants.includes(lastTwo[0])) {
    result = stem.slice(0, -1);
  } else if (stem.endsWith('v')) {
    result = stem + 'e';
  } else if (/[aeiou]z$/.test(stem)) {
    result = stem + 'e';
  } else if (/[aeiou]c$/.test(stem)) {
    result = stem + 'e';
  } else {
    result = stem;
  }

  return word[0] === word[0].toUpperCase() ? result[0].toUpperCase() + result.slice(1) : result;
}

// ── Attribute expansion ───────────────────────────────────────────────────────

// Parsed lazily from artifacts/attributes.adoc on first use.
let _attrsCache = null;

function loadKnownAttrs() {
  if (_attrsCache) return _attrsCache;
  _attrsCache = {};
  const root = repoRoot();
  const attrFile = resolve(root, 'artifacts/attributes.adoc');
  if (!existsSync(attrFile)) return _attrsCache;
  for (const line of readFileSync(attrFile, 'utf8').split('\n')) {
    if (!line.startsWith(':')) continue;
    const m = /^:([a-zA-Z][a-zA-Z0-9_-]*):\s*(.*)/.exec(line);
    if (!m) continue;
    const [, name, rawValue] = m;
    // Skip internal/structural attrs (paths, URLs, versions, book links, etc.)
    if (name.endsWith('-link') || name.endsWith('-title') || name.startsWith('_')) continue;
    if (rawValue.startsWith('link:') || rawValue.startsWith('http')) continue;
    // Resolve nested {attr} references in values
    let value = rawValue;
    for (let i = 0; i < 5 && value.includes('{'); i++) {
      value = value.replaceAll(/\{([a-zA-Z0-9_-]+)\}/g, (_, ref) => _attrsCache[ref] ?? '');
    }
    _attrsCache[name] = value.toLowerCase().replaceAll(/\s+/g, '-');
  }
  return _attrsCache;
}

function resolveAttr(name, fileLines, attrLines) {
  const known = loadKnownAttrs();
  if (known[name] !== undefined) return known[name];
  const re = new RegExp(String.raw`^:${name}:\s*(.*)`);
  for (const lines of [fileLines, attrLines]) {
    for (const l of lines) {
      const m = re.exec(l);
      if (m) return m[1].trim();
    }
  }
  return name;
}

function expandAttributes(text, fileLines, attrLines) {
  let out = text;
  let iterations = 0;
  while (/\{[a-zA-Z0-9_-]+\}/.test(out) && iterations++ < 10) {
    out = out.replaceAll(/\{([a-zA-Z0-9_-]+)\}/g, (_, name) => resolveAttr(name, fileLines, attrLines));
  }
  return out;
}

// ── Title-to-ID conversion ────────────────────────────────────────────────────

// Attrs expanded in IDs/filenames — only core product identities that should
// appear in module names. All other attrs are stripped from IDs.
const ID_ATTRS = {
  'product': 'rhdh', 'product-short': 'rhdh', 'product-very-short': 'rhdh',
  'product-local': 'rhdh-local', 'product-local-very-short': 'rhdh-local',
  'product-cli': 'rhdh-cli', 'product-custom-resource-type': '',
  'technology-preview': 'technology-preview', 'developer-preview': 'developer-preview',
  'rhbk-brand-name': 'rhbk', 'rhbk': 'rhbk',
  'azure-brand-name': 'microsoft-azure',
  'ocp-brand-name': 'ocp', 'ocp-short': 'ocp',
};

function titleToId(titleRaw) {
  let t = titleRaw;
  // Apply ID-relevant attribute substitutions
  for (const [attr, slug] of Object.entries(ID_ATTRS)) {
    t = t.replaceAll(`{${attr}}`, slug);
  }
  // Strip remaining attrs — they don't belong in IDs
  t = t.replaceAll(/\{[a-zA-Z0-9_-]*\}/g, '');

  return t.toLowerCase()
    .replaceAll(/[^a-z0-9-]+/g, '-')
    .replaceAll(/-+/g, '-').replaceAll(/^-|-$/g, '')
    .replaceAll(/\brhdh-rhdh\b/g, 'rhdh')
    .replaceAll(/\brhbk-rhbk\b/g, 'rhbk')
    .replaceAll(/\bocp-ocp\b/g, 'ocp');
}

// ── File analysis ─────────────────────────────────────────────────────────────

const PREFIX = { PROCEDURE: 'proc-', CONCEPT: 'con-', REFERENCE: 'ref-', ASSEMBLY: 'assembly-', SNIPPET: 'snip-' };

function analyzeFile(root, file, attrLines) {
  const bn = basename(file);
  const contentType = getContentType(file);
  const stem = bn.replace(/\.adoc$/, '');

  // Skip files with no content type and no known prefix
  const knownPrefixes = ['proc-', 'con-', 'ref-', 'assembly-', 'snip-'];
  if (!contentType && !knownPrefixes.some(p => stem.startsWith(p))) return null;

  const lines = getLines(file);

  if (contentType === 'SNIPPET') {
    const snippetTitle = lines.find(l => l.startsWith('= '))?.slice(2).trim();
    return { contentType, snippetTitle: snippetTitle ?? null, changed: !!snippetTitle };
  }

  const effectiveType = contentType || inferTypeFromPrefix(stem);
  if (!effectiveType) return null;

  const prefix = PREFIX[effectiveType];
  const expectedForm = getExpectedForm(effectiveType, lines);

  // Extract raw title
  const titleLine = lines.find(l => l.startsWith('= '));
  if (!titleLine) return { contentType: effectiveType, noTitle: true };
  const titleRaw = titleLine.slice(2).trim();

  // Fix gerunds if imperative form expected
  let fixedTitleRaw = titleRaw;
  if (expectedForm === 'imperative') {
    fixedTitleRaw = fixGerunds(fixedTitleRaw);
  }

  // Compute expected ID and filename
  const expectedId = titleToId(fixedTitleRaw);
  const expectedFilename = `${prefix}${expectedId}.adoc`;

  // Extract current ID
  const idLine = lines.find(l => /\[id=/.test(l));
  const currentId = idLine ? (/\[id=["']([^"'_]+)/.exec(idLine) ?? [])[1] ?? null : null;

  const changed = fixedTitleRaw !== titleRaw || currentId !== expectedId || bn !== expectedFilename;

  return {
    contentType: effectiveType,
    prefix,
    titleRaw,
    fixedTitleRaw,
    titleChanged: fixedTitleRaw !== titleRaw,
    currentId,
    expectedId,
    currentFilename: bn,
    expectedFilename,
    changed,
  };
}

function inferTypeFromPrefix(stem) {
  if (stem.startsWith('proc-')) return 'PROCEDURE';
  if (stem.startsWith('con-')) return 'CONCEPT';
  if (stem.startsWith('ref-')) return 'REFERENCE';
  if (stem.startsWith('assembly-')) return 'ASSEMBLY';
  if (stem.startsWith('snip-')) return 'SNIPPET';
  return null;
}

function getExpectedForm(contentType, lines) {
  if (contentType === 'PROCEDURE') return 'imperative';
  if (contentType === 'ASSEMBLY') {
    return lines.some(l => /include::.*proc-.*\.adoc/.test(l)) ? 'imperative' : 'noun phrase';
  }
  return 'noun phrase';
}

function fixGerunds(title) {
  // Fix first word
  let result = title.replace(/^([A-Za-z]+ing)(\s|$)/, (_, word, rest) => {
    if (/^\{.*\}$/.test(word)) return word + rest;
    return gerundToImperative(word) + rest;
  });

  // Fix words after "and"
  result = result.replaceAll(/( and )([A-Za-z]+ing)( )/g, (_, before, word, after) =>
    before + gerundToImperative(word) + after
  );

  return result;
}

// ── Checker ───────────────────────────────────────────────────────────────────

export default class Cqa10Titles extends Checker {
  id = '10';
  name = 'Verify titles are brief, complete, and descriptive';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const attrLines = loadAttrLines(root, masterAdocPath);
    const issues = [];

    for (const file of files) {
      const bn = basename(file);
      if (bn === 'attributes.adoc' || bn === 'master.adoc') continue;
      if (!existsSync(resolve(root, file))) continue;

      const contentType = getContentType(file);
      const stem = bn.replace(/\.adoc$/, '');
      const knownPrefixes = ['proc-', 'con-', 'ref-', 'assembly-', 'snip-'];
      const hasKnownPrefix = knownPrefixes.some(p => stem.startsWith(p));
      if (!contentType) {
        if (hasKnownPrefix) {
          issues.push(delegate(file, '03', 'No content type metadata -- run CQA-03 first'));
        }
        continue;
      }

      const result = analyzeFile(root, file, attrLines);
      if (!result?.changed) continue;

      issues.push(...issuesFromResult(file, result));
    }

    return issues;
  }

  fix(masterAdocPath, issues) {
    const root = repoRoot();
    const attrLines = loadAttrLines(root, masterAdocPath);
    const fixedFiles = new Set(issues.map(i => i.file));

    for (const file of fixedFiles) {
      applyFix(root, file, attrLines);
    }
  }
}

function issuesFromResult(file, result) {
  if (result.noTitle) return [manual(file, "No title found (looking for '= Title')")];
  if (result.snippetTitle) return [manual(file, `Snippet has a title '= ${result.snippetTitle}' -- snippets must not have titles`)];

  const issues = [];
  if (result.titleChanged) {
    issues.push(autofix(file, `Title: ${result.titleRaw} -> ${result.fixedTitleRaw}`));
  }
  if (result.currentId !== result.expectedId) {
    issues.push(autofix(file, `ID: ${result.currentId ?? ''} -> ${result.expectedId}`));
  }
  if (result.currentFilename !== result.expectedFilename) {
    issues.push(autofix(file, `File: ${result.currentFilename} -> ${result.expectedFilename}`));
  }
  return issues;
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function applyFix(root, file, attrLines) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  const result = analyzeFile(root, file, attrLines);
  if (!result?.changed) return;

  let text = readFileSync(abs, 'utf8');

  if (result.titleChanged) {
    text = text.replaceAll(`= ${result.titleRaw}`, `= ${result.fixedTitleRaw}`);
  }

  if (result.currentId !== result.expectedId && result.currentId) {
    const old = result.currentId;
    const neo = result.expectedId;
    text = text.replaceAll(new RegExp(String.raw`\[id="${old}(?:_\{context\})?"]`, 'g'), `[id="${neo}_{context}"]`);
    text = text.replaceAll(new RegExp(String.raw`\[id='${old}(?:_\{context\})?']`, 'g'), `[id="${neo}_{context}"]`);
    if (result.contentType === 'ASSEMBLY') {
      text = text.replace(/^:context: .*$/m, `:context: ${neo}`);
    }
    writeFileSync(abs, text, 'utf8');
    // Update xrefs
    updateXrefs(root, old, neo);
  } else {
    writeFileSync(abs, text, 'utf8');
  }

  if (result.currentFilename !== result.expectedFilename) {
    const newAbs = resolve(dirname(abs), result.expectedFilename);
    try {
      execFileSync(GIT, ['mv', abs, newAbs], { cwd: root });
    } catch {
      renameSync(abs, newAbs);
    }
    updateIncludes(root, result.currentFilename, result.expectedFilename);
  }
}

function updateXrefs(root, oldId, newId) {
  for (const f of findAdocFiles(root, ['assemblies', 'modules', 'titles'])) {
    const text = readFileSync(f, 'utf8');
    if (!text.includes(`xref:${oldId}_`)) continue;
    writeFileSync(f, text.replaceAll(`xref:${oldId}_`, `xref:${newId}_`), 'utf8');
  }
}

function updateIncludes(root, oldBn, newBn) {
  for (const f of findAdocFiles(root, ['assemblies', 'modules', 'titles'])) {
    const text = readFileSync(f, 'utf8');
    if (!text.includes(oldBn)) continue;
    writeFileSync(f, text.replaceAll(oldBn, newBn), 'utf8');
  }
}

function loadAttrLines(root, masterAdocPath) {
  const dir = dirname(resolve(root, masterAdocPath));
  const attrFile = resolve(dir, 'artifacts/attributes.adoc');
  const fallback = resolve(root, 'artifacts/attributes.adoc');
  let f = null;
  if (existsSync(attrFile)) f = attrFile;
  else if (existsSync(fallback)) f = fallback;
  return f ? readFileSync(f, 'utf8').split('\n') : [];
}

function findAdocFiles(root, dirs) {
  const result = [];
  for (const dir of dirs) {
    const abs = resolve(root, dir);
    if (existsSync(abs)) collectAdoc(abs, result);
  }
  return result;
}

function collectAdoc(dir, result) {
  for (const entry of readdirSync(dir)) {
    const abs = resolve(dir, entry);
    if (statSync(abs).isDirectory()) collectAdoc(abs, result);
    else if (entry.endsWith('.adoc')) result.push(abs);
  }
}
