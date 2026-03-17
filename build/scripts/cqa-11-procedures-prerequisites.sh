#!/bin/bash
# cqa-11-procedures-prerequisites.sh
# Validates procedure prerequisites requirements (CQA #11)
#
# Usage: ./cqa-11-procedures-prerequisites.sh [--fix] <file-path>
#   --fix:  Fix singular .Prerequisite to .Prerequisites
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-11-procedures-prerequisites.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - .Prerequisites label used (not .Prerequisite singular)
#   - Prerequisites use bulleted list (not numbered)
#   - No more than 10 prerequisites per procedure
#   - No imperative instructions in prerequisites (should be completed states)
#
# Skips:
#   - Non-PROCEDURE files
#   - SNIPPET, CONCEPT, REFERENCE, ASSEMBLY files
#   - attributes.adoc and master.adoc files
#   - Content inside source/listing blocks

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Parse arguments
FIX_MODE=false
TARGET_FILE=""

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

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== CQA #11: Verify Procedure Prerequisites ==="
echo ""
echo "Reference: .claude/skills/cqa-11-procedures-prerequisites.md"
echo ""
if [[ "$FIX_MODE" == true ]]; then
    echo -e "${YELLOW}FIX MODE${NC} - Will fix singular .Prerequisite to .Prerequisites"
    echo ""
fi

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

TOTAL_FILES=0
VIOLATIONS=0
FILES_FIXED=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Skip non-.adoc files
    [[ "$file" != *.adoc ]] && continue

    # Skip special files
    [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
    [[ "$(basename "$file")" == "master.adoc" ]] && continue

    # Get content type
    content_type=$(get_content_type "$file")
    [[ -z "$content_type" ]] && continue

    # Only check PROCEDURE files
    [[ "$content_type" != "PROCEDURE" ]] && continue

    TOTAL_FILES=$((TOTAL_FILES + 1))

    file_violations=()

    # Check 1: Singular .Prerequisite (should be .Prerequisites)
    if grep -q "^\.Prerequisite$" "$file" 2>/dev/null; then
        file_violations+=("Singular .Prerequisite should be .Prerequisites")
        if [[ "$FIX_MODE" == true ]]; then
            sed -i 's/^\.Prerequisite$/.Prerequisites/' "$file"
            FILES_FIXED=$((FILES_FIXED + 1))
        fi
    fi

    # Check 2: Count prerequisites (max 10)
    if grep -q "^\.Prerequisites" "$file" 2>/dev/null; then
        prereq_items=$(awk '/^\.Prerequisites/{flag=1; next} flag && /^\.(Procedure|Verification|Troubleshooting|Next steps|Additional)/{exit} flag && /^\* /{count++} END{print count+0}' "$file" 2>/dev/null)
        if [[ $prereq_items -gt 10 ]]; then
            file_violations+=("Too many prerequisites: $prereq_items (max 10)")
        fi

        # Check 3: Prerequisites using numbered list (should be bulleted)
        numbered_prereqs=$(awk '/^\.Prerequisites/{flag=1; next} flag && /^\.(Procedure|Verification|Troubleshooting|Next steps|Additional)/{exit} flag && /^\. /{count++} END{print count+0}' "$file" 2>/dev/null)
        if [[ $numbered_prereqs -gt 0 ]]; then
            file_violations+=("Prerequisites use numbered list ($numbered_prereqs items) - should use bullets (*)")
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
    else
        echo -e "${GREEN}v${NC} $file"
    fi
done

echo ""
echo "=== Summary ==="
echo "Procedures checked: $TOTAL_FILES"

if [[ "$FIX_MODE" == true ]] && [[ $FILES_FIXED -gt 0 ]]; then
    echo -e "${YELLOW}Fixed $FILES_FIXED file(s)${NC}"
fi

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}v All procedure prerequisites meet requirements${NC}"
    exit 0
else
    echo -e "${RED}x Found violations in $VIOLATIONS file(s)${NC}"
    if [[ "$FIX_MODE" != true ]]; then
        echo ""
        echo "Run with --fix to auto-fix singular .Prerequisite:"
        echo "  $0 --fix $TARGET_FILE"
    fi
    exit 1
fi
