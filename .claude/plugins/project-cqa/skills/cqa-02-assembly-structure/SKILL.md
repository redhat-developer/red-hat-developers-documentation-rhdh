---
name: cqa-02-assembly-structure
description: Validates assembly files follow the modular docs template structure. Use when creating or restructuring assemblies.
---

# CQA-02: Assembly Structure

**Spec:** See `resources/cqa-spec.md` section "CQA-02: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 02 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 02 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Assembly must declare correct content type
- Context must be saved at the start and restored at the end
- No prose content between include directives
- Heading levels must be consistent and correct

## Manual Items
None for most structural issues. Delegates to CQA-09 for abstract/short description validation.
