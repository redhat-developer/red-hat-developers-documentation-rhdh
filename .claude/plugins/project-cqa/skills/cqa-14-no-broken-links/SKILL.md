---
name: cqa-14-no-broken-links
description: Detects broken include and image targets that reference non-existent files. Use when restructuring content or after file renames.
---

# CQA-14: Broken Links

**Spec:** See `resources/cqa-spec.md` section "CQA-14: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 14 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 14 --fix titles/<your-title>/master.adoc
```

## What It Checks
- `include::` directive targets must point to existing files
- `image::` directive targets must point to existing image files
- Skips paths containing AsciiDoc attribute substitutions (e.g., `{attr-name}`)

## Manual Items
All issues are MANUAL. Broken links need human judgment to determine the correct target file or whether the reference should be removed.
