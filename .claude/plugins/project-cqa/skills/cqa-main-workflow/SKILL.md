---
name: cqa-main-workflow
description: Orchestrates all 19 CQA checks in optimal workflow order for a documentation title. Use when asked to run CQA compliance, audit a title, or check documentation quality.
---

# CQA 2.1 Main Workflow

Execute all 19 CQA requirements in optimal order. The full specification is in `resources/cqa-spec.md`.

**CRITICAL EXECUTION RULES:**
1. Run checks in the exact order listed
2. Re-execute each check until it produces no new changes (idempotent state)
3. Re-execute the entire sequence until stable

## Prerequisites

Before starting, confirm with the user:
- JIRA ticket number (e.g., RHIDP-12345)
- Title name or path to master.adoc file

## Script Interface

```bash
# Run all checks for a title
node build/scripts/cqa/index.js titles/<your-title>/master.adoc

# Auto-fix all checks for a title
node build/scripts/cqa/index.js --fix titles/<your-title>/master.adoc

# Run a single check
node build/scripts/cqa/index.js --check NN titles/<your-title>/master.adoc

# Run across all titles
node build/scripts/cqa/index.js --all
```

**Output markers:**
- `[AUTOFIX]` — fixable with `--fix`
- `[FIXED]` — was auto-fixed
- `[MANUAL]` — requires human judgment
- `[-> CQA-NN AUTOFIX]` / `[-> CQA-NN MANUAL]` — delegated to another check

## Workflow Order

For each check: run `--fix`, then re-run report mode to verify. Repeat until clean.

1. **CQA-00a:** Orphaned modules — delete unreferenced files
2. **CQA-00b:** Directory structure — verify `<category>_<context>` naming
3. **CQA-03:** Modularization — content type metadata, filename prefixes
4. **CQA-13:** Content type match — content matches declared type
5. **CQA-10:** Titles — imperative form, ID/filename alignment
6. **CQA-08:** Short description content — no self-referential language
7. **CQA-09:** Short description format — `[role="_abstract"]`, 50-300 chars
8. **CQA-11:** Prerequisites — `.Prerequisites` label, bullet list, max 10
9. **CQA-02:** Assembly structure — template compliance
10. **CQA-05:** Required modular elements — all mandatory elements present
11. **CQA-04:** Module templates — CONCEPT/PROCEDURE/REFERENCE templates
12. **CQA-06:** Assembly scope — single user story per assembly
13. **CQA-07:** TOC depth — max 3 heading levels
14. **CQA-16:** Product names — use attribute references
15. **CQA-01:** Vale DITA — AsciiDoc DITA compliance
16. **CQA-12:** Grammar — Vale grammar/style, errors only
17. **CQA-17:** Disclaimers — Tech/Dev Preview legal snippets
18. **CQA-14:** Broken links — include/image targets exist
19. **CQA-15:** Redirects — redirects for deleted/renamed titles

## Completion Criteria

- ALL 19 checks pass (0 issues or only acceptable MANUAL items)
- Idempotency verified (re-running produces no changes)
- Build succeeds: `./build/scripts/build-ccutil.sh`

Do not claim completion unless all checks are verified clean.
