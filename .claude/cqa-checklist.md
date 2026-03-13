# CQA 2.1 Compliance Checklist

Execute all 17 CQA requirements in optimal order. Follow [cqa-master-workflow.md](skills/cqa-master-workflow.md) for skill links.

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

### Phase 0: Resources

- [ ] **Update all resources** - [Skill](skills/update-all-resources.md)
  ```bash
  ./build/scripts/update-cqa-resources.sh
  ```
  - [ ] Vale styles synced
  - [ ] Red Hat style guides current

---

### Phase 1: Structure & Content Type

- [ ] **CQA #3: Content is modularized** - [Skill](skills/cqa-03-content-is-modularized.md)
  - [ ] Modular structure (assemblies include modules)
  - [ ] Correct metadata (`:_mod-docs-content-type:`)
  - [ ] Correct filename prefixes (proc-, con-, ref-, assembly-)

- [ ] **CQA #13: Correct content type** - [Skill](skills/cqa-13-information-is-conveyed-using-the-correct-content.md)
  ```bash
  ./build/scripts/fix-content-type.sh titles/<your-title>/master.adoc
  ```
  - [ ] Content matches declared type (PROCEDURE/CONCEPT/REFERENCE/ASSEMBLY)
  - [ ] Procedures have `.Procedure` sections
  - [ ] No violations found

---

### Phase 2: Short Descriptions & Titles

- [ ] **CQA #8: Short description content** - [Skill](skills/cqa-08-short-description-content.md)
  - [ ] WHY user should read (benefit-focused)
  - [ ] Not self-referential ("This section describes...")
  - [ ] Explains value/purpose

- [ ] **CQA #9: Short description format** - [Skill](skills/cqa-09-short-description-format.md)
  ```bash
  ./build/scripts/verify-short-descriptions.sh titles/<your-title>/master.adoc
  ```
  - [ ] `[role="_abstract"]` marker present
  - [ ] 50-300 characters
  - [ ] No empty line after marker

- [ ] **CQA #10: Titles are brief, complete, and descriptive** - [Skill](skills/cqa-10-titles-are-brief-complete-and-descriptive.md)
  ```bash
  ./build/scripts/fix-title-id-filename.sh titles/<your-title>/master.adoc
  ```
  - [ ] Procedures: imperative form ("Install" not "Installing")
  - [ ] Concepts: noun phrases ("Configuration options")
  - [ ] References: noun phrases ("API reference")
  - [ ] IDs match titles (lowercase-with-hyphens_{context})
  - [ ] Filenames match titles (with prefix)
  - [ ] All xrefs updated for changed IDs
  - [ ] All includes updated for renamed files

- [ ] **CQA #11: Procedures have prerequisites** - [Skill](skills/cqa-11-procedures-prerequisites.md)
  - [ ] `.Prerequisites` label used (plural)
  - [ ] Max 10 items
  - [ ] Use completed states ("You have installed...")
  - [ ] Link to procedures when possible

---

### Phase 3: Assembly Structure

- [ ] **CQA #2: Assembly structure** - [Skill](skills/cqa-02-assembly-structure.md)
  - [ ] Introduction paragraph (context)
  - [ ] Include statements only (no inline content)
  - [ ] Context restoration at end (`:context: {parent-context}`)
  - [ ] Proper leveloffset on includes

- [ ] **CQA #5: Required elements** - [Skill](skills/cqa-05-modular-elements-checklist.md)
  - [ ] All mandatory elements present per type
  - [ ] Procedures: title, abstract, prerequisites, procedure, verification
  - [ ] Concepts: title, abstract, content
  - [ ] References: title, abstract, data

- [ ] **CQA #4: Official templates** - [Skill](skills/cqa-04-modules-use-official-templates.md)
  - [ ] CONCEPT template structure followed
  - [ ] PROCEDURE template structure followed
  - [ ] REFERENCE template structure followed

- [ ] **CQA #6: Assembly tells one story** - [Skill](skills/cqa-06-assemblies-use-the-official-template-assemblies-ar.md)
  - [ ] Single user story per assembly
  - [ ] No overlapping content with other assemblies
  - [ ] Clear purpose statement

- [ ] **CQA #7: TOC depth max 3 levels** - [Skill](skills/cqa-07-toc-max-3-levels.md)
  - [ ] Maximum 3 heading levels
  - [ ] No excessive nesting
  - [ ] Proper leveloffset usage

---

### Phase 4: Names & Validation

- [ ] **CQA #16: Official product names** - [Skill](skills/cqa-16-official-product-names-are-used.md)
  - [ ] Use attributes ({product}, {ocp-short}, etc.)
  - [ ] Follow Red Hat OPL (Official Product List)
  - [ ] No hardcoded product names

- [ ] **CQA #1: Vale DITA** - [Skill](skills/cqa-01-asciidoctor-dita-vale.md)
  ```bash
  vale --config .vale-dita-only.ini \
    $(./build/scripts/list-all-included-files-starting-from titles/<your-title>/master.adoc)
  ```
  - [ ] 0 errors
  - [ ] Only acceptable warnings (callouts, false positives)
  - [ ] 0 suggestions
  - [ ] Final error count: 0
  - [ ] Final warning count: _____

- [ ] **CQA #12: Grammar** - [Skill](skills/cqa-12-content-is-grammatically-correct-and-follows-rules.md)
  ```bash
  vale --config .vale.ini \
    $(./build/scripts/list-all-included-files-starting-from titles/<your-title>/master.adoc)
  ```
  - [ ] 0 errors
  - [ ] American English
  - [ ] No passive voice in procedures
  - [ ] Parallel structure in lists
  - [ ] Final error count: 0
  - [ ] Final warning count: 0

- [ ] **CQA #17: Disclaimers** - [Skill](skills/cqa-17-includes-appropriate-legal-approved-disclaimers-f.md)
  - [ ] Tech Preview disclaimer if applicable
  - [ ] Developer Preview disclaimer if applicable
  - [ ] Legal-approved text used

---

### Phase 5: Links & Build

- [ ] **CQA #14: No broken links** - [Skill](skills/cqa-14-no-broken-links.md)
  ```bash
  build/scripts/build.sh
  ```
  - [ ] All xrefs resolve
  - [ ] All external links valid
  - [ ] Build completes successfully
  - [ ] No xref errors in output

- [ ] **CQA #15: Redirects** - [Skill](skills/cqa-15-redirects-if-needed-are-in-place-and-work-correc.md)
  - [ ] Redirects in place if files moved
  - [ ] Old URLs redirect to new locations
  - [ ] Redirect file syntax correct

---

### Cleanup & Verification

- [ ] **Remove orphaned modules**
  ```bash
  ./build/scripts/fix-orphaned-modules.sh
  ```
  - [ ] Review list: _____ files found
  - [ ] Verify truly orphaned
  - [ ] Delete: `./build/scripts/fix-orphaned-modules.sh --execute`

- [ ] **Verify .claude/settings.json** (if updated)
  - [ ] Permissions alphabetically sorted
  - [ ] Uses wildcard patterns (not individual files)
  - [ ] No sensitive information (API keys, tokens, usernames)
  - [ ] Repository-relative paths only
  - [ ] Valid JSON: `jq . .claude/settings.json`

---

## Completion Checklist

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
- [ ] Orphaned modules removed
- [ ] .claude/settings.json verified (if updated)

---

## Commit & PR

- [ ] **Commit changes**
  ```bash
  git add <files>
  git commit -m "RHIDP-XXXXX: CQA 2.1 compliance for [TITLE NAME]

  - Fixed content types (X files)
  - Aligned title/ID/filename (X files)
  - Added short descriptions (X files)
  - Fixed Vale DITA errors (X errors)
  - Fixed Vale language issues (X issues)
  - Removed X orphaned modules
  [Add .claude/settings.json note if applicable]

  Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
  ```

- [ ] **Create pull request**
  ```bash
  gh pr create --title "RHIDP-XXXXX: CQA 2.1 compliance for [TITLE NAME]" --body "$(cat <<'EOF'
  **IMPORTANT: Do Not Merge - To be merged by Docs Team Only**

  **Version(s):** main
  **Issue:** https://issues.redhat.com/browse/RHIDP-XXXXX
  **Preview:** [Preview URL]

  ## Summary
  [Brief summary of changes]

  ## CQA 2.1 Results
  - ✅ Vale DITA: 0 errors, X acceptable warnings
  - ✅ Vale style: 0 errors, 0 warnings
  - ✅ Build: successful
  - ✅ All 17 CQA requirements met
  - ✅ Idempotency verified

  ## Changes Made
  - Content type compliance: X files
  - Title/ID/filename alignment: X files
  - Short descriptions: X files
  - Orphaned modules removed: X files

  🤖 Generated with Claude Code
  EOF
  )"
  ```
  - [ ] PR created successfully
  - [ ] PR number: #_____
  - [ ] Preview URL added to PR

---

## Assessment

**Title:** _____ | **JIRA:** RHIDP-_____ | **Status:** ⬜ In Progress | ⬜ Complete | ⬜ Blocked

**Results:**
- Vale DITA: _____ errors, _____ warnings
- Vale style: _____ errors, _____ warnings
- Build: _____ (success/fail)
- Files updated: _____

**Notes:** _____

---

**CRITICAL:** Do not claim completion unless ALL checkboxes marked ✓
