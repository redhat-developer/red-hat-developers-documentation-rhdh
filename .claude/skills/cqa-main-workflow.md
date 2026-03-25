# CQA 2.1 Main Workflow

Execute all 19 CQA requirements in optimal order. Each links to detailed skill with commands, criteria, and fixes.

**CRITICAL EXECUTION RULES:**
1. **Run skills in the exact order listed** - The sequence is optimized to minimize conflicts
2. **Follow each skill precisely** - Read the linked skill file and execute ALL steps as documented
3. **Never skip steps** - Every command, check, and validation in the skill must be completed
4. **Never reinvent the skill** - Use the documented commands, don't create alternative approaches
5. **Mark each checkbox only after completing ALL sub-items** in that skill

**Idempotency requirement:**
- Re-execute each requirement until it produces no new changes (idempotent state)
- Re-execute the entire sequence until the full workflow reaches idempotency (no changes across all requirements)

## Prerequisites

- [ ] JIRA: RHIDP-_____
- [ ] Title: _____
- [ ] Path: `titles/_____/master.adoc`

---

## Unified Script Interface

Run all 19 CQA checks in workflow order with `cqa.sh`:

```bash
# Run all checks for a title
./build/scripts/cqa.sh titles/<your-title>/master.adoc

# Auto-fix all checks for a title
./build/scripts/cqa.sh --fix titles/<your-title>/master.adoc

# Run all checks across all titles
./build/scripts/cqa.sh --all
```

Or run individual scripts (all share a common interface via `cqa-lib.sh`):

```bash
./build/scripts/cqa-XX-*.sh [--fix] [--all] titles/<your-title>/master.adoc
```

**Output markers:**
- `[AUTOFIX]` - Can be auto-fixed with `--fix`
- `[FIXED]` - Was auto-fixed (in `--fix` mode)
- `[MANUAL]` - Requires human judgment
- `[-> CQA-NN AUTOFIX]` / `[-> CQA-NN MANUAL]` - Delegated to another CQA script

---

## Process

**For each requirement below:** Run validation/fixes until no new changes occur. **For the entire sequence:** Re-run all requirements until the full workflow is stable.

- [ ] **CQA-0:** Orphaned modules — `cqa-00-orphaned-modules.sh` — Find/delete unreferenced files
- [ ] **CQA-0:** Directory structure — `cqa-00-directory-structure.sh` — Verify `<category>_<context>` naming
- [ ] Resources current. [Update all resources](update-all-resources.md)
- [ ] **CQA-3:** [Content is modularized](cqa-03-content-is-modularized.md) - Modular structure, correct metadata/prefixes
- [ ] **CQA-13:** [Correct content type](cqa-13-information-is-conveyed-using-the-correct-content.md) - Content matches declared type
- [ ] **CQA-10:** [Titles](cqa-10-titles-are-brief-complete-and-descriptive.md) - Brief, complete, descriptive; renames files/IDs
- [ ] **CQA-8:** [Short description content](cqa-08-short-description-content.md) - WHY user should read, benefit-focused
- [ ] **CQA-9:** [Short description format](cqa-09-short-description-format.md) - `[role="_abstract"]`, 50-300 chars
- [ ] **CQA-11:** [Prerequisites](cqa-11-procedures-prerequisites.md) - `.Prerequisites` label, max 10 items, completed states
- [ ] **CQA-2:** [Assembly structure](cqa-02-assembly-structure.md) - Introduction + includes only
- [ ] **CQA-5:** [Required elements](cqa-05-modular-elements-checklist.md) - All mandatory elements present
- [ ] **CQA-4:** [Official templates](cqa-04-modules-use-official-templates.md) - CONCEPT, PROCEDURE, REFERENCE templates
- [ ] **CQA-6:** [Assembly one story](cqa-06-assemblies-structure.md) - Single user story
- [ ] **CQA-7:** [TOC depth](cqa-07-toc-max-3-levels.md) - Max 3 levels
- [ ] **CQA-16:** [Product names](cqa-16-official-product-names.md) - Use attributes, follow OPL
- [ ] **CQA-1:** [Vale DITA](cqa-01-asciidoctor-dita-vale.md) - 0 errors, acceptable warnings only
- [ ] **CQA-12:** [Grammar](cqa-12-grammar-and-style-guide.md) - 0 errors, American English
- [ ] **CQA-17:** [Disclaimers](cqa-17-include-legal-approved-disclaimers.md) - Legal-approved for Tech/Dev Preview
- [ ] **CQA-14:** [No broken links](cqa-14-no-broken-links.md) - All xrefs/external links valid, build succeeds
- [ ] **CQA-15:** [Redirects](cqa-15-redirects.sh) - Redirects in place if needed

---

## Completion

**All 18 Requirements:**
- [ ] CQA-0: Orphaned modules
- [ ] CQA-1: Vale DITA
- [ ] CQA-2: Assembly structure
- [ ] CQA-3: Modularized
- [ ] CQA-4: Templates
- [ ] CQA-5: Required elements
- [ ] CQA-6: One story
- [ ] CQA-7: TOC depth
- [ ] CQA-8: Short desc content
- [ ] CQA-9: Short desc format
- [ ] CQA-10: Titles
- [ ] CQA-11: Prerequisites
- [ ] CQA-12: Grammar
- [ ] CQA-13: Content type
- [ ] CQA-14: No broken links
- [ ] CQA-15: Redirects
- [ ] CQA-16: Product names
- [ ] CQA-17: Disclaimers

**Final Steps:**
- [ ] All automation scripts run
- [ ] All manual assessments complete
- [ ] Commit with JIRA reference
- [ ] PR created

**CRITICAL:** Do not claim completion unless ALL checkboxes marked

---

## Assessment

**Title:** _____ | **JIRA:** RHIDP-_____ | **Status:** In Progress | Complete | Blocked

**Results:**
- Vale DITA: _____ errors, _____ warnings
- Vale style: _____ errors
- Build: _____ (success/fail)
- Files updated: _____

**Notes:** _____
