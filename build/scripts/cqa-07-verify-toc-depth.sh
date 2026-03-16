#!/bin/bash
# cqa-07-verify-toc-depth.sh
# Validates TOC depth does not exceed 3 levels (CQA #7)
#
# Usage: ./cqa-07-verify-toc-depth.sh <file-path>
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-07-verify-toc-depth.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - Heading depth must not exceed 3 levels (= == ===)
#   - Level 4+ (==== or deeper) is a violation
#
# Skips:
#   - Content inside source/listing blocks (----, ....)
#   - attributes.adoc files

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <file-path>" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  $0 titles/install-rhdh-ocp/master.adoc" >&2
    exit 1
fi

TARGET_FILE="$1"

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "Error: File not found: $TARGET_FILE" >&2
    exit 1
fi

# Function to extract included files from a given file
get_includes() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi

    grep "^include::" "$file" 2>/dev/null | sed 's/^include:://' | sed 's/\[.*//' | while read -r include_path; do
        local dir
        dir=$(dirname "$file")
        local resolved_path

        if [[ "$include_path" == /* ]]; then
            resolved_path="$include_path"
        elif [[ "$include_path" == ../* ]]; then
            resolved_path="$dir/$include_path"
        else
            resolved_path="$dir/$include_path"
        fi

        if [[ -f "$resolved_path" ]]; then
            # shellcheck disable=SC2269
            resolved_path=$(realpath --relative-to="$REPO_ROOT" "$resolved_path" 2>/dev/null) || resolved_path="$resolved_path"
            echo "$resolved_path"
        fi
    done
}

# Function to recursively collect all files to process
collect_files() {
    local file="$1"
    local var_name="$2"

    local current_files
    eval "current_files=(\"\${${var_name}[@]}\")"

    for existing_file in "${current_files[@]}"; do
        if [[ "$existing_file" == "$file" ]]; then
            return
        fi
    done

    eval "${var_name}+=('$file')"

    while IFS= read -r included_file; do
        collect_files "$included_file" "$var_name"
    done < <(get_includes "$file")
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== CQA #7: Verify TOC Depth (Max 3 Levels) ==="
echo ""
echo "Reference: .claude/skills/cqa-07-toc-max-3-levels.md"
echo ""

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

# Track violations
TOTAL_FILES=0
VIOLATIONS=0
MAX_DEPTH_FOUND=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Skip non-.adoc files
    [[ "$file" != *.adoc ]] && continue

    # Skip attributes.adoc
    [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

    TOTAL_FILES=$((TOTAL_FILES + 1))

    # Find max heading depth, skipping source/listing blocks
    local_max=0
    in_block=false
    violation_lines=()

    while IFS= read -r line; do
        # Track source/listing block boundaries
        if [[ "$line" =~ ^----+$ ]] || [[ "$line" =~ ^\.\.\.\.+$ ]]; then
            if [[ "$in_block" == false ]]; then
                in_block=true
            else
                in_block=false
            fi
            continue
        fi

        # Skip content inside blocks
        if [[ "$in_block" == true ]]; then
            continue
        fi

        # Check for headings (= followed by space)
        if [[ "$line" =~ ^(=+)[[:space:]] ]]; then
            depth=${#BASH_REMATCH[1]}
            if [[ $depth -gt $local_max ]]; then
                local_max=$depth
            fi
            if [[ $depth -gt 3 ]]; then
                violation_lines+=("Level $depth: $line")
            fi
        fi
    done < "$file"

    if [[ $local_max -gt $MAX_DEPTH_FOUND ]]; then
        MAX_DEPTH_FOUND=$local_max
    fi

    # Report status
    if [[ $local_max -eq 0 ]]; then
        echo -e "  - $(basename "$file"): No headings"
    elif [[ $local_max -le 3 ]]; then
        echo -e "  ${GREEN}v${NC} $(basename "$file"): Max depth $local_max"
    else
        echo -e "  ${RED}x${NC} $(basename "$file"): Max depth $local_max (exceeds limit of 3)"
        VIOLATIONS=$((VIOLATIONS + 1))
        for vline in "${violation_lines[@]}"; do
            echo "      $vline"
        done
    fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $TOTAL_FILES"
echo "Maximum heading depth found: $MAX_DEPTH_FOUND"

if [[ $VIOLATIONS -eq 0 && $MAX_DEPTH_FOUND -le 3 ]]; then
    echo -e "${GREEN}v All files comply with TOC depth requirement (max 3 levels)${NC}"
    exit 0
else
    if [[ $VIOLATIONS -gt 0 ]]; then
        echo -e "${RED}x Found $VIOLATIONS file(s) with TOC depth violations${NC}"
    fi
    echo ""
    echo "TOC Level Guidelines:"
    echo "  Level 1 (=):   Book/main assembly title"
    echo "  Level 2 (==):  Major sections"
    echo "  Level 3 (===): Sub-sections/procedure headings"
    echo "  Level 4+ (====): NOT ALLOWED"
    echo ""
    echo "See .claude/skills/cqa-07-toc-max-3-levels.md for restructuring strategies"
    exit 1
fi
