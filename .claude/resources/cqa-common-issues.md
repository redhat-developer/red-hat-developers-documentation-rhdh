# CQA Common Issues and Fixes

Reference guide for troubleshooting common CQA 2.1 validation issues.

## Modules nested within modules

- **Symptom**: Include statements for modules within other modules (not in assemblies)
- **Root cause**: Violates Red Hat modular documentation rule: "A module should not contain another module"
- **Fix**:
  1. Create an assembly to contain the modules
  2. Move all module includes to the assembly
  3. Update parent assembly to include the new assembly instead of individual modules
- **Example**: If `proc-main.adoc` includes `proc-substep.adoc`, create `assembly-main-process.adoc` to include both procedures

## Custom subheadings in procedure modules

- **Symptom**: Procedure modules contain section headings (`== Custom Section`) beyond standard ones
- **Root cause**: Red Hat modular docs restrict procedure subheadings to predefined types only
- **Fix**: Remove custom subheadings; use only: `.Prerequisites`, `.Procedure`, `.Verification`, `.Troubleshooting`, `.Next steps`, `.Additional resources`
- **Alternative**: Move content requiring subheadings to concept or reference modules

## Block titles incompatible with DITA

- **Symptom**: Vale warning about block titles (`.Title` format) in unexpected contexts
- **Fix**: Convert to section headings (`== Title` format) or remove if in snippets

## Short description missing or wrong length

- **Symptom**: Vale error about missing shortdesc or character count
- **Fix**: Add `[role="_abstract"]` before intro paragraph, ensure 50-300 chars
- **Important**: Don't duplicate content—mark existing paragraph when appropriate

## Incorrect title pattern - Concept module

- **Symptom**: Concept module using imperative verb (e.g., "Achieve high availability")
- **Fix**: Change to noun phrase (e.g., "High availability with database layers")

## Incorrect title pattern - Procedure module

- **Symptom**: Procedure module using gerund form (e.g., "Achieving high availability")
- **Fix**: Change to imperative form (e.g., "Achieve high availability")

## Grammar/parallel structure

- **Symptom**: Verb agreement issues in compound phrases
- **Fix**: Ensure parallel structure (e.g., "helps simplify and accelerate" not "helps simplify and accelerates")

## Missing context restoration in assembly

- **Symptom**: Assembly doesn't restore parent context at end
- **Fix**: Add at end of assembly:
  ```asciidoc
  ifdef::parent-context-of-[context-name][:context: {parent-context-of-[context-name]}]
  ifndef::parent-context-of-[context-name][:!context:]
  ```

## Content other than a single list in .Procedure section

- **Symptom**: DITA task mapping error: "Content other than a single list cannot be mapped to DITA tasks"
- **Fix**: Move descriptive content (bullets, explanations) before the `.Procedure` section
- **Example**: If you have bullets describing what data is displayed, put them in the introductory content, not after `.Procedure`

## Red Hat style violations

- **Symptom**: Vale warning about using "like" instead of "such as"
- **Fix**: Use "such as" for examples (e.g., "catalog entities (such as components, APIs)")
- **Note**: Always run Vale with default config after DITA validation to catch style issues

## Snippet files with structural elements

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

## Inline admonitions in procedures

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

## Admonitions in procedure steps without continuation marks

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

## Example blocks nested in other blocks

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

## Modules in wrong directories

- **Symptom**: Modules in `modules/configuring/` but not actually used in the Configuring title
- **Root cause**: Modules should be organized by where they're actually used, not by their topic
- **Fix**:
  1. Use `git mv` to relocate modules to directories matching their actual usage
  2. Update include paths in all titles/assemblies that reference the moved modules
  3. Run build validation to ensure everything still works
- **Example**: A module `con-dynamic-plugins-dependencies.adoc` in `modules/configuring/` but only included in the "Installing plugins" title should be moved to `modules/dynamic-plugins/`

## Usage of "respective" and "respectively"

- **Symptom**: Not a Vale error, but poor writing style that makes content harder to understand
- **Fix**: Rewrite sentences to be explicit about which items correspond to which
- **Examples**:
  - ✗ Wrong: "certificates and keys respectively in the `ldap_certs.pem` and `ldap_keys.pem` files"
  - ✓ Correct: "certificates in the `ldap_certs.pem` file and keys in the `ldap_keys.pem` file"
  - ✗ Wrong: "their respective environment variable names"
  - ✓ Correct: "the corresponding environment variable name for each secret"
  - ✗ Wrong: "Files with _.k8s_ or _.ocp_ extensions provide overrides for Kubernetes and OpenShift, respectively"
  - ✓ Correct: "Files with _.k8s_ extension provide overrides for Kubernetes, and files with _.ocp_ extension provide overrides for OpenShift"

## Reference modules with nested sections (level 2+)

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

## Broken cross-references after module splitting

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
