#!/bin/bash
# cqa-08-short-description-content.sh
# Validates short description content quality (CQA #8)
#
# Usage: ./cqa-08-short-description-content.sh [--fix] <file-path>
#   --fix:  Currently no automatic fixes available (validation only)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-08-short-description-content.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - No self-referential language ("This section...", "This document...")
#   - Abstract present (has [role="_abstract"] marker)
#
# Skips:
#   - SNIPPET files
#   - attributes.adoc and master.adoc files

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Parse arguments
FIX_MODE=false
TARGET_FILE=""

# shellcheck disable=SC2034
for arg in "$@"; do
    case "$arg" in
        --fix) FIX_MODE=true ;;
        *)
            if [[ -z "$TARGET_FILE" ]]; then
                TARGET_FILE="$arg"
            else
                echo "Error: unexpected argument: $arg" >&2
                echo "Usage: $0 [--fix] <file-path>" >&2
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$TARGET_FILE" ]]; then
    echo "Usage: $0 [--fix] <file-path>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 titles/install-rhdh-ocp/master.adoc" >&2
    echo "  $0 --fix titles/install-rhdh-ocp/master.adoc" >&2
    exit 1
fi

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

# Get content type from first line of file
get_content_type() {
    local file="$1"
    local first_line
    first_line=$(head -1 "$file" 2>/dev/null)
    if [[ "$first_line" =~ ^:_mod-docs-content-type:[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# Self-referential patterns to detect
SELF_REF_PATTERNS=(
    "This section"
    "This document"
    "This chapter"
    "This guide"
    "This module"
    "This assembly"
    "This topic"
    "The following section"
    "The following document"
    "Here we"
    "Here you will"
    "In this section"
    "In this document"
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== CQA #8: Verify Short Description Content Quality ==="
echo ""
echo "Reference: .claude/skills/cqa-08-short-description-content.md"
echo ""

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

TOTAL_FILES=0
VIOLATIONS=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Skip non-.adoc files
    [[ "$file" != *.adoc ]] && continue

    # Skip special files
    [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
    [[ "$(basename "$file")" == "master.adoc" ]] && continue

    # Get content type
    content_type=$(get_content_type "$file")
    [[ -z "$content_type" ]] && continue

    # Skip SNIPPET
    [[ "$content_type" == "SNIPPET" ]] && continue

    TOTAL_FILES=$((TOTAL_FILES + 1))

    file_violations=()

    # Check for [role="_abstract"] marker
    if ! grep -q '\[role="_abstract"\]' "$file" 2>/dev/null; then
        file_violations+=("Missing [role=\"_abstract\"] marker")
    else
        # Extract the abstract text (line after [role="_abstract"])
        abstract_text=$(awk '/\[role="_abstract"\]/{getline; print}' "$file" 2>/dev/null)

        # Check for self-referential language in abstract
        for pattern in "${SELF_REF_PATTERNS[@]}"; do
            if echo "$abstract_text" | grep -qi "$pattern" 2>/dev/null; then
                file_violations+=("Self-referential language in abstract: \"$pattern\"")
            fi
        done

        # Also check if abstract is empty
        if [[ -z "$abstract_text" ]] || [[ "$abstract_text" =~ ^[[:space:]]*$ ]]; then
            file_violations+=("Empty abstract (no text after [role=\"_abstract\"])")
        fi
    fi

    # Check for self-referential language anywhere in the first 10 lines after title
    intro_text=$(awk '/^= /{found=1; next} found && NR<=15{print}' "$file" 2>/dev/null)
    for pattern in "${SELF_REF_PATTERNS[@]}"; do
        if echo "$intro_text" | grep -qi "$pattern" 2>/dev/null; then
            # Only flag if not already caught in abstract check
            already_flagged=false
            for v in "${file_violations[@]}"; do
                if [[ "$v" == *"$pattern"* ]]; then
                    already_flagged=true
                    break
                fi
            done
            if [[ "$already_flagged" == false ]]; then
                file_violations+=("Self-referential language in intro: \"$pattern\"")
            fi
        fi
    done

    # Report results
    if [[ ${#file_violations[@]} -gt 0 ]]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        echo -e "${RED}x${NC} $file [$content_type]"
        for violation in "${file_violations[@]}"; do
            echo "  $violation"
        done
        echo ""
    else
        echo -e "${GREEN}v${NC} $file [$content_type]"
    fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $TOTAL_FILES"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}v All short descriptions meet content quality requirements${NC}"
    exit 0
else
    echo -e "${RED}x Found $VIOLATIONS file(s) with content quality issues${NC}"
    echo ""
    echo "See .claude/skills/cqa-08-short-description-content.md for guidelines"
    exit 1
fi
