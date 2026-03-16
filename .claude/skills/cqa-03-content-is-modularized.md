# CQA #3 - Modularization

## Content is modularized

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md)

**Quality Level:** Required/non-negotiable

## Command

**Run content type detection and validation:**
```bash
./build/scripts/cqa-03-fix-content-type.sh titles/<your-title>/master.adoc
```

**What the script does:**
- Detects and validates `:_mod-docs-content-type:` metadata
- Auto-fixes content type declarations where possible
- Reports compliant, violation, and auto-fixed counts
- Validates PROCEDURE structure (numbered vs unnumbered lists)
- Checks filename prefixes match declared types

**Target Results:**
- ✅ All modules have correct content type metadata (ASSEMBLY, CONCEPT, PROCEDURE, REFERENCE, SNIPPET)
- ✅ All filenames use correct prefixes (`assembly-`, `con-`, `proc-`, `ref-`, `snip-`)
- ✅ All declared types match actual content structure

## Notes

**Modularization Requirements:**

All content must follow Red Hat modular documentation structure:

1. **Assemblies** - Combine modules to address a single user story
   - Introduction paragraph (marked with `[role="_abstract"]`)
   - Include statements for modules
   - Optional: Prerequisites, Additional resources

2. **Concept Modules** (`con-*.adoc`) - Explain "what" and "why"
   - `:_mod-docs-content-type: CONCEPT`
   - No step-by-step instructions
   - Optional subheadings allowed

3. **Procedure Modules** (`proc-*.adoc`) - Step-by-step instructions
   - `:_mod-docs-content-type: PROCEDURE`
   - Standard sections only: `.Prerequisites`, `.Procedure`, `.Verification`, `.Troubleshooting`, `.Next steps`
   - NO custom subheadings

4. **Reference Modules** (`ref-*.adoc`) - Lookup data
   - `:_mod-docs-content-type: REFERENCE`
   - Tables, lists, specifications
   - Optional subheadings allowed for complex content

5. **Snippets** (`snip-*.adoc`) - Reusable content fragments
   - `:_mod-docs-content-type: SNIPPET`
   - NO structural elements (anchors, H1 headings, block titles)

**Critical Rule:** A module should not contain another module (no includes within modules)

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md)

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
