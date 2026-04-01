---
name: cqa-01-vale-dita
description: Runs Vale DITA compliance checks using .vale-dita-only.ini. Use when validating AsciiDoc DITA standards compliance.
---

# CQA-01: Vale DITA

**Spec:** See `resources/cqa-spec.md` section "CQA-01: ..." for full detection/fix logic and edge cases.

## Run

```bash
# Report
node build/scripts/cqa/index.js --check 01 titles/<your-title>/master.adoc

# Fix
node build/scripts/cqa/index.js --check 01 --fix titles/<your-title>/master.adoc
```

## What It Checks
- AsciiDoc DITA compliance via Vale with `.vale-dita-only.ini` configuration
- Auto-fixable rules: AuthorLine, CalloutList, BlockTitle, TaskContents, TaskStep
- Delegates ShortDescription issues to CQA-08 and DocumentId issues to CQA-10

## Manual Items
- DocumentTitle: title format issues needing human review
- TaskTitle: task title wording requiring judgment
- ConceptLink: concept cross-reference issues
- AssemblyContents: assembly content organization
- RelatedLinks: related links formatting
- ExampleBlock: example block structure
