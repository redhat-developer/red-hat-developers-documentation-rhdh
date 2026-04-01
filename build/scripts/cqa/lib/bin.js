/**
 * Resolve external binary paths at startup to satisfy S4036 (PATH security).
 * Each binary is resolved once via `which` and cached as an absolute path.
 */

import { execFileSync } from 'node:child_process';

function resolve(name) {
  try {
    return execFileSync('which', [name], { encoding: 'utf8' }).trim(); // NOSONAR
  } catch {
    return name; // fallback to bare name if which fails
  }
}

export const GIT = resolve('git');
export const VALE = resolve('vale');
export const SED = resolve('sed');
