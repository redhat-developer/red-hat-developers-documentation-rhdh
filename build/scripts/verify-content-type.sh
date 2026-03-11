#!/bin/bash
# Verify that information is conveyed using the correct content type (CQA requirement #11)
#
# Usage: ./verify-content-type.sh [file]
#   file: Optional. If provided, verifies that file and all its includes recursively
#         Example: ./verify-content-type.sh titles/install-rhdh-ocp/master.adoc
#           Processes: master.adoc → assemblies → all included modules (recursive)
#         If not provided, verifies all .adoc files in the repository
#
# Requirements per CQA.md:
# - Concepts: explain what something is, why it matters
# - Procedures: step-by-step instructions (numbered steps)
# - References: tables, lists, specifications, sizing guides
#
# This script focuses on the most concrete verification:
# - PROCEDURE modules MUST contain numbered steps (. at line start)

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

echo "=== CQA Requirement #11: Verify Content Type Usage ==="
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

# Find all .adoc files with content type metadata
VIOLATIONS=0
CHECKED=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Extract content type and trim trailing whitespace
    CONTENT_TYPE=$(grep "^:_mod-docs-content-type:" "$file" | sed 's/^:_mod-docs-content-type: *//' | sed 's/ *$//')

    if [[ -z "$CONTENT_TYPE" ]]; then
        continue
    fi

    CHECKED=$((CHECKED + 1))

    case "$CONTENT_TYPE" in
        PROCEDURE)
            # Verify that procedure has steps (numbered or unnumbered) or includes snippets
            # Look for:
            # - Lines starting with one or more dots followed by space (numbered: '. ', '.. ', '... ')
            # - Lines starting with '* ' (unnumbered for single-step procedures)
            # - Include statements after .Procedure section (steps in snippets)
            if grep -q "^\(\.\.* \|\* \)" "$file" || \
               (grep -q "^\.Procedure" "$file" && grep -A 10 "^\.Procedure" "$file" | grep -q "^include::"); then
                echo -e "${GREEN}✓${NC} $file (PROCEDURE with steps)"
            else
                echo -e "${RED}✗${NC} $file"
                echo "  Content type: PROCEDURE"
                echo "  Issue: No steps found (procedures must have numbered/unnumbered lists or include snippets)"
                echo ""
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
            ;;
        CONCEPT)
            # Concepts should explain "what" and "why" - harder to verify automatically
            # Just confirm the content type is present
            echo -e "${GREEN}✓${NC} $file (CONCEPT)"
            ;;
        REFERENCE)
            # References should have tables/lists - could check for |=== or * but less strict
            echo -e "${GREEN}✓${NC} $file (REFERENCE)"
            ;;
        ASSEMBLY)
            # Assemblies are collections of modules
            # They MUST include other modules using the include:: directive
            if grep -q "^include::" "$file"; then
                echo -e "${GREEN}✓${NC} $file (ASSEMBLY)"
            else
                echo -e "${RED}✗${NC} $file"
                echo "  Content type: ASSEMBLY"
                echo "  Issue: Assemblies must include modules using include:: directive"
                echo ""
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
            ;;
        SNIPPET)
            # Snippets are reusable content fragments
            # They CANNOT include structural elements like module-level anchor IDs or H1 headings
            # Module-level IDs typically appear in first 10 lines and use format [id="..."]
            if (head -10 "$file" | grep -q '^\[id=".*"]') || grep -q "^= " "$file"; then
                echo -e "${RED}✗${NC} $file"
                echo "  Content type: SNIPPET"
                echo "  Issue: Snippets cannot include module-level anchor IDs or H1 headings"
                echo ""
                VIOLATIONS=$((VIOLATIONS + 1))
            else
                echo -e "${GREEN}✓${NC} $file (SNIPPET)"
            fi
            ;;
        *)
            echo -e "${YELLOW}?${NC} $file"
            echo "  Content type: $CONTENT_TYPE (unknown type)"
            echo ""
            VIOLATIONS=$((VIOLATIONS + 1))
            ;;
    esac
done

echo ""
echo "=== Summary ==="
echo "Files checked: $CHECKED"
if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✓ All files use correct content type${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $VIOLATIONS violation(s)${NC}"
    exit 1
fi
