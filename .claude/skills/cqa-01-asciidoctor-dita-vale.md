# CQA #1 - AsciiDoc DITA Vale

## Content passes Vale asciidoctor-dita-vale tool check with no errors

**Reference:** https://github.com/jhradilek/asciidoctor-dita-vale

**Quality Level:** Required/non-negotiable

## Automated Validation

**IMPORTANT:** ALWAYS use the script below. NEVER run `vale` directly — the script handles file discovery, attributes.adoc exclusion, and correct config selection. Running `vale` directly also requires separate authorization.

### Run Complete Validation Script

```bash
./build/scripts/cqa-01-asciidoctor-dita-vale.sh titles/<your-title>/master.adoc

# JSON output for programmatic parsing
./build/scripts/cqa-01-asciidoctor-dita-vale.sh --output JSON titles/<your-title>/master.adoc
```

**What the script validates:**
- Runs Vale with `.vale-dita-only.ini` configuration
- Validates all included files (master.adoc + assemblies + modules)
- Reports errors, warnings, and suggestions
- Supports `--output line` (default, human-readable) or `--output JSON` (structured)

**Target Results:**
- ✅ 0 errors
- ✅ 0 warnings (all warnings must be fixed)
- ✅ 0 suggestions

**Example output:**
```
✓ All files pass AsciiDoc DITA validation
✔ 0 errors, 0 warnings and 0 suggestions in 13 files.
```

## Common DITA Warnings and Fixes

**All DITA warnings must be fixed.** There are no acceptable warnings.

| Warning | Cause | Fix |
|---------|-------|-----|
| `AsciiDocDITA.BlockTitle` | Non-standard block title (e.g., `.Example` inside a block, or custom `.Title` in unexpected context) | Remove the block title or convert to plain text with a lead-in sentence. Standard procedure block titles (`.Prerequisites`, `.Procedure`, `.Verification`) are expected and do not trigger this. |
| `AsciiDocDITA.CalloutList` | Callouts in code blocks | Replace with inline comments or numbered annotations |
| `AsciiDocDITA.ConceptLink` | Links inside task-type sections (`.Procedure`, `.Prerequisites`) that DITA maps as concept links | Move links to `.Additional resources` section, or use plain text references |
| `AsciiDocDITA.DocumentId` | Missing document ID | Add `[id="{context}"]` before the level 0 heading in master.adoc |
| `AsciiDocDITA.ExampleBlock` | Example blocks nested inside other blocks | Convert to regular text with source blocks, or move outside the parent block |
| `AsciiDocDITA.RelatedLinks` | `.Additional resources` items contain explanatory text | Items must be link-only (no surrounding prose) |
| `AsciiDocDITA.ShortDescription` | Missing or incorrect short description | Add `[role="_abstract"]` before the introductory paragraph |
| `AsciiDocDITA.TaskStep` | Non-list content after `.Procedure` (admonitions, paragraphs, code blocks not attached to a step) | Attach content to the preceding step with a continuation mark (`+`), or move descriptive content before `.Procedure` |

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
