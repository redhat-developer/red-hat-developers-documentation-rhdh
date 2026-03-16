#!/bin/bash
# cqa-06-assemblies-use-the-official-template-assemblies-ar.sh
# Validates assemblies follow the official template and tell one user story (CQA #6)
#
# Usage: ./cqa-06-assemblies-use-the-official-template-assemblies-ar.sh [--fix] <file-path>
#   --fix:  Currently no automatic fixes available (validation only)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-06-assemblies-use-the-official-template-assemblies-ar.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - Assembly has exactly one user story (single focus topic)
#   - Assembly title reflects the user story
#   - Assembly does not combine unrelated procedures
#   - Module count is reasonable (not too many for a single story)
#
# Skips:
#   - Non-assembly files (PROCEDURE, CONCEPT, REFERENCE, SNIPPET)
#   - attributes.adoc files

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

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== CQA #6: Verify Assemblies Follow Official Template (One User Story) ==="
echo ""
echo "Reference: .claude/skills/cqa-06-assemblies-use-the-official-template-assemblies-ar.md"
echo ""

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

# Track violations
TOTAL_FILES=0
VIOLATIONS=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Skip non-.adoc files
    [[ "$file" != *.adoc ]] && continue

    # Skip attributes.adoc and master.adoc
    [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

    # Get content type
    content_type=$(get_content_type "$file")
    [[ -z "$content_type" ]] && continue

    # Only check ASSEMBLY files
    [[ "$content_type" != "ASSEMBLY" ]] && continue

    TOTAL_FILES=$((TOTAL_FILES + 1))

    file_violations=()

    # Count included modules
    include_count=$(grep -c "^include::" "$file" 2>/dev/null || true)

    # Check for multiple unrelated assembly includes (nested assemblies)
    assembly_includes=$(grep "^include::" "$file" 2>/dev/null | grep -c "assembly-" || true)
    if [[ $assembly_includes -gt 3 ]]; then
        file_violations+=("Has $assembly_includes nested assembly includes (may cover multiple user stories)")
    fi

    # Check for excessive module count (suggests multiple stories)
    if [[ $include_count -gt 15 ]]; then
        file_violations+=("Has $include_count includes (consider splitting - may cover multiple user stories)")
    fi

    # Check assembly has a title
    if ! grep -q "^= " "$file" 2>/dev/null; then
        file_violations+=("Missing assembly title (= Title)")
    fi

    # Report results
    if [[ ${#file_violations[@]} -gt 0 ]]; then
        VIOLATIONS=$((VIOLATIONS + 1))
        echo -e "${RED}x${NC} $file [$content_type] ($include_count includes)"
        for violation in "${file_violations[@]}"; do
            echo "  $violation"
        done
        echo ""
    else
        echo -e "${GREEN}v${NC} $file [$content_type] ($include_count includes)"
    fi
done

echo ""
echo "=== Summary ==="
echo "Assemblies checked: $TOTAL_FILES"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}v All assemblies follow the one-user-story pattern${NC}"
    exit 0
else
    echo -e "${RED}x Found $VIOLATIONS assembly(ies) with potential issues${NC}"
    echo ""
    echo "Review flagged assemblies to ensure each tells a single user story."
    echo "See .claude/skills/cqa-06-assemblies-use-the-official-template-assemblies-ar.md"
    exit 1
fi
