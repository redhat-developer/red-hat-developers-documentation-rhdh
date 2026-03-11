#!/bin/bash
# Verify short descriptions (abstracts) per CQA requirements #6 and #7
#
# Usage: ./verify-short-descriptions.sh [file]
#   file: Optional. If provided, verifies that file and all its includes recursively
#         Example: ./verify-short-descriptions.sh titles/install-rhdh-ocp/master.adoc
#           Processes: master.adoc → assemblies → all included modules (recursive)
#         If not provided, verifies all .adoc files in the repository
#
# Requirements:
# - Every module and assembly must have a single, concise introductory paragraph
# - Mark with [role="_abstract"] immediately after the title
# - Introduction should be 50-300 characters for AEM migration
# - The [role="_abstract"] line cannot be followed by an empty line

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Function to extract included files from a given file
get_includes() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi

    # Extract include:: statements and resolve relative paths
    grep "^include::" "$file" 2>/dev/null | sed 's/^include:://' | sed 's/\[.*//' | while read -r include_path; do
        # Resolve relative path from file's directory
        local dir=$(dirname "$file")
        local resolved_path

        if [[ "$include_path" == /* ]]; then
            resolved_path="$include_path"
        elif [[ "$include_path" == ../* ]]; then
            resolved_path="$dir/$include_path"
        else
            resolved_path="$dir/$include_path"
        fi

        # Normalize and make relative to repo root
        if [[ -f "$resolved_path" ]]; then
            # Make path relative to REPO_ROOT
            resolved_path=$(realpath --relative-to="$REPO_ROOT" "$resolved_path" 2>/dev/null) || resolved_path="$resolved_path"
            echo "$resolved_path"
        fi
    done
}

# Function to recursively collect all files to process
collect_files() {
    local file="$1"
    local var_name="$2"

    # Use eval to access the array by name
    local current_files
    eval "current_files=(\"\${${var_name}[@]}\")"

    # Skip if already processed
    for existing_file in "${current_files[@]}"; do
        if [[ "$existing_file" == "$file" ]]; then
            return
        fi
    done

    # Add file to array
    eval "${var_name}+=('$file')"

    # Get includes and process recursively
    while IFS= read -r included_file; do
        collect_files "$included_file" "$var_name"
    done < <(get_includes "$file")
}

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== CQA Requirements #6 & #7: Verify Short Descriptions ==="
echo ""

# Determine which files to process
FILES_TO_PROCESS=()

if [[ $# -eq 1 ]]; then
    # Process specified file and all its includes
    TARGET_FILE="$1"
    if [[ ! -f "$TARGET_FILE" ]]; then
        echo "Error: File not found: $TARGET_FILE"
        exit 1
    fi
    echo "Processing file and includes: $TARGET_FILE"
    echo ""
    collect_files "$TARGET_FILE" FILES_TO_PROCESS
else
    # Process all .adoc files
    while IFS= read -r file; do
        FILES_TO_PROCESS+=("$file")
    done < <(find . -name "*.adoc" -type f \
        -not -path "./build/*" \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        | sort)
fi

VIOLATIONS=0
CHECKED=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Extract content type
    CONTENT_TYPE=$(grep "^:_mod-docs-content-type:" "$file" | sed 's/^:_mod-docs-content-type: *//' | sed 's/ *$//')

    if [[ -z "$CONTENT_TYPE" ]]; then
        continue
    fi

    # Skip snippets - they don't need abstracts
    if [[ "$CONTENT_TYPE" == "SNIPPET" ]]; then
        continue
    fi

    CHECKED=$((CHECKED + 1))

    # Check for [role="_abstract"]
    if ! grep -q '^\[role="_abstract"\]' "$file"; then
        echo -e "${RED}✗${NC} $file"
        echo "  Issue: Missing [role=\"_abstract\"] marker"
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
        continue
    fi

    # Get line number of [role="_abstract"]
    ABSTRACT_LINE=$(grep -n '^\[role="_abstract"\]' "$file" | head -1 | cut -d: -f1)

    # Check if next line is empty (violation)
    NEXT_LINE=$((ABSTRACT_LINE + 1))
    NEXT_LINE_CONTENT=$(sed -n "${NEXT_LINE}p" "$file")

    if [[ -z "$NEXT_LINE_CONTENT" ]]; then
        echo -e "${RED}✗${NC} $file"
        echo "  Issue: Empty line after [role=\"_abstract\"] (abstract must start on next line)"
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
        continue
    fi

    # Extract abstract text (can be multi-line, ends at first empty line or next section)
    ABSTRACT_TEXT=""
    LINE_NUM=$NEXT_LINE
    while true; do
        LINE_CONTENT=$(sed -n "${LINE_NUM}p" "$file")
        # Stop at empty line, section marker, or include statement
        if [[ -z "$LINE_CONTENT" ]] || [[ "$LINE_CONTENT" =~ ^\. ]] || [[ "$LINE_CONTENT" =~ ^include:: ]]; then
            break
        fi
        ABSTRACT_TEXT="${ABSTRACT_TEXT}${LINE_CONTENT} "
        LINE_NUM=$((LINE_NUM + 1))
    done

    # Remove leading/trailing whitespace and collapse multiple spaces
    ABSTRACT_TEXT=$(echo "$ABSTRACT_TEXT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -s ' ')

    # Calculate character count (excluding AsciiDoc attributes)
    # For character count, we need to consider rendered text
    CHAR_COUNT=${#ABSTRACT_TEXT}

    # Check character count (50-300 characters)
    if [[ $CHAR_COUNT -lt 50 ]]; then
        echo -e "${YELLOW}⚠${NC} $file"
        echo "  Issue: Abstract too short ($CHAR_COUNT chars, minimum 50)"
        echo "  Text: $ABSTRACT_TEXT"
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
    elif [[ $CHAR_COUNT -gt 300 ]]; then
        echo -e "${YELLOW}⚠${NC} $file"
        echo "  Issue: Abstract too long ($CHAR_COUNT chars, maximum 300)"
        echo "  Text: ${ABSTRACT_TEXT:0:100}..."
        echo ""
        VIOLATIONS=$((VIOLATIONS + 1))
    else
        echo -e "${GREEN}✓${NC} $file ($CHAR_COUNT chars)"
    fi

done

echo ""
echo "=== Summary ==="
echo "Files checked: $CHECKED"
if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✓ All files have compliant short descriptions${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $VIOLATIONS violation(s)${NC}"
    exit 1
fi
