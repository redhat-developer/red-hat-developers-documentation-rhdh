#!/bin/bash
# cqa-07-verify-toc-depth.sh
# Validates TOC depth does not exceed 3 levels (CQA #7)
#
# Reference: .claude/skills/cqa-07-toc-max-3-levels.md
#
# Usage: ./cqa-07-verify-toc-depth.sh <path-to-master.adoc>

set -e

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <path-to-master.adoc>" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  $0 titles/integrating-with-github/master.adoc" >&2
    exit 1
fi

TARGET_FILE="$1"

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "Error: File not found: $TARGET_FILE" >&2
    exit 1
fi

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT="."

# Function to get all included files
get_all_files() {
    local file="$1"
    "$REPO_ROOT/build/scripts/list-all-included-files-starting-from" "$file"
}

# Function to count max heading depth in a file
get_max_depth() {
    local file="$1"
    local max_depth=0

    # Find all heading lines (starting with =)
    while IFS= read -r line; do
        if [[ "$line" =~ ^(=+)[[:space:]] ]]; then
            # Count number of = signs
            depth=${#BASH_REMATCH[1]}
            if [[ $depth -gt $max_depth ]]; then
                max_depth=$depth
            fi
        fi
    done < "$file"

    echo "$max_depth"
}

# Get all files (space-separated list)
ALL_FILES=$(get_all_files "$TARGET_FILE")

# Convert space-separated list to newline-separated
# Filter to .adoc files (modules, assemblies, and master files)
ADOC_FILES=$(echo "$ALL_FILES" | tr ' ' '\n' | grep "\.adoc$" | grep -v "attributes.adoc" || true)

if [[ -z "$ADOC_FILES" ]]; then
    echo "No .adoc files found."
    exit 0
fi

echo "=== CQA #7: Verify TOC Depth (Max 3 Levels) ==="
echo ""
echo "Reference: .claude/skills/cqa-07-toc-max-3-levels.md"
echo ""

# Track violations
TOTAL_FILES=0
VIOLATIONS=0
MAX_DEPTH_FOUND=0

# Check each file
while IFS= read -r file; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    TOTAL_FILES=$((TOTAL_FILES + 1))

    # Get max depth in this file
    DEPTH=$(get_max_depth "$file")

    if [[ $DEPTH -gt $MAX_DEPTH_FOUND ]]; then
        MAX_DEPTH_FOUND=$DEPTH
    fi

    # Report status
    if [[ $DEPTH -eq 0 ]]; then
        # No headings (probably a snippet or attributes file)
        echo "  - $(basename "$file"): No headings"
    elif [[ $DEPTH -le 3 ]]; then
        # Compliant (= to === allowed)
        echo "  ✓ $(basename "$file"): Max depth $DEPTH"
    else
        # Violation (4+ levels)
        echo "  ✗ $(basename "$file"): Max depth $DEPTH (exceeds limit of 3)"
        VIOLATIONS=$((VIOLATIONS + 1))

        # Show the violating lines
        echo "    Violating headings:"
        grep -n "^====\+ " "$file" | head -3 | while IFS=: read -r line_num heading; do
            # Count depth
            depth=$(echo "$heading" | grep -o "^=*" | wc -c)
            depth=$((depth - 1))
            echo "      Line $line_num: Level $depth heading"
        done
    fi
done <<< "$ADOC_FILES"

echo ""
echo "=== Summary ==="
echo "Files checked: $TOTAL_FILES"
echo "Maximum heading depth found: $MAX_DEPTH_FOUND"

if [[ $VIOLATIONS -eq 0 && $MAX_DEPTH_FOUND -le 3 ]]; then
    echo "✓ All files comply with TOC depth requirement (max 3 levels)"
    exit 0
else
    if [[ $VIOLATIONS -gt 0 ]]; then
        echo "✗ Found $VIOLATIONS file(s) with TOC depth violations"
    fi
    if [[ $MAX_DEPTH_FOUND -gt 3 ]]; then
        echo "✗ Maximum depth of $MAX_DEPTH_FOUND exceeds limit of 3"
    fi
    echo ""
    echo "TOC Level Guidelines:"
    echo "  Level 1 (=):   Book/main assembly title"
    echo "  Level 2 (==):  Major sections"
    echo "  Level 3 (===): Sub-sections/procedure headings"
    echo "  Level 4+ (====): ✗ NOT ALLOWED"
    echo ""
    echo "See .claude/skills/cqa-07-toc-max-3-levels.md for restructuring strategies"
    exit 1
fi
