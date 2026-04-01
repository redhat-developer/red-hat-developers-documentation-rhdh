---
name: cqa-17-disclaimers
description: Detects files mentioning Technology or Developer Preview without official disclaimer snippets. Use when adding preview feature content.
---

# CQA-17: Disclaimers

**Spec:** See `resources/cqa-spec.md` section "CQA-17: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 17 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 17 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Files mentioning Technology Preview or Developer Preview must include the official disclaimer snippet
- Validates that the appropriate disclaimer include directive is present
- Flags files that reference preview features without the required legal text

## Manual Items
All issues are MANUAL. The disclaimer snippet path varies depending on the title and context, so human judgment is needed to insert the correct include directive.
