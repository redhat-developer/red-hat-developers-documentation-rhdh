---
name: cqa-00b-directory-structure
description: Validates directory naming conventions for titles, assemblies, and modules. Use when restructuring content or adding new directories.
---

# CQA-00b: Directory Structure

**Spec:** See `resources/cqa-spec.md` section "CQA-00b: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 00b titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 00b --fix titles/<your-title>/master.adoc
```

## What It Checks
- Title, assembly, and module directories must follow `<category>_<context>` naming convention
- Validates that directory structure matches expected modular docs layout
- Checks for consistent naming patterns across the content hierarchy

## Manual Items
Complex renames that involve many cross-references or ambiguous naming may require human judgment.
