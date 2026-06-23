---
name: jtbd-map
description: Populate JTBD navigation map files with actual include directives from Jira tickets or category/job/topic names. Use when mapping content for a JTBD job, populating nav files, or connecting existing modules to the JTBD structure.
argument-hint: "[RHIDP-XXXX or category/job/topic]"
allowed-tools: Bash(git *) Bash(node *) Read Grep Glob Edit Write
---

# JTBD Map: Populate navigation map files

## Purpose

This skill populates the JTBD (Jobs To Be Done) navigation map files under `titles/product_product/category-maps/` with actual `include::` directives pointing to existing modules. It bridges the migration from modular docs (assemblies) to JTBD docs (MAP files).

## Arguments

The skill accepts one or more of:
- **Jira ticket** IDs (e.g., `RHIDP-14636` or `RHIDP-14545 RHIDP-14546 RHIDP-14547`) -- fetches ticket content to identify the category, job, or topic
- A **category name** (e.g., `Secure`, `Install`) -- maps the entire category
- A **job or topic name** (e.g., `Configure authentication providers`) -- maps a specific job

## Workflow

### Step 1: Identify scope and check file state

If the argument is a Jira ticket:
1. Use the `jira-reader` skill to fetch the ticket summary and description
2. Match the ticket to a category, job, or topic in the TOC mapping reference

If the argument is a category/job/topic name:
1. Search the TOC mapping reference file at `.claude/skills/jtbd-map/jtbd-toc-mapping.tsv`
2. Find the matching entry in the hierarchy

Then, for each entry in scope:
3. Check whether the corresponding `nav-*.adoc` and `con-*.adoc` files exist in `titles/product_product/category-maps/<category>/`
4. If any nav or con file is missing, create it using the standard templates (see "MAP file structure" and "Concept file structure" below)
5. For existing nav files, check whether they contain `// TODO:` comments (need population) or actual `include::` directives (already populated). Skip entries that are already fully populated.

### Step 2: Confirm scope with user

Before proceeding, show the user:
- The identified category, job, and topic hierarchy from the TSV
- The nav files that will be populated, indicating which have TODOs vs. which are already done

Ask the user to confirm before making changes.

### Step 3: Find existing assemblies and modules

For each topic in the scope, find the corresponding assembly file first, then derive modules from it:

1. Search `assemblies/<category>_*/` for matching assembly files by title (using `Glob` and `Grep`)
2. If no match, search `assemblies/shared/`
3. If still no match, search all `assemblies/*/` subdirectories (catches content that moved categories, such as reference and troubleshooting content originating in other directories)
4. Read the found assembly's `include::` directives -- these give the module file paths to use in the nav file
5. Read the assembly's body content (abstract, paragraphs, admonitions, snippet includes, additional resources) -- this content goes into the concept file
6. **Verify the topic title from the TSV with enhanced hierarchy detection**:
   - **Enhanced TSV parsing**: The skill now correctly handles the variable column structure where "Is a job?" can appear in columns 8-11
   - **Entry type classification**: Each TSV entry is classified as Job L2/L3/L4, Topic L2/L3/L4, Topic H2, or Topic H3
   - **Exact title matching**: Extract the expected topic title from the appropriate TSV column based on the entry type
   - **Module title verification**: Read the module's actual title (the `= Title` line) and compare exactly
   - **Navtitle requirement**: If the module title does NOT match the TSV topic title exactly, you MUST use a `navtitle` attribute override
   - **Exact match requirement**: The `navtitle` value MUST match the TSV topic title exactly (including capitalization, punctuation, and spacing)

If no assembly is found for a topic, fall back to searching modules directly:
1. Search `modules/<category>_*/`
2. If no match, search `modules/shared/`
3. If still no match, search all `modules/*/` subdirectories
4. **Apply the same navtitle verification** as described above

### Step 3.5: Handle subsections in reference modules (CRITICAL PATTERN)

**IMPORTANT**: When the TSV lists multiple H2/H3 topics under a single job, but those topics don't have corresponding separate module files, they may be **subsections within a larger reference module**. This is a common pattern in troubleshooting and reference content.

**Detection**: You will encounter this pattern when:
1. The TSV shows multiple consecutive H2/H3 topics (e.g., 8 topics listed)
2. The existing nav file includes fewer modules than expected (e.g., only 6 includes)
3. A single reference module is included multiple times with different `navtitle` overrides
4. A reference module contains multiple H2 (`==`) sections that match TSV topic titles

**Example from Troubleshoot category:**
```
TSV lists 8 topics:
- Troubleshoot login failed errors
- Diagnose specific login failures  
- Troubleshoot catalog provider errors
- Resolve malformed LDAP entity envelopes

But only 2 modules exist:
- ref-troubleshoot-login-failed-errors.adoc (contains 3 H2 sections)
- ref-troubleshoot-catalog-provider-errors.adoc (contains 3 H2 sections)
```

**Solution - Extract subsections into granular modules:**

1. **Identify the parent module**: Find the reference module that contains multiple H2 sections matching TSV topics
   ```bash
   grep -n "^==" modules/path/to/ref-module.adoc
   ```

2. **Create separate granular modules**: For each H2 section that the TSV lists as a separate topic:
   - Extract the section content into a new module file
   - Use the appropriate module type prefix (`proc-`, `ref-`, `con-`)
   - Ensure the new module's title matches the TSV topic title exactly
   - Include the `[role="_abstract"]` paragraph
   - Preserve all content from that section only

3. **Convert parent module to overview**: Update the original reference module to:
   - Keep the title and abstract
   - Add a brief overview or list of common causes
   - Add `xref:` links to the newly created granular modules
   - Remove the detailed subsection content (now in separate modules)

4. **Update nav file**: Replace the single include (or duplicate includes with navtitles) with separate includes for each granular module:
   ```asciidoc
   include::modules/shared/ref-parent-overview.adoc[leveloffset=+1]
   include::modules/shared/proc-specific-task-1.adoc[leveloffset=+1]
   include::modules/shared/proc-specific-task-2.adoc[leveloffset=+1]
   include::modules/shared/proc-specific-task-3.adoc[leveloffset=+1]
   ```

5. **Update related assemblies**: If an assembly exists that includes the parent module, add the new granular modules to it as well.

**Verification**: After extraction:
- Run the verification script: `node .claude/skills/jtbd-map/verify-titles.js "Category"`
- Ensure all TSV topics are now represented by separate module includes
- No module should be included multiple times with different navtitles
- Each module should focus on a single task or concept

**Why this matters**: JTBD architecture requires **granular, task-focused topics** rather than large multi-section reference documents. This enables:
- Better topic reuse across different jobs
- Clearer user task completion
- More accurate analytics on topic usage
- Easier maintenance and updates

### Step 4: Populate nav files

For each nav file in scope:
1. Replace `// TODO:` comments with actual `include::` directives
2. Use the format without navtitle (default):
   ```
   include::modules/<subdirectory>/<module>.adoc[leveloffset=+1]
   ```
   Where `<subdirectory>` is the actual directory the module lives in (e.g., `shared`, `configure_configuring-rhdh`, `extend_orchestrator-in-rhdh`), accessed through the `modules` symlink in the category directory.
3. **Add `navtitle` when the module title does not match the TSV topic title**:
   - First, check if the TSV's Navtitle column (column 9) has an explicit value - if so, use that
   - Otherwise, extract the topic title from the appropriate TSV column (L2/L3/L4 for jobs, H2/H3 for leaf topics)
   - Read the module's actual `= Title` line
   - If they don't match exactly, add a `navtitle` attribute with the TSV topic title:
   ```
   include::modules/<subdirectory>/<module>.adoc[leveloffset=+1,navtitle="<exact TSV topic title>"]
   ```
   - **The `navtitle` value MUST match the TSV exactly** (same capitalization, punctuation, and spacing)
4. Keep any existing includes that are already populated
5. If a nav file would contain only one module include (besides the mandatory concept file), collapse it: delete the nav+con pair and include the module directly in the parent nav file with a `navtitle` override

### Step 5: Populate concept files

The concept file (`con-*.adoc`) in the MAP structure contains the assembly's non-include content. For each `con-*.adoc` concept file paired with a nav file:

1. Read the corresponding assembly file to extract all non-include content
2. Replace the TODO placeholder with the following content, in this order:
   a. The `[role="_abstract"]` paragraph -- always exactly one paragraph (the short description)
   b. Body content after the abstract -- additional paragraphs, admonitions, notes, lists, maintaining the original order from the assembly
   c. Snippet includes -- `include::` directives to `snip-*` files (such as Technology Preview admonitions), placed where they appeared in the assembly body
   d. `[role="_additional-resources"]` section -- always last, if present in the assembly
3. Do NOT include in the concept file:
   - Module includes (`proc-*`, `ref-*`, `con-*`, `assembly-*`) -- these go in the nav file
   - Context save/restore (`ifdef::context[:parent-context:]`, `ifdef::parent-context[:context:]`)
   - `[id="..."]` attributes -- the nav file owns the ID
   - `:context:` declarations -- the nav file owns the context

### Step 6: Resolve xref dependencies

When the content you are migrating (modules or concept body text) contains `xref:` cross-references pointing to IDs that do not yet exist in the MAP structure, you must also migrate the referenced content as a dependency:

1. For each `xref:<target-id>` found in migrated content, check whether `<target-id>` resolves to an existing `[id="..."]` in the `product_product` include tree
2. If the target ID is missing, trace it back to the old assembly or module that defines it
3. Use the TOC mapping reference (`.claude/skills/jtbd-map/jtbd-toc-mapping.tsv`) to determine the correct JTBD category and job for the missing content
4. Create or populate the corresponding nav file and concept file in the correct category directory, adding the module includes that provide the missing ID
5. Use hardcoded IDs (e.g., `[id="permission-policies-reference_authorization-in-rhdh"]`) when the xrefs use hardcoded context values instead of `_{context}`
6. When a module defines `[id="module-id_{context}"]` and existing xrefs use a hardcoded old context value (e.g., `xref:module-id_old-assembly-context[...]`), temporarily set `:context:` to the old value before the module include and restore it after:
   ```asciidoc
   // Temporarily set old context for backward-compatible module IDs
   :context: old-assembly-context
   include::modules/<subdirectory>/<module>.adoc[leveloffset=+1]
   :context: current-nav-context
   ```
7. For assembly-level IDs (e.g., `xref:old-assembly-id_old-context[...]`), add a backward-compatible anchor before the concept include in the nav file:
   ```asciidoc
   // Backward-compatible anchor for xrefs using the old assembly context
   [id="old-assembly-id_old-context"]
   ```
8. Repeat until all xref targets in the migrated scope are resolvable within the `product_product` build

This ensures the ccutil build passes with 0 "Unknown ID" errors.

### Step 7: Ensure required attributes

For each modified nav file, verify:

1. **Mandatory attributes** are present:
   - `:_mod-docs-content-type: MAP` before the ID
   - `[id="<context-value>_{context}"]` before the title
   - `:context: <context-value>` after the title
2. **Cross-reference attributes** are defined where needed:
   - `:secrets-context:` for authentication-related nav files (needed by 9 modules using `{secrets-context}` in xrefs)
   - `:import-context:` for authentication nav files (needed by PingFederate module)
3. **Platform attributes** for non-OCP install nav files. Each hyperscaler section must include the corresponding platform attribute file before its includes and restore OCP defaults after. The platform attribute files are at `titles/product_product/platform-{ocp,eks,gke,aks}.adoc`, each defining 8 attributes (`:platform-id:`, `:platform-long:`, `:platform:`, `:platform-cli:`, `:platform-cli-link:`, `:platform-cli-name:`, `:a-platform-generic:`, `:namespace:`).

   ```asciidoc
   // EKS: override platform attributes
   include::../../platform-eks.adoc[]

   // ... EKS content includes ...

   // Restore platform attributes to OCP defaults
   include::../../platform-ocp.adoc[]

   // GKE: override platform attributes
   include::../../platform-gke.adoc[]

   // ... GKE content includes ...

   // Restore platform attributes to OCP defaults
   include::../../platform-ocp.adoc[]
   ```

### Step 8: Verify titles and navtitles match TSV exactly

For each nav and con file in scope, verify that:
1. The `= Title` line in nav/con files matches the TSV title exactly
2. The `navtitle` attribute values in module includes match the TSV topic titles exactly

**Automated verification script:**

Use the provided verification script to check both titles and navtitles:

```bash
# Check a specific category
node .claude/skills/jtbd-map/verify-titles.js "Category Name"

# Check all categories
node .claude/skills/jtbd-map/verify-titles.js

# Show TSV hierarchy for debugging
node .claude/skills/jtbd-map/verify-titles.js "Category Name" --hierarchy
```

The script will:
1. Parse the TSV with enhanced logic to handle the variable column structure:
   - The "Is a job?" column can appear in different positions (columns 8-11) depending on the content level
   - The script automatically detects TRUE/FALSE values to correctly identify jobs vs topics
   - Hierarchy levels are properly identified: L2/L3/L4 for jobs, H2/H3 for topics

2. **Enhanced title verification logic:**
   - **Category (L1)**: Column 1 "Category (L1)" 
   - **Jobs (L2-L4)**: Columns 2-4 "Level 2 (Jobs)", "Level 3 (Jobs or Topics)", "Level 4 (Jobs or Topics)"
   - **Topics that are jobs** (when "Is a job?" = TRUE): Use the corresponding L2/L3/L4 column value
   - **Leaf topics (H2/H3)**: Columns 5-6 "Topic (H2)", "H3"
   - **Entry type classification**: Job L2/L3/L4, Topic L2/L3/L4, Topic H2, Topic H3

3. For each nav and con file:
   - Extract the actual title from the `= Title` line in the file
   - Compare against the expected title from the TSV hierarchy
   - Report mismatches with detailed TSV hierarchy context showing:
     - Entry type (Job L2/L3/L4, Topic L2/L3/L4, Topic H2/H3)
     - Complete TSV hierarchy (L2, L3, L4, H2, H3 values)
     - Job status (is a job: true/false)
     - Expected vs actual title
     - TSV row number for reference

4. For each `navtitle` attribute in module includes:
   - Extract the navtitle value from includes like `include::...adoc[...,navtitle="..."]`
   - Compare against the expected topic title from the TSV
   - Report mismatches with entry type classification
   - Show file path, module path, expected vs actual navtitle
   - Include TSV row number for reference

5. **Missing topic validation:**
   - Verify that parent nav files include all expected child topics from the TSV
   - Check parent-child relationships based on the TSV hierarchy
   - **Enhanced include detection**: When a module is included with a `navtitle` override, it satisfies BOTH the original module title AND the navtitle topic
   - Report missing topic includes that should be present

6. Exit with code 0 if all verifications pass, code 1 if any issues are found

**Manual verification steps:**

When the script reports mismatches, fix them by:
1. For title mismatches:
   - Read the nav and con files with reported mismatches
   - Update the `= Title` line to match exactly what's in the TSV
2. For navtitle mismatches:
   - Read the nav file with the mismatch
   - Update the `navtitle="..."` attribute value to match exactly what's in the TSV
3. Ensure capitalization, punctuation, and spacing match exactly
4. Re-run the verification script to confirm fixes

**Troubleshooting common verification issues:**

When the verification script reports issues, use these debugging approaches:

1. **Use hierarchy display for context**:
   ```bash
   node .claude/skills/jtbd-map/verify-titles.js "Category Name" --hierarchy
   ```
   This shows the complete TSV structure with entry types, job status, and expected file prefixes.

2. **Understanding entry types**:
   - **Job L2/L3/L4**: Entries marked as jobs (Is a job: true) at level 2, 3, or 4 - these need nav+con file pairs
   - **Topic L2/L3/L4**: Non-job entries at job levels - these may need nav+con pairs if they have children
   - **Topic H2/H3**: Leaf topics - these are included as modules in parent nav files

3. **Common title mismatch causes**:
   - Capitalization differences between TSV and file titles
   - Punctuation variations (quotes, hyphens, colons)
   - Extra or missing spaces
   - Different word order or phrasing

4. **Navtitle verification**:
   - Check if the TSV has an explicit "Navtitle" column value - use that if present
   - Otherwise, use the topic title from the appropriate hierarchy level (L2/L3/L4 or H2/H3)
   - Ensure navtitle exactly matches the TSV, not the module's internal title

5. **Missing topic includes**:
   - Verify the parent-child relationships in the TSV hierarchy
   - Check that parent nav files include all expected child topics
   - Look for missing `include::` directives or incorrect file paths

6. **Subsections treated as separate topics** (CRITICAL):
   - **Symptom**: TSV lists N topics, but nav file includes fewer than N modules, OR the same module appears multiple times with different navtitles
   - **Root cause**: Multiple TSV topics are subsections (H2 `==`) within a single reference module
   - **Detection**: 
     ```bash
     # Check for duplicate includes in nav file
     grep "include::" nav-file.adoc | sort | uniq -c | grep -v "^ *1 "
     
     # Check H2 sections in suspected module
     grep -n "^==" modules/path/to/ref-module.adoc
     ```
   - **Solution**: See Step 3.5 - Extract subsections into granular modules
   - **Example**: `ref-troubleshoot-login-failed-errors.adoc` had 3 H2 sections but was included once with navtitle, when TSV expected 3 separate topics. Solution: Extract each H2 into separate `proc-*.adoc` files.

### Step 9: Validate

1. Run CQA checks: `node build/scripts/cqa/index.js titles/product_product/master.adoc`
2. Run full build: `build/scripts/build-ccutil.sh`
3. Report any errors and suggest fixes

## Architecture reference

### Old structure (modular docs with assemblies)
```
titles/<category>_<title>/
  master.adoc                              # Title entry point with :context:
  assemblies/<category>_<title>/
    assembly-<topic>.adoc                  # Assembly: includes modules
  modules/<category>_<title>/
    proc-<step>.adoc                       # Procedure module
    con-<concept>.adoc                     # Concept module
    ref-<reference>.adoc                   # Reference module
```

### New structure (JTBD with MAP files)
```
titles/product_product/
  master.adoc                              # Product entry point
  title-attributes.adoc                    # Title, subtitle, abstract, context
  platform-ocp.adoc                        # OCP platform defaults (8 attributes)
  platform-eks.adoc                        # EKS platform overrides
  platform-gke.adoc                        # GKE platform overrides
  platform-aks.adoc                        # AKS platform overrides
  category-maps/
    <category>.adoc                        # Category MAP (includes concept + job navs)
    <category>/
      modules -> ../../../../modules       # Symlink to shared modules
      con-<category>.adoc                  # Category intro concept
      nav-<job>.adoc                       # Job MAP (includes concept + topic modules)
      con-<job>.adoc                       # Job overview concept
```

### MAP file structure
```asciidoc
:_mod-docs-content-type: MAP

[id="<context-value>_{context}"]
= <Title>
:context: <context-value>

include::con-<matching-concept>.adoc[leveloffset=+1]
include::modules/<subdirectory>/<module>.adoc[leveloffset=+1]
include::nav-<sub-job>.adoc[leveloffset=+1]
```

**Mandatory attributes:**
- `:_mod-docs-content-type: MAP`
- `[id="<context-value>_{context}"]`
- `:context: <context-value>`

**Optional attributes:**
- `:secrets-context:`, `:import-context:` (for authentication-related nav files)
- Platform attribute blocks (for non-OCP install nav files)

**Also allowed:**
- Comments (`// ...`) and blank lines
- `// TODO: include <Topic title>` for topics not yet populated

### Concept file structure
```asciidoc
:_mod-docs-content-type: CONCEPT

= <Title>

[role="_abstract"]
<Short description paragraph.>
```

**Rules:**
- No `[id="..."]` anchor -- the ID is inherited from the parent MAP
- No `:context:` declaration -- the MAP file owns the context
- Title matches the corresponding nav file section title

### Key rules
- First include in a MAP must be a `con-` concept file
- MAP files contain only the mandatory attributes listed above, optional attributes, `include::` directives, comments, and blank lines
- `navtitle` is only added when the module's internal title does not match the desired navigation title
- Context values must be unique across all MAP files (IDs derive from context)
- Some nav files share a context value with their parent for xref compatibility

## TOC mapping reference

The complete TOC mapping is available at `.claude/skills/jtbd-map/jtbd-toc-mapping.tsv`. This file maps:
- Categories (L1) to their Jira tickets and assignees
- Jobs (L2) and sub-jobs (L3/L4) to their topics
- Topics to their H2/H3 headings and `.adoc` file paths

Each level in the TSV hierarchy can correspond to either a MAP file (nav + con pair) or a leaf module include. The skill determines which from the actual file structure on disk.

## Categories (16)

Discover, Get started, Plan, Install, Upgrade, Migrate, Administer, Develop, Configure, Secure, Observe, Integrate, Optimize, Extend, Troubleshoot, Reference

## Real-world examples and lessons learned

### Troubleshoot category: Extracting subsections into granular modules (2026-06-23)

**Problem**: The Troubleshoot category had mapping issues where TSV topics didn't match the actual nav file includes.

**Specific issues found:**

1. **Authentication troubleshooting** (`nav-troubleshoot-authentication-issues.adoc`):
   - TSV listed 8 H2 topics
   - Nav file only included 6 modules
   - Two reference modules contained subsections being treated as single topics with navtitle overrides:
     - `ref-troubleshoot-login-failed-errors.adoc` had 3 H2 subsections
     - `ref-troubleshoot-catalog-provider-errors.adoc` had 3 H2 subsections

2. **AI Connector troubleshooting** (`nav-troubleshoot-ai-connector-functionality.adoc`):
   - The same module `ref-troubleshoot-connector-functionality.adoc` was included 4 times with different navtitles
   - This created duplicate content instead of granular topics
   - The reference module had 3 H2 subsections that should have been separate modules

**Solution applied:**

1. **Created granular modules** by extracting H2 subsections:
   - `ref-diagnose-specific-login-failures.adoc` - Extracted from login errors reference
   - `proc-resolve-malformed-ldap-entity-envelopes.adoc` - Extracted from catalog provider errors
   - `proc-verify-dynamic-plugin-status.adoc` - Extracted from AI connector reference  
   - `proc-inspect-plugin-logs.adoc` - Extracted from AI connector reference
   - `proc-inspect-the-openshift-ai-connector.adoc` - Extracted from AI connector reference

2. **Converted parent modules to overviews**:
   - `ref-troubleshoot-login-failed-errors.adoc` - Now an overview with xrefs to detailed topics
   - `ref-troubleshoot-catalog-provider-errors.adoc` - Removed LDAP section (now separate)
   - `ref-troubleshoot-connector-functionality.adoc` - Now an overview with xrefs

3. **Updated nav files** to include all granular modules separately (no duplicate includes)

4. **Updated assemblies**:
   - `assembly-troubleshoot-authentication-issues.adoc` - Added new module includes

**Results:**
- ✅ All 8 authentication troubleshooting topics now have separate modules
- ✅ All 4 AI connector troubleshooting topics now have separate modules  
- ✅ No duplicate module includes
- ✅ Verification script passes: 0 title mismatches, 0 navtitle mismatches, 0 missing topics
- ✅ Build completes successfully

**Key lesson**: When TSV topic counts don't match module include counts, look for H2 subsections within reference modules that should be extracted into granular, task-focused modules. This pattern is common in troubleshooting and reference content where a single reference module was created with multiple subsections before the JTBD migration.
