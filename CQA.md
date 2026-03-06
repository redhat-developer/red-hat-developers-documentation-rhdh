# CQA 2.1 Compliance Prompt Template

Use this prompt to request CQA 2.1 (Content Quality Assessment) compliance work for Red Hat Developer Hub documentation titles in preparation for Adobe Experience Manager (AEM) migration.

## How to Use This Template

1. Copy the prompt below
2. Replace `[TITLE NAME]` with the specific title you want to make compliant (e.g., "Getting Started with Red Hat Developer Hub", "Configuring Red Hat Developer Hub")
3. Replace `[PATH TO ASSEMBLY FILE]` with the actual path to the main assembly file for that title
4. Submit the prompt to Claude Code

---

## Prompt Template

```
CQA 2.1 compliance: [TITLE NAME]

Make the "[TITLE NAME]" title compliant with CQA 2.1 – Content Quality Assessment for Adobe Experience Manager (AEM) migration.

Background:
- Target path: [PATH TO ASSEMBLY FILE]
- All included modules must be updated
- Changes must pass Vale DITA validation with 0 errors, 0 warnings

Requirements (CQA 2.1 Acceptance Criteria):

1. **Vale DITA validation**: Run `vale --config .vale-dita-only.ini` against all AsciiDoc files included in the title. Result must be 0 errors, 0 warnings, 0 suggestions.

2. **Content is modularized following Red Hat modular documentation rules**:
   - Use official templates (assemblies, concept modules, reference modules, procedure modules)
   - Each module has correct `:_mod-docs-content-type:` metadata
   - Proper file naming conventions (assembly-*.adoc, con-*.adoc, ref-*.adoc, proc-*.adoc)

3. **Assemblies contain only an introductory section, and then include statements for modules**:
   - Assemblies have brief introduction (1-3 paragraphs max)
   - No detailed content in assemblies (move to modules)
   - Context is set and restored properly using ifdef/ifndef
   - No commented-out content

4. **Assemblies are one user story each**:
   - Each assembly addresses a single user goal or task
   - Clear scope and purpose

5. **Content is not deeply nested in the TOC (≤3 levels)**:
   - Maximum TOC depth: 3 levels
   - Count from the title level (assembly = level 1, first include = level 2, etc.)

6. **Modules and assemblies start with a clear short description**:
   - Every module and assembly has `[role="_abstract"]` before the introductory paragraph
   - Short description is 50-300 characters
   - Describes the value/purpose (not just "Learn about X")
   - If an introduction paragraph already exists, add `[role="_abstract"]` to mark it (do NOT duplicate)
   - Remove self-referential language ("Learn about", "This section describes")

7. **In AsciiDoc, short descriptions must be**:
   - Added as `[role="_abstract"]` immediately after the title
   - Between 50-300 characters
   - Not duplicating existing content—mark the existing intro paragraph when appropriate

8. **Titles are brief, complete, and descriptive**:
   - Concept modules: use noun phrases (e.g., "High availability with database and cache layers")
   - Procedure modules: use gerunds (e.g., "Installing the Operator")
   - Reference modules: use noun phrases (e.g., "Sizing requirements for Red Hat Developer Hub")
   - Assembly titles: describe the user story/goal
   - Avoid imperative verbs in concept/reference titles (bad: "Achieve high availability", good: "High availability")

9. **If a procedure includes prerequisites, they are formatted correctly**:
   - Use `.Prerequisites` block title (not a section heading)
   - List prerequisites as bulleted items
   - N/A if no procedures in the title

10. **Content is grammatically correct and uses American English**:
    - Parallel structure in lists and phrases
    - Correct verb agreement (e.g., "helps simplify and accelerate" not "helps simplify and accelerates")
    - Proper grammar constructs (e.g., "by using" not just "using" after a noun)

11. **Information is conveyed using the correct content type**:
    - Concepts: explain what something is, why it matters
    - Procedures: step-by-step instructions (numbered steps)
    - References: tables, lists, specifications, sizing guides

12. **No broken links**:
    - All internal references use proper xref syntax
    - All external links are valid Red Hat URLs or use attributes
    - Cross-references use context-aware IDs

13. **Official product names are used throughout**:
    - Use attributes for product names: `{product}`, `{product-short}`, `{product-very-short}`, `{ocp-brand-name}`, `{company-name}`
    - Follow Red Hat Official Product List (OPL)
    - Never hardcode product names

14. **Includes appropriate, legal-approved disclaimers for Technology Preview and Developer Preview features/content**:
    - Tech Preview features have proper admonition blocks
    - N/A if no preview features in the title

Process:
1. Read the main assembly file and all included modules
2. Run Vale DITA validation to identify issues
3. Fix all validation errors and warnings:
   - Add `[role="_abstract"]` short descriptions (50-300 chars) to all modules
   - Convert DITA-incompatible block titles (`.Title`) to section headings (`== Title`)
   - Fix title patterns (concept modules use noun phrases, not imperative verbs)
   - Fix grammar issues (parallel structure, verb agreement)
   - Add context restoration to assemblies
   - Remove commented-out content
4. Re-run Vale DITA validation to confirm 0 errors, 0 warnings, 0 suggestions
5. Verify all 14 acceptance criteria are met
6. Commit changes with message format: "RHIDP-XXXXX: CQA 2.1 compliance for [TITLE NAME]"

Verification checklist after completing work:
- [ ] Vale DITA: 0 errors, 0 warnings, 0 suggestions
- [ ] Modularization with official templates
- [ ] Assembly structure compliant
- [ ] Short descriptions (50-300 chars with [role="_abstract"])
- [ ] Titles brief, complete, descriptive
- [ ] TOC nesting ≤ 3 levels
- [ ] Grammar and American English
- [ ] Prerequisites formatted correctly (or N/A)
- [ ] Correct content types
- [ ] No broken links
- [ ] Official product names
- [ ] Tech Preview disclaimers (or N/A)
```

---

## Example Usage

For the "About Red Hat Developer Hub" title:

```
CQA 2.1 compliance: About Red Hat Developer Hub

Make the "About Red Hat Developer Hub" title compliant with CQA 2.1 – Content Quality Assessment for Adobe Experience Manager (AEM) migration.

Background:
- Target path: titles/about/assemblies/assembly-about-rhdh.adoc
- All included modules must be updated
- Changes must pass Vale DITA validation with 0 errors, 0 warnings

[... rest of requirements as specified in template above ...]
```

---

## Files to Check

When working on a title, you typically need to update:

1. **Main assembly file** (e.g., `assemblies/assembly-*.adoc`)
2. **All included concept modules** (`modules/*/con-*.adoc`)
3. **All included reference modules** (`modules/*/ref-*.adoc`)
4. **All included procedure modules** (`modules/*/proc-*.adoc`)

## Common Issues Found and Fixes

### Issue: Block titles incompatible with DITA
- **Symptom**: Vale warning about block titles (`.Title` format)
- **Fix**: Convert to section headings (`== Title` format)

### Issue: Short description missing or wrong length
- **Symptom**: Vale error about missing shortdesc or character count
- **Fix**: Add `[role="_abstract"]` before intro paragraph, ensure 50-300 chars
- **Important**: Don't duplicate content—mark existing paragraph when appropriate

### Issue: Incorrect title pattern for content type
- **Symptom**: Concept module using imperative verb (e.g., "Achieve high availability")
- **Fix**: Change to noun phrase (e.g., "High availability with database layers")

### Issue: Grammar/parallel structure
- **Symptom**: Verb agreement issues in compound phrases
- **Fix**: Ensure parallel structure (e.g., "helps simplify and accelerate" not "helps simplify and accelerates")

### Issue: Missing context restoration in assembly
- **Symptom**: Assembly doesn't restore parent context at end
- **Fix**: Add at end of assembly:
  ```asciidoc
  ifdef::parent-context-of-[context-name][:context: {parent-context-of-[context-name]}]
  ifndef::parent-context-of-[context-name][:!context:]
  ```

## Validation Command

Always run this command from the repository root to validate:

```bash
vale --config .vale-dita-only.ini <path-to-assembly-file>
```

Or to validate all included files at once, run against the directory containing the modules.

## Success Criteria

The work is complete when:
- Vale DITA validation shows: `0 errors, 0 warnings, 0 suggestions`
- All 14 CQA 2.1 acceptance criteria are verified and met
- Changes are committed with proper JIRA reference in commit message
- Pull request is created with proper template and issue link
