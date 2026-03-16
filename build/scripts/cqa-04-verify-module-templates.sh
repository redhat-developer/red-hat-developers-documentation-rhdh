#!/bin/bash
# cqa-04-verify-module-templates.sh
# Verify modules use official Red Hat modular documentation templates (CQA requirement #4)
#
# Usage: ./cqa-04-verify-module-templates.sh [--fix] <file-path>
#   --fix:  Apply automatic fixes where possible
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-04-verify-module-templates.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - PROCEDURE modules must not have custom subheadings (===)
#   - PROCEDURE modules must have a .Procedure section
#   - PROCEDURE modules must have .Prerequisites (not .Prerequisite)
#   - All modules must have an intro paragraph after the title
#   - CONCEPT modules must not have numbered steps
#
# Skips:
#   - ASSEMBLY and SNIPPET files
#   - master.adoc and attributes.adoc files

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

# Pre-compute source block ranges for a file
declare -A BLOCK_RANGES

compute_block_ranges() {
    local file="$1"

    if [[ -n "${BLOCK_RANGES[$file]+x}" ]]; then
        return
    fi

    local ranges=""
    local in_block=false
    local block_start=0
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^----+$ ]] || [[ "$line" =~ ^\.\.\.\.+$ ]]; then
            if [[ "$in_block" == false ]]; then
                in_block=true
                block_start=$line_num
            else
                in_block=false
                ranges="$ranges $block_start:$line_num"
            fi
        fi
    done < "$file"

    BLOCK_RANGES[$file]="$ranges"
}

is_in_block() {
    local file="$1"
    local line_num="$2"

    local ranges="${BLOCK_RANGES[$file]}"
    for range in $ranges; do
        local start end
        start="${range%%:*}"
        end="${range##*:}"
        if [[ $line_num -ge $start ]] && [[ $line_num -le $end ]]; then
            return 0
        fi
    done
    return 1
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

echo "=== CQA #4: Verify Module Templates ==="
echo ""
echo "Reference: .claude/skills/cqa-04-modules-use-official-templates.md"
echo ""
if [[ "$FIX_MODE" == true ]]; then
    echo -e "${YELLOW}FIX MODE${NC} - Will apply automatic fixes where possible"
    echo ""
fi

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

TOTAL_VIOLATIONS=0
FILES_WITH_VIOLATIONS=0
FILES_CHECKED=0
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

    # Skip ASSEMBLY and SNIPPET
    [[ "$content_type" == "ASSEMBLY" ]] && continue
    [[ "$content_type" == "SNIPPET" ]] && continue

    FILES_CHECKED=$((FILES_CHECKED + 1))
    compute_block_ranges "$file"

    file_violations=()

    # === Check 1: PROCEDURE modules must not have custom subheadings (===) ===
    if [[ "$content_type" == "PROCEDURE" ]]; then
        while IFS=: read -r line_num line_content; do
            [[ -z "$line_num" ]] && continue
            if is_in_block "$file" "$line_num"; then
                continue
            fi
            file_violations+=("Line $line_num: Custom subheading in PROCEDURE (not allowed): $line_content")
        done < <(grep -n "^=== " "$file" 2>/dev/null || true)
    fi

    # === Check 2: PROCEDURE modules must have .Procedure section ===
    if [[ "$content_type" == "PROCEDURE" ]]; then
        if ! grep -q "^\.Procedure" "$file" 2>/dev/null; then
            file_violations+=("Missing .Procedure section (required for PROCEDURE modules)")
        fi
    fi

    # === Check 3: .Prerequisite should be .Prerequisites (plural) ===
    if [[ "$content_type" == "PROCEDURE" ]]; then
        while IFS=: read -r line_num line_content; do
            [[ -z "$line_num" ]] && continue
            if is_in_block "$file" "$line_num"; then
                continue
            fi
            # Only flag singular .Prerequisite, not .Prerequisites
            if [[ "$line_content" == ".Prerequisite" ]]; then
                file_violations+=("Line $line_num: .Prerequisite should be .Prerequisites (plural)")
            fi
        done < <(grep -n "^\.Prerequisite$" "$file" 2>/dev/null || true)
    fi

    # === Check 4: All modules must have an intro paragraph ===
    # Check for [role="_abstract"] marker
    if ! grep -q '\[role="_abstract"\]' "$file" 2>/dev/null; then
        file_violations+=("Missing [role=\"_abstract\"] intro paragraph after title")
    fi

    # === Check 5: CONCEPT modules must not have numbered steps ===
    if [[ "$content_type" == "CONCEPT" ]]; then
        if grep -q "^\.Procedure" "$file" 2>/dev/null; then
            file_violations+=("CONCEPT module has .Procedure section (move to a PROCEDURE module)")
        fi
    fi

    # Report results
    if [[ ${#file_violations[@]} -gt 0 ]]; then
        FILES_WITH_VIOLATIONS=$((FILES_WITH_VIOLATIONS + 1))
        TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + ${#file_violations[@]}))

        echo -e "${RED}x${NC} $file [$content_type]"
        for violation in "${file_violations[@]}"; do
            echo "  $violation"
        done

        if [[ "$FIX_MODE" == true ]]; then
            local_fixed=false

            # Fix: .Prerequisite → .Prerequisites
            if grep -q "^\.Prerequisite$" "$file" 2>/dev/null; then
                sed -i 's/^\.Prerequisite$/.Prerequisites/' "$file"
                local_fixed=true
                echo -e "  ${YELLOW}Fixed:${NC} .Prerequisite -> .Prerequisites"
            fi

            if [[ "$local_fixed" == true ]]; then
                FILES_FIXED=$((FILES_FIXED + 1))
            fi
        fi
        echo ""
    else
        echo -e "${GREEN}v${NC} $file [$content_type]"
    fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $FILES_CHECKED"

if [[ "$FIX_MODE" == true ]] && [[ $FILES_FIXED -gt 0 ]]; then
    echo -e "${YELLOW}Fixed $FILES_FIXED file(s)${NC}"
    echo ""
    echo "Review fixes and verify manually:"
    echo "  - Custom subheadings in PROCEDURE must be removed manually"
    echo "  - Missing .Procedure sections must be added manually"
    echo "  - Missing [role=\"_abstract\"] intro must be added manually"
    exit 0
elif [[ $TOTAL_VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}v All modules follow official templates${NC}"
    exit 0
else
    echo -e "${RED}x Found $TOTAL_VIOLATIONS violation(s) in $FILES_WITH_VIOLATIONS file(s)${NC}"
    echo ""
    echo "Run with --fix to apply automatic fixes (singular .Prerequisite):"
    echo "  $0 --fix $TARGET_FILE"
    echo ""
    echo "Manual fixes required for:"
    echo "  - Custom subheadings in PROCEDURE: remove or convert to standard sections"
    echo "  - Missing .Procedure section: add .Procedure followed by numbered steps"
    echo "  - Missing intro paragraph: add [role=\"_abstract\"] paragraph after title"
    exit 1
fi
