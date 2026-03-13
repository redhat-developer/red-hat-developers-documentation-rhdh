# CQA 2.1 Compliance Checklist

**Title:** [FILL IN: e.g., "Installing RHDH on OpenShift"]
**JIRA:** RHIDP-[FILL IN: e.g., 12345]
**Target File:** titles/[FILL IN]/master.adoc

## Critical Rules
- [ ] Complete ALL steps in exact order - DO NOT SKIP
- [ ] DO NOT batch steps - complete each fully before proceeding
- [ ] Mark each item ✓ IMMEDIATELY when done
- [ ] If step says "do not fix yet", only identify issues

---

## Steps 1-4: Initial Assessment and Validation

- [ ] **Step 1:** Read main assembly file and all included modules
- [ ] **Step 2:** Run content type script and verify results
  ```bash
  ./build/scripts/fix-content-type.sh titles/<your-title>/master.adoc
  ```
  - [ ] Review script output (compliant/violations/auto-fixed counts)
  - [ ] Manually fix filename violations with `git mv` if needed
  - [ ] Add missing `.Procedure` sections if flagged
  - [ ] Verify content semantically matches declared types

- [ ] **Step 3:** Verify content type metadata is present (should be done by step 2)

- [ ] **Step 4:** Run Vale DITA validation to identify issues (DO NOT FIX YET)
  ```bash
  vale --config .vale-dita-only.ini titles/<your-title>/
  ```
  - [ ] Note error count: _____
  - [ ] Note warning count: _____

---

## Step 5: Title/ID/Filename Compliance (Multi-Step Process)

- [ ] **STEP 0:** Run alignment script on target file
  ```bash
  ./build/scripts/fix-title-id-filename.sh titles/<your-title>/master.adoc
  ```
  - [ ] Review script output (✓ aligned / 📝 changed files)
  - [ ] Verify assembly titles use correct form (imperative if includes procedures)
  - [ ] Verify attribute names preserved in IDs
  - [ ] Review git changes before committing

**For EACH file needing manual fixes (if any), complete STEP 1-5:**

- [ ] **STEP 1:** Fix titles FIRST (title is source of truth)
  - [ ] Procedures: imperative form ("Install" not "Installing")
  - [ ] Concepts: noun phrases ("Configuration options")
  - [ ] References: noun phrases ("API reference")
  - [ ] Task assemblies: imperative form ("Deploy the application")

- [ ] **STEP 2:** Update IDs and context to match title
  - [ ] Update `[id="..."]`: lowercase-with-hyphens_{context}
  - [ ] Do NOT include module prefix (proc-, con-, ref-) in ID
  - [ ] Update `:context:` in assemblies to match title

- [ ] **STEP 3:** Update all xrefs pointing to changed IDs
  ```bash
  grep -r "xref:old-id" assemblies/ modules/
  ```
  - [ ] Update xref statements with new ID
  - [ ] Update anchor links in same file

- [ ] **STEP 4:** Update filename to match title
  - [ ] Keep module type prefix (proc-, con-, ref-, assembly-)
  - [ ] Convert title to lowercase-with-hyphens
  - [ ] Move to correct modules/[title-name]/ subdirectory
  - [ ] Use `git mv` to preserve history

- [ ] **STEP 5:** Update all include statements
  ```bash
  grep -r "include::.*old-filename" assemblies/ modules/
  ```
  - [ ] Update include statements in assemblies
  - [ ] Verify no includes point to old filename

- [ ] **VERIFICATION:** Re-run alignment script - all files should show ✓
  ```bash
  ./build/scripts/fix-title-id-filename.sh titles/<your-title>/master.adoc
  ```

- [ ] **STEP 6:** Remove orphaned modules
  ```bash
  ./build/scripts/fix-orphaned-modules.sh
  ```
  - [ ] Review list of orphaned files: _____ files found
  - [ ] Verify files are truly orphaned
  - [ ] Delete if appropriate: `./build/scripts/fix-orphaned-modules.sh --execute`
  - [ ] Remove empty directories if needed

- [ ] **STEP 7:** Fix other issues (only after title/ID/filename aligned)
  - [ ] Add `[role="_abstract"]` short descriptions (50-300 chars)
  - [ ] Convert `.Title` to `== Title` in concept/reference modules
  - [ ] Fix grammar issues (parallel structure, verb agreement)
  - [ ] Add context restoration to assemblies
  - [ ] Remove commented-out content

---

## Steps 7-10: Content Structure Verification

- [ ] **Step 7:** Verify short descriptions for all modules
  ```bash
  ./build/scripts/verify-short-descriptions.sh titles/<your-title>/master.adoc
  ```
  - [ ] All modules have `[role="_abstract"]` after title
  - [ ] No empty line after `[role="_abstract"]`
  - [ ] Abstract is 50-300 characters
  - [ ] Abstract describes what user accomplishes (not self-referential)
  - [ ] Concepts: Answer "What is this?" and "Why care?"
  - [ ] Procedures: Explain what user accomplishes
  - [ ] References: Describe data being presented
  - [ ] Assemblies: Explain user story/goal addressed

- [ ] **Step 8:** Verify assembly internal structure and content
  - [ ] Each assembly has proper structure
  - [ ] Content follows modular docs guidelines

- [ ] **Step 9:** Verify assembly includes one unique story
  - [ ] Each assembly addresses single user story
  - [ ] No overlapping or duplicate content

- [ ] **Step 10:** Verify include depth is appropriate
  - [ ] Assembly include statements don't go too deep
  - [ ] Maximum nesting levels respected

---

## Steps 11-13: Validation and Build

- [ ] **Step 11:** Re-run Vale DITA validation
  ```bash
  vale --config .vale-dita-only.ini titles/<your-title>/
  ```
  - [ ] 0 errors
  - [ ] Only acceptable warnings
  - [ ] 0 suggestions
  - [ ] Final error count: 0
  - [ ] Final warning count: _____

- [ ] **Step 12:** Run Vale default for language compliance
  ```bash
  vale --config .vale.ini titles/<your-title>/
  ```
  - [ ] Fix all errors
  - [ ] Fix all warnings
  - [ ] Final error count: 0
  - [ ] Final warning count: 0

- [ ] **Step 13:** Run build validation on all titles
  ```bash
  build/scripts/build.sh
  ```
  - [ ] All xrefs still resolve
  - [ ] Build completes successfully
  - [ ] No broken links

---

## Steps 14-17: Final Verification and Submission

- [ ] **Step 14:** Verify .claude/settings.json (if updated)
  - [ ] Permissions alphabetically sorted
  - [ ] Uses wildcard patterns (not individual files)
  - [ ] No sensitive information (API keys, tokens)
  - [ ] No personal references (home directories, usernames)
  - [ ] Repository-relative paths use `//` prefix
  - [ ] File read permissions restricted to docs directories
  - [ ] Valid JSON: `jq . .claude/settings.json`
  - [ ] Include in commit with explanation in commit message

- [ ] **Step 15:** Verify all 14 acceptance criteria are met
  - [ ] 1. Uses correct context variable across all modules
  - [ ] 2. Content type metadata present on first line
  - [ ] 3. Assembly structure follows modular docs (prereq, procedure, verification, etc.)
  - [ ] 4. Each assembly includes one unique story
  - [ ] 5. Include statements don't go too deep
  - [ ] 6. Concept modules have short descriptions with [role="_abstract"]
  - [ ] 7. Reference modules have short descriptions with [role="_abstract"]
  - [ ] 8. Modules use correct title form (imperative for procedures, noun for concepts)
  - [ ] 9. Context variable correctly scoped (:context: in assemblies, {context} in modules)
  - [ ] 10. Language follows style guide (no self-referential, concise, parallel structure)
  - [ ] 11. Content conveyed using correct type (PROCEDURE/CONCEPT/REFERENCE/ASSEMBLY)
  - [ ] 12. Each module has unique ID (:_mod-docs-content-type: metadata)
  - [ ] 13. Product names use attributes (follow Red Hat OPL, no hardcoding)
  - [ ] 14. Appropriate disclaimers for Tech/Developer Preview features

- [ ] **Step 16:** Commit changes with correct message format
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

- [ ] **Step 17:** Create pull request
  ```bash
  gh pr create --title "RHIDP-XXXXX: CQA 2.1 compliance for [TITLE NAME]" --body "$(cat <<'EOF'
  **IMPORTANT: Do Not Merge - To be merged by Docs Team Only**

  **Version(s):** main

  **Issue:** https://issues.redhat.com/browse/RHIDP-XXXXX

  **Preview:** TBD

  ## Summary
  [Add summary of changes]

  ## Changes Made
  - Content type compliance: X files updated
  - Title/ID/filename alignment: X files updated
  - Short descriptions: X files updated
  - Vale DITA: Fixed X errors
  - Vale language: Fixed X issues
  - Removed X orphaned modules

  ## Verification
  - ✅ All 14 acceptance criteria met
  - ✅ Vale DITA: 0 errors
  - ✅ Vale language: 0 errors, 0 warnings
  - ✅ Build successful
  - ✅ All xrefs resolve

  🤖 Generated with Claude Code
  EOF
  )"
  ```
  - [ ] PR created successfully
  - [ ] PR number: #_____

---

## Completion Verification

- [ ] ALL steps 1-17 marked complete above
- [ ] All git changes committed
- [ ] PR created and submitted
- [ ] CQA process complete for this title

**NEVER claim completion unless ALL checkboxes above are checked ✓**
