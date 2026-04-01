# CQA Specification

**Version:** 2.1 (extracted from bash scripts 2026-03-31)
**Purpose:** Complete specification of all 19 CQA checks. Sufficient to rewrite both the automation scripts and the Claude skills from scratch.
**Future home:** `.claude/plugins/cqa/resources/cqa-spec.md`

---

## Overview

CQA (Content Quality Assessment) validates AsciiDoc documentation in the `red-hat-developers-documentation-rhdh` repo against Red Hat modular documentation standards. It runs as a GitHub Actions workflow on every PR and locally via CLI.

**19 checks in workflow order:**

| # | ID | Name | Fixable |
|---|---|---|---|
| 1 | CQA-00a | Orphaned modules | Autofix (delete) |
| 2 | CQA-00b | Directory structure | Autofix (git mv) |
| 3 | CQA-03 | Modularization | Autofix |
| 4 | CQA-13 | Content type match | Autofix |
| 5 | CQA-10 | Titles | Autofix |
| 6 | CQA-08 | Short description content | Autofix / Manual |
| 7 | CQA-09 | Short description format | Autofix |
| 8 | CQA-11 | Prerequisites | Autofix / Manual |
| 9 | CQA-02 | Assembly structure | Autofix |
| 10 | CQA-05 | Required modular elements | Autofix / Manual |
| 11 | CQA-04 | Module templates | Autofix / Manual |
| 12 | CQA-06 | Assembly scope (one story) | Manual |
| 13 | CQA-07 | TOC depth max 3 levels | Autofix / Manual |
| 14 | CQA-16 | Official product names | Autofix |
| 15 | CQA-01 | Vale AsciiDoc DITA | Autofix / Manual |
| 16 | CQA-12 | Grammar and style (Vale) | Manual |
| 17 | CQA-17 | Legal disclaimers | Manual |
| 18 | CQA-14 | No broken links | Manual |
| 19 | CQA-15 | Redirects | Manual |

**Workflow order rationale:**
- CQA-00: Clean up garbage first (orphans, misnamed dirs) before analysing content
- CQA-03 before CQA-10: set content type metadata before title/filename renames use it
- CQA-13 before CQA-10: validate content matches declared type before renaming
- CQA-10 before CQA-08/09/11: rename files before checking their content details
- CQA-02 before CQA-05: fix assembly structure before checking required elements
- CQA-01/12 near end: Vale runs on already-fixed content
- CQA-14/15 last: verify links after all file renames are done

---

## Execution Interface

```bash
# Report issues for a single title
node build/scripts/cqa/index.js titles/<title>/master.adoc

# Auto-fix issues for a single title
node build/scripts/cqa/index.js --fix titles/<title>/master.adoc

# Report across all titles
node build/scripts/cqa/index.js --all

# Auto-fix across all titles
node build/scripts/cqa/index.js --fix --all

# Run a single check
node build/scripts/cqa/index.js --check 03 titles/<title>/master.adoc
```

**Output markers (identical to current bash output):**
- `[AUTOFIX] file: Line N: message` — fixable with `--fix`
- `[FIXED]   file: message` — was auto-fixed (in `--fix` mode)
- `[MANUAL]  file: Line N: message` — requires human judgment
- `[-> CQA-NN AUTOFIX]` / `[-> CQA-NN MANUAL]` — delegated to another check

**Idempotency requirement:** Each check must be re-run until it produces no new changes. The full sequence must be re-run until stable.

---

## Shared Infrastructure

### File discovery

Starting from `master.adoc`, collect all included files recursively via `include::` directives. Resolve paths relative to the including file's directory. Deduplicate by realpath (handles symlinks).

Skip files: non-`.adoc`, `attributes.adoc` (in most checks).

**Key function:** `collectTitle(masterAdocPath) → string[]` — returns ordered array of file paths.

### Content type detection

Content type is declared on line 1 of each file:
```asciidoc
:_mod-docs-content-type: PROCEDURE
```

Valid values: `ASSEMBLY`, `PROCEDURE`, `CONCEPT`, `REFERENCE`, `SNIPPET`.

**Key function:** `getContentType(filePath) → string | null`

### Block range detection

AsciiDoc source/listing blocks are delimited by `----`, `....`, or `++++`. Content inside blocks must be skipped by checks that do text pattern matching (to avoid false positives on code examples).

**Key function:** `computeBlockRanges(filePath) → Array<{start, end}>` and `isInBlock(ranges, lineNum) → boolean`

**AST advantage:** With asciidoctor.js, use `doc.findBy({context: 'listing'})` or `doc.findBy({context: 'literal'})` to get block objects with line ranges directly from the AST, eliminating the need for fragile delimiter counting.

### Issue model

```typescript
interface Issue {
  file: string;       // repo-relative path
  line: number | null;
  message: string;
  fixable: boolean;   // true = AUTOFIX, false = MANUAL
  delegateTo?: string; // e.g. "9" for CQA-09
}
```

### Output format

```
## CQA-03: Verify content type metadata
Processing: titles/install-rhdh-ocp/master.adoc

### modules/install_rhdh-ocp/proc-install-rhdh.adoc
- [ ] [AUTOFIX] modules/.../proc-install-rhdh.adoc: Line 1: Missing :_mod-docs-content-type: -- add PROCEDURE

### Summary
Files: 12 checked, 1 with issues
Violations: 1 total (1 autofixable, 0 manual, 0 delegated)
Run with --fix to auto-resolve 1 issues.
```

---

## Requirements

### CQA-00a: Orphaned modules

**What:** `.adoc` files in `artifacts/`, `assemblies/`, `modules/` that are not referenced by any `include::` directive anywhere in the repo. Also image files in `images/` not referenced by any `.adoc` file.

**Scope:** Entire repo (not per-title). Accepts but ignores `--all` and file path args for interface compatibility.

**Detection:**
1. Scan all `include::` lines across the entire repo, collect all referenced basenames
2. Handle attribute substitution in include paths: `include::snip-{product}-note.adoc[]` — convert `{attr}` to `.*` regex pattern for matching
3. For each `.adoc` in `artifacts/`, `assemblies/`, `modules/`: if its basename is not in referenced set → orphan
4. For images: collect all `image::` and `image:` references across `titles/`, `modules/`, `assemblies/`. For each file in `images/`: if its basename is not referenced → orphan
5. Skip `*.template.adoc` files

**Fix:** `git rm` if tracked, `rm` if untracked. Clean empty image directories after deletion.

**Output:** `[AUTOFIX] path/to/file: Orphaned .adoc file (not included anywhere)`

---

### CQA-00b: Directory structure

**What:** Title directories, assembly directories, module directories, and image directories must follow `<category>_<context>` naming convention.

**Scope:** Entire repo.

**Convention:**
- `titles/<category>_<context>/` — e.g. `titles/install_rhdh-ocp/`
- `assemblies/<category>_<context>/` — owned by one title
- `assemblies/<category>_shared/` — shared within a category
- `assemblies/shared/` — shared across categories
- Same rules for `modules/` and `images/`

**Detection:**
1. Read `:_mod-docs-category:` and `:context:` from each `titles/*/master.adoc`
2. Derive expected directory name: `slugify(category) + "_" + context`
3. Determine assembly/module/image ownership by tracing which titles include them (iterative for nested assemblies)
4. Report mismatches as `[AUTOFIX]`

**Attribute resolution:** The script has a hardcoded map of known RHDH attributes (`{product}` → `rhdh`, `{ocp-short}` → `ocp`, etc.) for deriving context slugs from `:title:` attributes.

**Fix:** `git mv` in phases: (1) title dirs, (2) assembly dirs, (3) module dirs, (4) image files, (5) update all `include::` and `image::` paths in all `.adoc` files, (6) verify no broken includes remain.

**Single-title mode:** `node index.js --check 00b titles/<dir> [<new-context>]` — renames just one title's directories.

---

### CQA-03: Modularization

**What:** Every `.adoc` file must have `:_mod-docs-content-type:` on line 1. The declared type must match the detected type. PROCEDURE files must have numbered steps in `.Procedure` and `.Verification` sections.

**Detection:**
1. Detect content type from content and filename:
   - Has `include::` lines referencing `proc-`, `ref-`, `con-` files → ASSEMBLY
   - Has `.Procedure` section → PROCEDURE
   - Filename prefix: `assembly-` / `master` → ASSEMBLY, `proc-` → PROCEDURE, `con-` → CONCEPT, `ref-` → REFERENCE, `snip-` → SNIPPET
2. Compare detected type to declared type on line 1
3. Check for duplicates (`:_mod-docs-content-type:` appearing more than once)
4. For PROCEDURE: validate list formatting in `.Procedure` and `.Verification` sections:
   - Single numbered step → convert to unnumbered bullet (single steps should be unnumbered)
   - Mixed numbered + unnumbered → convert to all numbered
   - Multiple unnumbered items → convert to numbered
   - Single numbered step in `.Procedure` with no includes → `[MANUAL]` (procedures need multiple steps)
5. Skip files where content type cannot be detected

**Fix:** Remove all `:_mod-docs-content-type:` lines, insert correct one on line 1. Fix list formatting with `sed`.

**AST advantage:** Use `doc.getAttribute('_mod-docs-content-type')` and check line number. Use `doc.findBy({context: 'list'})` to get list objects instead of scanning for `^\. ` and `^\* ` patterns.

---

### CQA-13: Content type match

**What:** Content must match its declared type. Filename prefix must match declared type.

**Detection:**
- PROCEDURE: must have `.Procedure` section
- CONCEPT: must NOT have `.Procedure` section
- REFERENCE: must NOT have `.Procedure` section
- ASSEMBLY: must have `include::` directives
- Filename prefix must match: `proc-`, `con-`, `ref-`, `assembly-`

**Fix:** Rename file with correct prefix via `git mv`. Update all `include::` references across `assemblies/`, `modules/`, `titles/`.

**Skips:** SNIPPET, `attributes.adoc`, `master.adoc`.

---

### CQA-10: Titles

**What:** Procedure titles must be imperative (not gerund). All titles must have IDs matching the title, and filenames matching the ID.

**Detection:**
1. Read title from `^= ` line
2. Expand attribute references in title for ID derivation
3. For PROCEDURE/ASSEMBLY-with-procedures: first word must not end in `-ing` (gerund)
4. Expected ID = lowercase title, replace non-alphanum with `-`, collapse `--`, strip leading/trailing `-`
5. Expected filename = `{prefix}{id}.adoc`
6. Report mismatches

**Fix:**
1. Convert gerund first word to imperative (160+ hardcoded rules: `running→run`, `configuring→configure`, etc., plus pattern-based fallback)
2. Fix gerunds after "and" (e.g. "Installing and Configuring" → "Install and Configure")
3. Update `[id="..._{context}"]` attribute in file
4. Update `:context:` attribute for ASSEMBLY
5. Update all `xref:OLD_ID_` → `xref:NEW_ID_` across repo
6. `git mv` file to new name
7. Update all `include::` references across repo

**Delegates to CQA-03:** If content type is missing, reports `[-> CQA-03 MANUAL]` and skips.

**Attribute expansion map:** Handles `{product}` → `rhdh`, `{ocp-short}` → `ocp`, `{rhbk-brand-name}` → `rhbk`, `{azure-brand-name}` → `microsoft-azure`, etc.

**Skips:** `attributes.adoc`, `master.adoc`, SNIPPET files (snippets must not have titles).

---

### CQA-08: Short description content

**What:** The abstract (text immediately after `[role="_abstract"]`) must not contain self-referential language.

**Self-referential patterns (detected, case-insensitive):**
`"This section"`, `"This document"`, `"This chapter"`, `"This guide"`, `"This module"`, `"This assembly"`, `"This topic"`, `"The following section"`, `"The following document"`, `"Here we"`, `"Here you will"`, `"In this section"`, `"In this document"`

**Auto-removable prefixes (autofix):**
`"This section describes "`, `"This section explains "`, `"This section provides "`, `"This document describes "`, `"This document explains "`, `"This topic describes "`, `"This topic explains "`, `"In this section, you "`, `"In this section, we "`

**Detection:** Find `[role="_abstract"]`, read next line as abstract text. Check for self-referential patterns.

**Fix:** Remove auto-removable prefix, capitalize first letter of remaining text. Non-removable patterns → `[MANUAL]`.

**Delegates to CQA-09:** If `[role="_abstract"]` missing.

**Skips:** SNIPPET, `attributes.adoc`, `master.adoc`.

---

### CQA-09: Short description format

**What:** Every non-SNIPPET module must have `[role="_abstract"]` immediately before the intro paragraph (no blank line between marker and text). Abstract length: 50–300 characters.

**Detection:**
1. Check for `[role="_abstract"]` (exact match at line start)
2. If present: next line must not be empty
3. Extract abstract text (lines until first empty line, `.` block title, or `include::`)
4. Handle attribute reference `{abstract}` — resolve from file attributes
5. Count characters (after trimming and collapsing spaces)
6. < 50 chars → `[MANUAL]`; > 300 chars → `[MANUAL]`; missing marker → `[AUTOFIX]`; blank line after marker → `[AUTOFIX]`

**Fix:**
- Missing marker: find first content line after title (skip `:attr:`, blank lines, `[id=...]`, `ifdef::` lines), insert `[role="_abstract"]` before it
- Blank line after marker: delete the blank line

---

### CQA-11: Prerequisites

**What:** PROCEDURE files must use `.Prerequisites` (plural, not `.Prerequisite`). Prerequisites must use bulleted list (`*`), not numbered (`. `). Maximum 10 prerequisites.

**Detection:** Check `.Prerequisites`/`.Prerequisite` presence, count items in the section (stop at next section label: `.Procedure`, `.Verification`, `.Troubleshooting`, `.Next steps`, `.Additional`), check list format.

**Fix:** `.Prerequisite` → `.Prerequisites`. Convert numbered items (`^\. `) to bullets (`^\* `) within the prerequisites section.

**Skips:** Non-PROCEDURE files, `attributes.adoc`, `master.adoc`.

---

### CQA-02: Assembly structure

**What:** Assembly files must follow the official template structure.

**Checks (per assembly file):**
1. `:_mod-docs-content-type: ASSEMBLY` on line 1 (not repeated)
2. `[role="_abstract"]` intro present — **delegates to CQA-09**
3. Introduction length 50–300 chars (non-master files) — **delegates to CQA-09**
4. `[id="..._{context}"]` attribute present (non-master files)
5. `:context:` attribute present and after the title (non-master files)
6. Context save on line 2 (non-master): `ifdef::context[:parent-context: {context}]` (not repeated)
7. Context restore at end (non-master): `ifdef::parent-context[:context: {parent-context}]` + `ifndef::parent-context[:!context:]`
8. `.Prerequisites` must use `==` heading, not block title
9. No `===` level-3 subheadings
10. `.Additional resources` must use `[role="_additional-resources"]` + `== Additional resources` (not `.Additional resources` block title)
11. No prose content between `include::` statements

**Files processed:** Only `assemblies/` files and `titles/*/master.adoc`.

**Fix:** Most checks have autofix: content type, context save/restore, ID suffix, `:context:`, prerequisites heading, additional resources format.

**AST advantage:** Check 11 (content between includes) — use AST blocks between section boundaries instead of line scanning. Check 9 (level-3 headings) — `doc.findBy({context: 'section'}).filter(s => s.level >= 3)`.

---

### CQA-05: Required modular elements

**What:** All modules must have required structural elements present.

**Checks by content type:**

**All types (except SNIPPET):**
- Content type metadata → **delegates to CQA-03**
- Topic ID with `_{context}` suffix (or `[id="{context}"]` for master.adoc) → autofix (add suffix) or manual (missing entirely)
- Exactly one H1 title (`= Title`) → manual
- `[role="_abstract"]` marker → **delegates to CQA-09**
- Blank line after H1 → autofix (insert blank line)
- Image alt text in quotes for all `image::` directives → manual
- No admonition titles (`.NOTE`, `.WARNING`, `.IMPORTANT`, `.TIP`, `.CAUTION`) → autofix (delete title line)

**ASSEMBLY additional:**
- No `===` level-3+ subheadings → manual
- No block titles except `.Additional resources` → **delegates to CQA-02**
- Nested assembly: context save/restore/declaration → **delegates to CQA-02**

**PROCEDURE additional:**
- No `==` subheadings at all → manual
- Exactly one `.Procedure` block title (not `.Procedure something`) → manual / delegates to CQA-04
- Non-standard block titles forbidden (only: `.Prerequisites`, `.Prerequisite`, `.Procedure`, `.Verification`, `.Results`, `.Result`, `.Troubleshooting`, `.Troubleshooting steps`, `.Next steps`, `.Next step`, `.Additional resources`) → manual

**CONCEPT/REFERENCE additional:**
- `===` level-3+ subheadings forbidden (only `==` H2 allowed) → manual
- Non-standard block titles (only `.Additional resources` and `.Next steps` allowed) → manual

**SNIPPET:**
- Must NOT have a title (`= Title`) → manual
- Must NOT have block titles → manual

**AST advantage:** Section level detection, block title enumeration, and admonition detection all benefit from AST — no regex on raw text needed.

---

### CQA-04: Module templates

**What:** Modules must follow official Red Hat modular documentation templates.

**Checks:**
- PROCEDURE: no `===` custom subheadings → manual (extract to separate module)
- PROCEDURE: must have `.Procedure` section → autofix (insert before first `^\. ` item) or manual (no numbered list found)
- PROCEDURE: `.Prerequisite` singular → `.Prerequisites` plural → autofix
- All modules: must have `[role="_abstract"]` intro → **delegates to CQA-09**
- CONCEPT: must NOT have `.Procedure` section → manual

**Skips:** ASSEMBLY, SNIPPET, `attributes.adoc`, `master.adoc`.

---

### CQA-06: Assembly scope

**What:** Each assembly (non-master) should tell exactly one user story.

**Checks:**
- Has a title (`= Title`) → manual
- Nested assembly includes ≤ 3 → manual (may cover multiple user stories)
- Total includes ≤ 15 → manual (consider splitting)

**Note:** `master.adoc` is skipped for user story checks (it legitimately aggregates multiple stories).

**All violations are `[MANUAL]`** — splitting assemblies always requires human judgment.

---

### CQA-07: TOC depth

**What:** Heading depth must not exceed 3 levels (`=`, `==`, `===`). Level 4+ (`====` or deeper) is a violation.

**Detection:** Scan each line for `^=+[space]` pattern. Count `=` signs to determine level. Skip lines inside source/listing blocks.

**Fix:** If ≤ 3 violations in a file: promote `====` to `===` via sed. If > 3 violations: report as `[MANUAL]` (too many deep headings for safe auto-promote).

**AST advantage:** `doc.findBy({context: 'section'}).filter(s => s.level > 3)` — no regex on raw text, no block range checking needed.

**Skips:** `attributes.adoc`.

---

### CQA-16: Official product names

**What:** Product names must use AsciiDoc attribute references, not hardcoded text.

**Pattern list (longest first to avoid substring false positives):**

| Hardcoded | Attribute |
|---|---|
| `Red Hat Developer Hub` | `{product}` or `{product-short}` |
| `Red Hat OpenShift Container Platform` | `{ocp-brand-name}` |
| `Red Hat Build of Keycloak` | `{rhbk-brand-name}` |
| `Red Hat OpenShift AI` | `{rhoai-brand-name}` |
| `Red Hat Enterprise Linux` | `{rhel}` |
| `Red Hat Advanced Cluster Security` | `{rhacs-brand-name}` |
| `Red Hat Developer Lightspeed` | `{ls-brand-name}` |
| `OpenShift Container Platform` | `{ocp-short}` |
| `Developer Hub` | `{product-short}` |
| `Developer Lightspeed` | `{ls-short}` |
| `Backstage` | `{backstage}` or `{product-custom-resource-type}` |
| `RHDH` | `{product-very-short}` |
| (+ 50 more patterns) | (see script for full list) |

**Detection:** For each pattern, grep the file. Skip lines inside source/listing blocks, attribute definitions (`^:`), and comments (`^//`). Strip known attribute references to avoid false positives (e.g. a line containing `{product}` should not also match `Developer Hub`). Check parent patterns to avoid substring matches.

**Fix:** Apply all replacements via sed, process patterns longest-first. Fix `{{` / `}}` double-brace artifacts. Reports as `[AUTOFIX]`.

**AST advantage:** Blocks detection via AST eliminates the block-range caching (`cqa_compute_block_ranges`) entirely.

**Skips:** `attributes.adoc` (defines the attributes), SNIPPET files.

---

### CQA-01: Vale AsciiDoc DITA

**What:** Files must pass Vale validation with `.vale-dita-only.ini` configuration (AsciiDoc DITA compliance rules).

**Requires:** `vale` CLI installed, `.vale-dita-only.ini` in repo root.

**Delegates:**
- `AsciiDocDITA.ShortDescription` → CQA-08 (manual)
- `AsciiDocDITA.DocumentId` → CQA-10 (manual)

**Manual-only Vale rules** (no autofix possible):
- `AsciiDocDITA.DocumentTitle`
- `AsciiDocDITA.TaskTitle`
- `AsciiDocDITA.ConceptLink`
- `AsciiDocDITA.AssemblyContents`
- `AsciiDocDITA.RelatedLinks`
- `AsciiDocDITA.ExampleBlock`

**Autofixable Vale rules:**
- `AsciiDocDITA.AuthorLine` — missing blank line after title → insert blank line
- `AsciiDocDITA.CalloutList` — callout format `<1> text` → `<1>:: text` (description list)
- `AsciiDocDITA.BlockTitle` — invalid `.Title` before non-block content → convert to lead-in sentence `Title:` (skip if followed by table `|===`, example `====`, source `----`, or `image::`)
- `AsciiDocDITA.TaskContents` — `.Procedure` missing → insert before first `^\. ` item
- `AsciiDocDITA.TaskStep` — blank line between steps → replace with `+` continuation (or remove if after `.Procedure`)

**Implementation note:** Vale is called as an external CLI. The Node.js implementation calls `vale --output JSON` and parses the JSON output (same as current bash approach). This check does NOT benefit from the AsciiDoc AST.

**Skips:** `attributes.adoc`.

---

### CQA-12: Grammar and style

**What:** Files must pass Vale validation with `.vale.ini` (grammar, spelling, style, terminology rules).

**Requires:** `vale` CLI, `.vale.ini` in repo root.

**Behavior:** Only reports errors (not warnings or suggestions) as failures. Warnings and suggestions are shown but do not cause the check to fail.

**No autofix:** Vale `--fix` not yet supported for these rules. All violations are `[MANUAL]`.

**Skips:** `attributes.adoc`.

---

### CQA-17: Legal disclaimers

**What:** Files mentioning Technology Preview or Developer Preview features must include the official legal-approved disclaimer snippet (via `include::`).

**Detection:**
- Technology Preview: grep for `technology preview` or `{technology-preview}` (case-insensitive), outside source/listing blocks
- Developer Preview: grep for `developer preview` or `{developer-preview}` (case-insensitive), outside source/listing blocks
- If mention found: check for `include::.*snip-.*tech.*preview`, `include::.*snip-.*tp-`, or direct URL `access.redhat.com/support/offerings/techpreview`
- Same pattern for Developer Preview with `snip-.*dev.*preview`, `snip-.*dp-`, `access.redhat.com/support/offerings/devpreview`

**All violations are `[MANUAL]`** — the correct snippet path varies by title directory structure.

**Skips:** `attributes.adoc`, SNIPPET files (they ARE the disclaimers).

**AST advantage:** Block detection for filtering Technology Preview mentions inside code blocks.

---

### CQA-14: No broken links

**What:** All `include::` targets and `image::` references must resolve to existing files.

**Detection:**
1. For each `include::path[...]`: resolve path relative to including file's directory. Skip paths containing `{attribute}` substitutions.
2. For each `image::path[...]` and inline `image:path[...]`: resolve using `:imagesdir:` attribute (from target file or `artifacts/attributes.adoc`), then file directory, then repo root. Skip URLs (`://`), paths with spaces or quotes, paths without `/`.

**All violations are `[MANUAL]`** — fixing broken links requires human judgment on the correct target.

**Note:** Full external URL validation requires `build-ccutil.sh` (full build).

---

### CQA-15: Redirects

**What:** If titles are deleted or renamed (`:title:` changed), redirects must be in place.

**Detection:** Uses `git diff HEAD~5..HEAD` to detect:
1. Deleted `titles/*/master.adoc` files
2. Changed `:title:` in `master.adoc`

**All violations are `[MANUAL]`** — redirect implementation is platform-dependent.

**Limitation:** Only looks back 5 commits. Not useful for branches with fewer commits than the actual changes.

---

## Workflow Order: Dependency Map

```
CQA-00a (orphans)
  ↓
CQA-00b (dir structure)
  ↓
CQA-03 (modularization) ← sets content type used by: CQA-10, 13, 04, 05, 06, 07, 11, 08, 02
  ↓
CQA-13 (content type match) ← validates before renaming
  ↓
CQA-10 (titles) ← renames files/IDs before link checks
  ↓
CQA-08, CQA-09 (short description)
  ↓
CQA-11 (prerequisites)
  ↓
CQA-02 (assembly structure) ← fixes structure before element checks
  ↓
CQA-05, CQA-04 (elements, templates)
  ↓
CQA-06 (scope — manual only)
  ↓
CQA-07 (TOC depth)
  ↓
CQA-16 (product names)
  ↓
CQA-01 (Vale DITA) ← runs on already-fixed content
  ↓
CQA-12 (Vale grammar)
  ↓
CQA-17 (disclaimers)
  ↓
CQA-14 (broken links) ← after all renames
  ↓
CQA-15 (redirects) ← after all renames
```

---

## Delegation Map

Some checks report issues as delegated to another check (the other check is the right place to fix it):

| From | To | What |
|---|---|---|
| CQA-01 | CQA-08 | `AsciiDocDITA.ShortDescription` |
| CQA-01 | CQA-10 | `AsciiDocDITA.DocumentId` |
| CQA-02 | CQA-09 | Missing abstract |
| CQA-04 | CQA-09 | Missing abstract |
| CQA-05 | CQA-03 | Missing content type |
| CQA-05 | CQA-09 | Missing abstract |
| CQA-05 | CQA-02 | Assembly issues |
| CQA-05 | CQA-04 | Missing `.Procedure` |
| CQA-08 | CQA-09 | Missing `[role="_abstract"]` |
| CQA-10 | CQA-03 | Missing content type |

---

## File Scope Reference

| Check | Processes | Skips |
|---|---|---|
| CQA-00a | `artifacts/`, `assemblies/`, `modules/`, `images/` | `*.template.adoc` |
| CQA-00b | All title/assembly/module/image dirs | `shared/` dirs |
| CQA-03 | All collected `.adoc` | `attributes.adoc` |
| CQA-13 | All collected `.adoc` | SNIPPET, `attributes.adoc`, `master.adoc` |
| CQA-10 | All collected `.adoc` | `attributes.adoc`, `master.adoc` |
| CQA-08 | All collected `.adoc` | SNIPPET, `attributes.adoc`, `master.adoc` |
| CQA-09 | All collected `.adoc` | SNIPPET |
| CQA-11 | PROCEDURE files only | `attributes.adoc`, `master.adoc` |
| CQA-02 | `assemblies/` + `titles/*/master.adoc` | — |
| CQA-05 | `assemblies/`, `modules/`, `titles/*/master.adoc` | — |
| CQA-04 | Non-ASSEMBLY, non-SNIPPET | `attributes.adoc`, `master.adoc` |
| CQA-06 | ASSEMBLY files only | `attributes.adoc` |
| CQA-07 | All collected `.adoc` | `attributes.adoc` |
| CQA-16 | All collected `.adoc` | SNIPPET, `attributes.adoc` |
| CQA-01 | All collected `.adoc` | `attributes.adoc` |
| CQA-12 | All collected `.adoc` | `attributes.adoc` |
| CQA-17 | All collected `.adoc` | SNIPPET, `attributes.adoc`, `snip-*` |
| CQA-14 | All collected `.adoc` | — |
| CQA-15 | `master.adoc` only | — |

---

## Known Limitations and Design Debts

1. **CQA-15 redirect detection** only looks back 5 commits (`git diff HEAD~5..HEAD`). Does not detect renames in older history or on the first commit of a branch.

2. **CQA-10 gerund-to-imperative** has 160+ hardcoded rules and a fallback pattern. The fallback is imperfect for irregular verbs. Edge cases should be added as discovered.

3. **CQA-16 product name patterns** are hardcoded and may drift from the Vale `Attributes.yml` rule. Ideally these are derived from the same source.

4. **Block range detection** in the bash implementation uses delimiter counting (`----`, `....`, `++++`) which can be fooled by malformed or intentionally unusual AsciiDoc. The Node.js AST implementation eliminates this.

5. **CQA-00b directory structure** attribute resolution for context slugs has a hardcoded substitution map for known product attributes. New attributes must be added manually.

6. **CQA-12 Vale grammar** reports all errors as `[MANUAL]` — Vale's `--fix` mode is not yet supported. When Vale adds fix support, this can be upgraded to `[AUTOFIX]`.
