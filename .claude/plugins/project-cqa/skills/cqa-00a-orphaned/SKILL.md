---
name: cqa-00a-orphaned
description: Finds orphaned .adoc and image files not referenced by any include or image directive. Use when cleaning up unused files or after restructuring content.
---

# CQA-00a: Orphaned Modules

**Spec:** See `resources/cqa-spec.md` section "CQA-00a: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 00a titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 00a --fix titles/<your-title>/master.adoc
```

## What It Checks
- Finds `.adoc` files not referenced by any `include::` directive in the repo
- Finds image files not referenced by any `image::` or `image:` directive
- Scope covers the entire repository, not just a single title
- Ensures every content file is reachable from some master.adoc

## Manual Items
None. Fix action is `git rm` of orphaned files.
