#!/bin/bash
# cqa-02-assembly-structure.sh - Validates assembly structure compliance (CQA #2)
# Usage: ./cqa-02-assembly-structure.sh <file-path>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_FILE="${1:?Usage: $0 <file-path>}"

[[ $# -gt 1 ]] && { echo "Error: unexpected argument: $2" >&2; exit 1; }
[[ -f "$TARGET_FILE" ]] || { echo "Error: File not found: $TARGET_FILE" >&2; exit 1; }

# Get assembly files from the title's include tree
mapfile -t ASSEMBLY_FILES < <("$SCRIPT_DIR/list-all-included-files-starting-from.sh" "$TARGET_FILE" | tr ' ' '\n' | grep -v '^$' | grep -E "assemblies/.*\.adoc$|titles/.*/master\.adoc$" || true)

[[ ${#ASSEMBLY_FILES[@]} -gt 0 ]] || { echo "No assembly files found."; exit 0; }

echo "=== CQA #2: Verify Assembly Structure ==="
echo ""

TOTAL=0
VIOLATIONS=0

# Helper: get line number of first match after a given line
lineno() { grep -n "$1" "$2" | cut -d: -f1; }

for file in "${ASSEMBLY_FILES[@]}"; do
    [[ -f "$file" ]] || continue
    TOTAL=$((TOTAL + 1))
    V=0

    echo "Checking: $(basename "$file")"

    # Check 1: Content type must be ASSEMBLY (in first 5 lines)
    CT=$(head -5 "$file" | sed -n 's/:_mod-docs-content-type:[[:space:]]*//p' | tr -d '[:space:]')
    if [[ -z "$CT" ]]; then
        echo "  ✗ Missing :_mod-docs-content-type: ASSEMBLY"; V=$((V + 1))
    elif [[ "$CT" != "ASSEMBLY" ]]; then
        echo "  ✗ Content type is '$CT' (expected ASSEMBLY)"; V=$((V + 1))
    fi

    # Check 2: Has abstract
    grep -q '\[role="_abstract"\]' "$file" || { echo "  ✗ Missing [role=\"_abstract\"] introduction"; V=$((V + 1)); }

    # Check 3: Prerequisites must use == heading, not .block title
    grep -q "^\.Prerequisites" "$file" && { echo "  ✗ Uses .Prerequisites block title instead of == Prerequisites heading"; V=$((V + 1)); }

    # Check 4: No level 3+ subheadings
    grep -q "^===[[:space:]]" "$file" && { echo "  ✗ Contains level 3+ subheadings (=== or deeper)"; V=$((V + 1)); }

    # Find module include line numbers (after title, excluding artifacts/)
    TITLE_LN=$(lineno "^= " "$file" | head -1)
    if [[ -n "$TITLE_LN" ]]; then
        mapfile -t INCLUDE_LNS < <(tail -n +"$TITLE_LN" "$file" | grep -n "^include::" | grep -v "artifacts/" | cut -d: -f1 | while read -r n; do echo $((TITLE_LN + n - 1)); done)
    else
        INCLUDE_LNS=()
    fi

    if [[ ${#INCLUDE_LNS[@]} -gt 0 ]]; then
        FIRST_INC=${INCLUDE_LNS[0]}
        LAST_INC=${INCLUDE_LNS[-1]}

        # Check 5: Prerequisites must be before first include
        PREREQ_LN=$(lineno "^== Prerequisites" "$file" | head -1)
        [[ -n "$PREREQ_LN" && "$PREREQ_LN" -gt "$FIRST_INC" ]] && { echo "  ✗ Prerequisites appears after include statements"; V=$((V + 1)); }

        # Check 6: Additional resources must be after last include
        RES_LN=$(lineno "^\.Additional resources" "$file" | head -1)
        [[ -n "$RES_LN" && "$RES_LN" -lt "$LAST_INC" ]] && { echo "  ✗ .Additional resources appears before include statements"; V=$((V + 1)); }

        # Check 7: No content between includes
        if [[ "$FIRST_INC" != "$LAST_INC" ]]; then
            BETWEEN=$(sed -n "$((FIRST_INC + 1)),$((LAST_INC - 1))p" "$file" | \
                grep -v -E "^$|^include::|^//|^ifdef::|^ifndef::|^endif::|^\.Additional resources|^== " || true)
            [[ -n "$BETWEEN" ]] && { echo "  ✗ Content between include statements ($(echo "$BETWEEN" | wc -l) lines)"; V=$((V + 1)); }
        fi
    fi

    [[ $V -eq 0 ]] && echo "  ✓ Structure compliant" || VIOLATIONS=$((VIOLATIONS + V))
    echo ""
done

echo "=== Summary ==="
echo "Assemblies checked: $TOTAL"
[[ $VIOLATIONS -eq 0 ]] && { echo "✓ All assemblies have compliant structure"; exit 0; }
echo "✗ Found $VIOLATIONS violation(s)"
exit 1
