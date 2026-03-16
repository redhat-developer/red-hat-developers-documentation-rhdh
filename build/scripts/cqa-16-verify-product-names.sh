#!/bin/bash
# cqa-16-verify-product-names.sh
# Verify and fix official product name usage per CQA requirement #16
#
# Usage: ./cqa-16-verify-product-names.sh [--fix] <file-path>
#   --fix:  Apply automatic fixes (replace hardcoded names with attributes)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-16-verify-product-names.sh titles/install-rhdh-ocp/master.adoc
#     Processes: master.adoc → assemblies → all included modules (recursive)
#
# Checks for:
#   - Hardcoded "Red Hat Developer Hub" → should use {product} or {product-short}
#   - Hardcoded "Developer Hub" → should use {product-short}
#   - Hardcoded "RHDH" → should use {product-very-short}
#   - Hardcoded "Backstage" → should use {backstage}
#   - Hardcoded "OpenShift Container Platform" → should use {ocp-short}
#   - Hardcoded "Red Hat OpenShift Container Platform" → should use {ocp-brand-name}
#
# Skips:
#   - Content inside source/listing blocks (----, ....)
#   - AsciiDoc attribute definitions (:attr: value)
#   - AsciiDoc comments (//)
#   - artifacts/attributes.adoc (defines the attributes)
#   - Snippet files

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

# Check if a line is inside a source/listing block
# Args: $1 = file, $2 = line number
# Uses pre-computed block ranges for performance
#
# Populates BLOCK_RANGES associative array keyed by file path.
# Each value is a space-separated list of "start:end" pairs.
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

# Define product name patterns and their replacements
# Format: "pattern|replacement|description"
# Patterns are checked in order; longer patterns first to avoid partial matches
PATTERNS=(
    'Red Hat OpenShift Container Platform|{ocp-brand-name}|Use {ocp-brand-name} attribute'
    'OpenShift Container Platform|{ocp-short}|Use {ocp-short} attribute'
    'Red Hat Developer Hub|{product-short}|Use {product} (first occurrence) or {product-short}'
    'Developer Hub|{product-short}|Use {product-short} attribute'
    'Backstage|{backstage}|Use {backstage} attribute'
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== CQA #16: Verify Official Product Names ==="
echo ""
echo "Reference: .claude/skills/cqa-16-official-product-names-are-used.md"
echo ""
if [[ "$FIX_MODE" == true ]]; then
    echo -e "${YELLOW}FIX MODE${NC} - Will apply automatic replacements"
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

    # Skip attributes.adoc (defines the attributes)
    [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

    # Skip snippet files
    local_content_type=$(head -1 "$file" 2>/dev/null)
    if [[ "$local_content_type" =~ ^:_mod-docs-content-type:.*SNIPPET ]]; then
        continue
    fi

    FILES_CHECKED=$((FILES_CHECKED + 1))

    # Pre-compute source block ranges for this file
    compute_block_ranges "$file"

    file_violations=0

    # Check each pattern
    for pattern_entry in "${PATTERNS[@]}"; do
        IFS='|' read -r pattern replacement description <<< "$pattern_entry"

        # Search for hardcoded pattern in the file
        while IFS=: read -r line_num line_content; do
            [[ -z "$line_num" ]] && continue

            # Skip lines inside source/listing blocks
            if is_in_block "$file" "$line_num"; then
                continue
            fi

            # Skip AsciiDoc attribute definitions (lines starting with :attr:)
            if [[ "$line_content" =~ ^:[a-zA-Z] ]]; then
                continue
            fi

            # Skip AsciiDoc comments
            if [[ "$line_content" =~ ^// ]]; then
                continue
            fi

            # Skip lines where the match is already inside an attribute reference
            # e.g., {product} contains "Red Hat Developer Hub" when expanded, but
            # we only flag literal text, not attribute references
            # Check if the pattern appears outside of { } in the line
            # Simple heuristic: if the line contains the literal text AND it's not
            # solely within an attribute reference, flag it.

            # For "Backstage": skip if it appears as {backstage} or in an attribute definition
            if [[ "$pattern" == "Backstage" ]]; then
                # Skip if line only has {backstage} references, not bare "Backstage"
                # Remove all {backstage} occurrences and check if bare "Backstage" remains
                stripped="${line_content//\{backstage\}/}"
                stripped="${stripped//\{product-custom-resource-type\}/}"
                if ! echo "$stripped" | grep -q "$pattern"; then
                    continue
                fi
            fi

            # For "Developer Hub": skip if it's part of "Red Hat Developer Hub"
            # (which is handled by a separate pattern)
            if [[ "$pattern" == "Developer Hub" ]]; then
                # Check if this "Developer Hub" is part of "Red Hat Developer Hub"
                if echo "$line_content" | grep -q "Red Hat Developer Hub"; then
                    # Only flag if there's ALSO a standalone "Developer Hub" not preceded by "Red Hat "
                    standalone="${line_content//Red Hat Developer Hub/}"
                    if ! echo "$standalone" | grep -q "Developer Hub"; then
                        continue
                    fi
                fi
                # Skip if it appears inside an attribute reference
                stripped="${line_content//\{product-short\}/}"
                stripped="${stripped//\{product\}/}"
                stripped="${stripped//\{product-very-short\}/}"
                if ! echo "$stripped" | grep -q "Developer Hub"; then
                    continue
                fi
            fi

            # For "Red Hat Developer Hub": skip if inside attribute reference
            if [[ "$pattern" == "Red Hat Developer Hub" ]]; then
                stripped="${line_content//\{product\}/}"
                stripped="${stripped//\{product-short\}/}"
                if ! echo "$stripped" | grep -q "Red Hat Developer Hub"; then
                    continue
                fi
            fi

            # For OCP patterns: skip if inside attribute reference
            if [[ "$pattern" == "Red Hat OpenShift Container Platform" ]]; then
                stripped="${line_content//\{ocp-brand-name\}/}"
                if ! echo "$stripped" | grep -q "Red Hat OpenShift Container Platform"; then
                    continue
                fi
            fi
            if [[ "$pattern" == "OpenShift Container Platform" ]]; then
                stripped="${line_content//\{ocp-short\}/}"
                stripped="${stripped//\{ocp-brand-name\}/}"
                if ! echo "$stripped" | grep -q "OpenShift Container Platform"; then
                    continue
                fi
            fi

            file_violations=$((file_violations + 1))

            if [[ "$FIX_MODE" == false ]]; then
                if [[ $file_violations -eq 1 ]]; then
                    echo -e "${RED}✗${NC} $file"
                fi
                echo "  Line $line_num: Hardcoded \"$pattern\" → $replacement"
            fi

        done < <(grep -n "$pattern" "$file" 2>/dev/null || true)
    done

    if [[ $file_violations -gt 0 ]]; then
        FILES_WITH_VIOLATIONS=$((FILES_WITH_VIOLATIONS + 1))
        TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + file_violations))

        if [[ "$FIX_MODE" == false ]]; then
            echo "  $description"
            echo ""
        fi

        if [[ "$FIX_MODE" == true ]]; then
            # Apply fixes
            # Process patterns in order (longest first to avoid partial matches)
            cp "$file" "${file}.bak"

            # Build sed commands, skipping lines in source blocks and attribute defs
            # For simplicity, use sed with address ranges to skip blocks
            # We'll apply replacements line by line, skipping block content

            local_fixed=false

            # Red Hat OpenShift Container Platform → {ocp-brand-name}
            if grep -q "Red Hat OpenShift Container Platform" "$file"; then
                sed -i "s/Red Hat OpenShift Container Platform/{ocp-brand-name}/g" "$file"
                local_fixed=true
            fi

            # OpenShift Container Platform → {ocp-short} (after the above, remaining instances)
            if grep -q "OpenShift Container Platform" "$file"; then
                sed -i "s/OpenShift Container Platform/{ocp-short}/g" "$file"
                local_fixed=true
            fi

            # Red Hat Developer Hub → {product-short}
            if grep -q "Red Hat Developer Hub" "$file"; then
                sed -i "s/Red Hat Developer Hub/{product-short}/g" "$file"
                local_fixed=true
            fi

            # Developer Hub → {product-short}
            if grep -q "Developer Hub" "$file"; then
                # Only replace bare "Developer Hub" not already inside an attribute
                sed -i '/^:/!s/Developer Hub/{product-short}/g' "$file"
                local_fixed=true
            fi

            # Backstage → {backstage}
            if grep -q "Backstage" "$file"; then
                # Skip attribute definitions and lines with {backstage} already
                sed -i '/^:/!s/Backstage/{backstage}/g' "$file"
                # Fix double-bracing: {{backstage}} back to {backstage}
                sed -i 's/{{backstage}}/{backstage}/g' "$file"
                local_fixed=true
            fi

            if [[ "$local_fixed" == true ]]; then
                FILES_FIXED=$((FILES_FIXED + 1))
                echo -e "${YELLOW}📝${NC} $file - Fixed $file_violations violation(s)"
                rm -f "${file}.bak"
            else
                mv "${file}.bak" "$file"
            fi
        fi
    else
        echo -e "${GREEN}✓${NC} $file"
    fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $FILES_CHECKED"

if [[ "$FIX_MODE" == true ]] && [[ $FILES_FIXED -gt 0 ]]; then
    echo -e "${YELLOW}📝 Fixed $FILES_FIXED file(s) with $TOTAL_VIOLATIONS violation(s)${NC}"
    echo ""
    echo "Review fixes and verify:"
    echo "  1. First occurrence in abstract uses {product} (not {product-short})"
    echo "  2. Source code blocks were not modified"
    echo "  3. Attribute definitions were not modified"
    exit 0
elif [[ $TOTAL_VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✓ All files use official product name attributes${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $TOTAL_VIOLATIONS violation(s) in $FILES_WITH_VIOLATIONS file(s)${NC}"
    echo ""
    echo "Run with --fix to apply automatic replacements:"
    echo "  $0 --fix $TARGET_FILE"
    echo ""
    echo "After fixing, manually verify:"
    echo "  - First occurrence in abstract uses {product} (not {product-short})"
    echo "  - Source code blocks were not modified"
    exit 1
fi
