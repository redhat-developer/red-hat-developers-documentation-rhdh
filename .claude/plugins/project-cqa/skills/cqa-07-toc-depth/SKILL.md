---
name: cqa-07-toc-depth
description: Validates maximum heading depth does not exceed 3 levels. Use when deep heading nesting is detected.
---

# CQA-07: TOC Depth

**Spec:** See `resources/cqa-spec.md` section "CQA-07: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 07 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 07 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Maximum 3 heading levels allowed (`=`, `==`, `===`)
- Detects `====` (level 4) and deeper headings that exceed the limit
- Validates table of contents depth is navigable

## Manual Items
Many deep headings (more than 3 violations) require human judgment to restructure content. Auto-fix promotes `====` to `===` only when there are 3 or fewer violations.
