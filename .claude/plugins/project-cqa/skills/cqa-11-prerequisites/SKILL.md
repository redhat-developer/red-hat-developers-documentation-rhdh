---
name: cqa-11-prerequisites
description: Validates prerequisites section format in procedure files. Use when editing prerequisites or creating new procedures.
---

# CQA-11: Prerequisites

**Spec:** See `resources/cqa-spec.md` section "CQA-11: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 11 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 11 --fix titles/<your-title>/master.adoc
```

## What It Checks
- PROCEDURE files must use `.Prerequisites` (plural, not `.Prerequisite`)
- Prerequisites must be formatted as a bullet list (not numbered)
- Maximum of 10 prerequisite items allowed

## Manual Items
Too many prerequisite items (more than 10) require human judgment to consolidate or restructure.
