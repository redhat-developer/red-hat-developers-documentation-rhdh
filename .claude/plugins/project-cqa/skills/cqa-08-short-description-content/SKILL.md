---
name: cqa-08-short-description-content
description: Validates abstract content is not self-referential. Use when editing short descriptions or abstracts.
---

# CQA-08: Short Description Content

**Spec:** See `resources/cqa-spec.md` section "CQA-08: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 08 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 08 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Abstract must not contain self-referential language (e.g., "This section describes...", "This procedure explains...")
- Validates the content quality of the short description text
- Delegates to CQA-09 if the `[role="_abstract"]` marker is missing

## Manual Items
Non-removable self-referential patterns where removing the prefix would make the sentence grammatically incorrect or meaningless.
