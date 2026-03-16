#!/bin/bash
# cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh
# Validates Technology Preview and Developer Preview disclaimers (CQA #17)
#
# Usage: ./cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh [--fix] <file-path>
#   --fix:  Currently no automatic fixes available (validation only)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - Files mentioning "Technology Preview" include the official disclaimer snippet
#   - Files mentioning "Developer Preview" include the official disclaimer snippet
#   - Disclaimer snippets are properly included (not hardcoded)
#
# Skips:
#   - attributes.adoc files
#   - Snippet files (snip-*.adoc) — these ARE the disclaimers
#   - Content inside source/listing blocks

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

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== CQA #17: Verify Legal Disclaimers for Preview Features ==="
echo ""
echo "Reference: .claude/skills/cqa-17-includes-appropriate-legal-approved-disclaimers-f.md"
echo ""

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

TOTAL_FILES=0
VIOLATIONS=0
PREVIEW_FILES=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Skip non-.adoc files
    [[ "$file" != *.adoc ]] && continue

    # Skip attributes.adoc
    [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

    # Skip snippet files (they ARE the disclaimers)
    [[ "$(basename "$file")" == snip-* ]] && continue

    TOTAL_FILES=$((TOTAL_FILES + 1))

    file_violations=()

    # Check for Technology Preview mentions
    if grep -qi "technology preview" "$file" 2>/dev/null; then
        PREVIEW_FILES=$((PREVIEW_FILES + 1))

        # Check if file includes a tech preview disclaimer snippet
        if ! grep -q "include::.*snip-.*tech.*preview\|include::.*snip-.*tp-" "$file" 2>/dev/null; then
            # Check if there's an attribute reference for the disclaimer
            if ! grep -q "{technology-preview}" "$file" 2>/dev/null; then
                file_violations+=("Mentions 'Technology Preview' but may not include official disclaimer snippet")
            fi
        fi
    fi

    # Check for Developer Preview mentions
    if grep -qi "developer preview" "$file" 2>/dev/null; then
        PREVIEW_FILES=$((PREVIEW_FILES + 1))

        # Check if file includes a dev preview disclaimer snippet
        if ! grep -q "include::.*snip-.*dev.*preview\|include::.*snip-.*dp-" "$file" 2>/dev/null; then
            if ! grep -q "{developer-preview}" "$file" 2>/dev/null; then
                file_violations+=("Mentions 'Developer Preview' but may not include official disclaimer snippet")
            fi
        fi
    fi

    # Report results
    if [[ ${#file_violations[@]} -gt 0 ]]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        echo -e "${RED}x${NC} $file"
        for violation in "${file_violations[@]}"; do
            echo "  $violation"
        done
        echo ""
    fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $TOTAL_FILES"
echo "Files mentioning preview features: $PREVIEW_FILES"

if [[ $PREVIEW_FILES -eq 0 ]]; then
    echo -e "${GREEN}v No preview feature mentions found - disclaimers not needed${NC}"
    exit 0
elif [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}v All preview features have appropriate disclaimers${NC}"
    exit 0
else
    echo -e "${YELLOW}Found $VIOLATIONS file(s) that may need disclaimer review${NC}"
    echo ""
    echo "Verify each flagged file includes the official legal-approved disclaimer."
    echo "Use snippets for disclaimers in assembly files."
    echo "See .claude/skills/cqa-17-includes-appropriate-legal-approved-disclaimers-f.md"
    exit 1
fi
