#!/bin/bash
# cqa-03-content-is-modularized.sh - Validates content type metadata (CQA #3)
# Usage: ./cqa-03-content-is-modularized.sh [--fix] <file-path>

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
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

[[ -n "$TARGET_FILE" ]] || { echo "Usage: $0 [--fix] <file-path>" >&2; exit 1; }
[[ -f "$TARGET_FILE" ]] || { echo "Error: File not found: $TARGET_FILE" >&2; exit 1; }

# Detect content type from file content and filename
detect_content_type() {
    local file="$1"
    local bn
    bn=$(basename "$file" .adoc)

    # Content-based detection first
    if grep -q "^include::" "$file" 2>/dev/null && grep "^include::" "$file" | grep -qE "(proc-|ref-|con-)"; then
        echo "ASSEMBLY"; return
    fi
    if grep -q "^\.Procedure" "$file" 2>/dev/null; then
        echo "PROCEDURE"; return
    fi

    # Filename-based detection
    case "$bn" in
        assembly-*|master) echo "ASSEMBLY" ;;
        proc-*)            echo "PROCEDURE" ;;
        con-*)             echo "CONCEPT" ;;
        ref-*)             echo "REFERENCE" ;;
        snip-*)            echo "SNIPPET" ;;
        attributes)        echo "SNIPPET" ;;
        *)                 echo "" ;;
    esac
}

# Get current content type from first line
get_current_type() {
    local first_line
    first_line=$(head -1 "$1" 2>/dev/null)
    if [[ "$first_line" =~ ^:_mod-docs-content-type:[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# Count occurrences of content type metadata
count_type_occurrences() {
    grep -c "^:_mod-docs-content-type:" "$1" 2>/dev/null || echo "0"
}

# Fix content type metadata: ensure correct type on first line, remove duplicates
fix_content_type() {
    local file="$1" type="$2"
    if [[ "$FIX_MODE" == true ]]; then
        sed -i '/^:_mod-docs-content-type:/d' "$file"
        sed -i "1s/^/:_mod-docs-content-type: ${type}\n\n/" "$file"
    fi
}

# Fix list formatting in a section (.Procedure or .Verification)
# $1=file $2=section name (e.g., "Procedure" or "Verification")
fix_section_lists() {
    local file="$1" section="$2"

    grep -q "^\.${section}" "$file" 2>/dev/null || return 1

    local after
    after=$(awk "/^\\.${section}\$/{flag=1; next} flag && /^\\.(Prerequisites|Procedure|Verification|Troubleshooting|Next steps|Additional)/{exit} flag" "$file" 2>/dev/null)

    local includes unnumbered nested numbered
    includes=$(echo "$after" | grep -c "^include::" || true)
    unnumbered=$(echo "$after" | grep -c "^\* " || true)
    nested=$(echo "$after" | grep -c "^\*\* " || true)
    numbered=$(echo "$after" | grep -cE "^\\.+ " || true)

    # Skip files with includes
    [[ $includes -gt 0 ]] && return 1

    local fix_type=""
    if [[ $numbered -eq 1 && $unnumbered -eq 0 ]]; then
        fix_type="single-to-unnumbered"
    elif [[ $unnumbered -ge 1 && $numbered -ge 1 && $nested -eq 0 ]]; then
        fix_type="mixed-to-numbered"
    elif [[ $unnumbered -ge 2 && $numbered -eq 0 && $nested -eq 0 ]]; then
        fix_type="unnumbered-to-numbered"
    fi

    [[ -z "$fix_type" ]] && return 1

    if [[ "$FIX_MODE" == true ]]; then
        case "$fix_type" in
            single-to-unnumbered)
                sed -i "/^\.${section}/,/^[^[:space:]]/{s/^\(\.\.\?\.* \)/* /}" "$file" ;;
            mixed-to-numbered|unnumbered-to-numbered)
                sed -i "/^\.${section}\$/,/^\.(Prerequisites|Procedure|Verification|Troubleshooting|Next steps|Additional)/{/^\./!s/^\* /. /}" "$file" ;;
        esac
    fi

    case "$fix_type" in
        single-to-unnumbered)   echo "  * Convert single numbered step in .${section} to unnumbered item" ;;
        mixed-to-numbered)      echo "  * Convert mixed list formatting in .${section} to numbered steps" ;;
        unnumbered-to-numbered) echo "  * Convert multiple unnumbered items in .${section} to numbered steps" ;;
    esac
    return 0
}

# Validate PROCEDURE structure
validate_procedure() {
    local file="$1"
    if ! grep -q "^\.Procedure" "$file" 2>/dev/null; then
        echo "  ⚠ Missing .Procedure section"
        return
    fi

    local after
    after=$(awk '/^\.Procedure$/{flag=1; next} flag && /^\.(Prerequisites|Verification|Troubleshooting|Next steps|Additional)/{exit} flag' "$file" 2>/dev/null)

    local includes numbered unnumbered
    includes=$(echo "$after" | grep -c "^include::" || true)
    unnumbered=$(echo "$after" | grep -c "^\* " || true)
    numbered=$(echo "$after" | grep -cE "^\\.+ " || true)

    if [[ $includes -eq 0 && $numbered -eq 1 && $unnumbered -eq 0 ]]; then
        echo "  ⚠ .Procedure has only 1 numbered step (should be multiple or 1 unnumbered)"
    fi
}

# ── Main ──

echo "=== CQA #3: Verify Content Type Metadata ==="
echo ""
[[ "$FIX_MODE" == true ]] && echo "FIX MODE - Will apply automatic fixes" && echo ""

# Collect files using shared script
mapfile -t FILES < <("$SCRIPT_DIR/list-all-included-files-starting-from.sh" "$TARGET_FILE" | tr ' ' '\n' | grep -v '^$')

echo "Processing ${#FILES[@]} file(s) from: $TARGET_FILE"
echo ""

PROCESSED=0 COMPLIANT=0 CHANGED=0

for file in "${FILES[@]}"; do
    [[ -f "$file" ]] || continue
    PROCESSED=$((PROCESSED + 1))

    detected=$(detect_content_type "$file")
    if [[ -z "$detected" ]]; then
        echo "? $(basename "$file") (cannot determine content type)"
        continue
    fi

    current=$(get_current_type "$file")
    occurrences=$(count_type_occurrences "$file")
    needs_fix=false

    # Check if metadata is correct
    if [[ "$current" != "$detected" ]] || [[ "$occurrences" -ne 1 ]]; then
        needs_fix=true
    fi

    if [[ "$needs_fix" == true ]]; then
        CHANGED=$((CHANGED + 1))
        if [[ "$FIX_MODE" == true ]]; then
            echo "📝 $(basename "$file")"
        else
            echo "✗ $(basename "$file")"
        fi

        if [[ -z "$current" && "$occurrences" -eq 0 ]]; then
            echo "  + Add :_mod-docs-content-type: ${detected}"
        elif [[ -z "$current" && "$occurrences" -gt 0 ]]; then
            echo "  * Move content type to first line"
        elif [[ "$current" != "$detected" ]]; then
            echo "  * Content type: ${current} → ${detected}"
        fi
        [[ "$occurrences" -gt 1 ]] && echo "  * Remove $((occurrences - 1)) duplicate(s)"

        fix_content_type "$file" "$detected"
    else
        COMPLIANT=$((COMPLIANT + 1))
    fi

    # Fix and validate section lists for PROCEDURE files
    if [[ "$detected" == "PROCEDURE" ]]; then
        fix_section_lists "$file" "Procedure" || true
        fix_section_lists "$file" "Verification" || true
        validate_procedure "$file"
    fi
done

echo ""
echo "=== Summary ==="
echo "Files processed: $PROCESSED"
echo "Compliant: $COMPLIANT"

if [[ $CHANGED -gt 0 ]]; then
    if [[ "$FIX_MODE" == true ]]; then
        echo "✓ Updated $CHANGED file(s)"
    else
        echo "✗ Found $CHANGED file(s) with issues"
        echo ""
        echo "Run with --fix to apply automatic fixes:"
        echo "  $0 --fix $TARGET_FILE"
    fi
fi
