---
name: cqa-16-product-names
description: Detects hardcoded product names that should use AsciiDoc attribute references. Use when product names are hardcoded in content.
---

# CQA-16: Product Names

**Spec:** See `resources/cqa-spec.md` section "CQA-16: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 16 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 16 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Hardcoded product names must use AsciiDoc attribute references instead
- Replaces all detected hardcoded names with their corresponding attributes
- Skips `attributes.adoc`, SNIPPET content type, code blocks, comments, and attribute definitions

## Manual Items
None. All hardcoded product names are auto-replaced with attribute references.
