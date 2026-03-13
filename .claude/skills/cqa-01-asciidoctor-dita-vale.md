# CQA #1 - AsciiDoc DITA Vale

## Content passes Vale asciidoctor-dita-vale tool check with no errors

**Reference:** https://github.com/jhradilek/asciidoctor-dita-vale

**Quality Level:** Required/non-negotiable

## Command

**Run Vale DITA validation on title master.adoc and ALL included files:**

```bash
# For a specific title (recommended approach)
vale --config .vale-dita-only.ini \
  $(./build/scripts/list-all-included-files-starting-from titles/<title-name>/master.adoc)
```

**Example for install-rhdh-osd-gcp:**
```bash
vale --config .vale-dita-only.ini \
  $(./build/scripts/list-all-included-files-starting-from titles/install-rhdh-osd-gcp/master.adoc)
```

**See also:** [get-title-files.md](get-title-files.md) for detailed explanation of the file list extraction script.

**Target Results:**
- ✅ 0 errors
- ✅ Only acceptable warnings (see below)
- ✅ 0 suggestions

**IMPORTANT:** Do NOT run `vale titles/<title>/` on the entire directory - this validates files NOT part of the title and produces misleading results. Always specify master.adoc and its includes.

## Notes

The AsciiDocDITA tool identifies markup that does not have a direct equivalent in DITA 1.3. See the readme for details about specific issues that it finds. Note: The AsciiDocDITA tool is updated frequently.

**Reference:** https://github.com/jhradilek/asciidoctor-dita-vale

**Acceptable Warnings:**
- `AsciiDocDITA.CalloutList`: Callouts in code blocks (known DITA limitation)
- `AsciiDocDITA.ConceptLink`: False positives on abbreviations like "CR"

**Common Errors to Fix:**
- `AsciiDocDITA.TaskStep`: Content other than list in `.Procedure` - move descriptive content before `.Procedure`
- `AsciiDocDITA.ExampleBlock`: Nested example blocks - convert to regular text with source blocks
- `AsciiDocDITA.ShortDescription`: Missing or incorrect `[role="_abstract"]`

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
