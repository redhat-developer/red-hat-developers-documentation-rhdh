# Helper: Get Title Files

Extract list of all files in a documentation title (master.adoc and all included modules/assemblies).

## Purpose

Many CQA requirements need to validate or process ALL files that make up a documentation title:
- The master.adoc file itself
- All assemblies included by master.adoc
- All modules included by those assemblies
- Recursively, all nested includes

This helper extracts that complete file list for use in CQA validation commands.

## Command

```bash
# Get all files included in a title
grep -r "^include::" titles/<title-name>/ --include="*.adoc" \
  | cut -d: -f2- \
  | sed 's/^include::\([^[]*\).*/\1/' \
  | sed 's|^\.\./|\1|' \
  | sort -u
```

**Or using a more robust approach with the master.adoc as starting point:**

```bash
# Function to recursively find all included files
find_includes() {
  local file=$1
  local dir=$(dirname "$file")

  # Print the file itself
  echo "$file"

  # Find and process includes
  grep "^include::" "$file" 2>/dev/null | while read -r line; do
    # Extract include path
    local include_path=$(echo "$line" | sed 's/^include::\([^[]*\).*/\1/')

    # Resolve relative paths
    if [[ "$include_path" == ../* ]]; then
      include_path="$dir/$include_path"
    elif [[ "$include_path" != /* ]]; then
      include_path="$dir/$include_path"
    fi

    # Normalize path and recurse
    include_path=$(realpath -m "$include_path" 2>/dev/null || echo "$include_path")
    if [[ -f "$include_path" ]]; then
      find_includes "$include_path"
    fi
  done
}

# Get all files for a title
find_includes titles/<title-name>/master.adoc | sort -u
```

## Example Usage

**For titles/install-rhdh-osd-gcp/master.adoc:**

```bash
# Simple approach - get files from directory
grep -r "^include::" titles/install-rhdh-osd-gcp/ --include="*.adoc" \
  | cut -d: -f2- \
  | sed 's/^include::\([^[]*\).*/\1/' \
  | sort -u

# Example output:
# assemblies/assembly-install-rhdh-osd-gcp.adoc
# modules/install-rhdh-osd-gcp/proc-install-product-on-osd-short-on-gcp-short-using-the-operator.adoc
# modules/install-rhdh-osd-gcp/proc-install-product-on-osd-short-on-gcp-short-using-the-helm-chart.adoc
```

## Using with Vale

**Vale DITA validation on title files:**
```bash
vale --config .vale-dita-only.ini titles/<title-name>/master.adoc $(grep -r "^include::" titles/<title-name>/ --include="*.adoc" | cut -d: -f2- | sed 's/^include::\([^[]*\).*/\1/' | sed 's|^\.\./||' | sort -u)
```

**Vale style validation on title files:**
```bash
vale --config .vale.ini titles/<title-name>/master.adoc $(grep -r "^include::" titles/<title-name>/ --include="*.adoc" | cut -d: -f2- | sed 's/^include::\([^[]*\).*/\1/' | sed 's|^\.\./||' | sort -u)
```

## Notes

- The simple directory-based approach is usually sufficient for CQA work
- It includes all .adoc files referenced within the title directory
- Handles relative paths (../) for assemblies and modules
- Removes duplicates with `sort -u`
- Works with attribute substitution (Vale will expand attributes when processing)

## When to Use

Use this helper for CQA requirements that need to validate all title content:
- CQA #1: Vale DITA validation
- CQA #8: Short description content
- CQA #9: Short description format
- CQA #10: Title/ID/filename alignment
- CQA #12: Grammar and style validation
- CQA #16: Product name usage
