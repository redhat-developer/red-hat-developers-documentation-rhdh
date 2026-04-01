/**
 * CQA-00b: Directory structure
 *
 * Verifies that title, assembly, module, and image directories follow
 * <category>_<context> naming convention. Reports misnamed directories
 * as [AUTOFIX] findings.
 *
 * Scope: entire repo (ignores title path arg).
 * Fix: git mv operations in 6 phases (titles → assemblies → modules → images → includes → verify).
 */

import { readdirSync, existsSync, readFileSync, mkdirSync, rmdirSync } from 'node:fs';
import { resolve, basename, dirname, join } from 'node:path';
import { execFileSync } from 'node:child_process';
import { GIT, SED } from '../lib/bin.js';
import { Checker, autofix, manual } from '../lib/checker.js';
import { repoRoot, repoRelative } from '../lib/asciidoc.js';

const SHARED = 'shared';

// ── Attribute substitution map (known RHDH product attributes) ────────────────

const ATTR_MAP = {
  'ls-brand-name': 'developer-lightspeed-for-rhdh',
  'ls-short': 'developer-lightspeed-for-rhdh',
  'openshift-ai-connector-name': 'openshift-ai-connector-for-rhdh',
  'openshift-ai-connector-name-short': 'openshift-ai-connector-for-rhdh',
  'product': 'rhdh',
  'product-short': 'rhdh',
  'product-very-short': 'rhdh',
  'product-local': 'rhdh-local',
  'product-local-very-short': 'rhdh-local',
  'ocp-brand-name': 'ocp',
  'ocp-short': 'ocp',
  'ocp-very-short': 'ocp',
  'aks-brand-name': 'aks',
  'aks-name': 'aks',
  'aks-short': 'aks',
  'eks-brand-name': 'eks',
  'eks-name': 'eks',
  'eks-short': 'eks',
  'gke-brand-name': 'gke',
  'gke-short': 'gke',
  'gcp-brand-name': 'gcp',
  'gcp-short': 'gcp',
  'osd-brand-name': 'osd',
  'osd-short': 'osd',
  'rhacs-brand-name': 'acs',
  'rhacs-short': 'acs',
  'rhacs-very-short': 'acs',
  'rhoai-brand-name': 'openshift-ai',
  'rhoai-short': 'openshift-ai',
  'backstage': 'backstage',
};

export default class Cqa00bDirectoryStructure extends Checker {
  id = '00b';
  name = 'Directory structure';

  check(_masterAdocPath) {
    const root = repoRoot();
    const issues = [];

    // Phase 0: read all title metadata
    const { ctxCat, ctxDest, dirCtx } = readTitleMetadata(root, issues);

    // Build ownership maps
    const asmFileOwners = buildAsmFileOwners(root, dirCtx);
    propagateSubAssemblyOwners(root, asmFileOwners);
    const modDirOwners = buildModDirOwners(root, dirCtx, asmFileOwners);
    const imgFileOwners = buildImgFileOwners(root, dirCtx, modDirOwners, asmFileOwners);

    // Report misnamed directories and misplaced files
    reportMisnamedTitleDirs(dirCtx, ctxDest, issues);
    reportMisnamedAsmDirs(root, asmFileOwners, ctxCat, ctxDest, issues);
    reportFlatAsmFiles(root, asmFileOwners, ctxCat, ctxDest, issues);
    reportMisnamedModDirs(root, modDirOwners, ctxCat, ctxDest, issues);
    reportMisplacedImages(root, imgFileOwners, ctxCat, ctxDest, issues);

    return issues;
  }

  fix(_masterAdocPath, issues) {
    // Fix is complex (6 phases of git mv + include rewriting).
    // Implemented as a series of targeted operations based on issue messages.
    const root = repoRoot();

    const { ctxCat, ctxDest, dirCtx } = readTitleMetadata(root, []);
    const asmFileOwners = buildAsmFileOwners(root, dirCtx);
    propagateSubAssemblyOwners(root, asmFileOwners);
    const modDirOwners = buildModDirOwners(root, dirCtx, asmFileOwners);
    const imgFileOwners = buildImgFileOwners(root, dirCtx, modDirOwners, asmFileOwners);

    const asmDirDest = computeAsmDirDest(root, asmFileOwners, ctxCat, ctxDest);
    const flatAsmDest = computeFlatAsmDest(root, asmFileOwners, ctxCat, ctxDest);
    const modDirDest = computeModDirDest(root, modDirOwners, ctxCat, ctxDest);
    const imgFileDest = computeImgFileDest(root, imgFileOwners, ctxCat, ctxDest);

    // Phase 1: title dirs
    fixTitleDirs(root, dirCtx, ctxDest);
    // Phase 2: assembly dirs then flat files
    fixAsmDirs(root, asmDirDest);
    fixFlatAsmFiles(root, flatAsmDest);
    // Phase 3: module dirs
    fixModDirs(root, modDirDest);
    // Phase 4: image files
    fixImageFiles(root, imgFileDest);
    // Phase 5: update include paths across all .adoc files
    fixIncludePaths(root, { asmDirDest, flatAsmDest, modDirDest, imgFileDest });
  }
}

// ── Check reporting helpers ──────────────────────────────────────────────────

function reportMisnamedTitleDirs(dirCtx, ctxDest, issues) {
  for (const [d, ctx] of Object.entries(dirCtx)) {
    const expected = ctxDest[ctx];
    if (d !== expected) {
      issues.push(autofix(`titles/${d}`, `Title dir should be titles/${expected}`));
    }
  }
}

function reportMisnamedAsmDirs(root, asmFileOwners, ctxCat, ctxDest, issues) {
  for (const asmDir of listDirs(resolve(root, 'assemblies'))) {
    if (asmDir === SHARED || asmDir === 'modules') continue;
    const allOwners = collectAsmDirOwners(root, asmDir, asmFileOwners);
    if (allOwners.length === 0) continue;
    const dest = computeDest(allOwners, ctxCat, ctxDest);
    if (asmDir !== dest) {
      issues.push(autofix(`assemblies/${asmDir}`, `Assembly dir should be assemblies/${dest}`));
    }
  }
}

function reportFlatAsmFiles(root, asmFileOwners, ctxCat, ctxDest, issues) {
  for (const f of listAdocFiles(resolve(root, 'assemblies'))) {
    const bn = basename(f);
    const owners = uniqueSorted((asmFileOwners[bn] || []).flat());
    if (owners.length === 0) continue;
    const dest = computeDest(owners, ctxCat, ctxDest);
    issues.push(autofix(repoRelative(f), `Flat assembly should be in assemblies/${dest}/`));
  }
}

function reportMisnamedModDirs(root, modDirOwners, ctxCat, ctxDest, issues) {
  for (const [md, owners] of Object.entries(modDirOwners)) {
    if (!existsSync(resolve(root, 'modules', md))) continue;
    const dest = computeDest(uniqueSorted(owners), ctxCat, ctxDest);
    if (md !== dest) {
      issues.push(autofix(`modules/${md}`, `Module dir should be modules/${dest}`));
    }
  }
}

function reportMisplacedImages(root, imgFileOwners, ctxCat, ctxDest, issues) {
  for (const [ref, owners] of Object.entries(imgFileOwners)) {
    if (!existsSync(resolve(root, 'images', ref))) continue;
    const dest = computeDest(uniqueSorted(owners), ctxCat, ctxDest);
    const oldDir = dirname(ref);
    if (oldDir !== dest) {
      issues.push(autofix(`images/${ref}`, `Image should be in images/${dest}/`));
    }
  }
}

// ── Title metadata ────────────────────────────────────────────────────────────

function readTitleMetadata(root, issues) {
  const ctxCat = {};    // context → category slug
  const ctxDest = {};   // context → <catslug>_<context>
  const dirCtx = {};    // title dir basename → context

  const titlesDir = resolve(root, 'titles');
  if (!existsSync(titlesDir)) return { ctxCat, ctxDest, dirCtx };

  for (const d of readdirSync(titlesDir)) {
    const master = resolve(titlesDir, d, 'master.adoc');
    if (!existsSync(master)) continue;

    const lines = readLines(master);
    const ctx = readAttr(lines, 'context');
    const cat = readAttr(lines, '_mod-docs-category');

    if (!cat) {
      issues.push(manual(`titles/${d}/master.adoc`, 'Missing :_mod-docs-category: attribute'));
      continue;
    }

    const cs = slugify(cat);
    ctxCat[ctx] = cs;
    ctxDest[ctx] = `${cs}_${ctx}`;
    dirCtx[d] = ctx;
  }

  return { ctxCat, ctxDest, dirCtx };
}

// ── Ownership maps ────────────────────────────────────────────────────────────

function buildAsmFileOwners(root, dirCtx) {
  // asmFileOwners: relative asm path (from assemblies/) → string[]
  const owners = {};

  for (const [d, ctx] of Object.entries(dirCtx)) {
    const master = resolve(root, 'titles', d, 'master.adoc');
    if (!existsSync(master)) continue;
    for (const inc of extractIncludes(master, 'assemblies/')) {
      owners[inc] = owners[inc] || [];
      if (!owners[inc].includes(ctx)) owners[inc].push(ctx);
    }
  }
  return owners;
}

function propagateSubAssemblyOwners(root, asmFileOwners) {
  let changed = true;
  while (changed) {
    changed = false;
    for (const [af, parentOwners] of Object.entries(asmFileOwners)) {
      const abs = resolve(root, 'assemblies', af);
      if (!existsSync(abs)) continue;
      changed = propagateFromAssembly(abs, af, parentOwners, asmFileOwners) || changed;
    }
  }
}

function propagateFromAssembly(abs, af, parentOwners, asmFileOwners) {
  let changed = false;
  const asmDir = dirname(af);

  // sub-assemblies in same dir
  for (const sub of extractIncludes(abs, 'assembly-')) {
    const subPath = asmDir === '.' ? sub : `${asmDir}/${sub}`;
    changed = mergeOwners(asmFileOwners, subPath, parentOwners) || changed;
  }
  // sub-assemblies via ../assemblies/ path
  for (const sub of extractIncludes(abs, '../assemblies/')) {
    changed = mergeOwners(asmFileOwners, sub, parentOwners) || changed;
  }
  return changed;
}

function mergeOwners(ownersMap, key, newOwners) {
  const before = (ownersMap[key] || []).join(',');
  const merged = uniqueSorted([...(ownersMap[key] || []), ...newOwners]);
  if (merged.join(',') !== before) {
    ownersMap[key] = merged;
    return true;
  }
  return false;
}

function buildModDirOwners(root, dirCtx, asmFileOwners) {
  const owners = {};
  collectModDirOwnersFromTitles(root, dirCtx, owners);
  collectModDirOwnersFromAssemblies(root, asmFileOwners, owners);
  return owners;
}

function collectModDirOwnersFromTitles(root, dirCtx, owners) {
  for (const [d, ctx] of Object.entries(dirCtx)) {
    const master = resolve(root, 'titles', d, 'master.adoc');
    if (!existsSync(master)) continue;
    for (const md of extractModDirs(master)) {
      if (md === SHARED) continue;
      owners[md] = owners[md] || [];
      if (!owners[md].includes(ctx)) owners[md].push(ctx);
    }
  }
}

function collectModDirOwnersFromAssemblies(root, asmFileOwners, owners) {
  for (const [af, afOwners] of Object.entries(asmFileOwners)) {
    const abs = resolve(root, 'assemblies', af);
    if (!existsSync(abs)) continue;
    for (const md of extractModDirs(abs)) {
      if (md === SHARED) continue;
      addAllOwners(owners, md, afOwners);
    }
  }
}

function addAllOwners(owners, key, newOwners) {
  owners[key] = owners[key] || [];
  for (const o of newOwners) {
    if (!owners[key].includes(o)) owners[key].push(o);
  }
}

function buildImgFileOwners(root, dirCtx, modDirOwners, asmFileOwners) {
  const owners = {};
  const addOwner = (ref, ctx) => {
    owners[ref] = owners[ref] || [];
    if (!owners[ref].includes(ctx)) owners[ref].push(ctx);
  };

  collectImgOwnersFromTitles(root, dirCtx, addOwner);
  collectImgOwnersFromModules(root, modDirOwners, addOwner);
  collectImgOwnersFromSharedModules(root, dirCtx, asmFileOwners, addOwner);
  collectImgOwnersFromAssemblies(root, asmFileOwners, addOwner);

  return owners;
}

function collectImgOwnersFromTitles(root, dirCtx, addOwner) {
  for (const [d, ctx] of Object.entries(dirCtx)) {
    const master = resolve(root, 'titles', d, 'master.adoc');
    if (!existsSync(master)) continue;
    for (const ref of extractImageRefs(master)) addOwner(ref, ctx);
  }
}

function collectImgOwnersFromModules(root, modDirOwners, addOwner) {
  for (const [md, mdOwners] of Object.entries(modDirOwners)) {
    if (md === SHARED) continue;
    const modDir = resolve(root, 'modules', md);
    if (!existsSync(modDir)) continue;
    collectImgOwnersFromDir(modDir, mdOwners, addOwner);
  }
}

function collectImgOwnersFromDir(dir, dirOwners, addOwner) {
  for (const f of listAdocFilesInDir(dir)) {
    for (const ref of extractImageRefs(f)) {
      for (const o of dirOwners) addOwner(ref, o);
    }
  }
}

function collectImgOwnersFromSharedModules(root, dirCtx, asmFileOwners, addOwner) {
  const sharedModDir = resolve(root, 'modules', SHARED);
  if (!existsSync(sharedModDir)) return;

  const sharedModOwners = buildSharedModOwners(root, dirCtx, asmFileOwners);
  for (const f of listAdocFilesInDir(sharedModDir)) {
    const bn = basename(f);
    const shOwners = sharedModOwners[bn] || [];
    if (shOwners.length === 0) continue;
    for (const ref of extractImageRefs(f)) {
      for (const o of shOwners) addOwner(ref, o);
    }
  }
}

function collectImgOwnersFromAssemblies(root, asmFileOwners, addOwner) {
  for (const [af, afOwners] of Object.entries(asmFileOwners)) {
    const abs = resolve(root, 'assemblies', af);
    if (!existsSync(abs)) continue;
    for (const ref of extractImageRefs(abs)) {
      for (const o of afOwners) addOwner(ref, o);
    }
  }
}

function buildSharedModOwners(root, dirCtx, asmFileOwners) {
  const owners = {};
  const addOwner = (bn, ctx) => {
    owners[bn] = owners[bn] || [];
    if (!owners[bn].includes(ctx)) owners[bn].push(ctx);
  };

  collectSharedModOwnersFromTitles(root, dirCtx, addOwner);
  collectSharedModOwnersFromAssemblies(root, asmFileOwners, addOwner);

  return owners;
}

const SHARED_MOD_RE = /modules\/shared\/([^[]+)/g;

function collectSharedModOwnersFromTitles(root, dirCtx, addOwner) {
  for (const [d, ctx] of Object.entries(dirCtx)) {
    const master = resolve(root, 'titles', d, 'master.adoc');
    if (!existsSync(master)) continue;
    collectSharedModRefsFromFile(master, [ctx], addOwner);
  }
}

function collectSharedModOwnersFromAssemblies(root, asmFileOwners, addOwner) {
  for (const [af, afOwners] of Object.entries(asmFileOwners)) {
    const abs = resolve(root, 'assemblies', af);
    if (!existsSync(abs)) continue;
    collectSharedModRefsFromFile(abs, afOwners, addOwner);
  }
}

function collectSharedModRefsFromFile(file, fileOwners, addOwner) {
  for (const line of readLines(file)) {
    if (line.startsWith('//')) continue;
    for (const m of line.matchAll(SHARED_MOD_RE)) {
      for (const o of fileOwners) addOwner(basename(m[1]), o);
    }
  }
}

// ── computeDest ───────────────────────────────────────────────────────────────

function computeDest(owners, ctxCat, ctxDest) {
  if (owners.length === 0) return 'UNKNOWN';
  if (owners.length === 1) return ctxDest[owners[0]] || 'UNKNOWN';

  const firstCat = ctxCat[owners[0]];
  const allSameCat = owners.every(o => ctxCat[o] === firstCat);
  return allSameCat ? `${firstCat}_${SHARED}` : SHARED;
}

function collectAsmDirOwners(root, asmDir, asmFileOwners) {
  const all = [];
  const absDir = resolve(root, 'assemblies', asmDir);
  if (!existsSync(absDir)) return all;

  for (const f of listAdocFilesInDir(absDir)) {
    const rel = `${asmDir}/${basename(f)}`;
    for (const o of (asmFileOwners[rel] || [])) {
      if (!all.includes(o)) all.push(o);
    }
  }
  return uniqueSorted(all);
}

// ── Parsing helpers ───────────────────────────────────────────────────────────

function readLines(file) {
  try { return readFileSync(file, 'utf8').split('\n'); } catch { return []; }
}

function readAttr(lines, attrName) {
  const prefix = `:${attrName}:`;
  for (const line of lines) {
    if (line.startsWith(prefix)) return line.slice(prefix.length).trim();
  }
  return '';
}

const INCLUDE_RE = /^include::([^[]+)\[/;

function extractIncludes(file, prefix) {
  const lines = readLines(file);
  const results = [];
  for (const line of lines) {
    if (line.startsWith('//')) continue;
    const m = INCLUDE_RE.exec(line);
    if (!m) continue;
    const path = m[1];
    if (!path.includes(prefix)) continue;
    const idx = path.indexOf(prefix);
    results.push(path.slice(idx + prefix.length));
  }
  return results;
}

const MOD_DIR_RE = /include::(?:\.\.\/)?modules\/([^/[]+)\//g;

function extractModDirs(file) {
  const lines = readLines(file);
  const dirs = new Set();
  for (const line of lines) {
    if (line.startsWith('//')) continue;
    for (const m of line.matchAll(MOD_DIR_RE)) dirs.add(m[1]);
  }
  return [...dirs];
}

const IMG_RE = /image::?([^/[\s]+\/[^[\]]+)\[/g;

function extractImageRefs(file) {
  const lines = readLines(file);
  const refs = [];
  for (const line of lines) {
    if (line.startsWith('//')) continue;
    for (const m of line.matchAll(IMG_RE)) {
      const ref = m[1];
      const isUrl = ref.startsWith('http://') || ref.startsWith('https://');
      if (!isUrl) refs.push(ref);
    }
  }
  return refs;
}

// ── File system helpers ───────────────────────────────────────────────────────

function listDirs(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true })
    .filter(e => e.isDirectory())
    .map(e => e.name);
}

/** List .adoc files directly in a directory (non-recursive) */
function listAdocFiles(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir, { withFileTypes: true })
    .filter(e => e.isFile() && e.name.endsWith('.adoc'))
    .map(e => join(dir, e.name));
}

function listAdocFilesInDir(dir) {
  return listAdocFiles(dir);
}

/** Glob .adoc files up to maxDepth levels deep */
function* globAdoc(dir, maxDepth = 3, depth = 1) {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory() && depth < maxDepth) yield* globAdoc(full, maxDepth, depth + 1);
    else if (entry.isFile() && entry.name.endsWith('.adoc')) yield full;
  }
}

// ── Fix destination computation ──────────────────────────────────────────────

function computeAsmDirDest(root, asmFileOwners, ctxCat, ctxDest) {
  const dest = {};
  for (const asmDir of listDirs(resolve(root, 'assemblies'))) {
    if (asmDir === SHARED || asmDir === 'modules') continue;
    const allOwners = collectAsmDirOwners(root, asmDir, asmFileOwners);
    if (allOwners.length === 0) continue;
    dest[asmDir] = computeDest(allOwners, ctxCat, ctxDest);
  }
  return dest;
}

function computeFlatAsmDest(root, asmFileOwners, ctxCat, ctxDest) {
  const dest = {};
  for (const f of listAdocFiles(resolve(root, 'assemblies'))) {
    const bn = basename(f);
    const owners = uniqueSorted((asmFileOwners[bn] || []).flat());
    if (owners.length === 0) continue;
    dest[bn] = computeDest(owners, ctxCat, ctxDest);
  }
  return dest;
}

function computeModDirDest(root, modDirOwners, ctxCat, ctxDest) {
  const dest = {};
  for (const [md, owners] of Object.entries(modDirOwners)) {
    if (!existsSync(resolve(root, 'modules', md))) continue;
    dest[md] = computeDest(uniqueSorted(owners), ctxCat, ctxDest);
  }
  return dest;
}

function computeImgFileDest(root, imgFileOwners, ctxCat, ctxDest) {
  const dest = {};
  for (const [ref, owners] of Object.entries(imgFileOwners)) {
    if (!existsSync(resolve(root, 'images', ref))) continue;
    const d = computeDest(uniqueSorted(owners), ctxCat, ctxDest);
    const oldDir = dirname(ref);
    if (oldDir !== d) dest[ref] = d;
  }
  return dest;
}

// ── Fix phase helpers ────────────────────────────────────────────────────────

function fixTitleDirs(root, dirCtx, ctxDest) {
  for (const [d, ctx] of Object.entries(dirCtx)) {
    const newDir = ctxDest[ctx];
    if (d !== newDir) gitMv(root, `titles/${d}`, `titles/${newDir}`);
  }
}

function fixAsmDirs(root, asmDirDest) {
  for (const [oldDir, newDir] of Object.entries(asmDirDest)) {
    if (oldDir === newDir) continue;
    if (!existsSync(resolve(root, 'assemblies', oldDir))) continue;
    moveDirContents(root, `assemblies/${oldDir}`, `assemblies/${newDir}`);
  }
}

function fixFlatAsmFiles(root, flatAsmDest) {
  for (const [bn, dest] of Object.entries(flatAsmDest)) {
    if (!existsSync(resolve(root, 'assemblies', bn))) continue;
    mkdirSync(resolve(root, 'assemblies', dest), { recursive: true });
    gitMv(root, `assemblies/${bn}`, `assemblies/${dest}/${bn}`);
  }
}

function fixModDirs(root, modDirDest) {
  for (const [oldDir, newDir] of Object.entries(modDirDest)) {
    if (oldDir === newDir) continue;
    if (!existsSync(resolve(root, 'modules', oldDir))) continue;
    moveDirContents(root, `modules/${oldDir}`, `modules/${newDir}`);
  }
}

function fixImageFiles(root, imgFileDest) {
  for (const [ref, dest] of Object.entries(imgFileDest)) {
    if (!existsSync(resolve(root, 'images', ref))) continue;
    const bn = basename(ref);
    mkdirSync(resolve(root, 'images', dest), { recursive: true });
    gitMv(root, `images/${ref}`, `images/${dest}/${bn}`);
  }
  removeEmptyDirs(resolve(root, 'images'));
}

function fixIncludePaths(root, { asmDirDest, flatAsmDest, modDirDest, imgFileDest }) {
  const masterSed = buildSedExpr({ asmDirDest, flatAsmDest, modDirDest, imgFileDest, mode: 'master' });
  if (masterSed) {
    for (const master of globAdoc(resolve(root, 'titles'), 2)) {
      runSed(root, masterSed, repoRelative(master));
    }
  }

  const asmSed = buildSedExpr({ asmDirDest, flatAsmDest, modDirDest, imgFileDest, mode: 'assembly' });
  if (asmSed) {
    for (const asm of globAdoc(resolve(root, 'assemblies'), 2)) {
      runSed(root, asmSed, repoRelative(asm));
    }
  }

  const modSed = buildSedExpr({ imgFileDest, mode: 'module' });
  if (modSed) {
    for (const mod of globAdoc(resolve(root, 'modules'), 3)) {
      runSed(root, modSed, repoRelative(mod));
    }
  }
}

// ── Fix helpers ───────────────────────────────────────────────────────────────

function gitMv(root, src, dest) {
  try {
    execFileSync(GIT, ['mv', src, dest], { cwd: root, stdio: 'pipe' });
  } catch (e) {
    console.error(`git mv failed: ${src} → ${dest}: ${e.message}`);
  }
}

function moveDirContents(root, src, dest) {
  const absDest = resolve(root, dest);
  mkdirSync(absDest, { recursive: true });
  const absSrc = resolve(root, src);
  if (!existsSync(absSrc)) return;
  for (const entry of readdirSync(absSrc)) {
    const target = join(absDest, entry);
    if (!existsSync(target)) gitMv(root, `${src}/${entry}`, `${dest}/${entry}`);
  }
  try { rmdirSync(absSrc); } catch { /* ignore non-empty */ }
}

function removeEmptyDirs(dir) {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) removeEmptyDirs(join(dir, entry.name));
  }
  if (readdirSync(dir).length === 0) {
    try { rmdirSync(dir); } catch { /* ignore */ }
  }
}

function runSed(root, expr, file) {
  try {
    execFileSync(SED, ['-i', expr, file], { cwd: root, stdio: 'pipe' });
  } catch { /* ignore */ }
}

function buildSedExpr({ asmDirDest = {}, flatAsmDest = {}, modDirDest = {}, imgFileDest = {}, mode }) {
  const parts = [];

  if (mode === 'master' || mode === 'assembly') {
    buildIncludeSedParts(parts, asmDirDest, flatAsmDest, modDirDest, mode);
  }

  buildImageSedParts(parts, imgFileDest);

  return parts.join(';');
}

function buildIncludeSedParts(parts, asmDirDest, flatAsmDest, modDirDest, mode) {
  for (const [old, newDir] of Object.entries(asmDirDest)) {
    if (old === newDir) continue;
    const prefix = mode === 'assembly' ? '../assemblies/' : 'assemblies/';
    parts.push(`s|include::${prefix}${old}/|include::${prefix}${newDir}/|g`);
  }
  for (const [bn, dest] of Object.entries(flatAsmDest)) {
    if (mode === 'master') parts.push(`s|include::assemblies/${bn}|include::assemblies/${dest}/${bn}|g`);
  }
  for (const [old, newDir] of Object.entries(modDirDest)) {
    if (old === newDir) continue;
    const prefix = mode === 'assembly' ? '../modules/' : 'modules/';
    parts.push(`s|include::${prefix}${old}/|include::${prefix}${newDir}/|g`);
  }
}

function buildImageSedParts(parts, imgFileDest) {
  for (const [ref, dest] of Object.entries(imgFileDest)) {
    const bn = basename(ref);
    const oldDir = dirname(ref);
    parts.push(
      `s|image::${oldDir}/${bn}|image::${dest}/${bn}|g`,
      `s|image:${oldDir}/${bn}|image:${dest}/${bn}|g`,
    );
  }
}

// ── Utilities ─────────────────────────────────────────────────────────────────

function slugify(s) {
  return s.toLowerCase().replaceAll(' ', '-');
}

function uniqueSorted(arr) {
  return [...new Set(arr)].sort((a, b) => a.localeCompare(b));
}
