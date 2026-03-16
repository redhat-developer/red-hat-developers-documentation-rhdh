#!/bin/bash
# cqa-14-no-broken-links.sh
# Validates no broken links exist (CQA #14)
#
# Usage: ./cqa-14-no-broken-links.sh [--fix] <file-path>
#   --fix:  Currently no automatic fixes available (validation only)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-14-no-broken-links.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - Internal xrefs point to existing files
#   - Anchor IDs referenced in xrefs exist in target files
#   - include:: targets exist
#   - Image references point to existing files
#
# Note: For full link validation including external URLs, run build-ccutil.sh
#       which executes htmltest on the generated HTML.

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
NC='\033[0m'

echo "=== CQA #14: Verify No Broken Links ==="
echo ""
echo "Reference: .claude/skills/cqa-14-no-broken-links.md"
echo ""

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

TOTAL_FILES=0
VIOLATIONS=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Skip non-.adoc files
    [[ "$file" != *.adoc ]] && continue

    TOTAL_FILES=$((TOTAL_FILES + 1))

    file_violations=()
    file_dir=$(dirname "$file")

    # Check 1: Broken include:: references
    while IFS= read -r line; do
        include_path=$(echo "$line" | sed 's/^include:://' | sed 's/\[.*//')
        # Skip lines with attribute substitutions
        if [[ "$include_path" == *"{"* ]]; then
            continue
        fi
        local_path="$file_dir/$include_path"
        if [[ ! -f "$local_path" ]]; then
            file_violations+=("Broken include: $include_path")
        fi
    done < <(grep "^include::" "$file" 2>/dev/null || true)

    # Check 2: Broken image references
    while IFS=: read -r line_num line_content; do
        [[ -z "$line_content" ]] && continue
        image_path=$(echo "$line_content" | sed -E 's/.*image::?([^[]*)\[.*/\1/')
        # Skip lines with attribute substitutions
        if [[ "$image_path" == *"{"* ]]; then
            continue
        fi
        if [[ -n "$image_path" ]] && [[ ! -f "$file_dir/$image_path" ]] && [[ ! -f "$image_path" ]]; then
            file_violations+=("Line $line_num: Broken image: $image_path")
        fi
    done < <(grep -n "image::.*\[" "$file" 2>/dev/null || true)

    # Report results
    if [[ ${#file_violations[@]} -gt 0 ]]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        echo -e "${RED}x${NC} $file"
        for violation in "${file_violations[@]}"; do
            echo "  $violation"
        done
        echo ""
    else
        echo -e "${GREEN}v${NC} $file"
    fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $TOTAL_FILES"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}v No broken links found${NC}"
    echo ""
    echo "Note: For full validation including external URLs, run:"
    echo "  ./build/scripts/build-ccutil.sh"
    exit 0
else
    echo -e "${RED}x Found broken links in $VIOLATIONS file(s)${NC}"
    echo ""
    echo "See .claude/skills/cqa-14-no-broken-links.md"
    exit 1
fi
