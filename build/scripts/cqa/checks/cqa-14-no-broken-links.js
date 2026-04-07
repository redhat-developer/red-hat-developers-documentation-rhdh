/**
 * CQA-14: No broken links
 *
 * For each .adoc file:
 *   - include:: targets must resolve to existing files
 *   - image:: references must resolve to existing files
 *   - Skip paths with attribute substitutions ({attr})
 *
 * Title chain validation (runs on master.adoc only):
 *   A. :title: must use {<name>-book-title} attribute reference
 *   B. docinfo.xml <title> must contain {title}
 *   C. Book-link slug must match Pantheon-derived slug from book-title
 *
 * Lychee cross-title link checking:
 *   - Builds fresh HTML, runs lychee with URL remapping
 *   - Reports broken cross-title links as MANUAL issues
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, dirname, basename, join } from 'node:path';
import { execSync } from 'node:child_process';
import { Checker, autofix, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getLines, invalidateCache } from '../lib/asciidoc.js';

const INCLUDE_RE = /^include::([^[]+)\[/;
const IMAGE_BLOCK_RE = /image::([^[]+)\[/;
const IMAGESDIR_RE = /^:imagesdir:\s*(.+)/;

// Module-level lychee results cache (build+lychee runs once across all titles)
let _lycheeIssuesCache = null;

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

    // Title chain validation (only for master.adoc)
    if (basename(masterAdocPath) === 'master.adoc') {
      issues.push(...checkTitleChain(root, masterAdocPath));

      // Lychee cross-title link checking (runs once, cached)
      const lycheeIssues = getLycheeIssues(root);
      const titleDir = dirname(masterAdocPath);
      for (const iss of lycheeIssues) {
        if (iss.file.startsWith(titleDir + '/') || iss.file === titleDir) {
          issues.push(iss);
        }
      }
    }

    return issues;
  }

  fix(masterAdocPath, issues) {
    const root = repoRoot();
    if (basename(masterAdocPath) !== 'master.adoc') return;

    const titleChainIssues = issues.filter(i =>
      i.message.startsWith('[title-chain]')
    );
    if (titleChainIssues.length > 0) {
      fixTitleChain(root, masterAdocPath, titleChainIssues);
    }
  }
}

// ── Lychee cross-title link checking ────────────────────────────────────────

/**
 * Run build orchestrator + lychee once, cache results as CQA issues.
 * Returns all lychee issues (across all titles) — caller filters by title.
 */
function getLycheeIssues(root) {
  if (_lycheeIssuesCache !== null) return _lycheeIssuesCache;
  _lycheeIssuesCache = [];

  try {
    // Run build orchestrator (builds fresh HTML + runs lychee with remapping)
    const branch = 'main';
    execSync(`node build/scripts/build-orchestrator.js -b ${branch}`, {
      cwd: root,
      stdio: 'pipe',
      timeout: 600000, // 10 minutes
    });
  } catch {
    // Build may exit non-zero if lychee finds broken links — that's expected
  }

  // Read the build report
  const reportPath = join(root, 'build-report.json');
  if (!existsSync(reportPath)) return _lycheeIssuesCache;

  try {
    const report = JSON.parse(readFileSync(reportPath, 'utf8'));
    if (!report.lychee || !report.lychee.errors) return _lycheeIssuesCache;

    for (const err of report.lychee.errors) {
      const sources = err.sources || [];
      for (const source of sources) {
        _lycheeIssuesCache.push(manual(
          source,
          `Broken link: ${err.line || err.url || 'unknown'} — ${err.cause || 'link check failed'}`,
          null
        ));
      }
      // If no source found, report against the HTML file
      if (sources.length === 0 && err.htmlFile) {
        _lycheeIssuesCache.push(manual(
          err.htmlFile,
          `Broken link: ${err.line || err.url || 'unknown'} — ${err.cause || 'link check failed'}`,
          null
        ));
      }
    }
  } catch {
    // JSON parse failed — skip lychee results
  }

  return _lycheeIssuesCache;
}

// ── Title chain validation ──────────────────────────────────────────────────

/**
 * Parse all :name: value attribute definitions from a text.
 */
function parseAttributes(text) {
  const attrs = {};
  const re = /^:([\w-]+):\s+(.+)$/gm;
  let m;
  while ((m = re.exec(text)) !== null) {
    attrs[m[1]] = m[2];
  }
  return attrs;
}

/**
 * Resolve attribute references in text using a lookup table.
 * Iterates up to 5 levels for nested attributes.
 */
function resolveAttrs(text, attrs) {
  let prev;
  for (let i = 0; i < 5 && text !== prev; i++) {
    prev = text;
    text = text.replace(/\{([\w-]+)\}/g, (_, name) => attrs[name] || `{${name}}`);
  }
  return text;
}

/**
 * Derive a Pantheon-compatible slug from resolved title text.
 * Algorithm: lowercase → non-alphanumeric characters → underscore → trim.
 */
function deriveSlug(resolvedTitle) {
  return resolvedTitle
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_|_$/g, '');
}

/**
 * Expand local-only attributes in text, keeping global attribute references.
 * Local attributes not defined in globalAttrs are substituted with their
 * local definitions (which may reference global attributes).
 */
function expandLocalAttrs(text, localAttrs, globalAttrs) {
  let prev;
  for (let i = 0; i < 10 && text !== prev; i++) {
    prev = text;
    text = text.replace(/\{([\w-]+)\}/g, (match, name) => {
      // Keep global attribute references as-is
      if (name in globalAttrs) return match;
      // Expand local-only attributes
      if (name in localAttrs) return localAttrs[name];
      return match;
    });
  }
  return text;
}

/**
 * Find the best matching book-title key for a resolved title.
 *
 * Strategy:
 * 1. Exact resolved value match
 * 2. Word-overlap scoring between resolved values (picks highest)
 * 3. Directory-name heuristic (strip 'rhdh' from dir, check key containment)
 * 4. Fall back: derive new key from resolved title slug
 */
function findMatchingBookTitleKey(resolvedTitle, entries, globalAttrs, titleDir) {
  const candidates = Object.entries(entries).filter(([, e]) => e.titleValue);

  // Normalize directory name for matching
  const dirBaseName = basename(titleDir);
  const dirSuffix = dirBaseName.includes('_') ? dirBaseName.slice(dirBaseName.indexOf('_') + 1) : dirBaseName;
  const normDirSuffix = dirSuffix.replace(/-?rhdh-?/g, '-').replace(/--+/g, '-').replace(/^-|-$/g, '');

  // 1. Exact resolved value match (prefer key that matches directory name)
  const exactMatches = candidates.filter(([, entry]) =>
    resolveAttrs(entry.titleValue, globalAttrs) === resolvedTitle
  );
  if (exactMatches.length === 1) return exactMatches[0][0];
  if (exactMatches.length > 1) {
    const dirMatch = exactMatches.find(([key]) => {
      const normKey = key.replace(/-?rhdh-?/g, '-').replace(/--+/g, '-').replace(/^-|-$/g, '');
      return normDirSuffix.includes(normKey) || normKey.includes(normDirSuffix);
    });
    if (dirMatch) return dirMatch[0];
    return exactMatches[0][0];
  }

  // 2. Word-overlap scoring
  const titleWords = toWordSet(resolvedTitle);
  let bestKey = null;
  let bestScore = 0;
  for (const [key, entry] of candidates) {
    const entryWords = toWordSet(resolveAttrs(entry.titleValue, globalAttrs));
    const score = wordOverlapScore(titleWords, entryWords);
    if (score > bestScore) {
      bestScore = score;
      bestKey = key;
    }
  }
  const minWords = Math.min(titleWords.size, bestScore > 0 ? toWordSet(resolveAttrs(entries[bestKey].titleValue, globalAttrs)).size : Infinity);
  if (bestScore >= Math.max(2, minWords * 0.6)) return bestKey;

  // 3. Directory-name heuristic
  for (const [key] of candidates) {
    const normKey = key.replace(/-?rhdh-?/g, '-').replace(/--+/g, '-').replace(/^-|-$/g, '');
    if (normDirSuffix.includes(normKey) || normKey.includes(normDirSuffix)) return key;
  }

  // 4. Fall back: derive new key
  return deriveSlug(resolvedTitle);
}

/**
 * Convert text to a set of normalized words (lowercase, >= 3 chars, no stopwords).
 */
function toWordSet(text) {
  const stopwords = new Set(['the', 'and', 'for', 'with', 'your', 'from', 'that', 'this', 'its']);
  return new Set(
    text.toLowerCase().split(/[^a-z0-9]+/)
      .filter(w => w.length >= 3 && !stopwords.has(w))
  );
}

/**
 * Count overlapping words between two sets, with prefix matching for words >= 4 chars.
 */
function wordOverlapScore(setA, setB) {
  let score = 0;
  for (const wordA of setA) {
    for (const wordB of setB) {
      if (wordA === wordB) { score++; break; }
      // Prefix match: "scorecard" matches "scorecards", "install" matches "installing"
      if (wordA.length >= 4 && wordB.length >= 4) {
        const shorter = wordA.length <= wordB.length ? wordA : wordB;
        const longer = wordA.length <= wordB.length ? wordB : wordA;
        if (longer.startsWith(shorter) || shorter.startsWith(longer.slice(0, Math.max(4, shorter.length)))) {
          score += 0.8;
          break;
        }
      }
    }
  }
  return score;
}

/**
 * Parse book-link and book-title entries from attributes.adoc.
 * Returns { keyPrefix: { slug, titleValue } }
 */
function parseBookEntries(attrsText) {
  const entries = {};
  const linkRe = /^:([\w-]+)-book-link:\s+\{product-docs-link\}\/html-single\/([^/\s]+)\/index/gm;
  const titleRe = /^:([\w-]+)-book-title:\s+(.+)$/gm;
  let m;

  while ((m = linkRe.exec(attrsText)) !== null) {
    const key = m[1];
    if (!entries[key]) entries[key] = {};
    entries[key].slug = m[2];
  }
  while ((m = titleRe.exec(attrsText)) !== null) {
    const key = m[1];
    if (!entries[key]) entries[key] = {};
    entries[key].titleValue = m[2];
  }

  return entries;
}

/**
 * Check title chain for a master.adoc file.
 * Returns issues for detections A, B, and C.
 */
function checkTitleChain(root, masterAdocPath) {
  const issues = [];
  const masterAbs = resolve(root, masterAdocPath);
  const masterContent = readFileSync(masterAbs, 'utf8');
  const titleDir = dirname(masterAdocPath);

  // Parse :title: from master.adoc
  const titleMatch = masterContent.match(/^:title:\s+(.+)$/m);
  if (!titleMatch) return issues;
  const titleValue = titleMatch[1].trim();

  // Detection A: :title: must use {<name>-book-title} reference
  const bookTitleRefRe = /^\{[\w-]+-book-title\}$/;
  if (!bookTitleRefRe.test(titleValue)) {
    issues.push(autofix(
      masterAdocPath,
      `[title-chain] :title: uses literal value "${titleValue}" instead of {<name>-book-title} attribute reference`,
      findLineNumber(masterContent, /^:title:\s+/)
    ));
  }

  // Detection B: docinfo.xml must use {title}
  const docinfoPath = join(titleDir, 'docinfo.xml');
  const docinfoAbs = resolve(root, docinfoPath);
  if (existsSync(docinfoAbs)) {
    const docinfoContent = readFileSync(docinfoAbs, 'utf8');
    const docinfoTitleMatch = docinfoContent.match(/<title>([^<]*)<\/title>/);
    if (docinfoTitleMatch && docinfoTitleMatch[1].trim() !== '{title}') {
      issues.push(autofix(
        docinfoPath,
        `[title-chain] docinfo.xml <title> contains "${docinfoTitleMatch[1]}" instead of "{title}"`,
        findLineNumber(docinfoContent, /<title>/)
      ));
    }
  }

  // Detection C: Book-link slug must match Pantheon-derived slug
  // Only check if :title: already uses a book-title reference
  if (bookTitleRefRe.test(titleValue)) {
    const keyPrefix = titleValue.match(/^\{([\w-]+)-book-title\}$/)[1];
    const attrsPath = join('artifacts', 'attributes.adoc');
    const attrsAbs = resolve(root, attrsPath);
    if (existsSync(attrsAbs)) {
      const attrsText = readFileSync(attrsAbs, 'utf8');
      const globalAttrs = parseAttributes(attrsText);
      const entries = parseBookEntries(attrsText);
      const entry = entries[keyPrefix];
      if (entry && entry.titleValue && entry.slug) {
        const resolvedTitle = resolveAttrs(entry.titleValue, globalAttrs);
        const expectedSlug = deriveSlug(resolvedTitle);
        if (entry.slug !== expectedSlug) {
          issues.push(manual(
            attrsPath,
            `[title-chain] Book-link slug "${entry.slug}" doesn't match derived slug "${expectedSlug}" for title "${resolvedTitle}". Verify against Pantheon before changing.`,
            null
          ));
        }
      }
    }
  }

  return issues;
}

/**
 * Find line number for a regex match in content.
 */
function findLineNumber(content, regex) {
  const lines = content.split('\n');
  for (let i = 0; i < lines.length; i++) {
    if (regex.test(lines[i])) return i + 1;
  }
  return null;
}

/**
 * Apply title chain fixes.
 */
function fixTitleChain(root, masterAdocPath, issues) {
  const masterAbs = resolve(root, masterAdocPath);
  const titleDir = dirname(masterAdocPath);
  const attrsPath = join('artifacts', 'attributes.adoc');
  const attrsAbs = resolve(root, attrsPath);

  for (const issue of issues) {
    if (issue.message.includes(':title: uses literal value')) {
      fixDetectionA(root, masterAbs, masterAdocPath, attrsAbs, attrsPath);
    } else if (issue.message.includes('docinfo.xml <title>')) {
      fixDetectionB(root, join(titleDir, 'docinfo.xml'));
    }
  }
}

/**
 * Fix Detection A: Replace literal :title: with {<name>-book-title} reference.
 *
 * 1. Read literal :title: value from master.adoc
 * 2. Expand local-only attributes to global forms
 * 3. Match against existing book-title entries or create new one
 * 4. Update attributes.adoc book-title value if needed
 * 5. Replace :title: in master.adoc with {<key>-book-title}
 */
function fixDetectionA(root, masterAbs, masterAdocPath, attrsAbs, attrsPath) {
  const masterContent = readFileSync(masterAbs, 'utf8');
  const titleMatch = masterContent.match(/^:title:\s+(.+)$/m);
  if (!titleMatch) return;
  const rawTitleValue = titleMatch[1].trim();

  // Parse global attributes from attributes.adoc
  const attrsText = readFileSync(attrsAbs, 'utf8');
  const globalAttrs = parseAttributes(attrsText);

  // Parse local attributes from master.adoc (defined after include::artifacts/attributes.adoc[])
  const localAttrs = { ...globalAttrs };
  const afterInclude = masterContent.split(/include::artifacts\/attributes\.adoc\[\]/)[1] || '';
  const localOnlyAttrs = parseAttributes(afterInclude);
  Object.assign(localAttrs, localOnlyAttrs);

  // Expand local-only attributes to get a canonical form using global refs
  const canonicalTitle = expandLocalAttrs(rawTitleValue, localOnlyAttrs, globalAttrs);

  // Fully resolve for comparison
  const resolvedTitle = resolveAttrs(canonicalTitle, globalAttrs);

  // Parse existing book entries
  const entries = parseBookEntries(attrsText);

  // Match against existing book-title entries
  let matchedKey = findMatchingBookTitleKey(
    resolvedTitle, entries, globalAttrs, dirname(masterAdocPath)
  );

  // Update or create book-title entry in attributes.adoc
  let updatedAttrs = attrsText;
  const bookTitleLineRe = new RegExp(`^:${matchedKey}-book-title:\\s+.+$`, 'm');
  if (bookTitleLineRe.test(updatedAttrs)) {
    // Update existing book-title value with canonical form
    updatedAttrs = updatedAttrs.replace(bookTitleLineRe, `:${matchedKey}-book-title: ${canonicalTitle}`);
  } else {
    // Create new book-title and book-link entries
    const slug = deriveSlug(resolvedTitle);
    const newEntries = `:${matchedKey}-book-title: ${canonicalTitle}\n:${matchedKey}-book-link: {product-docs-link}/html-single/${slug}/index`;
    // Insert after the last book-link/book-title entry
    const lastEntryMatch = updatedAttrs.match(/^:[\w-]+-book-(link|title):\s+.+$/gm);
    if (lastEntryMatch) {
      const lastEntry = lastEntryMatch[lastEntryMatch.length - 1];
      const insertPos = updatedAttrs.lastIndexOf(lastEntry) + lastEntry.length;
      updatedAttrs = updatedAttrs.slice(0, insertPos) + '\n' + newEntries + updatedAttrs.slice(insertPos);
    }
  }

  if (updatedAttrs !== attrsText) {
    writeFileSync(attrsAbs, updatedAttrs, 'utf8');
    invalidateCache(attrsPath);
  }

  // Replace :title: in master.adoc with reference
  const updatedMaster = masterContent.replace(
    /^:title:\s+.+$/m,
    `:title: {${matchedKey}-book-title}`
  );
  if (updatedMaster !== masterContent) {
    writeFileSync(masterAbs, updatedMaster, 'utf8');
    invalidateCache(masterAdocPath);
  }
}

/**
 * Fix Detection B: Replace docinfo.xml <title> with {title}.
 */
function fixDetectionB(root, docinfoPath) {
  const docinfoAbs = resolve(root, docinfoPath);
  if (!existsSync(docinfoAbs)) return;

  const content = readFileSync(docinfoAbs, 'utf8');
  const updated = content.replace(/<title>[^<]*<\/title>/, '<title>{title}</title>');
  if (updated !== content) {
    writeFileSync(docinfoAbs, updated, 'utf8');
  }
}

/**
 * Fix Detection C: Update book-link slug to match derived slug.
 */
// ── Original broken link checks ─────────────────────────────────────────────

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
