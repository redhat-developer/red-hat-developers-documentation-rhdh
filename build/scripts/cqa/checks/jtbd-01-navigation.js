/**
 * JTBD-01: Navigation file structure
 *
 * Validates MAP modules (nav- prefix):
 *   - Must have :_mod-docs-content-type: MAP
 *   - Must contain only a title and include:: directives (no body text)
 *   - First include must be a con- (concept) file
 *   - Comments (// ...), blank lines, attribute lines (:key: value),
 *     and ID lines ([id="..."]) are allowed
 *
 * No autofix — structural issues require manual correction.
 */

import { existsSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { Checker, manual } from '../lib/checker.js';
import { repoRoot, collectTitle, getContentType, getLines } from '../lib/asciidoc.js';

export default class Jtbd01Navigation extends Checker {
  id = 'jtbd-01';
  name = 'Verify navigation file structure';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const issues = [];

    for (const file of files) {
      const bn = basename(file);
      if (!bn.startsWith('nav-')) continue;
      if (!existsSync(resolve(root, file))) continue;

      issues.push(...checkNavFile(file));
    }

    return issues;
  }
}

function checkNavFile(file) {
  const issues = [];
  const contentType = getContentType(file);
  const lines = getLines(file);

  // Must have MAP content type
  if (contentType !== 'MAP') {
    issues.push(manual(file, 'Navigation file must have :_mod-docs-content-type: MAP'));
  }

  // Parse structure: only title, includes, comments, blank lines, attribute lines
  let hasTitle = false;
  let firstInclude = null;
  let firstIncludeLine = 0;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();

    // Skip blank lines
    if (trimmed === '') continue;
    // Skip comments
    if (trimmed.startsWith('//')) continue;
    // Skip attribute lines (:key: value)
    if (/^:[a-zA-Z_]/.test(trimmed)) continue;
    // Skip ID lines ([id="..."])
    if (trimmed.startsWith('[id=')) continue;
    // Title line
    if (trimmed.startsWith('= ')) {
      hasTitle = true;
      continue;
    }
    // Include directive
    if (trimmed.startsWith('include::')) {
      if (!firstInclude) {
        firstInclude = trimmed;
        firstIncludeLine = i + 1;
      }
      continue;
    }

    // Anything else is body text — not allowed in navigation files
    issues.push(manual(file,
      `Line ${i + 1}: Navigation files must contain only a title and include directives (found: "${trimmed.slice(0, 60)}")`));
    break; // Report only the first violation
  }

  if (!hasTitle) {
    issues.push(manual(file, 'Navigation file must have a title (= Title)'));
  }

  // First include must be a con_ file
  if (firstInclude) {
    const raw = firstInclude.replace(/^include::/, '');
    const bracketIdx = raw.indexOf('[');
    const includeTarget = bracketIdx >= 0 ? raw.slice(0, bracketIdx) : raw;
    const targetBn = basename(includeTarget);
    if (!targetBn.startsWith('con_') && !targetBn.startsWith('con-')) {
      issues.push(manual(file,
        `Line ${firstIncludeLine}: First include must be a concept file (con_*), got: ${targetBn}`));
    }
  }

  return issues;
}
