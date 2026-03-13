# CQA 2.1 Master Workflow

Execute all 17 CQA requirements in optimal order. Each links to detailed skill with commands, criteria, and fixes.

**Idempotency requirement:**
- Re-execute each requirement until it produces no new changes (idempotent state)
- Re-execute the entire sequence until the full workflow reaches idempotency (no changes across all requirements)

## Prerequisites

- [ ] JIRA: RHIDP-_____
- [ ] Title: _____
- [ ] Path: `titles/_____/master.adoc`

---

## Process

**For each requirement below:** Run validation/fixes until no new changes occur. **For the entire sequence:** Re-run all requirements until the full workflow is stable.

- [ ] Resources current. [Update all resources](update-all-resources.md)
- [ ] **CQA #3:** [Content is modularized](cqa-03-content-is-modularized.md) - Modular structure, correct metadata/prefixes
- [ ] **CQA #13:** [Correct content type](cqa-13-information-is-conveyed-using-the-correct-content.md) - Content matches declared type
- [ ] **CQA #8:** [Short description content](cqa-08-short-description-content.md) - WHY user should read, benefit-focused
- [ ] **CQA #9:** [Short description format](cqa-09-short-description-format.md) - `[role="_abstract"]`, 50-300 chars
- [ ] **CQA #10:** [Titles](cqa-10-titles-are-brief-complete-and-descriptive.md) - Brief, complete, descriptive
- [ ] **CQA #11:** [Prerequisites](cqa-11-procedures-prerequisites.md) - `.Prerequisites` label, max 10 items, completed states
- [ ] **CQA #2:** [Assembly structure](cqa-02-assembly-structure.md) - Introduction + includes only
- [ ] **CQA #5:** [Required elements](cqa-05-modular-elements-checklist.md) - All mandatory elements present
- [ ] **CQA #4:** [Official templates](cqa-04-modules-use-official-templates.md) - CONCEPT, PROCEDURE, REFERENCE templates
- [ ] **CQA #6:** [Assembly one story](cqa-06-assemblies-use-the-official-template-assemblies-ar.md) - Single user story
- [ ] **CQA #7:** [TOC depth](cqa-07-toc-max-3-levels.md) - Max 3 levels
- [ ] **CQA #16:** [Product names](cqa-16-official-product-names-are-used.md) - Use attributes, follow OPL
- [ ] **CQA #1:** [Vale DITA](cqa-01-asciidoctor-dita-vale.md) - 0 errors, acceptable warnings only
- [ ] **CQA #12:** [Grammar](cqa-12-content-is-grammatically-correct-and-follows-rules.md) - 0 errors, American English
- [ ] **CQA #17:** [Disclaimers](cqa-17-includes-appropriate-legal-approved-disclaimers-f.md) - Legal-approved for Tech/Dev Preview
- [ ] **CQA #14:** [No broken links](cqa-14-no-broken-links.md) - All xrefs/external links valid, build succeeds
- [ ] **CQA #15:** [Redirects](cqa-15-redirects-if-needed-are-in-place-and-work-correc.md) - Redirects in place if needed

---

## Completion

**All 17 Requirements:**
- [ ] CQA #1: Vale DITA ✓
- [ ] CQA #2: Assembly structure ✓
- [ ] CQA #3: Modularized ✓
- [ ] CQA #4: Templates ✓
- [ ] CQA #5: Required elements ✓
- [ ] CQA #6: One story ✓
- [ ] CQA #7: TOC depth ✓
- [ ] CQA #8: Short desc content ✓
- [ ] CQA #9: Short desc format ✓
- [ ] CQA #10: Titles ✓
- [ ] CQA #11: Prerequisites ✓
- [ ] CQA #12: Grammar ✓
- [ ] CQA #13: Content type ✓
- [ ] CQA #14: No broken links ✓
- [ ] CQA #15: Redirects ✓
- [ ] CQA #16: Product names ✓
- [ ] CQA #17: Disclaimers ✓

**Final Steps:**
- [ ] All automation scripts run
- [ ] All manual assessments complete
- [ ] Commit with JIRA reference
- [ ] PR created

**CRITICAL:** Do not claim completion unless ALL checkboxes marked ✓

---

## Assessment

**Title:** _____ | **JIRA:** RHIDP-_____ | **Status:** ⬜ In Progress | ⬜ Complete | ⬜ Blocked

**Results:**
- Vale DITA: _____ errors, _____ warnings
- Vale style: _____ errors
- Build: _____ (success/fail)
- Files updated: _____

**Notes:** _____
