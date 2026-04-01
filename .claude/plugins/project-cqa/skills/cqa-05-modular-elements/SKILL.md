---
name: cqa-05-modular-elements
description: Validates all mandatory modular doc elements are present per content type. Use when modules are missing required sections.
---

# CQA-05: Required Modular Elements

**Spec:** See `resources/cqa-spec.md` section "CQA-05: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 05 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 05 --fix titles/<your-title>/master.adoc
```

## What It Checks
- All mandatory elements present per content type (title, abstract, procedure sections, etc.)
- PROCEDURE files have required `.Procedure` and `.Prerequisites` sections
- CONCEPT and REFERENCE files have required structural elements
- Delegates specific validations to CQA-03, CQA-09, CQA-02, and CQA-04

## Manual Items
Missing elements that cannot be auto-generated require human authoring.
