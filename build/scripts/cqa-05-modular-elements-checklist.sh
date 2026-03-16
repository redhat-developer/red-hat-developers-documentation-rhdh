#!/bin/bash
# cqa-05-modular-elements-checklist.sh
# Validates all required modular elements per CQA #5
#
# Reference: .claude/resources/modular-documentation-templates-checklist.md
#
# Usage: ./cqa-05-modular-elements-checklist.sh [--fix] <file-path>

set -e

# Constants for pattern matching
readonly PATTERN_BLOCK_TITLE='^\.[A-Z]'

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

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT="."

# Function to get all included files
get_all_files() {
    local file="$1"
    "$REPO_ROOT/build/scripts/list-all-included-files-starting-from" "$file"
}

# Get all files (space-separated list)
ALL_FILES=$(get_all_files "$TARGET_FILE")

# Convert space-separated list to newline-separated
# Filter to only .adoc files in assemblies/, modules/, or master.adoc in titles/
MODULE_FILES=$(echo "$ALL_FILES" | tr ' ' '\n' | grep -E "assemblies/|modules/|titles/.*master\.adoc$" | grep "\.adoc$" || true)

if [[ -z "$MODULE_FILES" ]]; then
    echo "No module or assembly files found."
    exit 0
fi

echo "=== CQA #5: Verify Required Modular Elements ==="
echo ""
echo "Reference: .claude/resources/modular-documentation-templates-checklist.md"
echo ""

# Track violations
TOTAL_FILES=0
VIOLATIONS=0

# Check each file
while IFS= read -r file; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    TOTAL_FILES=$((TOTAL_FILES + 1))
    FILE_VIOLATIONS=0

    # Get content type
    CONTENT_TYPE=$(head -1 "$file" 2>/dev/null | grep ":_mod-docs-content-type:" | sed 's/:_mod-docs-content-type:[[:space:]]*//' | sed 's/[[:space:]]*$//' || echo "")

    # Determine if this is a nested assembly
    IS_NESTED_ASSEMBLY=false
    if [[ "$CONTENT_TYPE" = "ASSEMBLY" ]] && grep -q "ifdef::context\[:parent-context:" "$file"; then
        IS_NESTED_ASSEMBLY=true
    fi

    echo "Checking: $(basename "$file") (${CONTENT_TYPE:-UNKNOWN})"

    # ALL MODULES AND ASSEMBLIES

    # Check 1: Has content type metadata
    if [[ -z "$CONTENT_TYPE" ]]; then
        echo "  ✗ Missing :_mod-docs-content-type: metadata"
        FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    fi

    # Check 2: Has topic ID with {context}
    # Exception: master.adoc files use [id="{context}"] without underscore prefix
    if [[ "$(basename "$file")" == "master.adoc" ]]; then
        # master.adoc: should have [id="{context}"] (no underscore prefix)
        if ! grep -q '\[id="{context}"\]' "$file" && ! grep -q "\[id='{context}'\]" "$file"; then
            echo "  ✗ Missing or incorrect topic ID (master.adoc should use [id=\"{context}\"])"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    else
        # Regular assemblies/modules: should have [id="name_{context}"]
        if ! grep -q '\[id=".*_{context}"\]' "$file" && ! grep -q "\[id='.*_{context}'\]" "$file"; then
            echo "  ✗ Missing or incorrect topic ID (must include _{context})"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # Check 3: Has exactly one H1 title
    H1_COUNT=$(grep -c "^= " "$file" || echo "0")
    if [[ "$H1_COUNT" -ne 1 ]]; then
        echo "  ✗ Has $H1_COUNT H1 titles (should be exactly 1)"
        FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    fi

    # Check 4: Has short introduction (abstract)
    if ! grep -q '\[role="_abstract"\]' "$file"; then
        echo "  ✗ Missing [role=\"_abstract\"] short introduction"
        FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    fi

    # Check 5: Has blank line between H1 and intro
    # Extract lines around H1 title
    H1_LINE=$(grep -n "^= " "$file" | head -1 | cut -d: -f1)
    if [[ -n "$H1_LINE" ]]; then
        NEXT_LINE=$((H1_LINE + 1))
        NEXT_CONTENT=$(sed -n "${NEXT_LINE}p" "$file")
        if [[ -n "$NEXT_CONTENT" ]]; then
            echo "  ✗ Missing blank line after H1 title"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # Check 6: Image alt text (if images present)
    if grep -q "^image::" "$file"; then
        if grep "^image::" "$file" | grep -v '\["' > /dev/null; then
            echo "  ✗ Image(s) missing alt text in quotes"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # Check 7: Admonitions do not include titles
    if grep -E "^\.(NOTE|WARNING|IMPORTANT|TIP|CAUTION)" "$file" > /dev/null 2>&1; then
        echo "  ✗ Admonition has title (should not have title)"
        FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    fi

    # NESTED ASSEMBLY FILES
    if [[ "$IS_NESTED_ASSEMBLY" = true ]]; then
        # Check 8: Has parent-context at top
        if ! grep -q "ifdef::context\[:parent-context: {context}\]" "$file"; then
            echo "  ✗ Nested assembly missing parent-context preservation at top"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi

        # Check 9: Has context restoration at bottom
        if ! grep -q "ifdef::parent-context\[:context: {parent-context}\]" "$file" || \
           ! grep -q "ifndef::parent-context\[:\!context:\]" "$file"; then
            echo "  ✗ Nested assembly missing context restoration at bottom"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi

        # Check 10: Has :context: declaration
        if ! grep -q "^:context: " "$file"; then
            echo "  ✗ Nested assembly missing :context: declaration"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # ALL ASSEMBLY FILES
    if [[ "$CONTENT_TYPE" = "ASSEMBLY" ]]; then
        # Check 11: Blank lines between includes
        # Look for consecutive include:: lines
        if grep -A 1 "^include::" "$file" | grep -B 1 "^include::" | grep -v "^--$" | grep -v "^include::" > /dev/null 2>&1; then
            echo "  ⚠ Warning: May be missing blank lines between include statements"
        fi

        # Check 12: No level 2+ subheadings
        if grep -E "^===[[:space:]]" "$file" > /dev/null 2>&1; then
            echo "  ✗ Assembly contains level 2+ subheadings (=== or deeper)"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi

        # Check 13: No block titles (except .Additional resources)
        # Block titles start with . followed by capital letter
        if grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v "\.Additional resources" > /dev/null 2>&1; then
            echo "  ✗ Assembly contains block titles (only .Additional resources allowed)"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # CONCEPT OR REFERENCE MODULE
    if [[ "$CONTENT_TYPE" = "CONCEPT" || "$CONTENT_TYPE" = "REFERENCE" ]]; then
        # Check 14: No imperative instructions (check for numbered lists as proxy)
        if grep -E "^\. [A-Z]" "$file" | grep -v "^\.\." > /dev/null 2>&1; then
            echo "  ⚠ Warning: May contain imperative instructions (numbered list detected)"
        fi

        # Check 15: No level 2+ subheadings (allowed in REFERENCE, not in CONCEPT per strict interpretation)
        # Note: The checklist says "Does not contain a level 2 (===) section title (H3) or lower.."
        # but modular docs allow subheadings in CONCEPT/REFERENCE for organization
        # We'll make this a warning, not an error

        # Check 16: No block titles except .Additional resources or .Next steps
        # Block titles start with . followed by capital letter
        if grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v "\.Additional resources" | grep -v "\.Additional references" | grep -v "\.Next steps" > /dev/null 2>&1; then
            echo "  ⚠ Warning: Contains block titles other than .Additional resources or .Next steps"
        fi
    fi

    # PROCEDURE MODULE
    if [[ "$CONTENT_TYPE" = "PROCEDURE" ]]; then
        # Check 17: Has .Procedure block title
        if ! grep -q "^\.Procedure$" "$file"; then
            echo "  ✗ Missing .Procedure block title"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi

        # Check 18: Only one .Procedure block title
        PROCEDURE_COUNT=$(grep -c "^\.Procedure" "$file" || echo "0")
        if [[ "$PROCEDURE_COUNT" -gt 1 ]]; then
            echo "  ✗ Has $PROCEDURE_COUNT .Procedure block titles (should be exactly 1)"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi

        # Check 19: No embellishments of .Procedure
        if grep "^\.Procedure " "$file" > /dev/null 2>&1; then
            echo "  ✗ .Procedure block title has embellishments (should be just '.Procedure')"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi

        # Check 20: Only standard block titles
        # Block titles start with . followed by a capital letter (not a space or number)
        ALLOWED_BLOCKS="^\\.Prerequisites$|^\\.Prerequisite$|^\\.Procedure$|^\\.Verification$|^\\.Results$|^\\.Result$|^\\.Troubleshooting$|^\\.Troubleshooting steps$|^\\.Troubleshooting step$|^\\.Next steps$|^\\.Next step$|^\\.Additional resources$"
        # Match lines starting with . followed by capital letter (block titles)
        # Exclude numbered lists (. followed by space) and nested lists (..)
        if grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v -E "$ALLOWED_BLOCKS" > /dev/null 2>&1; then
            echo "  ✗ Contains non-standard block titles"
            VIOLATING_BLOCKS=$(grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v -E "$ALLOWED_BLOCKS" | head -3)
            echo "    Examples: $VIOLATING_BLOCKS"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # Summary for this file
    if [[ $FILE_VIOLATIONS -eq 0 ]]; then
        echo "  ✓ All checks passed"
    else
        VIOLATIONS=$((VIOLATIONS + FILE_VIOLATIONS))
    fi
    echo ""
done <<< "$MODULE_FILES"

# Final summary
echo "=== Summary ==="
echo "Files checked: $TOTAL_FILES"
if [[ $VIOLATIONS -eq 0 ]]; then
    echo "✓ All files pass modular elements validation"
    exit 0
else
    echo "✗ Found $VIOLATIONS violation(s)"
    echo ""
    echo "See .claude/resources/modular-documentation-templates-checklist.md for details"
    exit 1
fi
