---
name: cqa-03-modularization
description: Validates modular docs metadata, prefix conventions, and list formatting in .adoc files. Use when creating or editing modules.
---

# CQA-03: Modularization

**Spec:** See `resources/cqa-spec.md` section "CQA-03: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 03 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 03 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Every `.adoc` file must have `:_mod-docs-content-type:` on line 1
- Filename prefix must match the declared content type (e.g., `proc_` for PROCEDURE)
- List formatting is validated against modular docs conventions
- Content type value must be one of the recognized types

## Manual Items
Single-step procedures may need human judgment to determine if they should remain as procedures or be converted to another type.
