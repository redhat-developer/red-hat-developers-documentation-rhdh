# CQA 2.1 Compliance

Content Quality Assessment for Red Hat Developer Hub documentation in preparation for Adobe Experience Manager (AEM) migration.

## Quick Start

For CQA 2.1 compliance work:

```
Read .claude/skills/cqa-master-workflow.md

CQA 2.1 compliance for [title name or path to master.adoc]
JIRA: RHIDP-[number]
```

The master workflow executes all 17 CQA requirements systematically with idempotency checks.

## Reference Documentation

- **Master workflow**: [.claude/skills/cqa-master-workflow.md](.claude/skills/cqa-master-workflow.md) - Execute all 17 requirements
- **Common issues**: [.claude/resources/cqa-common-issues.md](.claude/resources/cqa-common-issues.md) - Troubleshooting guide
- **Procedure style**: [.claude/resources/procedure-style-guide.md](.claude/resources/procedure-style-guide.md) - Formatting reference
- **Vale warnings**: [.claude/resources/vale-acceptable-warnings.md](.claude/resources/vale-acceptable-warnings.md) - Acceptable warnings

---

## CQA 2.1 Requirements

**Objective:** Make the title compliant with CQA 2.1 – Content Quality Assessment for Adobe Experience Manager (AEM) migration.

**Acceptance Criteria:**

1. **Vale DITA validation**: Run `vale --config .vale-dita-only.ini` against all AsciiDoc files included in the title. Result must be 0 errors, with only acceptable warnings documented (callouts, false positive concept links), 0 suggestions.

2. **Content is modularized following Red Hat modular documentation rules** (see link:https://redhat-documentation.github.io/modular-docs/[Red Hat Modular Documentation Reference Guide]):
   - Use official templates: assemblies, concept modules, procedure modules, reference modules, snippets
   - Each module has correct `:_mod-docs-content-type:` metadata (ASSEMBLY, CONCEPT, PROCEDURE, REFERENCE, SNIPPET)
   - Proper file naming conventions: `assembly-title.adoc`, `con-title.adoc`, `proc-title.adoc`, `ref-title.adoc`, `snip-*.adoc` (Convert title to lowercase with hyphens: "Install the Operator" → `proc-install-the-operator.adoc`)
     * Standard prefixes required: `assembly-`, `con-`, `proc-`, `ref-`, `snip-`
     * Alternative prefixes detected as violations: `concept-`, `procedure-`, `reference-`, `con_`, `proc_`, `ref_`, `snip_` (use `git mv` to rename)
   - Anchors follow format: `[id="title_{context}"]` (Convert title to lowercase with hyphens: "Install the Operator" → `install-the-operator_{context}`)
   - **No modules nested within modules** - modules should only be included in assemblies
   - **Snippets** (`:_mod-docs-content-type: SNIPPET`) contain reusable content blocks but NO structural elements (no anchors, H1 headings, or block titles like .Prerequisites)
   - **Module-specific rules**:
     * Concept modules: Explain "what" and "why"; no step-by-step instructions; optional subheadings allowed
     * Procedure modules: Step-by-step instructions only; NO custom subheadings (only standard: .Prerequisites, .Procedure, .Verification, .Troubleshooting, .Next steps); `.Procedure` section required; numbered lists (`. step`) for multi-step (2+), unnumbered list (`* step`) for single-step (cqa-03-content-is-modularized.sh auto-converts single numbered steps to unnumbered)
     * Reference modules: Lookup data in lists/tables; optional subheadings allowed for complex content
     * Assemblies: Introduction + include statements only; no detailed content

3. **Assemblies contain only an introductory section, and then include statements for modules**:
   - Assemblies have brief introduction (single concise paragraph required)
   - No detailed content in assemblies (move to modules) - "a module should not contain another module"
   - Introduction explains what the user accomplishes
   - Optional components: Prerequisites (applying to entire assembly), Additional resources (links only, no descriptive text)
   - Context is set and restored properly when nesting assemblies:
     ```asciidoc
     // At top of nested assembly
     ifdef::context[:parent-context: {context}]

     // At end of nested assembly
     ifdef::parent-context[:context: {parent-context}]
     ifndef::parent-context[:!context:]
     ```
   - No commented-out content
   - All includes use `leveloffset=+1` (or appropriate level)
   - All module/assembly titles must be H1 (`= Heading`)

4. **Assemblies are one user story each**:
   - Each assembly addresses a single user goal or task
   - Clear scope and purpose

5. **Content is not deeply nested in the TOC (≤3 levels)**:
   - Maximum TOC depth: 3 levels
   - Count from the title level (assembly = level 1, first include = level 2, etc.)

6. **Modules and assemblies start with a clear short description**:
   - Every module and assembly must have a **single, concise introductory paragraph** (Red Hat modular docs requirement)
   - Mark with `[role="_abstract"]` immediately after the title for DITA compatibility
   - Introduction should be 50-300 characters for AEM migration
   - **Purpose of introduction**:
     * Concept modules: Answer "What is this?" and "Why should users care?"
     * Procedure modules: Explain what the user accomplishes
     * Reference modules: Describe the data being presented
     * Assemblies: Explain what user story/goal is addressed
   - Introduction enables users to quickly determine if content is relevant
   - Describes the value/purpose (not just "Learn about X")
   - If an introduction paragraph already exists, add `[role="_abstract"]` to mark it (do NOT duplicate)
   - Remove self-referential language ("Learn about", "This section describes", "This module explains")

7. **In AsciiDoc, short descriptions must be**:
   - Added as `[role="_abstract"]` immediately after the title
   - **IMPORTANT**: The `[role="_abstract"]` line cannot be followed by an empty line - the abstract content must start on the very next line
   - Between 50-300 characters
   - Not duplicating existing content—mark the existing intro paragraph when appropriate

8. **Titles are brief, complete, and descriptive** (following Red Hat modular documentation guide):
   - **Concept modules**: Use noun phrases (e.g., "High availability with database and cache layers")
   - **Procedure modules**: Use imperative form per Style Guide (e.g., "Install the Operator", "Configure the database")
     * Note: Red Hat modular docs specify gerund phrases (e.g., "Installing the Operator"), but Style Guide requires imperative form. Only imperative form is acceptable.
   - **Reference modules**: Use noun phrases (e.g., "Sizing requirements for Red Hat Developer Hub", "Configuration options reference")
   - **Assembly titles**:
     * Task-based assemblies: Use imperative form per Style Guide (e.g., "Install the Operator", "Configure the database")
     * Non-task assemblies: Use noun phrases (e.g., "API reference")
   - Avoid imperative verbs in concept/reference titles (bad: "Achieve high availability", good: "High availability")

9. **If a procedure includes prerequisites, they are formatted correctly**:
   - Use `.Prerequisites` block title (not a section heading `== Prerequisites`)
   - Always use plural "Prerequisites" even for single item
   - List prerequisites as bulleted items
   - Prerequisites apply conditions or dependencies for the procedure
   - N/A if no procedures in the title
   - Standard procedure module sections (all optional except .Procedure):
     * `.Prerequisites` - conditions that must be met
     * `.Procedure` - the numbered steps (required)
     * `.Verification` - how to confirm success
     * `.Troubleshooting` - brief issue resolution (or link to separate troubleshooting procedure)
     * `.Next steps` - links to related instructions only
     * `.Additional resources` - links to related documentation
   - **No custom subheadings allowed in procedures** - only use the standard sections above

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

**Process:** See [.claude/skills/cqa-master-workflow.md](.claude/skills/cqa-master-workflow.md) for complete execution workflow with idempotency checks.

---

## Troubleshooting

For common issues and fixes, see [.claude/resources/cqa-common-issues.md](.claude/resources/cqa-common-issues.md).

## Automation Scripts

Available scripts for CQA 2.1 compliance:

```bash
# Content type detection and fixing
./build/scripts/cqa-03-content-is-modularized.sh titles/<your-title>/master.adoc

# Title/ID/filename alignment
./build/scripts/cqa-10-titles-are-brief-complete-and-descriptive.sh titles/<your-title>/master.adoc

# Orphaned module detection
./build/scripts/fix-orphaned-modules.sh          # List only
./build/scripts/fix-orphaned-modules.sh --execute # Delete

# Short description verification
./build/scripts/cqa-09-short-description-format.sh titles/<your-title>/master.adoc

# Build and preview generation
./build/scripts/build-ccutil.sh              # Build all titles
./build/scripts/build-ccutil.sh -b <branch>  # Build specific branch

# Vale DITA validation
vale --config .vale-dita-only.ini titles/<your-title>/

# Vale language compliance
vale --config .vale.ini titles/<your-title>/
```

## Style Guide

For procedure formatting and style guidelines, see [.claude/resources/procedure-style-guide.md](.claude/resources/procedure-style-guide.md).

## Validation

### Validation Strategy

Use a two-tier approach for efficient validation:

**Fast validation after each change** - Use asciidoctor for quick syntax checks:
```bash
asciidoctor titles/<title-name>/master.adoc -o /tmp/test.html 2>&1 | grep -i error
```

This provides immediate feedback on:
- AsciiDoc syntax errors
- Broken include statements
- Invalid cross-references within the title
- Missing files or resources

**Comprehensive validation at checkpoints** - Use build-ccutil.sh to validate all titles:
```bash
build/scripts/build-ccutil.sh 2>&1 | grep -E "(Unknown ID|fails to validate|Error)"
```

This validates:
- Cross-title xref statements (references from other titles)
- DITA compatibility
- Complete build chain
- All title dependencies

**Why validate all titles:** Cross-references may exist from other titles pointing to the modules/assemblies you changed. The full build ensures these external references still work correctly.

### DITA Validation (Required)

Always run this command from the repository root to validate DITA compliance:

```bash
vale --config .vale-dita-only.ini <path-to-assembly-file>
```

Or to validate all included files at once, run against the directory containing the modules.

**Target**: 0 errors, only acceptable warnings (see Acceptable Warnings section), 0 suggestions

### Red Hat Style Validation (Recommended)

After DITA validation passes, run Vale with default config to check Red Hat style guidelines:

```bash
vale assemblies/assembly-<name>.adoc modules/<category>/<name>/proc-*.adoc
```

**Target**: 0 errors, 0 warnings (suggestions about include directives can be ignored)

### Build Validation (Required)

After making changes, verify that all titles build successfully and all cross-references resolve:

```bash
build/scripts/build-ccutil.sh
```

**Target**: All titles build successfully with "Finished html-single", no "Unknown ID" errors, exit code 0

This validates:
- All include statements are correct
- All cross-references (xrefs) resolve properly
- All AsciiDoc syntax is valid
- Content structure is compatible with DocBook XML transformation

## Acceptable Warnings

For details on acceptable Vale DITA warnings, see [.claude/resources/vale-acceptable-warnings.md](.claude/resources/vale-acceptable-warnings.md).

## Success Criteria

The work is complete when:
- Vale DITA validation shows: `0 errors, 0-15 acceptable warnings, 0 suggestions`
- Acceptable warnings are documented and verified as false positives or known limitations
- Vale Red Hat style validation shows: `0 errors, 0 warnings`
- Build validation (`build/scripts/build-ccutil.sh`) completes successfully with all titles built and no xref errors
- All 14 CQA 2.1 acceptance criteria are verified and met
- Changes are committed with proper JIRA reference in commit message
- Pull request is created with proper template and issue link
