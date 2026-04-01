---
name: cqa-15-redirects
description: Detects deleted or renamed titles that may need URL redirects. Use after renaming or removing titles.
---

# CQA-15: Redirects

**Spec:** See `resources/cqa-spec.md` section "CQA-15: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 15 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 15 --fix titles/<your-title>/master.adoc
```

## What It Checks
- Detects deleted or renamed titles by comparing `git diff HEAD~5..HEAD`
- Flags titles that may need URL redirects to avoid broken bookmarks
- Analyzes recent git history for title directory changes

## Manual Items
All issues are MANUAL. Redirect configuration depends on the deployment platform and requires human judgment about the correct redirect targets.
