---
name: cqa-12-grammar
description: Runs Vale grammar and style checks using .vale.ini (errors only). Use when checking prose quality and style compliance.
---

# CQA-12: Grammar and Style

**Spec:** See `resources/cqa-spec.md` section "CQA-12: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 12 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 12 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Grammar and style compliance via Vale with `.vale.ini` configuration
- Reports errors only (warnings and suggestions are excluded)
- Covers standard Red Hat style guide rules

## Manual Items
All issues are MANUAL. Vale `--fix` is not yet supported, so all grammar and style corrections must be applied by hand.
