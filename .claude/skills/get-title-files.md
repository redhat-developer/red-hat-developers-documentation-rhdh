# Helper: Get Title Files

Extract list of all files in a documentation title (master.adoc and all included modules/assemblies).

## Purpose

Many CQA requirements need to validate or process ALL files that make up a documentation title:
- The master.adoc file itself
- All assemblies included by master.adoc
- All modules included by those assemblies
- Recursively, all nested includes

This functionality is integrated into `cqa-lib.sh` via `cqa_collect_files()`.

## Usage

All CQA scripts automatically use `cqa_collect_files()` when processing a title. The function:
1. Starts from the specified file (e.g., master.adoc)
2. Recursively extracts all `include::` statements
3. Resolves relative paths correctly
4. Deduplicates by realpath (handles symlinks)
5. Stores results in `_CQA_COLLECTED_FILES` array

```bash
# In a CQA script (after sourcing cqa-lib.sh):
cqa_collect_files "$target"
for file in "${_CQA_COLLECTED_FILES[@]}"; do
    # process each file
done
```

## When Used

Used by CQA requirements that validate all title content:
- CQA-1: Vale DITA validation
- CQA-8: Short description content
- CQA-9: Short description format
- CQA-10: Title/ID/filename alignment
- CQA-12: Grammar and style validation
- CQA-16: Product name usage
