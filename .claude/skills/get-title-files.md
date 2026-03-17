# Helper: Get Title Files

Extract list of all files in a documentation title (master.adoc and all included modules/assemblies).

## Purpose

Many CQA requirements need to validate or process ALL files that make up a documentation title:
- The master.adoc file itself
- All assemblies included by master.adoc
- All modules included by those assemblies
- Recursively, all nested includes

This helper provides a dedicated script to extract that complete file list for use in CQA validation commands.

## Script

**Location:** [build/scripts/list-all-included-files-starting-from.sh](../../build/scripts/list-all-included-files-starting-from.sh)

**Usage:**
```bash
./build/scripts/list-all-included-files-starting-from.sh titles/<title-name>/master.adoc
```

**Output:** Space-separated list of all files (master.adoc + all recursively included files) on a single line

**How it works:**
1. Starts from the specified file (e.g., master.adoc)
2. Recursively extracts all `include::` statements
3. Resolves relative paths (../) correctly
4. Avoids infinite loops by tracking processed files
5. Returns sorted, deduplicated list on a single line

## Example Usage

**For titles/install-rhdh-osd-gcp/master.adoc:**

```bash
./build/scripts/list-all-included-files-starting-from.sh titles/install-rhdh-osd-gcp/master.adoc
```

**Example output:**
```
/path/to/artifacts/attributes.adoc /path/to/modules/install-rhdh-osd-gcp/proc-install-product-on-osd-short-on-gcp-short-using-the-helm-chart.adoc /path/to/modules/install-rhdh-osd-gcp/proc-install-product-on-osd-short-on-gcp-short-using-the-operator.adoc titles/install-rhdh-osd-gcp/master.adoc
```

## Using with Vale

**Vale DITA validation on title files:**
```bash
vale --config .vale-dita-only.ini \
  $(./build/scripts/list-all-included-files-starting-from.sh titles/<title-name>/master.adoc)
```

**Vale style validation on title files:**
```bash
vale --config .vale.ini \
  $(./build/scripts/list-all-included-files-starting-from.sh titles/<title-name>/master.adoc)
```

## Notes

- Recursively follows all `include::` statements
- Handles relative paths (../) and absolute paths correctly
- Avoids infinite loops by tracking already-processed files
- Returns sorted, deduplicated list
- Works with attribute substitution in include paths (dynamically resolves {platform-id}, {context}, etc.)

## When to Use

Use this helper for CQA requirements that need to validate all title content:
- CQA #1: Vale DITA validation
- CQA #8: Short description content
- CQA #9: Short description format
- CQA #10: Title/ID/filename alignment
- CQA #12: Grammar and style validation
- CQA #16: Product name usage
