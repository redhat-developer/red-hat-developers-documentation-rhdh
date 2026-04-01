---
name: cqa-10-titles
description: Validates procedure titles use imperative mood, IDs match titles, and filenames match IDs. Use when editing titles or renaming files.
---

# CQA-10: Titles

**Spec:** See `resources/cqa-spec.md` section "CQA-10: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 10 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 10 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Procedure titles must be imperative (not gerund/"-ing" form)
- AsciiDoc IDs must match their corresponding titles
- Filenames must match their IDs
- Cross-references (xrefs) are updated when IDs or filenames change

## Manual Items
Ambiguous gerund-to-imperative conversions where the correct imperative form is unclear.
