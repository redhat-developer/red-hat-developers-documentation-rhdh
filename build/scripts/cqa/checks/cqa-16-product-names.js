/**
 * CQA-16: Verify official product names
 *
 * Detection: uses shared Vale cache (populated once by index.js) or falls back
 * to running Vale with .vale-product-names.ini.
 * Filters for DeveloperHub.ProductNames rule.
 *
 * Fix: replace hardcoded names with attribute references (longest first),
 *      fix double-bracing artifacts.
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename } from 'node:path';
import { execFileSync } from 'node:child_process';
import { Checker, autofix } from '../lib/checker.js';
import {
  repoRoot, collectTitle, getContentType,
  computeBlockRanges, isInBlock, invalidateCache,
} from '../lib/asciidoc.js';
import { hasValeCache, getCachedIssues } from '../lib/vale.js';

// Replacement patterns for fix(), ordered longest-first.
const PATTERNS = [
  { pattern: 'Red Hat Advanced Developer Suite', replacement: '{rhads-brand-name}' },
  { pattern: 'Red Hat OpenShift Container Platform', replacement: '{ocp-brand-name}' },
  { pattern: 'Red Hat Trusted Profile Analyzer', replacement: '{rhtpa-brand-name}' },
  { pattern: 'Red Hat Trusted Artifact Signer', replacement: '{rhtas-brand-name}' },
  { pattern: 'Red Hat Advanced Cluster Security', replacement: '{rhacs-brand-name}' },
  { pattern: 'Red Hat Developer Lightspeed', replacement: '{ls-brand-name}' },
  { pattern: 'Red Hat OpenShift Serverless', replacement: '{rhoserverless-brand-name}' },
  { pattern: 'Red Hat OpenShift Dedicated', replacement: '{osd-brand-name}' },
  { pattern: 'Red Hat OpenShift Logging', replacement: '{logging-brand-name}' },
  { pattern: 'Red Hat Container Registry', replacement: '{rhcr}' },
  { pattern: 'Red Hat Ecosystem Catalog', replacement: '{rhec}' },
  { pattern: 'Red Hat Build of Keycloak', replacement: '{rhbk-brand-name}' },
  { pattern: 'Red Hat Enterprise Linux', replacement: '{rhel}' },
  { pattern: 'Red Hat OpenShift AI', replacement: '{rhoai-brand-name}' },
  { pattern: 'Red Hat Developer Hub', replacement: '{product}' },
  { pattern: 'Microsoft Azure Kubernetes Service', replacement: '{aks-brand-name}' },
  { pattern: 'Amazon Elastic Kubernetes Service', replacement: '{eks-brand-name}' },
  { pattern: 'OpenShift AI Connector', replacement: '{openshift-ai-connector-name}' },
  { pattern: 'Red Hat Developer', replacement: '{rhdeveloper-name}' },
  { pattern: 'OpenShift Container Platform', replacement: '{ocp-short}' },
  { pattern: 'OpenShift Data Foundation', replacement: '{odf-name}' },
  { pattern: 'Developer Lightspeed', replacement: '{ls-short}' },
  { pattern: 'Lightspeed Core Service', replacement: '{lcs-name}' },
  { pattern: 'Trusted Profile Analyzer', replacement: '{rhtpa-short}' },
  { pattern: 'Trusted Artifact Signer', replacement: '{rhtas-short}' },
  { pattern: 'Advanced Cluster Security', replacement: '{rhacs-short}' },
  { pattern: 'Elastic Kubernetes Service', replacement: '{eks-name}' },
  { pattern: 'Azure Kubernetes Service', replacement: '{aks-name}' },
  { pattern: 'Google Kubernetes Engine', replacement: '{gke-brand-name}' },
  { pattern: 'Amazon Web Services', replacement: '{aws-brand-name}' },
  { pattern: 'Technology Preview', replacement: '{technology-preview}' },
  { pattern: 'Developer Preview', replacement: '{developer-preview}' },
  { pattern: 'OpenShift Dedicated', replacement: '{osd-short}' },
  { pattern: 'OpenShift Logging', replacement: '{logging-short}' },
  { pattern: 'Developer Hub', replacement: '{product-short}' },
  { pattern: 'Microsoft Azure', replacement: '{azure-brand-name}' },
  { pattern: 'Google Cloud', replacement: '{gcp-brand-name}' },
  { pattern: 'RHDH Local', replacement: '{product-local-very-short}' },
  { pattern: 'Backstage', replacement: '{backstage}' },
  { pattern: 'RHDH', replacement: '{product-very-short}' },
  { pattern: 'RHOCP', replacement: '{ocp-very-short}' },
  { pattern: 'RHOAI', replacement: '{rhoai-short}' },
  { pattern: 'RHBK', replacement: '{rhbk}' },
  { pattern: 'Azure', replacement: '{azure-short}' },
  { pattern: 'AWS', replacement: '{aws-short}' },
  { pattern: 'ACS', replacement: '{rhacs-very-short}' },
  { pattern: 'LCS', replacement: '{lcs-short}' },
  { pattern: 'TAS', replacement: '{rhtas-very-short}' },
  { pattern: 'TPA', replacement: '{rhtpa-very-short}' },
  { pattern: 'AKS', replacement: '{aks-short}' },
  { pattern: 'EKS', replacement: '{eks-short}' },
  { pattern: 'GKE', replacement: '{gke-short}' },
];

export default class Cqa16ProductNames extends Checker {
  id = '16';
  name = 'Verify official product names';

  check(masterAdocPath) {
    const root = repoRoot();
    const files = collectTitle(resolve(root, masterAdocPath));
    const adocFiles = files
      .filter(f => {
        if (!f.endsWith('.adoc')) return false;
        if (basename(f) === 'attributes.adoc') return false;
        if (getContentType(f) === 'SNIPPET') return false;
        return true;
      });

    if (adocFiles.length === 0) return [];

    if (hasValeCache()) {
      // Use pre-computed cache — filter for DeveloperHub.ProductNames
      const issues = [];
      for (const f of adocFiles) {
        for (const iss of getCachedIssues(f)) {
          if (iss.Check !== 'DeveloperHub.ProductNames') continue;
          issues.push(autofix(f, `${iss.Check}: ${iss.Message}`, iss.Line));
        }
      }
      return issues;
    }

    // Fallback: run Vale directly
    const valeConfig = resolve(root, '.vale-product-names.ini');
    if (!existsSync(valeConfig)) return [];
    const absFiles = adocFiles.map(f => resolve(root, f)).filter(f => existsSync(f));
    if (absFiles.length === 0) return [];
    return runValeAndClassify(root, valeConfig, absFiles);
  }

  fix(masterAdocPath, issues) {
    const root = repoRoot();
    const filesWithIssues = new Set(issues.filter(i => i.fixable).map(i => i.file));
    for (const file of filesWithIssues) {
      fixFile(root, file);
    }
  }
}

// ── Vale detection (fallback) ────────────────────────────────────────────────

function runValeAndClassify(root, configPath, files) {
  let jsonStr;
  try {
    jsonStr = execFileSync('vale', [
      '--config', configPath,
      '--output', 'JSON',
      ...files,
    ], { cwd: root, encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 });
  } catch (err) {
    jsonStr = err.stdout || '';
  }

  let data;
  try {
    data = JSON.parse(jsonStr);
  } catch {
    return [];
  }

  const issues = [];
  for (const [file, fileIssues] of Object.entries(data)) {
    const relPath = file.startsWith(root) ? file.slice(root.length + 1) : file;
    for (const iss of fileIssues) {
      issues.push(autofix(relPath, `${iss.Check}: ${iss.Message}`, iss.Line));
    }
  }

  return issues;
}

// ── Fix ───────────────────────────────────────────────────────────────────────

function fixFile(root, file) {
  const abs = resolve(root, file);
  if (!existsSync(abs)) return;

  let content = readFileSync(abs, 'utf8');
  const lines = content.split('\n');

  const blockRanges = computeBlockRanges(file);
  const fixedLines = lines.map((line, i) => {
    const lineNum = i + 1;
    if (isInBlock(blockRanges, lineNum)) return line;
    if (/^:[a-zA-Z]/.test(line)) return line;
    if (line.startsWith('//')) return line;

    let result = line;
    for (const entry of PATTERNS) {
      if (!result.includes(entry.pattern)) continue;
      const fixAttr = entry.replacement.split('|')[0];
      result = result.replaceAll(entry.pattern, fixAttr);
    }
    return result;
  });

  content = fixedLines.join('\n');
  content = content.replaceAll('{{', '{').replaceAll('}}', '}');

  writeFileSync(abs, content, 'utf8');
  invalidateCache(file);
}
