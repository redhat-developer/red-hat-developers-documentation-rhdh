# CQA #9 - Modularization

## Short description format requirements

**Quality Level:** Required/non-negotiable

**Focus:** Formatting and structure of short descriptions (HOW they're formatted)

Short descriptions must follow AsciiDoc/DITA format requirements:
- Marked with `[role="_abstract"]` immediately after title
- 50-300 characters in length
- NO empty line between `[role="_abstract"]` and abstract text
- Single paragraph only

**Reference:** https://docs.google.com/presentation/d/1cl5PFL0SRV7M6GHBJOZ1jNMAtbVI_85iHKe5XWMV0ek/edit?slide=id.g37974b26b7e_0_2#slide=id.g37974b26b7e_0_2

**Note:** For content quality requirements (WHY, keywords, self-referential language), see [CQA #8](cqa-08-short-description-content.md).

## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-09-short-description-format.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-09-short-description-format.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-09-short-description-format.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**What the script does:**
- Checks for `[role="_abstract"]` marker presence
- Validates character count (50-300 characters)
- Detects empty line after marker (DITA violation)
- Reports compliant files and violations

**Target Results:**
- ✅ All modules/assemblies have `[role="_abstract"]` marker
- ✅ All abstracts are 50-300 characters
- ✅ No empty lines after `[role="_abstract"]`
- ✅ 0 violations

## Format Checklist

For each module and assembly:

- [ ] Has `[role="_abstract"]` marker immediately after title
- [ ] Marker has NO empty line after it
- [ ] Abstract is 50-300 characters (ideal: 100-150)
- [ ] Abstract is single paragraph (no line breaks within)
- [ ] Proper placement: after title, before first section

## Correct Format Structure

### Regular Modules and Assemblies

```asciidoc
= Module or Assembly Title

[role="_abstract"]
Abstract text goes here as a single paragraph between 50-300 characters.

== First Section
```

**Key format rules:**
1. Blank line after title (`= Title`)
2. `[role="_abstract"]` marker
3. NO blank line after marker
4. Abstract text (50-300 chars, single paragraph)
5. Blank line after abstract
6. First section/content begins

### master.adoc Files (EXCEPTION)

**IMPORTANT:** master.adoc files require special format for docinfo.xml compatibility.

```asciidoc
:_mod-docs-content-type: ASSEMBLY

include::artifacts/attributes.adoc[]
:context: title-<name>
:imagesdir: images
:title: <The title content>
:subtitle: <The subtitle content>
:abstract: <The abstract content>

[id="{context}"]
= {title}

[role="_abstract"]
{abstract}

include::assemblies/assembly-<name>.adoc[leveloffset=+1]
```

**Why this format:**
- docinfo.xml requires `{title}`, `{product}`, `{product-version}`, `{subtitle}`, `{abstract}`, `{company-name}` attributes
- master.adoc must define: `{title}`, `{subtitle}`, `{abstract}`
- The `:abstract:` attribute is then referenced with `{abstract}` after `[role="_abstract"]`
- This allows the abstract to be used both in the document and in metadata

**Critical differences from regular files:**
- `:abstract:` attribute MUST be defined before the title
- `[role="_abstract"]` uses `{abstract}` reference, not inline text
- `[id="{context}"]` appears before title (master.adoc exception)
- Uses `= {title}` instead of literal title text

## Format Violations and Fixes

### Violation 1: Missing `[role="_abstract"]` marker

**Script output:**
```
✗ modules/admin/proc-configure-oauth.adoc
  Issue: Missing [role="_abstract"] marker
```

**Fix:** Add marker before first paragraph

❌ **Before:**
```asciidoc
= Configuring OAuth 2.0

Configure OAuth authentication for secure access.
```

✅ **After:**
```asciidoc
= Configuring OAuth 2.0

[role="_abstract"]
Configure OAuth authentication for secure access.
```

### Violation 2: Empty line after marker (CRITICAL)

**Script output:**
```
✗ modules/admin/con-plugin-system.adoc
  Issue: Empty line after [role="_abstract"] (abstract must start on next line)
```

**Fix:** Remove empty line between marker and abstract

❌ **Before:**
```asciidoc
= Plugin system

[role="_abstract"]

The plugin system extends Developer Hub functionality.
```

✅ **After:**
```asciidoc
= Plugin system

[role="_abstract"]
The plugin system extends Developer Hub functionality.
```

**Why critical:** Empty line after `[role="_abstract"]` breaks DITA conversion.

### Violation 3: Too short (<50 characters)

**Script output:**
```
⚠ assemblies/assembly-managing-plugins.adoc
  Issue: Abstract too short (28 chars, minimum 50)
  Text: Manage and configure plugins.
```

**Fix:** Expand to meet 50-character minimum

❌ **Before (28 chars):**
```asciidoc
[role="_abstract"]
Manage and configure plugins.
```

✅ **After (93 chars):**
```asciidoc
[role="_abstract"]
Manage and configure plugins to extend Red Hat Developer Hub functionality for your team.
```

### Violation 4: Too long (>300 characters)

**Script output:**
```
⚠ assemblies/assembly-troubleshooting.adoc
  Issue: Abstract too long (312 chars, maximum 300)
```

**Fix:** Condense to meet 300-character maximum

❌ **Before (312+ chars):**
```asciidoc
[role="_abstract"]
This comprehensive guide provides detailed troubleshooting steps for resolving common installation issues that may occur when deploying Red Hat Developer Hub on OpenShift Container Platform, including network connectivity problems, authentication failures, resource constraints, and configuration errors.
```

✅ **After (149 chars):**
```asciidoc
[role="_abstract"]
Troubleshoot common installation issues including network connectivity, authentication failures, and resource constraints when deploying on OpenShift.
```

### Violation 5: Multiple paragraphs (line breaks)

**Fix:** Combine into single paragraph

❌ **Before:**
```asciidoc
[role="_abstract"]
Configure authentication for Developer Hub.

This enables secure access control.
```

✅ **After:**
```asciidoc
[role="_abstract"]
Configure authentication for Developer Hub to enable secure access control.
```

## Character Count Guidelines

**Minimum: 50 characters**
- Ensures abstract is descriptive enough
- Required for link preview context
- Provides sufficient information for search results

**Maximum: 300 characters**
- Prevents overly verbose abstracts
- Ensures abstract fits in link previews
- Keeps content concise and scannable

**Ideal range: 100-150 characters**
- Balances detail with brevity
- Works well in most link preview formats
- Provides good search result summaries

**Quick character count:**
```bash
echo -n "Your abstract text here" | wc -c
```

## Common Format Errors

| Error | Detection | Fix |
|-------|-----------|-----|
| No marker | Script reports "Missing marker" | Add `[role="_abstract"]` before paragraph |
| Empty line after marker | Script reports "Empty line after marker" | Remove blank line |
| Too short | Script reports "too short (X chars)" | Expand to 50+ characters |
| Too long | Script reports "too long (X chars)" | Condense to ≤300 characters |
| Multiple paragraphs | Visual inspection | Combine into single paragraph |
| Wrong placement | Visual inspection | Place immediately after title |

## Quick Reference

**Correct placement:**
```asciidoc
= Title
[blank line]
[role="_abstract"]
Abstract text.
[blank line]
== First Section
```

**Character targets:**
- Minimum: 50 chars
- Ideal: 100-150 chars
- Maximum: 300 chars

**Critical rules:**
- ✅ Marker present
- ✅ NO empty line after marker
- ✅ 50-300 character count
- ✅ Single paragraph

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
