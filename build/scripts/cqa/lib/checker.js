/**
 * checker.js — Base Checker class and Issue model
 *
 * interface Issue {
 *   file: string;        // repo-relative path
 *   line: number | null;
 *   message: string;
 *   fixable: boolean;    // true = AUTOFIX, false = MANUAL
 *   delegateTo?: string; // e.g. "09" for CQA-09
 * }
 *
 * class Checker {
 *   id: string           // e.g. "00a"
 *   name: string         // e.g. "Orphaned modules"
 *   check(title): Issue[]
 *   fix(title, issues): void
 * }
 */

export function issue({ file, line = null, message, fixable, delegateTo = null }) {
  return { file, line, message, fixable, delegateTo };
}

export function autofix(file, message, line = null) {
  return issue({ file, line, message, fixable: true });
}

export function manual(file, message, line = null) {
  return issue({ file, line, message, fixable: false });
}

export function delegate(file, to, message, line = null, fixable = false) {
  return issue({ file, line, message, fixable, delegateTo: to });
}

export class Checker {
  /** @type {string} e.g. "00a" */
  id = '';
  /** @type {string} e.g. "Orphaned modules" */
  name = '';

  /**
   * @param {import('./asciidoc.js').Title} title
   * @returns {import('./checker.js').Issue[]}
   */
  check(_title) {
    throw new Error(`${this.constructor.name}.check() not implemented`);
  }

  /**
   * @param {import('./asciidoc.js').Title} title
   * @param {import('./checker.js').Issue[]} issues
   */
  fix(_title, _issues) {
    // Default: no-op (manual-only checks)
  }
}
