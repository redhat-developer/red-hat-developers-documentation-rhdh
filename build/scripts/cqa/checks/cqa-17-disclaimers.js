/**
 * CQA-17: Legal disclaimers for preview features
 *
 * For each .adoc (skip attributes.adoc, snip-* files):
 *   - Files mentioning "Technology Preview" must include the official disclaimer
 *   - Files mentioning "Developer Preview" must include the official disclaimer
 *   - Skip mentions inside source/listing blocks
 *
 * All violations are MANUAL — the correct snippet path varies by title.
 */

import { existsSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, manual } from '../lib/checker.js';
import {
  repoRoot, collectTitle, getLines,
  computeBlockRanges, isInBlock,
} from '../lib/asciidoc.js';

const TP_MENTION_RE = /tech(?:nology)? preview|\{technology-preview\}/i;
const DP_MENTION_RE = /dev(?:eloper)? preview|\{developer-preview\}/i;

const TP_DISCLAIMER_RE = /include::.*snip[-_].*tech.*preview|include::.*snip[-_].*tp[-_]/;
const DP_DISCLAIMER_RE = /include::.*snip[-_].*dev.*preview|include::.*snip[-_].*dp[-_]/;

// Inline disclaimer phrases (when disclaimer text is written directly, not via snippet)
const TP_INLINE_RE = /technology preview feature only/i;
const DP_INLINE_RE = /developer preview.*not supported|not supported.*developer preview/i;

export default class Cqa17Disclaimers extends Checker {
  id = '17';
  name = 'Verify legal disclaimers for preview features';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      const bn = basename(file);
      if (bn === 'attributes.adoc') continue;
      if (bn.startsWith('snip-')) continue;
      if (!existsSync(resolve(root, file))) continue;

      issues.push(...checkFile(file));
    }

    return issues;
  }

  // No fix() — all CQA-17 issues are manual
}

function checkFile(file) {
  const lines = getLines(file);
  const blockRanges = computeBlockRanges(file);
  const issues = [];

  // Check Technology Preview
  const tpLine = findMentionOutsideBlocks(lines, blockRanges, TP_MENTION_RE);
  if (tpLine !== null) {
    const hasDisclaimer = lines.some(l => TP_DISCLAIMER_RE.test(l)) ||
                          lines.some(l => TP_INLINE_RE.test(l));
    if (!hasDisclaimer) {
      issues.push(manual(file, "Mentions 'Technology Preview' but may not include official disclaimer snippet", tpLine));
    }
  }

  // Check Developer Preview
  const dpLine = findMentionOutsideBlocks(lines, blockRanges, DP_MENTION_RE);
  if (dpLine !== null) {
    const hasDisclaimer = lines.some(l => DP_DISCLAIMER_RE.test(l)) ||
                          lines.some(l => DP_INLINE_RE.test(l));
    if (!hasDisclaimer) {
      issues.push(manual(file, "Mentions 'Developer Preview' but may not include official disclaimer snippet", dpLine));
    }
  }

  return issues;
}

function findMentionOutsideBlocks(lines, blockRanges, regex) {
  // Only skip code/listing/passthrough/table blocks, NOT admonition (====) blocks
  // since admonition content is rendered prose that needs disclaimers
  const codeRanges = blockRanges.filter(r => r.delim !== '====');
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    // Skip comment lines
    if (line.trimStart().startsWith('//')) continue;
    if (regex.test(line) && !isInBlock(codeRanges, i + 1)) {
      return i + 1; // 1-based
    }
  }
  return null;
}
