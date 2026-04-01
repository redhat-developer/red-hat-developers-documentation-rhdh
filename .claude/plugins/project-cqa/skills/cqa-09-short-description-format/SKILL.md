---
name: cqa-09-short-description-format
description: Validates short description formatting including abstract marker, spacing, and length. Use when editing abstracts or module structure.
---

# CQA-09: Short Description Format

**Spec:** See `resources/cqa-spec.md` section "CQA-09: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 09 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 09 --fix titles/<your-title>/master.adoc
```

## What It Checks
- `[role="_abstract"]` marker must be present before the short description
- No blank line between the marker and the description text
- Short description must be between 50 and 300 characters

## Manual Items
Length violations (too short or too long) require human judgment to rewrite the description.
