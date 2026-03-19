# CQA #2 - Assembly Structure

## Assemblies should contain only an introductory section and include statements

**Quality Level:** Required/non-negotiable

## Requirement

Assemblies must have this structure:
1. **Content type** - `:_mod-docs-content-type: ASSEMBLY` as first line
2. **Introduction** - A single paragraph marked with `[role="_abstract"]` (50-300 chars)
3. **Optional: Prerequisites** - Use `== Prerequisites` heading (not `.Prerequisites` block title) so it appears in the TOC
4. **Include statements** - For modules only, no text between includes
5. **Optional: Additional resources** - Links only, at the end after all includes

**DITA Constraint:** DITA maps do not accept text between include statements for modules.

## Automated Validation

**IMPORTANT:** ALWAYS use the script below. Do not manually inspect assembly files without running the script first.

```bash
./build/scripts/cqa-02-assembly-structure.sh titles/<your-title>/master.adoc
```

**What the script validates:**
- Content type is ASSEMBLY
- Has `[role="_abstract"]` introduction
- No content between include statements
- `== Prerequisites` heading before first include (if present); `.Prerequisites` block title is an error
- `.Additional resources` at end after all includes (if present)
- No level 2+ subheadings (=== or deeper)

**Target Results:**
- ✅ All assemblies have compliant structure

## Correct Assembly Structure

```asciidoc
:_mod-docs-content-type: ASSEMBLY

[id="assembly-name_{context}"]
= Assembly title

[role="_abstract"]
Brief introduction explaining what user accomplishes.

== Prerequisites
* Prerequisite 1
* Prerequisite 2

include::modules/con-concept.adoc[leveloffset=+1]

include::modules/proc-procedure.adoc[leveloffset=+1]

.Additional resources
* link:https://example.com[Related documentation]
```

## Common Violations and Fixes

| Violation | Fix |
|-----------|-----|
| **Detailed content in assembly** (explanatory text, bullets) | Create a concept module, move content there, add include statement |
| **Text between include statements** | Move text into the relevant module, or create a new concept module |
| **`.Prerequisites` block title in assembly** | Change to `== Prerequisites` heading (block titles are for modules only) |
| **Prerequisites after includes** | Move to single `== Prerequisites` section before first include (max 10 items) |
| **Additional resources with descriptive text** | Keep only links, remove explanations |

## Context Management

Assemblies that include other assemblies must properly set and restore context:
```asciidoc
// At top of nested assembly
ifdef::context[:parent-context-of-my-assembly: {context}]

[id="my-assembly_{context}"]
= Assembly title

// At end of nested assembly
ifdef::parent-context-of-my-assembly[:context: {parent-context-of-my-assembly}]
ifndef::parent-context-of-my-assembly[:!context:]
```

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |


```
