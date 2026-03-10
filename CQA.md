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
- Changes must pass Vale DITA validation with 0 errors, only acceptable warnings

Requirements (CQA 2.1 Acceptance Criteria):

1. **Vale DITA validation**: Run `vale --config .vale-dita-only.ini` against all AsciiDoc files included in the title. Result must be 0 errors, with only acceptable warnings documented (callouts, false positive concept links), 0 suggestions.

2. **Content is modularized following Red Hat modular documentation rules** (see link:https://redhat-documentation.github.io/modular-docs/[Red Hat Modular Documentation Reference Guide]):
   - Use official templates: assemblies, concept modules, procedure modules, reference modules, snippets
   - Each module has correct `:_mod-docs-content-type:` metadata (ASSEMBLY, CONCEPT, PROCEDURE, REFERENCE, SNIPPET)
   - Proper file naming conventions: `assembly-*.adoc`, `con-*.adoc`, `proc-*.adoc`, `ref-*.adoc`, `snip-*.adoc`
   - Anchors follow format: `[id="filename_{context}"]` (must match filename without extension and prefix, include `{context}` variable)
   - **No modules nested within modules** - modules should only be included in assemblies
   - **Snippets** (`:_mod-docs-content-type: SNIPPET`) contain reusable content blocks but NO structural elements (no anchors, H1 headings, or block titles like .Prerequisites)
   - **Module-specific rules**:
     * Concept modules: Explain "what" and "why"; no step-by-step instructions; optional subheadings allowed
     * Procedure modules: Step-by-step instructions only; NO custom subheadings (only standard: .Prerequisites, .Procedure, .Verification, .Troubleshooting, .Next steps); numbered lists for multi-step, bullets for single-step
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
     * Task-based assemblies: Use gerund phrases (e.g., "Encrypting block devices")
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

Process:
1. Read the main assembly file and all included modules
2. Run Vale DITA validation to identify issues
3. Fix all validation errors and warnings **in this exact order** (CRITICAL - do not skip or reorder):

   a. **STEP 1: Fix titles FIRST** - The title is the source of truth:
      - Procedure modules: Use imperative/present tense (e.g., "Install the Operator" not "Installing the Operator")
      - Concept modules: Use noun phrases, not imperative verbs (e.g., "High availability" not "Achieve high availability")
      - Reference modules: Use noun phrases (e.g., "Configuration options" not "Configure options")
      - Assembly titles: Use gerund for task-based (e.g., "Installing plugins"), noun for non-task (e.g., "API reference")

   b. **STEP 2: Update IDs to match the title** - IDs derive from titles, NOT from filenames:
      - Convert title to lowercase with hyphens: "Install the Operator" → `install-the-operator`
      - Add `{context}` suffix: `[id="install-the-operator_{context}"]`
      - **Do NOT include the module prefix** (proc-, con-, ref-) in the ID
      - The ID must match the title exactly (lowercased with hyphens), not the current filename

   c. **STEP 3: Update filenames to match the title** - Filenames derive from titles:
      - Keep the module type prefix: `proc-`, `con-`, `ref-`, `assembly-`
      - Convert title to lowercase with hyphens: `proc-install-the-operator.adoc`
      - Use `git mv` to rename the file (preserves git history)
      - Update all include statements in assemblies that reference the renamed file
      - Update any xrefs that point to the old ID

   d. **STEP 4: Fix other issues** (only after title/ID/filename are aligned):
      - Add `[role="_abstract"]` short descriptions (50-300 chars) to all modules
      - Convert DITA-incompatible block titles (`.Title`) to section headings (`== Title`)
      - Fix grammar issues (parallel structure, verb agreement)
      - Add context restoration to assemblies
      - Remove commented-out content

   **Example of correct sequence for a procedure module:**

   **BEFORE (incorrect):**
   ```asciidoc
   # File: proc-installing-the-operator.adoc
   [id="proc-installing-the-operator_{context}"]
   = Installing the Operator
   ```

   **STEP 1 - Fix title:**
   ```asciidoc
   # File: proc-installing-the-operator.adoc (not renamed yet)
   [id="proc-installing-the-operator_{context}"]  (not updated yet)
   = Install the Operator  ✓ TITLE FIXED FIRST
   ```

   **STEP 2 - Update ID to match title:**
   ```asciidoc
   # File: proc-installing-the-operator.adoc (still not renamed)
   [id="install-the-operator_{context}"]  ✓ ID NOW MATCHES TITLE
   = Install the Operator
   ```

   **STEP 3 - Rename file to match title:**
   ```bash
   git mv proc-installing-the-operator.adoc proc-install-the-operator.adoc
   # Update include statements in assemblies
   ```

   **AFTER (all aligned):**
   ```asciidoc
   # File: proc-install-the-operator.adoc ✓
   [id="install-the-operator_{context}"]  ✓
   = Install the Operator  ✓
   ```

4. Re-run Vale DITA validation to confirm 0 errors, only acceptable warnings, 0 suggestions
5. Run build validation (`build/scripts/build.sh`) to verify xrefs still resolve
6. Verify all 14 acceptance criteria are met
7. Commit changes with message format: "RHIDP-XXXXX: CQA 2.1 compliance for [TITLE NAME]"
8. Create pull request using the template at `.github/pull_request_template.md`:
   ```bash
   gh pr create --title "RHIDP-XXXXX: CQA 2.1 compliance for [TITLE NAME]" --body "$(cat <<'EOF'
   **IMPORTANT: Do Not Merge - To be merged by Docs Team Only**

   **Version(s):** <version>

   **Issue:** https://issues.redhat.com/browse/RHIDP-XXXXX

   **Preview:** TBD

   ## Summary
   Brief summary of changes

   ## Changes
   - List of key changes

   ## Validation
   - Vale DITA: 0 errors, X warnings
   - Build: Success
   EOF
   )" --base main
   ```

**CRITICAL: Common Mistakes to Avoid**

❌ **WRONG - Aligning ID to filename first:**
```asciidoc
# File: proc-creating-template.adoc (current filename)
[id="proc-creating-template_{context}"]  ← WRONG: Copying from filename
= Create a template  ← Title is correct but ID is wrong
```

❌ **WRONG - Renaming file before fixing title:**
```bash
git mv proc-creating-template.adoc proc-create-template.adoc  ← WRONG: Filename still has gerund
# Title still says "Creating a template"  ← Title not fixed yet
```

❌ **WRONG - Updating ID and filename in wrong order:**
```asciidoc
# Filename already renamed but ID not updated yet
[id="proc-creating-template_{context}"]  ← WRONG: ID doesn't match title or filename
= Create a template
```

✅ **CORRECT - Follow the sequence: Title → ID → Filename**
1. Fix title FIRST: "Creating" → "Create"
2. Update ID to match title: `[id="create-a-template_{context}"]`
3. Rename file to match title: `proc-create-a-template.adoc`

Verification checklist after completing work:
- [ ] Vale DITA: 0 errors, only acceptable warnings, 0 suggestions
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
- [ ] **Title → ID → Filename sequence followed for all modules**
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
- Changes must pass Vale DITA validation with 0 errors, only acceptable warnings

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

### Issue: Modules nested within modules
- **Symptom**: Include statements for modules within other modules (not in assemblies)
- **Root cause**: Violates Red Hat modular documentation rule: "A module should not contain another module"
- **Fix**:
  1. Create an assembly to contain the modules
  2. Move all module includes to the assembly
  3. Update parent assembly to include the new assembly instead of individual modules
- **Example**: If `proc-main.adoc` includes `proc-substep.adoc`, create `assembly-main-process.adoc` to include both procedures

### Issue: Custom subheadings in procedure modules
- **Symptom**: Procedure modules contain section headings (`== Custom Section`) beyond standard ones
- **Root cause**: Red Hat modular docs restrict procedure subheadings to predefined types only
- **Fix**: Remove custom subheadings; use only: `.Prerequisites`, `.Procedure`, `.Verification`, `.Troubleshooting`, `.Next steps`, `.Additional resources`
- **Alternative**: Move content requiring subheadings to concept or reference modules

### Issue: Block titles incompatible with DITA
- **Symptom**: Vale warning about block titles (`.Title` format) in unexpected contexts
- **Fix**: Convert to section headings (`== Title` format) or remove if in snippets

### Issue: Short description missing or wrong length
- **Symptom**: Vale error about missing shortdesc or character count
- **Fix**: Add `[role="_abstract"]` before intro paragraph, ensure 50-300 chars
- **Important**: Don't duplicate content—mark existing paragraph when appropriate

### Issue: Incorrect title pattern for content type
- **Symptom**: Concept module using imperative verb (e.g., "Achieve high availability")
- **Fix**: Change to noun phrase (e.g., "High availability with database layers")

### Issue: Incorrect title pattern for content type
- **Symptom**: Procedure module using gerund verb (e.g., "Achieving high availability")
- **Fix**: Change to present-tense verb (e.g., "Achieve high availability")


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

### Issue: Content other than a single list in .Procedure section
- **Symptom**: DITA task mapping error: "Content other than a single list cannot be mapped to DITA tasks"
- **Fix**: Move descriptive content (bullets, explanations) before the `.Procedure` section
- **Example**: If you have bullets describing what data is displayed, put them in the introductory content, not after `.Procedure`

### Issue: Red Hat style violations
- **Symptom**: Vale warning about using "like" instead of "such as"
- **Fix**: Use "such as" for examples (e.g., "catalog entities (such as components, APIs)")
- **Note**: Always run Vale with default config after DITA validation to catch style issues

### Issue: Snippet files with structural elements
- **Symptom**: Vale warning about missing content type, document title, or block titles in snippet files
- **Root cause**: Snippet files should only contain content (lists, paragraphs, code blocks), not structural elements
- **Fix**:
  1. Add `:_mod-docs-content-type: SNIPPET` to the beginning of all snippet files
  2. Remove structural block titles (`.Prerequisites`, `.Procedure`, `.Verification`, `.Next steps`) from snippet files
  3. Add those block titles to the parent files before the include statements
- **Example**:
  - ✗ Wrong (in snippet):
    ```asciidoc
    .Prerequisites
    * You have installed the Operator.
    ```
  - ✓ Correct (in parent file):
    ```asciidoc
    .Prerequisites
    include::snip-prerequisites.adoc[]
    * Additional prerequisite in parent.
    ```
  - ✓ Correct (in snippet):
    ```asciidoc
    :_mod-docs-content-type: SNIPPET

    * You have installed the Operator.
    ```

### Issue: Inline admonitions in procedures
- **Symptom**: Inconsistent admonition formatting, or `AsciiDocDITA.TaskStep` warnings
- **Root cause**: Inline format (`TIP:`, `NOTE:`, etc.) is less consistent than block format
- **Fix**: Convert all inline admonitions to block format with delimiters
- **Example**:
  - ✗ Wrong:
    ```asciidoc
    TIP: Optionally, enable the cache for unsupported plugins.
    ```
  - ✓ Correct:
    ```asciidoc
    [TIP]
    ====
    Optionally, enable the cache for unsupported plugins.
    ====
    ```

### Issue: Admonitions in procedure steps without continuation marks
- **Symptom**: Vale warning `AsciiDocDITA.TaskStep`: "Content other than a single list cannot be mapped to DITA tasks"
- **Root cause**: Admonitions, source blocks, or other content after a procedure step need to be attached to that step using a continuation mark
- **Fix**: Add a line with a single `+` (continuation mark) before the admonition or content block
- **Example**:
  - ✗ Wrong:
    ```asciidoc
    . Enable the cache in your configuration file.

    [TIP]
    ====
    You can also enable caching for other plugins.
    ====
    ```
  - ✓ Correct:
    ```asciidoc
    . Enable the cache in your configuration file.
    +
    [TIP]
    ====
    You can also enable caching for other plugins.
    ====
    ```

### Issue: Example blocks nested in other blocks
- **Symptom**: Vale error `AsciiDocDITA.ExampleBlock`: "Examples can not be inside of other blocks in DITA"
- **Root cause**: DITA does not support nested example blocks (`.Example` with `====` delimiters)
- **Fix**: Convert the example block to regular text with a source code block, or move it outside the parent block
- **Example**:
  - ✗ Wrong:
    ```asciidoc
    ** Configure the base URL:
    +
    .Configuring the baseUrl
    ====
    [source,yaml]
    ----
    app:
      baseUrl: https://example.com
    ----
    ====
    ```
  - ✓ Correct:
    ```asciidoc
    ** Configure the base URL:
    +
    Configuring the baseUrl:
    +
    [source,yaml]
    ----
    app:
      baseUrl: https://example.com
    ----
    ```

### Issue: Modules in wrong directories
- **Symptom**: Modules in `modules/configuring/` but not actually used in the Configuring title
- **Root cause**: Modules should be organized by where they're actually used, not by their topic
- **Fix**:
  1. Use `git mv` to relocate modules to directories matching their actual usage
  2. Update include paths in all titles/assemblies that reference the moved modules
  3. Run build validation to ensure everything still works
- **Example**: A module `con-dynamic-plugins-dependencies.adoc` in `modules/configuring/` but only included in the "Installing plugins" title should be moved to `modules/dynamic-plugins/`

### Issue: Usage of "respective" and "respectively"
- **Symptom**: Not a Vale error, but poor writing style that makes content harder to understand
- **Fix**: Rewrite sentences to be explicit about which items correspond to which
- **Examples**:
  - ✗ Wrong: "certificates and keys respectively in the `ldap_certs.pem` and `ldap_keys.pem` files"
  - ✓ Correct: "certificates in the `ldap_certs.pem` file and keys in the `ldap_keys.pem` file"
  - ✗ Wrong: "their respective environment variable names"
  - ✓ Correct: "the corresponding environment variable name for each secret"
  - ✗ Wrong: "Files with _.k8s_ or _.ocp_ extensions provide overrides for Kubernetes and OpenShift, respectively"
  - ✓ Correct: "Files with _.k8s_ extension provide overrides for Kubernetes, and files with _.ocp_ extension provide overrides for OpenShift"

### Issue: Reference modules with nested sections (level 2+)
- **Symptom**: Vale DITA error: "Level 2, 3, 4, and 5 sections are not supported in DITA" in reference modules
- **Root cause**: Reference modules in DITA cannot have nested sections (`==`, `===`, etc.). They can only have:
  - Level 1 heading (module title)
  - Tables
  - Description lists
  - Paragraphs
  - Code blocks
- **Wrong approach**: Converting `==` subheadings to description lists maintains structure but may not be semantic
- **Correct approach**: Split the monolithic reference module into multiple focused reference modules:
  1. Create individual reference modules for each major section (each `==` becomes its own module)
  2. Create an assembly to organize and include all the new reference modules
  3. Update parent assembly to include the new assembly instead of the old monolithic module
  4. Update all cross-references (xrefs) throughout the documentation to point to the new assembly ID
- **Example**: A `ref-permissions.adoc` with 11 `==` subsections becomes:
  - 11 individual reference modules (one per subsection)
  - 1 assembly that includes all 11 modules
  - Parent assembly updated to include the new assembly
  - All xrefs updated from `ref-permissions_{context}` to `assembly-permissions-reference_{context}`

### Issue: Broken cross-references after module splitting
- **Symptom**: Build errors showing "Unknown ID" when building with ccutil
- **Root cause**: When you split a reference module into an assembly + multiple modules, old xrefs still point to the old module ID
- **Fix**: Search for all xrefs to the old module ID and update them to point to the new assembly ID:
  ```bash
  # Find all xrefs to old module
  grep -r "xref:old-module-id" modules/ assemblies/

  # Update them to new assembly ID
  xref:old-module-id_{context} → xref:new-assembly-id_{context}
  xref:old-module-id_title-name → xref:new-assembly-id_title-name
  ```
- **Verification**: Run `build/scripts/build-ccutil.sh` to verify all xrefs resolve correctly

## Procedure Module Style Guidelines

### Title → ID → Filename Sequence (CRITICAL)

**Always follow this exact order:**

1. **Fix the TITLE first** (the title is the source of truth):
   - Use imperative form (not gerund): "Enable the plugin" not "Enabling the plugin"
   - Remove unnecessary context: "Enable the plugin" not "Enable the plugin in {product}"
   - Example: `= Enable the Adoption Insights plugin`

2. **Update the ID to match the title** (ID derives from title, not filename):
   - Convert title to lowercase with hyphens
   - Add `_{context}` suffix
   - **Do NOT include the proc- prefix** in the ID
   - Example: `[id="enable-the-adoption-insights-plugin_{context}"]`

3. **Rename the filename to match the title** (filename derives from title):
   - Keep the `proc-` prefix in the filename
   - Convert title to lowercase with hyphens
   - Example: `proc-enable-the-adoption-insights-plugin.adoc`

### Complete Example (Correct Sequence)
```asciidoc
# File: proc-enable-the-adoption-insights-plugin.adoc (renamed to match title)

[id="enable-the-adoption-insights-plugin_{context}"]  ← Matches title

= Enable the Adoption Insights plugin  ← Source of truth
```

### Procedure Formatting

**Multi-step procedures**: Use ordered lists (numbered steps) with imperative statements
```asciidoc
.Procedure

. First step.
. Second step.
. Third step.
```

**Single-step procedures**: Use unordered list (single bullet) instead of numbered list
```asciidoc
.Procedure

* In your `dynamic-plugins.yaml` file, update the value to `true`.
```

**Note on title format**: Red Hat modular docs specify gerund phrases (e.g., "Creating tables"), but Style Guide uses imperative form (e.g., "Create tables"). Only imperative form is acceptable.

**Substeps**: Use proper indentation with continuation (+)
```asciidoc
. Main step.
+
Additional context for the step.
+
[source,yaml]
----
code example
----

. Next step with substeps:

.. Substep 1.
.. Substep 2.
```

**Standard procedure sections** (from Red Hat modular docs):
- `.Prerequisites` - Bulleted list of conditions (always plural)
- `.Procedure` - Numbered steps (required) or single bullet for one-step procedures
- `.Verification` - How to confirm success (show expected output or verification actions)
- `.Troubleshooting` - Brief issue resolution; link to separate procedures for complex troubleshooting
- `.Next steps` - Links to related instructions only (not additional instruction sequences)
- `.Additional resources` - Links to related documentation

### Content Organization

**One sentence per line**: Each sentence on its own line for better diff tracking and readability.

**Move non-procedure content before .Procedure**:
```asciidoc
[role="_abstract"]
Short description here.

Introductory content explaining context.

Field definitions or data descriptions go here:

Name::
Description of the name field

Kind::
Description of the kind field

.Procedure

. The actual steps go here.
```

### Description Lists vs Unordered Lists

**Use description lists** (not unordered lists with bold formatting) for field definitions:

✗ **Wrong**:
```asciidoc
* *Name*: Description
* *Kind*: Description
```

✓ **Correct**:
```asciidoc
Name::
Description

Kind::
Description
```

**Do NOT use bold formatting in description list terms** - the term itself is automatically formatted.

### Configuration Settings

**Use description lists for configuration parameters**:
```asciidoc
`maxBufferSize`::
(Optional) Enter the maximum buffer size for event batching.
The default value is `20`.

`flushInterval`::
(Optional) Enter the flush interval in milliseconds.
The default value is `5000ms`.
```

**Use "Enter" rather than "Specifies"** in parameter descriptions.

### File and Object References

- **Be specific about what you're referencing**:
  - Use "`dynamic-plugins.yaml` file" not "dynamic plugins config map" (unless you specifically mean a ConfigMap object)
  - Use "config map" (lowercase, two words) for the general concept
  - Use "ConfigMap" (one word, capitalized) only for Kubernetes ConfigMap objects

### Lists in Procedures

**Convert inline lists to proper list formatting**:

✗ **Wrong**:
```asciidoc
You can use the following options: *Option 1*, *Option 2*, or *Option 3*.
```

✓ **Correct**:
```asciidoc
You can use any of the following options:

* *Option 1*
* *Option 2*
* *Option 3*
```

### Source Code Block Types

**Use the correct source type for code blocks**:

- Use `[source,terminal]` for terminal commands (commands you run in a shell)
- Use `[source,bash]` only for bash scripts (complete scripts with shebang, variables, logic)
- Use `[source,yaml]`, `[source,json]`, etc. for configuration files

✗ **Wrong**:
```asciidoc
[source,bash]
----
$ oc project openshift-logging
----
```

✓ **Correct**:
```asciidoc
[source,terminal]
----
$ oc project openshift-logging
----
```

### Voice and Tense in Procedures

**Avoid passive voice in procedures (except in prerequisites)**:

✗ **Wrong**:
```asciidoc
. Configure outputs to specify where the captured logs are sent.
. Tuning can be applied per output as needed.
. Confirm that logs are being forwarded to your Splunk instance.
```

✓ **Correct**:
```asciidoc
. Configure outputs to specify where to send the captured logs.
. You can apply tuning per output as needed.
. Verify that your Splunk instance receives logs.
```

**Use present tense in procedures (except in prerequisites)**:

✗ **Wrong** (past or future tense):
```asciidoc
. The forwarder will send logs to the destination.
. The system was configured to use TLS.
```

✓ **Correct** (present tense):
```asciidoc
. The forwarder sends logs to the destination.
. The system uses TLS for secure communication.
```

**Note**: Prerequisites can use past tense (e.g., "You have installed", "You have configured").

### Abstract Guidelines

**Keep abstracts concise and focused**:

- 50-300 characters
- Focus on the essential action and tools
- Avoid excessive implementation details
- Describe the value/purpose, not just "Learn about X"

✗ **Wrong** (217 characters, too detailed):
```asciidoc
[role="_abstract"]
To forward audit logs from {product-short} to Splunk, use the {logging-brand-name} ({logging-short}) Operator and a ClusterLogForwarder instance to capture streamed logs and send them to the HTTPS endpoint of your Splunk instance.
```

✓ **Correct** (113 characters, focused):
```asciidoc
[role="_abstract"]
Forward audit logs from {product-short} to Splunk by using the {logging-short} Operator and a ClusterLogForwarder instance.
```

## Validation Commands

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

## Claude Code Configuration

This repository uses Claude Code for documentation work. The configuration is stored in `.claude/settings.json` with permission rules that control what operations Claude Code can perform.

### Permission Management Best Practices

**Consolidate permissions using wildcards** to keep settings maintainable:

- Instead of listing individual file paths, use wildcard patterns:
  ```json
  "Bash(git add *)"
  "Bash(git commit:*)"
  "Read(//tmp/**)"
  ```
- Consolidation example: 173 individual permissions → 22 wildcard permissions (87% reduction)
- Keep permissions in alphabetical order for easier maintenance

**Remove personal references** from tracked configuration files:

- No home directory paths: `/home/username/...`
- No GitHub usernames in commands or paths
- Use relative paths instead of absolute paths
- Example: `.claude` instead of `/home/username/project/.claude`

**Use `.gitignore` for local settings**:

- Add `.claude/settings.local.json` to `.gitignore` for personal overrides
- Add `.claude/settings.json.backup` to `.gitignore` for safety backups
- Only track the shared `.claude/settings.json` file

**Restrict file read permissions** for security:

- Limit `Read()` permissions to specific directories: `Read(//tmp/**)`
- Avoid overly permissive patterns like `Read(//*)`
- The `//` prefix in Read permissions indicates paths from repository root

### Settings File Structure

```json
{
  "permissions": {
    "allow": [
      "Bash(git add *)",
      "Read(//tmp/**)",
      "WebFetch(domain:*)"
    ],
    "additionalDirectories": [
      "/tmp",
      ".claude"
    ]
  }
}
```

### Consolidating Existing Permissions

If you have many individual permissions in `.claude/settings.local.json`:

1. Create a backup: `cp .claude/settings.json .claude/settings.json.backup`
2. Consolidate using wildcards and merge into `.claude/settings.json`
3. Sort alphabetically
4. Remove personal references (paths, usernames)
5. Clear `.claude/settings.local.json` (keep structure with empty `allow` array)
6. Add backup and local files to `.gitignore`:
   ```
   .claude/settings.local.json
   .claude/settings.json.backup
   ```
7. Remove from git tracking: `git rm --cached .claude/settings.local.json`
8. Commit the consolidated settings

## Acceptable Warnings

Some Vale DITA warnings are acceptable and do not block CQA 2.1 compliance:

### Callout Warnings
- **Warning**: `AsciiDocDITA.CalloutList`: "Callouts are not supported in DITA"
- **Context**: Callouts (`<1>`, `<2>`, etc.) in code blocks with corresponding explanations
- **Acceptable**: Yes - this is a known DITA limitation, but callouts are valuable for technical documentation
- **Note**: Track these warnings but do not remove callouts

### Concept Link False Positives
- **Warning**: `AsciiDocDITA.ConceptLink`: "Move all links and cross references to Additional resources"
- **Context**: Vale sometimes detects abbreviations like "CR" (Custom Resource) as cross-references
- **Acceptable**: Yes - if the warning is on plain text abbreviations, not actual links
- **Fix**: You can ignore these false positives, or spell out the abbreviation if desired

### Task Step Warnings in Introductory Content
- **Warning**: `AsciiDocDITA.TaskStep`: "Content other than a single list cannot be mapped to DITA tasks"
- **Context**: Descriptive content before `.Procedure` section
- **Acceptable**: Sometimes - if the content is legitimately before the procedure section (like field definitions)
- **Fix**: If the warning appears AFTER `.Procedure`, add a continuation mark (+). If before, it may be acceptable.

## Success Criteria

The work is complete when:
- Vale DITA validation shows: `0 errors, 0-15 acceptable warnings, 0 suggestions`
- Acceptable warnings are documented and verified as false positives or known limitations
- Vale Red Hat style validation shows: `0 errors, 0 warnings`
- Build validation (`build/scripts/build-ccutil.sh`) completes successfully with all titles built and no xref errors
- All 14 CQA 2.1 acceptance criteria are verified and met
- Changes are committed with proper JIRA reference in commit message
- Pull request is created with proper template and issue link
