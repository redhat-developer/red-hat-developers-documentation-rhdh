#!/bin/bash
# Fix content type metadata based on file content analysis (CQA requirement #11)
#
# Usage: ./fix-content-type.sh [file]
#   file: Optional. If provided, fixes that file and all its includes recursively
#         Example: ./fix-content-type.sh titles/install-rhdh-ocp/master.adoc
#           Processes: master.adoc → assemblies → all included modules (recursive)
#         If not provided, processes all .adoc files in the repository
#
# Content type detection logic:
# - ASSEMBLY: File includes one or more modules with proc-, ref-, or con- prefix
# - PROCEDURE: File has .Procedure section followed by one or more steps
#
# This script automatically adds or updates :_mod-docs-content-type: metadata

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

        # Normalize and make relative to repo root
        if [[ -f "$resolved_path" ]]; then
            # Make path relative to REPO_ROOT
            local normalized_path
            normalized_path=$(realpath --relative-to="$REPO_ROOT" "$resolved_path" 2>/dev/null) || normalized_path="$resolved_path"
            echo "$normalized_path"
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

# Function to detect content type from file content
detect_content_type() {
    local file="$1"

    # Check if file includes modules with proc-, ref-, or con- prefix
    # This makes it an ASSEMBLY
    if grep "^include::" "$file" 2>/dev/null | grep -qE "include::.*(proc-|ref-|con-)"; then
        echo "ASSEMBLY"
        return
    fi

    # Check if file has .Procedure section followed by steps
    # Steps are lines starting with one or more dots followed by space (. .. ...)
    if grep -q "^\.Procedure" "$file" 2>/dev/null; then
        # Check for steps after .Procedure section
        if grep -A 50 "^\.Procedure" "$file" | grep -qE "^\.\.* "; then
            echo "PROCEDURE"
            return
        fi
    fi

    # Cannot determine - return empty
    echo ""
}

# Function to get current content type from file
get_current_content_type() {
    local file="$1"
    grep "^:_mod-docs-content-type:" "$file" 2>/dev/null | sed 's/^:_mod-docs-content-type: *//' | sed 's/ *$//' || echo ""
}

# Function to process a single file
process_file() {
    local FILE="$1"

    # Detect content type from content
    local DETECTED_TYPE
    DETECTED_TYPE=$(detect_content_type "$FILE")

    # Skip if we can't detect a type
    if [[ -z "$DETECTED_TYPE" ]]; then
        echo "? $FILE (cannot determine content type)"
        return 0
    fi

    # Get current content type
    local CURRENT_TYPE
    CURRENT_TYPE=$(get_current_content_type "$FILE")

    # Check if change is needed
    if [[ "$CURRENT_TYPE" == "$DETECTED_TYPE" ]]; then
        echo "✓ $FILE ($DETECTED_TYPE)"
        return 0
    fi

    # Changes needed - show header
    echo ""
    echo "📝 $FILE"

    # Apply content type metadata
    if [[ -z "$CURRENT_TYPE" ]]; then
        # Add new metadata at the beginning
        sed -i.bak "1s/^/:_mod-docs-content-type: ${DETECTED_TYPE}\n\n/" "$FILE"
        rm -f "${FILE}.bak"
        echo "  + Added :_mod-docs-content-type: ${DETECTED_TYPE}"
    else
        # Update existing metadata
        sed -i.bak "s/^:_mod-docs-content-type:.*/:_mod-docs-content-type: ${DETECTED_TYPE}/" "$FILE"
        rm -f "${FILE}.bak"
        echo "  * Content type: ${CURRENT_TYPE} → ${DETECTED_TYPE}"
    fi

    echo ""
}

# Color codes for summary
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== Fix Content Type Metadata Based on File Content ==="
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

# Process each file
PROCESSED=0
CHANGED=0

for file in "${FILES_TO_PROCESS[@]}"; do
    PROCESSED=$((PROCESSED + 1))

    # Check if file was modified (by checking if it shows a change message)
    OUTPUT=$(process_file "$file")
    echo "$OUTPUT"

    if [[ "$OUTPUT" == *"📝"* ]]; then
        CHANGED=$((CHANGED + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "Files processed: $PROCESSED"
if [[ $CHANGED -eq 0 ]]; then
    echo -e "${GREEN}✓ No changes needed${NC}"
else
    echo -e "${GREEN}✓ Updated $CHANGED file(s)${NC}"
fi
