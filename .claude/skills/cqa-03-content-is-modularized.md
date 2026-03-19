# CQA #3 - Modularization

## Content is modularized

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md)

**Quality Level:** Required/non-negotiable

## Automated Validation

**IMPORTANT:** ALWAYS use the script below.

```bash
./build/scripts/cqa-03-content-is-modularized.sh [--fix] titles/<your-title>/master.adoc
```

**What the script does:**
- Detects and validates `:_mod-docs-content-type:` metadata (must be first line)
- Auto-fixes content type declarations in `--fix` mode
- Validates PROCEDURE structure (numbered vs unnumbered lists)
- Normalizes `.Procedure` and `.Verification` list formatting
- Checks filename prefixes match declared types

**Target Results:**
- ✅ All modules have correct content type metadata
- ✅ All filenames use correct prefixes (`assembly-`, `con-`, `proc-`, `ref-`, `snip-`)

## Module Types

| Type | Prefix | Content | Title form |
|------|--------|---------|------------|
| **ASSEMBLY** | `assembly-` / `master.adoc` | Combines modules for a user story | Imperative or noun phrase |
| **CONCEPT** | `con-` | Explains "what" and "why", no steps | Noun phrase |
| **PROCEDURE** | `proc-` | Step-by-step instructions, standard sections only | Imperative |
| **REFERENCE** | `ref-` | Lookup data (tables, lists) | Noun phrase |
| **SNIPPET** | `snip-` | Reusable fragments, no structural elements | N/A |

**Critical Rule:** A module should not contain another module (no includes within modules).

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |


```
