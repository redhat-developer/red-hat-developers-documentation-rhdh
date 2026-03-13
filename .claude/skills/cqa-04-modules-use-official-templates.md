# CQA #4 - Modularization

## Modules use the official templates

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md)

**Quality Level:** Required/non-negotiable

All modules must follow official Red Hat modular documentation templates for their content type.

## Commands

```bash
# Verify content type metadata and template structure
./build/scripts/fix-content-type.sh titles/<your-title>/master.adoc

# Find PROCEDURE modules with custom subheadings (violation)
grep -rn "^===" modules/proc-*.adoc

# Check for standard sections in PROCEDURE modules
grep -rn "^\.Procedure\|^\.Prerequisites" modules/proc-*.adoc
```

## Template Requirements by Module Type

| Module Type | Required Elements | Allowed Sections | Prohibited |
|-------------|-------------------|------------------|------------|
| **CONCEPT**<br>`con-*.adoc` | • Intro paragraph (What/Why)<br>• Body content | • Subheadings (`===`)<br>• `.Additional resources` | ❌ Numbered steps<br>❌ Action items |
| **PROCEDURE**<br>`proc-*.adoc` | • Title (gerund form)<br>• Intro<br>• Steps (imperative) | • `.Prerequisites`<br>• `.Procedure`<br>• `.Verification`<br>• `.Troubleshooting`<br>• `.Next steps`<br>• `.Additional resources` | ❌ Custom subheadings (`===`)<br>❌ Non-standard sections |
| **REFERENCE**<br>`ref-*.adoc` | • Concise intro<br>• Organized data (tables/lists) | • Subheadings (`===`)<br>• `.Additional resources` | ❌ Lengthy explanations |

### Example: CONCEPT Module

```asciidoc
[id="concept-name_{context}"]
= Concept title (noun phrase)
:_mod-docs-content-type: CONCEPT

Single intro: What is this? Why care?

== Optional subheading
Body content with paragraphs, lists, tables.
```

### Example: PROCEDURE Module

```asciidoc
[id="procedure-name_{context}"]
= Creating the resource (gerund)
:_mod-docs-content-type: PROCEDURE

Intro: What this accomplishes and why.

.Prerequisites
* You have installed X.

.Procedure
. Step one (imperative).
. Step two.

.Verification
* Verify result.
```

**Critical:** PROCEDURE modules use **standard sections only**. No custom subheadings (`===`).

### Example: REFERENCE Module

```asciidoc
[id="reference-name_{context}"]
= Reference title (noun phrase)
:_mod-docs-content-type: REFERENCE

Brief intro to reference data.

[options="header"]
|===
| Parameter | Type | Description
| `param1` | String | Desc
|===
```

## Common Template Violations

| Violation | Incorrect | Correct |
|-----------|-----------|---------|
| **Custom subheadings in PROCEDURE** | `=== Custom section` | Use standard sections (`.Prerequisites`, `.Procedure`) |
| **Steps in CONCEPT** | Numbered instructions | Move to PROCEDURE module |
| **Explanations in REFERENCE** | Lengthy paragraphs | Move to CONCEPT, keep only data tables |
| **No introduction** | Module starts with heading | Add intro paragraph after metadata |
| **Imperative in prerequisites** | "Install the Operator" | "You have installed the Operator" |
| **Wrong title form (PROCEDURE)** | "Install X" (imperative) | "Installing X" (gerund) |

## Validation Workflow

1. Run: `./build/scripts/fix-content-type.sh titles/<your-title>/master.adoc`
2. Check violations:
   - PROCEDURE: `grep -rn "^===" modules/proc-*.adoc` (should be empty)
   - All: Verify intro paragraph present
3. Fix:
   - Remove custom subheadings from PROCEDURE
   - Move steps from CONCEPT to PROCEDURE
   - Move explanations from REFERENCE to CONCEPT
   - Add missing intro paragraphs

## Assessment Checklist

- [ ] All modules have correct `:_mod-docs-content-type:` metadata
- [ ] CONCEPT: Intro + body, optional subheadings, no steps
- [ ] PROCEDURE: Intro + steps, standard sections only, no custom subheadings
- [ ] REFERENCE: Intro + organized data (tables/lists)
- [ ] All modules have intro paragraph
- [ ] PROCEDURE steps use imperative form
- [ ] Prerequisites use completed states
- [ ] Content matches template structure

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
