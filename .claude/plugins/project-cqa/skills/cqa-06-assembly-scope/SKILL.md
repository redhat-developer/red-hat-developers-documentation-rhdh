---
name: cqa-06-assembly-scope
description: Validates assembly scope limits for nested assemblies and total includes. Use when assemblies grow too large.
---

# CQA-06: Assembly Scope

**Spec:** See `resources/cqa-spec.md` section "CQA-06: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 06 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 06 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Each assembly should tell one user story
- Maximum 3 nested assemblies allowed
- Maximum 15 total include directives allowed
- Flags overly complex assemblies that should be split

## Manual Items
All issues are MANUAL. Splitting assemblies requires human judgment about content organization and user story boundaries.
