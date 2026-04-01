---
name: cqa-04-module-templates
description: Validates modules follow Red Hat modular docs templates. Use when creating new modules or fixing template compliance.
---

# CQA-04: Module Templates

**Spec:** See `resources/cqa-spec.md` section "CQA-04: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 04 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 04 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Modules must follow Red Hat modular docs templates for their content type
- PROCEDURE modules need `.Procedure` section with correct formatting
- `.Prerequisite` (singular) is corrected to `.Prerequisites` (plural)
- Validates overall template structure compliance

## Manual Items
Custom subheadings that do not match standard template sections require human judgment. Delegates to CQA-09 for abstract validation.
