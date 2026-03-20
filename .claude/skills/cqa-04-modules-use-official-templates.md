# CQA #4 - Modularization

## Modules use the official templates

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md)

**Quality Level:** Required/non-negotiable

All modules must follow official Red Hat modular documentation templates for their content type.

## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect module files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-04-modules-use-official-templates.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-04-modules-use-official-templates.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-04-modules-use-official-templates.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA #NN]`.

## Template Requirements by Module Type

| Module Type | Required Elements | Allowed Sections | Prohibited |
|-------------|-------------------|------------------|------------|
| **CONCEPT**<br>`con-*.adoc` | • Intro paragraph (What/Why)<br>• Body content | • Subheadings (`===`)<br>• `.Additional resources` | ❌ Numbered steps<br>❌ Action items |
| **PROCEDURE**<br>`proc-*.adoc` | • Title (imperative form)<br>• Intro<br>• Steps (imperative) | • `.Prerequisites`<br>• `.Procedure`<br>• `.Verification`<br>• `.Troubleshooting`<br>• `.Next steps`<br>• `.Additional resources` | ❌ Custom subheadings (`===`)<br>❌ Non-standard sections |
| **REFERENCE**<br>`ref-*.adoc` | • Concise intro<br>• Organized data (tables/lists) | • Subheadings (`===`)<br>• `.Additional resources` | ❌ Lengthy explanations |

### Example: CONCEPT Module

```asciidoc
:_mod-docs-content-type: CONCEPT

[id="concept-name_{context}"]
= Concept title (noun phrase)

Single intro: What is this? Why care?

== Optional subheading
Body content with paragraphs, lists, tables.
```

### Example: PROCEDURE Module

```asciidoc
:_mod-docs-content-type: PROCEDURE

[id="procedure-name_{context}"]
= Create the resource (imperative)

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
:_mod-docs-content-type: REFERENCE

[id="reference-name_{context}"]
= Reference title (noun phrase)

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
| **Wrong title form (PROCEDURE)** | "Installing X" (gerund) | "Install X" (imperative) |

## Validation Workflow

1. Run: `./build/scripts/cqa-04-modules-use-official-templates.sh --fix titles/<your-title>/master.adoc`
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
