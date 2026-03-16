# CQA #2 - Assembly Structure

## Assemblies should contain only an introductory section and include statements

**Quality Level:** Required/non-negotiable

## Requirement

Assemblies must have this structure:
1. **Introduction** - One or more paragraphs marked with `[role="_abstract"]`
2. **Include statements** - For modules only
3. **Optional: Additional resources** - Links only, at the end after all includes

**DITA Constraint:** DITA maps do not accept text between include statements for modules.

## Automated Validation

### Run Complete Validation Script

```bash
./build/scripts/cqa-02-assembly-structure.sh [--fix] titles/<your-title>/master.adoc
```

**What the script validates:**
- Has `[role="_abstract"]` introduction
- No content between include statements
- `.Prerequisites` appears before first include (if present)
- `.Additional resources` at end after all includes (if present)
- Content type is ASSEMBLY
- No level 2+ subheadings (=== or deeper)
- No detailed content between abstract and includes

**Target Results:**
- ✅ All assemblies have compliant structure
- ⚠️ Warnings indicate potential issues requiring manual review

**Example output:**
```
✓ All assemblies have compliant structure
Note: Warnings indicate potential issues that require manual review
```

## Verification

**Manual inspection of each assembly file:**

1. **Check assembly structure:**
   ```bash
   # List all assembly files
   find assemblies/ -name "assembly-*.adoc" -o -name "master.adoc"
   ```

2. **For each assembly, verify:**
   - [ ] Has introduction paragraph(s) with `[role="_abstract"]`
   - [ ] Only includes statements after introduction
   - [ ] NO detailed content in assembly (move to modules)
   - [ ] NO text between include statements
   - [ ] Optional `.Additional resources` is at end (after all includes)
   - [ ] Optional `.Prerequisites` section before includes (if needed)

**What to look for:**

✅ **Correct Structure:**
```asciidoc
= Assembly Title

[role="_abstract"]
Brief introduction explaining what user accomplishes.

.Prerequisites
* Prerequisite 1
* Prerequisite 2

include::modules/con-concept.adoc[leveloffset=+1]

include::modules/proc-procedure.adoc[leveloffset=+1]

.Additional resources
* link:https://example.com[Related documentation]
```

❌ **Incorrect - Detailed content in assembly:**
```asciidoc
= Assembly Title

[role="_abstract"]
Introduction paragraph.

This is a detailed explanation of concepts.  ← WRONG: Move to concept module

include::modules/proc-procedure.adoc[leveloffset=+1]

Here are additional details.  ← WRONG: No text between includes
```

## Common Violations and Fixes

### Violation 1: Detailed content in assembly
**Problem:** Assembly contains explanatory text, bullets, or detailed information

**Fix:**
1. Create a concept module (con-*.adoc) for explanatory content
2. Move detailed text to the concept module
3. Add include statement for the concept module
4. Keep only brief introduction in assembly

### Violation 2: Text between include statements
**Problem:** Assembly has paragraphs or content between module includes

**Fix:**
1. Move the text into one of the included modules
2. If text introduces a section, move it to the module being introduced
3. If text is standalone, create a new concept module

### Violation 3: Prerequisites in wrong location
**Problem:** Prerequisites listed after includes or scattered throughout

**Fix:**
1. Move all prerequisites to a single `.Prerequisites` section
2. Place immediately after introduction, before first include
3. Use bulleted list format
4. Max 10 prerequisites

### Violation 4: Additional resources with descriptive text
**Problem:** Additional resources section has explanatory content

**Fix:**
1. Keep only links in `.Additional resources`
2. Remove descriptive text
3. Link text should be descriptive enough (no extra explanation needed)

## Notes

**Reference:** This requirement aligns with DITA map structure constraints. DITA maps can only contain references to topics (modules), not inline content.

**Vale Check Status:** This will be added to Vale asciidoctor-dita-vale check (rule: AssemblyContents)

**Context Management:** Assemblies that include other assemblies must properly set and restore context:
```asciidoc
// At top of nested assembly
ifdef::context[:parent-context: {context}]

// At end of nested assembly
ifdef::parent-context[:context: {parent-context}]
ifndef::parent-context[:!context:]
```

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
