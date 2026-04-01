# CQA-1 - AsciiDoc DITA Vale

## Content passes Vale asciidoctor-dita-vale tool check with no errors

**Reference:** https://github.com/jhradilek/asciidoctor-dita-vale

**Quality Level:** Required/non-negotiable

## Automated Validation and Fixing

**IMPORTANT:** ALWAYS use the script below. NEVER run `vale` directly — the script handles file discovery, attributes.adoc exclusion, and correct config selection. Running `vale` directly also requires separate authorization.

```bash
# 1. Report issues
./build/scripts/cqa-01-asciidoctor-dita-vale.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-01-asciidoctor-dita-vale.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-01-asciidoctor-dita-vale.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues

# JSON output for programmatic parsing (pipe to jq)
./build/scripts/cqa-01-asciidoctor-dita-vale.sh --output JSON titles/<your-title>/master.adoc
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA-NN]`.

**Target Results:**
- ✅ 0 errors, 0 warnings, 0 suggestions

## DITA Warnings and Fixes

**All DITA warnings must be fixed.** There are no acceptable warnings. Fix each reported issue according to the table below.

| Warning | Fix |
|---------|-----|
| `AsciiDocDITA.ShortDescription` | **Delegated to [CQA-8](cqa-08-short-description-content.md).** Add `[role="_abstract"]` before the first paragraph after the title. Ensure the paragraph is 50-300 chars. |
| `AsciiDocDITA.AuthorLine` | **Auto-fixed.** Add a blank line after the title. The author line is not supported in DITA topics. |
| `AsciiDocDITA.DocumentTitle` | Add a level 0 heading (`= Title`). For master.adoc, ensure `= {title}` is present. |
| `AsciiDocDITA.DocumentId` | **Delegated to [CQA-10](cqa-10-titles.md).** Add `[id="{context}"]` before the level 0 heading. |
| `AsciiDocDITA.BlockTitle` | **Auto-fixed.** Convert to a lead-in sentence ending with `:`. Block titles (`.Something`) are only valid for examples, figures, and tables. Skips block titles before tables, examples, source blocks, and images. |
| `AsciiDocDITA.TaskContents` | **Auto-fixed.** Add `.Procedure` before the first numbered steps list. |
| `AsciiDocDITA.TaskTitle` | Unsupported sub-heading inside a procedure module. Remove the heading, or convert to a `.Procedure` block title or bold lead-in text. |
| `AsciiDocDITA.TaskStep` | **Auto-fixed.** After `.Procedure` and before the first step: remove. After a list: attach to the preceding step with `+` continuation. |
| `AsciiDocDITA.ConceptLink` | Links inside body text of concepts or procedures. Move links to `.Additional resources` section. |
| `AsciiDocDITA.AssemblyContents` | Content after include directives in an assembly. Move text into a module, or before the includes. |
| `AsciiDocDITA.RelatedLinks` | `.Additional resources` items contain explanatory text. Items must be link-only — remove surrounding prose. |
| `AsciiDocDITA.CalloutList` | **Auto-fixed.** Convert callout list items to description list items (`<1> text` → `<1>:: text`). |
| `AsciiDocDITA.ExampleBlock` | Example block nested inside another block. Move outside the parent block, or convert to a source block. |

**Auto-fixable with `--fix`:**
- AuthorLine — insert blank line after title
- BlockTitle — convert to lead-in sentence ending with `:` (skips titles before tables/examples/source/images)
- TaskContents — add `.Procedure` before first ordered list
- TaskStep — after `.Procedure` before first step: remove; after a list: replace blank line with `+` continuation
- CalloutList — convert `<1> text` to `<1>:: text` description list format

**Delegated:**
- ShortDescription — [CQA-8](cqa-08-short-description-content.md)
- DocumentId — [CQA-10](cqa-10-titles.md)

**Not auto-fixed (manual):**
- DocumentTitle — requires writing a title
- TaskTitle — requires restructuring (remove heading or convert)
- ConceptLink — requires moving links to Additional resources
- AssemblyContents — requires moving content into modules
- RelatedLinks — requires removing prose around links
- ExampleBlock — requires restructuring nested blocks

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
