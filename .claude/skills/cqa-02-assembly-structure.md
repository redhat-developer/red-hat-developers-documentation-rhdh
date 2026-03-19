# CQA #2 - Assembly Structure

## Assemblies should contain only an introductory section and include statements

**Reference:** [Assembly template](../resources/assembly-template.adoc)

**Quality Level:** Required/non-negotiable

## Requirement

Assemblies must follow the [assembly template](../resources/assembly-template.adoc). Required structure:
1. **Content type** - `:_mod-docs-content-type: ASSEMBLY` on first line
2. **Context save** - `ifdef::context[:parent-context: {context}]` on second line (skip for `master.adoc`)
3. **ID** - `[id="assembly-name_{context}"]`
4. **Title** - `= Assembly title`
5. **Context set** - `:context: assembly-name`
6. **Introduction** - A single paragraph marked with `[role="_abstract"]` (50-300 chars)
7. **Optional: Prerequisites** - Use `== Prerequisites` heading (not `.Prerequisites` block title)
8. **Include statements** - For modules only, no text between includes
9. **Optional: Additional resources** - `[role="_additional-resources"]` then `== Additional resources`, links only, after all includes
10. **Context restore** (if nestable) - `ifdef::parent-context[...]` and `ifndef::parent-context[...]`

**DITA Constraint:** DITA maps do not accept text between include statements for modules.

## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect assembly files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-02-assembly-structure.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-02-assembly-structure.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-02-assembly-structure.sh titles/<your-title>/master.adoc
```

**What the script validates (12 checks):**
- Content type is ASSEMBLY on first line, not repeated
- Has `[role="_abstract"]` introduction, warns if length outside 50-300 chars
- Has `[id="..._{context}"]` attribute
- Has `:context:` attribute set after title, separated by blank line
- Context save on line 2, not repeated; context restore as exact last two lines (except `master.adoc`)
- No `.Prerequisites` block title (must use `== Prerequisites` heading)
- More than 10 prerequisites (warning)
- No level 3+ subheadings (`===` or deeper)
- `[role="_additional-resources"]` present if `== Additional resources` heading is used
- Prerequisites before first include
- Additional resources after last include
- No content between include statements

**Auto-fixable with `--fix`:**
- Content type on first line (insert/move)
- Remove duplicate content type lines
- Add context save on line 2
- Add context restore as last two lines
- Remove duplicate context save/restore lines
- `.Prerequisites` block title → `== Prerequisites` heading
- `.Additional resources` block title → `[role="_additional-resources"]` + `== Additional resources` heading
- Missing `[role="_additional-resources"]` before `== Additional resources` heading
- Move `:context:` after title with blank line separator (if present but in wrong position)
- Add `_{context}` suffix to ID if missing
- Add missing `:context:` attribute (value derived from ID without `_{context}` suffix)

**Not auto-fixed (delegated):**
- ID value mismatch with title — handled by [CQA #10 - Titles](cqa-10-titles-are-brief-complete-and-descriptive.md)
- Introduction length (50-300 chars) — handled by [CQA #8 - Short descriptions](cqa-08-short-description-content.md)

**Not auto-fixed (manual):**
- Content between include statements — requires moving text into modules
- Missing `[role="_abstract"]` — requires writing introduction text
- Level 3+ subheadings — requires restructuring
- Prerequisites count, order, completeness
- Include order and additional resources link validity

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |


```
