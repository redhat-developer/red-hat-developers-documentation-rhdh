# CQA #5 - Modularization

## All required modular elements are present

**Reference:** [Modular Documentation Templates Checklist](../resources/modular-documentation-templates-checklist.md)

**Quality Level:** Required/non-negotiable

All modules and assemblies must include required structural elements per the Red Hat modular documentation templates.

**IMPORTANT:** This requirement validates against the official checklist at [.claude/resources/modular-documentation-templates-checklist.md](../resources/modular-documentation-templates-checklist.md). Review that checklist before running validation.

## Automated Validation

### Run Complete Validation Script

```bash
./build/scripts/cqa-05-verify-modular-elements.sh titles/<your-title>/master.adoc
```

**What the script validates:**

The script checks all requirements from [modular-documentation-templates-checklist.md](../resources/modular-documentation-templates-checklist.md):

**All modules and assemblies:**
- Has `:_mod-docs-content-type:` metadata
- Has topic ID with `_{context}` suffix
- Has exactly one H1 title
- Has short introduction (`[role="_abstract"]`)
- Has blank line between H1 and introduction
- Images have alt text in quotes
- Admonitions do not have titles

**Nested assemblies:**
- Parent-context preservation at top
- Context restoration at bottom
- Context variable declared

**All assemblies:**
- Blank lines between includes
- No level 2+ subheadings
- No block titles (except `.Additional resources`)

**Concepts and references:**
- No imperative instructions
- No inappropriate block titles

**Procedures:**
- Has `.Procedure` block title
- Only one `.Procedure` block
- No embellishments on `.Procedure`
- Only standard block titles allowed

### Manual Verification

For detailed manual verification, use the official checklist:

```bash
# Open the checklist
cat .claude/resources/modular-documentation-templates-checklist.md
```

Work through each checkbox in the checklist for thorough validation.

## Required Elements by File Type

### All Modules and Assemblies

| Element | Requirement | Check Command |
|---------|-------------|---------------|
| **Content type metadata** | `:_mod-docs-content-type: <TYPE>` | `grep ":_mod-docs-content-type:" <file>` |
| **Topic ID** | `[id="<filename>_{context}"]` | `grep '\[id=".*_{context}"\]' <file>` |
| **Single H1 title** | Exactly one `= Title` | `grep -c "^= " <file>` (should be 1) |
| **Short introduction** | Paragraph after H1 | Visual inspection after H1 |
| **Blank line after H1** | Empty line between H1 and intro | `grep -A 1 "^= " <file>` |
| **Image alt text** | `image::<path>[" alt text "]` | `grep 'image::.*\["' <file>` |
| **No admonition titles** | No `.<AdmonitionType>` | `grep "^\.(NOTE\|WARNING\|IMPORTANT)" <file>` |

### Assembly Files Only

| Element | Requirement | Violation Check |
|---------|-------------|-----------------|
| **Blank lines between includes** | Empty line after each `include::` | Visual inspection |
| **No level 2+ subheadings** | No `===` or deeper | `grep "^===" assemblies/<file>` (should be empty) |
| **No block titles** | No `.BlockTitle` except `.Additional resources` | `grep "^\." assemblies/<file> \| grep -v "Additional resources"` |

**Nested assemblies only:**
- Top: `ifdef::context[:parent-context: {context}]`
- Bottom: `ifdef::parent-context[:context: {parent-context}]` + `ifndef::parent-context[:!context:]`
- Context defined: `:context: assembly-name`

### Concept/Reference Modules Only

| Element | Requirement | Violation Check |
|---------|-------------|-----------------|
| **No imperative instructions** | No action items/numbered steps | Visual inspection for numbered lists |
| **No level 2+ subheadings** | Optional: `===` allowed for complex content | N/A (allowed) |
| **No block titles** | Except `.Additional resources` or `.Next steps` | `grep "^\." modules/con-*.adoc \| grep -v "Additional\|Next steps"` |

### Procedure Modules Only

| Element | Requirement | Check/Fix |
|---------|-------------|-----------|
| **`.Procedure` block title** | Required, followed by ordered/unordered list | `grep "^\.Procedure$" modules/proc-*.adoc` |
| **Only one `.Procedure`** | Single procedure section per module | `grep -c "^\.Procedure" <file>` (should be 1) |
| **No `.Procedure` embellishments** | Use `.Procedure` not `.Procedure for installing X` | `grep "^\.Procedure " modules/proc-*.adoc` (should be empty) |
| **Standard block titles only** | Only: `.Prerequisites`, `.Procedure`, `.Verification`, `.Troubleshooting`, `.Next steps`, `.Additional resources` | See command above |
| **Correct section order** | Prerequisites → Procedure → Verification → Troubleshooting → Next steps → Additional resources | Visual inspection |

## Common Violations and Fixes

| Violation | Incorrect | Correct |
|-----------|-----------|---------|
| **Missing content type** | No `:_mod-docs-content-type:` | Add metadata after ID |
| **Missing {context}** | `[id="filename"]` | `[id="filename_{context}"]` |
| **Multiple H1 titles** | Two `= Title` lines | Combine or split into separate modules |
| **No blank after H1** | `= Title`<br>Intro text | `= Title`<br>(blank line)<br>Intro text |
| **Assembly with subheadings** | `=== Section` in assembly | Remove subheading, move content to module |
| **PROCEDURE with custom blocks** | `.Installation steps` | Use `.Procedure` |
| **CONCEPT with numbered steps** | 1. Do this<br>2. Do that | Move to PROCEDURE module |

## Validation Workflow

1. **Run content type validation:**
   ```bash
   ./build/scripts/fix-content-type.sh titles/<your-title>/master.adoc
   ```

2. **Check all required elements present:**
   - Content type metadata in all files
   - Topic IDs with `{context}` variable
   - Single H1 title per file
   - Blank line after H1

3. **Check assembly-specific requirements:**
   - No subheadings (`===`)
   - No block titles (except `.Additional resources`)
   - Blank lines between includes

4. **Check module-specific requirements:**
   - CONCEPT/REFERENCE: No imperative instructions
   - PROCEDURE: Has `.Procedure` block title
   - PROCEDURE: Standard block titles only

5. **Fix violations:**
   - Add missing metadata
   - Add `{context}` to IDs
   - Remove custom subheadings from assemblies
   - Remove custom block titles from procedures
   - Move imperative content from concepts to procedures

## Assessment Checklist

- [ ] All files have `:_mod-docs-content-type:` metadata
- [ ] All IDs include `{context}` variable
- [ ] All files have exactly one H1 title
- [ ] All files have short introduction after H1
- [ ] All files have blank line between H1 and intro
- [ ] Assemblies have no subheadings (`===`)
- [ ] Assemblies have no block titles (except `.Additional resources`)
- [ ] PROCEDURE modules have `.Procedure` block title
- [ ] PROCEDURE modules use standard block titles only
- [ ] CONCEPT/REFERENCE modules have no imperative instructions
- [ ] All required elements present per templates checklist

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
