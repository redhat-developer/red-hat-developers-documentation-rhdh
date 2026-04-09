/**
 * output.js — Checklist output rendering
 *
 * Markers (identical to legacy bash output):
 *   [AUTOFIX]  file: Line N: message   — fixable with --fix
 *   [FIXED]    file: message           — was auto-fixed (in --fix mode)
 *   [MANUAL]   file: Line N: message   — requires human judgment
 *   [-> CQA-NN AUTOFIX] / [-> CQA-NN MANUAL] — delegated to another check
 */

export function renderIssue(issue, fixed = false) {
  const loc = issue.line == null ? '' : ` Line ${issue.line}:`;
  if (issue.delegateTo) {
    const kind = issue.fixable ? 'AUTOFIX' : 'MANUAL';
    return `- [ ] [-> CQA-${issue.delegateTo} ${kind}] ${issue.file}:${loc} ${issue.message}`;
  }
  if (fixed) {
    return `- [x] [FIXED]    ${issue.file}: ${issue.message}`;
  }
  const marker = issue.fixable ? '[AUTOFIX]' : '[MANUAL] ';
  return `- [ ] ${marker} ${issue.file}:${loc} ${issue.message}`;
}

export function renderCheckHeader(id, name, titlePath) {
  return `\n## CQA-${id}: ${name}\nProcessing: ${titlePath}\n`;
}

export function renderFileHeader(filePath) {
  return `\n### ${filePath}`;
}

export function renderSummary({ filesChecked, filesWithIssues, autofixable, manual, delegated, fixMode }) {
  const lines = [
    '\n### Summary',
    `Files: ${filesChecked} checked, ${filesWithIssues} with issues`,
    `Violations: ${autofixable + manual + delegated} total (${autofixable} autofixable, ${manual} manual, ${delegated} delegated)`,
  ];
  if (!fixMode && autofixable > 0) {
    lines.push(`Run \`node build/scripts/cqa/index.js --fix --all\` to auto-resolve ${autofixable} issue${autofixable === 1 ? '' : 's'}.`);
  }
  return lines.join('\n');
}
