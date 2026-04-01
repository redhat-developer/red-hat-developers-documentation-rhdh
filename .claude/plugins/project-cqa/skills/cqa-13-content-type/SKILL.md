---
name: cqa-13-content-type
description: Validates that file content matches its declared content type and filename prefix. Use when content type mismatches are suspected.
---

# CQA-13: Content Type Match

**Spec:** See `resources/cqa-spec.md` section "CQA-13: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 13 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 13 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Content must match its declared type (e.g., PROCEDURE files need `.Procedure` section)
- Filename prefix must match the declared content type
- Skips SNIPPET type files, `attributes.adoc`, and `master.adoc`

## Manual Items
None. Fix action renames files with the correct prefix and updates references.
