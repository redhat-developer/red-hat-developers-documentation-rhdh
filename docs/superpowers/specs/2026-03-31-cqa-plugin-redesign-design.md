# CQA Plugin Redesign — Design Document

**Date:** 2026-03-31
**Author:** Fabrice Flore-Thébault
**Jira:** Child of RHIDP-9152
**Status:** Approved, pending implementation plan

---

## Context

Feedback from the AI Show & Tell meeting (2026-03-26) on the first CQA implementation:

- Use the Skill Creator skill from the marketplace to build cleaner, more accurate skills
- Structure skill files into common subfolders (reference files, resources)
- After the exploration phase, "restart from scratch" to build something cleaner
- Read all CQA scripts and design something more maintainable and efficient
- Switching from bash to another language is an option

Current state: 19 bash scripts (`build/scripts/cqa-*.sh`), a shared library (`cqa-lib.sh`), an orchestrator (`cqa.sh`), and 19 flat Claude skill files (`.claude/skills/cqa-*.md`) with resources in `.claude/resources/`. Knowledge is scattered, scripts use fragile grep/awk/sed for AsciiDoc parsing, no unit tests.

---

## Decision: Node.js + asciidoctor.js

Scripts rewritten in Node.js using `asciidoctor.js` for AST-level document parsing. Rationale:

- **Eliminates false positives entirely** — current bash scripts use grep/awk on raw text, producing false positives on content inside code blocks, conditional sections (`ifdef`), and attribute substitutions. The AST knows exactly what is a heading, block, list, or attribute.
- **Unit testable** — JavaScript functions are trivially testable with Jest/Vitest; bash functions are not.
- **Checklist output only** — SARIF output is dropped. GitHub does not surface SARIF reports usefully in pull requests. The existing `[AUTOFIX]`/`[MANUAL]`/`[FIXED]` checklist format is retained unchanged.
- **`package.json` scoped to `build/scripts/cqa/`** — does not pollute the repo root.

---

## Architecture: Two Layers

The CQA system has two distinct layers:

**Layer 1 — Automation** (`build/scripts/cqa/`): Node.js module that performs file analysis and auto-fixes. Called by CI and by humans directly.

**Layer 2 — AI** (`.claude/plugins/cqa/`): Claude Code plugin with skills that orchestrate the automation, handle manual judgment calls, and guide Claude through the full workflow.

A single **CQA Spec** (`resources/cqa-spec.md`) is the source of truth for both layers — detailed enough that either layer could be rebuilt from scratch using only the spec.

The plugin lives inside this repo (not a separate repo). The CQA requirements are currently too opinionated to safely reuse across all Red Hat docs repos. A well-designed in-repo plugin can be extracted later if needed to influence a broader CQA standard.

---

## Section 1: Node.js Script Architecture

### File layout

```
build/scripts/cqa/
  package.json                  ← scoped here, not repo root
  index.js                      ← CLI entry point
  lib/
    asciidoc.js                 ← title loading, AST traversal helpers
    checker.js                  ← base Checker class, Issue model
    output.js                   ← checklist output ([AUTOFIX], [MANUAL], [FIXED])
  checks/
    cqa-00-orphaned.js
    cqa-00-directory-structure.js
    cqa-01-vale-dita.js
    cqa-02-assembly-template.js
    cqa-03-modularization.js
    cqa-04-module-templates.js
    cqa-05-modular-elements.js
    cqa-06-assembly-scope.js
    cqa-07-toc-depth.js
    cqa-08-short-description-content.js
    cqa-09-short-description-format.js
    cqa-10-titles.js
    cqa-11-prerequisites.js
    cqa-12-grammar.js
    cqa-13-content-type.js
    cqa-14-no-broken-links.js
    cqa-15-redirects.js
    cqa-16-product-names.js
    cqa-17-disclaimers.js
```

### Core model

```javascript
// lib/asciidoc.js
// Loads a title (master.adoc + all includes) via asciidoctor.js
// Resolves include:: directives, deduplicates symlinks
// Returns: { doc: AsciiDoc AST, files: string[], rawText: Map<file, string> }

// lib/checker.js
// Base class for all checks
// interface Checker {
//   id: string                         // e.g. "03"
//   name: string                       // e.g. "Modularization"
//   check(title: Title): Issue[]
//   fix(title: Title, issues: Issue[]): void
// }
// Issue: { file, line, message, fixable: boolean }

// lib/output.js
// Renders Issue[] as checklist format — identical markers to current bash output:
//   [AUTOFIX] file: Line N: message
//   [FIXED]   file: message
//   [MANUAL]  file: Line N: message
// No SARIF output.
```

### CLI interface

```bash
# Report issues for a title
node build/scripts/cqa/index.js titles/<title>/master.adoc

# Auto-fix issues for a title
node build/scripts/cqa/index.js --fix titles/<title>/master.adoc

# Report across all titles
node build/scripts/cqa/index.js --all

# Auto-fix across all titles
node build/scripts/cqa/index.js --fix --all
```

### AST vs line-scan per check

Checks that benefit most from AST (no longer fooled by code blocks or attributes):
- CQA-02: Assembly structure (includes, block content detection)
- CQA-03: Modularization (content type attribute, block ranges)
- CQA-05: Required modular elements (section presence)
- CQA-07: TOC depth (heading levels via `getSections()`)
- CQA-13: Content type matching (section structure)

Checks using line-scan (AST overhead not justified):
- CQA-08, 09: Short description (simple pattern, near top of file)
- CQA-11: Prerequisites (section label pattern)
- CQA-16: Product names (attribute usage)
- CQA-17: Disclaimers (include pattern)

### CI integration

`content-quality-assessment.yml` currently calls `./build/scripts/cqa.sh --all`.
Updated to: `node build/scripts/cqa/index.js --all`

A thin `build/scripts/cqa.sh` wrapper is kept during transition for backward compatibility.

---

## Section 2: Claude Plugin Structure

### File layout

```
.claude/plugins/cqa/
  plugin.json                       ← plugin manifest, permissions, skill list
  skills/
    cqa-main-workflow.md            ← orchestrates all 19 checks
    cqa-01-vale-dita.md
    cqa-02-assembly-template.md
    cqa-03-modularization.md
    cqa-04-module-templates.md
    cqa-05-modular-elements.md
    cqa-06-assembly-scope.md
    cqa-07-toc-depth.md
    cqa-08-short-description-content.md
    cqa-09-short-description-format.md
    cqa-10-titles.md
    cqa-11-prerequisites.md
    cqa-12-grammar.md
    cqa-13-content-type.md
    cqa-14-no-broken-links.md
    cqa-15-redirects.md
    cqa-16-product-names.md
    cqa-17-disclaimers.md
    update-all-resources.md         ← utility skill
  resources/
    cqa-spec.md                     ← THE comprehensive spec
    assembly-template.adoc
    concept-template.adoc
    procedure-template.adoc
    reference-template.adoc
    red-hat-modular-docs.md
    red-hat-ssg-for-cqa.md
    red-hat-peer-review-for-cqa.md
    content-types-for-cqa.md
```

### What gets deleted

- `.claude/skills/cqa-*.md` — replaced by plugin skills
- `.claude/skills/cqa-main-workflow.md` — moved into plugin
- `.claude/skills/get-title-files.md` — replaced by `asciidoc.js`
- `.claude/resources/generate_cqa_skills.py` — skills are now hand-authored via skill creator, not generated from HTML
- `.claude/cqa-checklist.md` — content absorbed into `cqa-main-workflow.md` skill

### What stays at `.claude/` level

- `.claude/skills/align-title-directories.md` — not CQA-specific
- `.claude/CLAUDE.md` — updated (see Section 4)
- `.claude/settings.json` — updated (see Section 4)

### Skill authoring

Each of the 19 skills is rewritten using the **skill-creator** skill from the marketplace. Skills follow the skill creator's output format and are validated with the skill-reviewer agent. Each skill:
- Has a clear trigger condition
- References the script command as the primary action
- Documents what [MANUAL] issues require human judgment
- References `resources/cqa-spec.md` for detailed requirements rather than duplicating them

---

## Section 3: The CQA Spec (`resources/cqa-spec.md`)

The spec is the single document that makes "restart from scratch" possible. It is rich enough to regenerate both the Node.js scripts and the Claude skills from scratch.

### Structure

```markdown
# CQA Specification

## Overview
Purpose, scope, the 19 checks at a glance, workflow order rationale.

## Execution Interface
CLI flags, output markers ([AUTOFIX], [FIXED], [MANUAL]),
idempotency requirement, --all mode behavior.

## Shared Infrastructure
- AsciiDoc loading via asciidoctor.js: patterns, API usage
- Title traversal: include:: resolution algorithm, symlink dedup
- Issue model and output format
- Block range detection: how to identify and skip code/listing blocks

## Requirements

One section per check covering:
- What it validates
- Detection logic (AST API calls or line patterns)
- Fix logic (what changes, how)
- Edge cases
- Example: passing vs failing AsciiDoc

### CQA-00: Orphaned modules
### CQA-01: Vale DITA
### CQA-02: Assembly structure
### CQA-03: Modularization
... (all 19)

## Workflow Order
Why each check runs in its position.
Key dependencies: CQA-03 before CQA-10 (content type before filename renames),
CQA-01/12 (Vale/grammar) near the end, CQA-14 (links) last.
```

Each requirement section is detailed enough to implement from without reading any existing code.

---

## Section 4: CLAUDE.md and Settings

### CLAUDE.md additions

A new **Claude Code Setup** section is added at the top of `.claude/CLAUDE.md`:

```markdown
## Claude Code Setup

Install these plugins before starting a session:

/plugin install atlassian     ← Jira: create tasks, set SP, add comments
/plugin install playwright    ← Browser: Pantheon, preview URLs
/plugin install plugin-dev    ← Plugin and skill development
/plugin install skill-creator ← Create and improve Claude skills

The `cqa` plugin is built into this repo at `.claude/plugins/cqa/` and
is loaded automatically — no install needed.
```

### `settings.json` cleanup

`settings.local.json` is audited: stale one-off permissions removed, any genuinely needed entries promoted to `settings.json`. The CQA plugin's `plugin.json` declares its own permissions (`node build/scripts/cqa/*`), reducing the number of entries needed in `settings.json`.

---

## Implementation Sequence

1. **Create Jira task** — child of RHIDP-9152, assign to Fabrice, set SP, create branch
2. **Write `cqa-spec.md`** — extract all knowledge from existing skills + scripts into the spec
3. **Rewrite scripts** — Node.js, one check at a time, validated against current bash output
4. **Build plugin** — `plugin.json`, migrate resources, rewrite skills with skill-creator
5. **Update CLAUDE.md and settings** — setup section, settings cleanup
6. **Delete old files** — remove flat `.claude/skills/cqa-*.md`, bash scripts, generator script
7. **Update CI** — point `content-quality-assessment.yml` at Node.js entry point
8. **PR and Jira close-out**

---

## Out of Scope

- Reusable external plugin / npm package (not requested, premature given opinionated implementation)
- SARIF output (dropped — GitHub doesn't surface it usefully in PRs)
- Google Docs integration (manual copy/paste remains the reliable method per meeting notes)
- Shared AI memory / trustworthiness scoring (separate initiative, not part of this task)
