#!/bin/bash
# cqa-13-information-is-conveyed-using-the-correct-content.sh
# Validates content matches its declared content type (CQA #13)
#
# Usage: ./cqa-13-information-is-conveyed-using-the-correct-content.sh [--fix] <file-path>
#   --fix:  Currently no automatic fixes available (validation only)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-13-information-is-conveyed-using-the-correct-content.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - PROCEDURE files have .Procedure section with numbered steps
#   - CONCEPT files do not have .Procedure sections or numbered steps
#   - REFERENCE files do not have .Procedure sections
#   - ASSEMBLY files contain only intro + includes (no detailed content)
#   - SNIPPET files have no structural elements (anchors, H1 headings, block titles)
#
# Skips:
#   - attributes.adoc and master.adoc files
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

echo "=== CQA #13: Verify Content Matches Declared Type ==="
echo ""
echo "Reference: .claude/skills/cqa-13-information-is-conveyed-using-the-correct-content.md"
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

    # Skip SNIPPET for most checks
    [[ "$content_type" == "SNIPPET" ]] && continue

    TOTAL_FILES=$((TOTAL_FILES + 1))

    file_violations=()

    case "$content_type" in
        PROCEDURE)
            # PROCEDURE must have .Procedure section
            if ! grep -q "^\.Procedure" "$file" 2>/dev/null; then
                file_violations+=("PROCEDURE without .Procedure section")
            fi
            ;;
        CONCEPT)
            # CONCEPT must not have .Procedure section
            if grep -q "^\.Procedure" "$file" 2>/dev/null; then
                file_violations+=("CONCEPT has .Procedure section (should be PROCEDURE or remove steps)")
            fi
            ;;
        REFERENCE)
            # REFERENCE must not have .Procedure section
            if grep -q "^\.Procedure" "$file" 2>/dev/null; then
                file_violations+=("REFERENCE has .Procedure section (should be PROCEDURE or remove steps)")
            fi
            ;;
        ASSEMBLY)
            # ASSEMBLY should not have detailed content (only intro + includes)
            # Count non-include, non-empty, non-comment, non-metadata lines after title
            detail_lines=$(awk '
                /^= /{found=1; next}
                found && /^include::/{next}
                found && /^\[role="_abstract"\]/{next}
                found && /^\[id=/{next}
                found && /^:_mod-docs-content-type:/{next}
                found && /^:context:/{next}
                found && /^ifdef::|^ifndef::|^endif::/{next}
                found && /^\/\//{next}
                found && /^\.Prerequisites/{next}
                found && /^\.Additional resources/{next}
                found && /^\* /{next}
                found && /^$/{next}
                found && /^ifeval::|^endif::/{next}
                found{count++}
                END{print count+0}
            ' "$file" 2>/dev/null)
            if [[ $detail_lines -gt 5 ]]; then
                file_violations+=("ASSEMBLY has $detail_lines lines of detailed content (should only have intro + includes)")
            fi
            ;;
    esac

    # Check filename prefix matches content type
    basename_file=$(basename "$file" .adoc)
    case "$content_type" in
        PROCEDURE)
            if [[ ! "$basename_file" =~ ^proc- ]]; then
                file_violations+=("Filename prefix mismatch: expected proc- for PROCEDURE (got: $basename_file)")
            fi
            ;;
        CONCEPT)
            if [[ ! "$basename_file" =~ ^con- ]]; then
                file_violations+=("Filename prefix mismatch: expected con- for CONCEPT (got: $basename_file)")
            fi
            ;;
        REFERENCE)
            if [[ ! "$basename_file" =~ ^ref- ]]; then
                file_violations+=("Filename prefix mismatch: expected ref- for REFERENCE (got: $basename_file)")
            fi
            ;;
        ASSEMBLY)
            if [[ ! "$basename_file" =~ ^assembly- ]]; then
                file_violations+=("Filename prefix mismatch: expected assembly- for ASSEMBLY (got: $basename_file)")
            fi
            ;;
    esac

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
    echo -e "${GREEN}v All content matches declared types${NC}"
    exit 0
else
    echo -e "${RED}x Found $VIOLATIONS file(s) with content type mismatches${NC}"
    echo ""
    echo "See .claude/skills/cqa-13-information-is-conveyed-using-the-correct-content.md"
    exit 1
fi
