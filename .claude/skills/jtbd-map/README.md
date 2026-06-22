# JTBD Map Skill

This skill populates JTBD (Jobs To Be Done) navigation map files with actual include directives from Jira tickets or category/job/topic names.

## Files

- `SKILL.md` - Complete skill documentation with workflow steps
- `jtbd-toc-mapping.tsv` - TSV file mapping the JTBD hierarchy (categories, jobs, topics)
- `verify-titles.js` - Script to verify nav/con file titles match TSV exactly

## Title and Navtitle Verification

The `verify-titles.js` script ensures that:
1. All titles in nav and con files match exactly what's specified in the TSV file
2. All `navtitle` attributes in module includes match the TSV topic titles exactly

### Usage

```bash
# Check a specific category
node .claude/skills/jtbd-map/verify-titles.js "Troubleshoot"

# Check all categories
node .claude/skills/jtbd-map/verify-titles.js
```

### What it checks

For each category, the script:
1. Reads the TSV to get expected titles for each level (L1-L4, H2, H3)
2. Finds corresponding nav-*.adoc and con-*.adoc files
3. Extracts the `= Title` line from each file
4. Compares actual vs expected titles
5. Extracts `navtitle` attribute values from module includes
6. Compares actual vs expected navtitles
7. Reports any mismatches with:
   - File path (and module path for navtitles)
   - TSV line number
   - Expected title/navtitle
   - Actual title/navtitle

### Exit codes

- `0` - All titles match
- `1` - One or more mismatches found

### Example output

```
=== Checking category: Troubleshoot ===
✓ All titles match TSV

=== Checking category: Get Started ===

Title mismatches (1):

  File: titles/product_product/category-maps/get-started/con-get-started.adoc
  TSV line: 16
  Expected: "Get Started"
  Actual:   "Get started"

Navtitle mismatches (1):

  File: titles/product_product/category-maps/get-started/nav-set-up-first-instance.adoc
  Module: modules/shared/proc-enable-guest-login.adoc
  TSV line: 27
  Expected navtitle: "Enable the Guest login"
  Actual navtitle:   "Enable the guest login"

=== Summary ===
Total title mismatches: 1
Total navtitle mismatches: 1
Total missing files: 0
```

## Integration with jtbd-map workflow

The title and navtitle verification step (Step 8 in SKILL.md) should be run:
- After populating nav and con files
- After adding or updating module includes with navtitle attributes
- Before running CQA checks
- As part of the PR validation process

This ensures consistency between the TSV source of truth and the actual documentation files.

## Why navtitle verification matters

When a module's internal title (its `= Title` line) doesn't match the desired navigation title from the TSV, we use the `navtitle` attribute to override it:

```asciidoc
include::modules/shared/proc-resolve-pod-startup-failure-when-upgrading-to-rhdh-1-8-6-with-orchestrator.adoc[leveloffset=+1,navtitle="Troubleshoot pod startup failures"]
```

The verification script ensures that these `navtitle` values match the TSV exactly, so the table of contents displays the intended topic names consistently across the documentation.
