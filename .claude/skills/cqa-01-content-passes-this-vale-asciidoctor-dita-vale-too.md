# CQA #1 - Asciidoc

## Content passes this Vale asciidoctor-dita-vale tool check with no errors or warnings

**Reference:** https://github.com/jhradilek/asciidoctor-dita-vale

**Quality Level:** Required/non-negotiable

## Command

**Run Vale DITA validation:**
```bash
vale --config .vale-dita-only.ini titles/<your-title>/
```

**Or for specific files:**
```bash
vale --config .vale-dita-only.ini assemblies/assembly-*.adoc modules/*/proc-*.adoc
```

**Target Results:**
- ✅ 0 errors
- ✅ Only acceptable warnings (callouts, false positive concept links)
- ✅ 0 suggestions

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
