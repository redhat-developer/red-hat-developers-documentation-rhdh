#!/bin/bash
# cqa-02-assembly-structure.sh
# Validates assembly structure compliance (CQA #2)
#
# Reference: .claude/skills/cqa-02-assembly-structure.md
#
# Assemblies should contain only:
# 1. Introduction with [role="_abstract"]
# 2. Include statements for modules
# 3. Optional .Prerequisites before includes
# 4. Optional .Additional resources at end
#
# Usage: ./cqa-02-assembly-structure.sh [--fix] <file-path>

set -e

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
    "$REPO_ROOT/build/scripts/list-all-included-files-starting-from.sh" "$file"
}

# Get all files
ALL_FILES=$(get_all_files "$TARGET_FILE")

# Filter to only assembly files
ASSEMBLY_FILES=$(echo "$ALL_FILES" | tr ' ' '\n' | grep -E "assemblies/.*\.adoc$|titles/.*/master\.adoc$" || true)

if [[ -z "$ASSEMBLY_FILES" ]]; then
    echo "No assembly files found."
    exit 0
fi

echo "=== CQA #2: Verify Assembly Structure ==="
echo ""
echo "Reference: .claude/skills/cqa-02-assembly-structure.md"
echo ""
echo "Assemblies should contain only:"
echo "  - Introduction with [role=\"_abstract\"]"
echo "  - Include statements for modules"
echo "  - Optional .Prerequisites before includes"
echo "  - Optional .Additional resources at end"
echo ""

# Track violations
TOTAL_ASSEMBLIES=0
VIOLATIONS=0

# Check each assembly
while IFS= read -r file; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    TOTAL_ASSEMBLIES=$((TOTAL_ASSEMBLIES + 1))
    FILE_VIOLATIONS=0

    echo "Checking: $(basename "$file")"

    # Check 1: Has abstract
    if ! grep -q '\[role="_abstract"\]' "$file"; then
        echo "  ✗ Missing [role=\"_abstract\"] introduction"
        FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    fi

    # Check 2: Detect content between includes (DITA violation)
    # This is complex - we need to find text that appears after an include but before the next include
    # Strategy: Look for lines that are not:
    # - Empty lines
    # - Include statements
    # - Comment lines (//)
    # - Metadata lines (:...)
    # - Block titles (.Prerequisites, .Additional resources)
    # - Context management (ifdef, ifndef)

    # Extract the section after abstract and before any context restoration
    # Look for non-empty, non-include, non-metadata content between includes

    # Simple heuristic: Count paragraphs (non-empty lines that aren't special syntax)
    # Only check includes after the = title line (preamble includes like
    # include::artifacts/attributes.adoc[] are not subject to this rule)
    TITLE_LINE=$(grep -n "^= " "$file" | head -1 | cut -d: -f1 || echo "0")
    FIRST_INCLUDE_LINE=$(tail -n +"${TITLE_LINE:-1}" "$file" | grep -n "^include::" | head -1 | cut -d: -f1 || echo "0")
    if [[ "$FIRST_INCLUDE_LINE" != "0" && "$TITLE_LINE" != "0" ]]; then
        FIRST_INCLUDE_LINE=$((TITLE_LINE + FIRST_INCLUDE_LINE - 1))
    fi

    if [[ "$FIRST_INCLUDE_LINE" != "0" ]]; then
        # Get content after first include (post-title)
        CONTENT_AFTER_INCLUDES=$(tail -n +$((FIRST_INCLUDE_LINE + 1)) "$file")

        # Check for problematic content between includes
        # Problematic = paragraph text (not empty, not include, not block title, not metadata, not comment)
        SUSPECT_LINES=$(echo "$CONTENT_AFTER_INCLUDES" | grep -v "^$" | \
                                                         grep -v "^include::" | \
                                                         grep -v "^//" | \
                                                         grep -v "^:" | \
                                                         grep -v "^ifdef::" | \
                                                         grep -v "^ifndef::" | \
                                                         grep -v "^endif::" | \
                                                         grep -v "^\." | \
                                                         grep -v "^=" | \
                                                         grep -v "^\*" | \
                                                         grep -v "^-" | \
                                                         grep -v "^|" | \
                                                         grep -v "^\[" | \
                                                         grep -v "^----$" | \
                                                         grep -v "^====$" || true)

        if [[ -n "$SUSPECT_LINES" ]]; then
            SUSPECT_COUNT=$(echo "$SUSPECT_LINES" | wc -l)
            echo "  ⚠ Warning: May contain content between includes ($SUSPECT_COUNT lines)"
            echo "    Review for paragraphs/text between include statements"
        fi
    fi

    # Check 3: Prerequisites location (should be before first include if present)
    PREREQ_LINE=$(grep -n "^\.Prerequisites" "$file" | cut -d: -f1 || true)
    PREREQ_LINE=${PREREQ_LINE:-0}
    if [[ "$PREREQ_LINE" != "0" && "$FIRST_INCLUDE_LINE" != "0" ]]; then
        if [[ "$PREREQ_LINE" -gt "$FIRST_INCLUDE_LINE" ]]; then
            echo "  ✗ .Prerequisites appears after include statements"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # Check 4: Additional resources location (should be at end, after all includes if present)
    RESOURCES_LINE=$(grep -n "^\.Additional resources" "$file" | head -1 | cut -d: -f1 || true)
    RESOURCES_LINE=${RESOURCES_LINE:-0}
    LAST_INCLUDE_LINE=$(grep -n "^include::" "$file" | tail -1 | cut -d: -f1 || true)
    LAST_INCLUDE_LINE=${LAST_INCLUDE_LINE:-0}

    if [[ "$RESOURCES_LINE" != "0" && "$LAST_INCLUDE_LINE" != "0" ]]; then
        if [[ "$RESOURCES_LINE" -lt "$LAST_INCLUDE_LINE" ]]; then
            echo "  ✗ .Additional resources appears before include statements"
            FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
        fi
    fi

    # Check 5: Content type should be ASSEMBLY
    CONTENT_TYPE=$(head -20 "$file" | grep ":_mod-docs-content-type:" | sed 's/:_mod-docs-content-type:[[:space:]]*//' | sed 's/[[:space:]]*$//' || echo "")
    if [[ -n "$CONTENT_TYPE" && "$CONTENT_TYPE" != "ASSEMBLY" ]]; then
        echo "  ⚠ Warning: Content type is '$CONTENT_TYPE' (expected ASSEMBLY)"
    fi

    # Check 6: No level 2+ subheadings (assemblies shouldn't have === or deeper)
    if grep -q "^===[[:space:]]" "$file"; then
        echo "  ✗ Contains level 2+ subheadings (=== or deeper)"
        FILE_VIOLATIONS=$((FILE_VIOLATIONS + 1))
    fi

    # Check 7: No detailed lists/content after abstract (before first include)
    ABSTRACT_LINE=$(grep -n '\[role="_abstract"\]' "$file" | head -1 | cut -d: -f1 || echo "0")

    if [[ "$ABSTRACT_LINE" != "0" && "$FIRST_INCLUDE_LINE" != "0" ]]; then
        # Extract content between abstract and first include
        BETWEEN_ABSTRACT_AND_INCLUDE=$(sed -n "$((ABSTRACT_LINE + 2)),$((FIRST_INCLUDE_LINE - 1))p" "$file")

        # Check for problematic content (paragraphs, lists, but allow .Prerequisites)
        # Remove .Prerequisites section and check what remains
        FILTERED=$(echo "$BETWEEN_ABSTRACT_AND_INCLUDE" | \
                  grep -v "^\.Prerequisites" | \
                  grep -v "^$" | \
                  grep -v "^\*" | \
                  grep -v "^-" | \
                  grep -v "^:" | \
                  grep -v "^//" || true)

        if [[ -n "$FILTERED" ]]; then
            NON_EMPTY=$(echo "$FILTERED" | grep -v "^$" || true)
            if [[ -n "$NON_EMPTY" ]]; then
                echo "  ⚠ Warning: May contain detailed content between abstract and includes"
                echo "    Review for explanatory text that should be in a concept module"
            fi
        fi
    fi

    # Summary for this file
    if [[ $FILE_VIOLATIONS -eq 0 ]]; then
        echo "  ✓ Structure compliant"
    else
        VIOLATIONS=$((VIOLATIONS + FILE_VIOLATIONS))
    fi
    echo ""
done <<< "$ASSEMBLY_FILES"

# Final summary
echo "=== Summary ==="
echo "Assemblies checked: $TOTAL_ASSEMBLIES"

if [[ $VIOLATIONS -eq 0 ]]; then
    echo "✓ All assemblies have compliant structure"
    echo ""
    echo "Note: Warnings indicate potential issues that require manual review"
    echo "See .claude/skills/cqa-02-assembly-structure.md for guidance"
    exit 0
else
    echo "✗ Found $VIOLATIONS violation(s)"
    echo ""
    echo "Common fixes:"
    echo "  - Move detailed content to concept modules"
    echo "  - Remove text between include statements"
    echo "  - Move .Prerequisites before first include"
    echo "  - Remove subheadings from assemblies"
    echo ""
    echo "See .claude/skills/cqa-02-assembly-structure.md for details"
    exit 1
fi
