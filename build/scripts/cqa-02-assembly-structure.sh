#!/bin/bash
# cqa-02-assembly-structure.sh - Validates assembly structure compliance (CQA #2)
# Usage: ./cqa-02-assembly-structure.sh [--fix] <file-path>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

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

# Get assembly files from the title's include tree
mapfile -t ASSEMBLY_FILES < <("$SCRIPT_DIR/list-all-included-files-starting-from.sh" "$TARGET_FILE" | tr ' ' '\n' | grep -v '^$' | grep -E "assemblies/.*\.adoc$|titles/.*/master\.adoc$" || true)

[[ ${#ASSEMBLY_FILES[@]} -gt 0 ]] || { echo "No assembly files found."; exit 0; }

echo "=== CQA #2: Assembly Structure — $TARGET_FILE ==="
[[ "$FIX_MODE" == true ]] && echo "FIX MODE - Will apply automatic fixes"

TOTAL=0
VIOLATIONS=0
FIXED=0

# Helper: get line number of first match
lineno() { grep -n "$1" "$2" | cut -d: -f1; }

# Fix helpers
fix_content_type_first_line() {
    local file="$1"
    # Remove all content type lines, then insert on first line
    sed -i '/^:_mod-docs-content-type:/d' "$file"
    sed -i '1s/^/:_mod-docs-content-type: ASSEMBLY\n/' "$file"
    echo "  >> Fixed: content type on first line"
    FIXED=$((FIXED + 1))
}

fix_remove_duplicate_content_type() {
    local file="$1"
    # Keep only the first occurrence
    awk '/^:_mod-docs-content-type:/ && ++n > 1 {next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "  >> Fixed: removed duplicate content type lines"
    FIXED=$((FIXED + 1))
}

fix_add_context_save() {
    local file="$1"
    # Insert context save on line 2 (after content type on line 1)
    sed -i '1a\ifdef::context[:parent-context: {context}]' "$file"
    echo "  >> Fixed: added context save on line 2"
    FIXED=$((FIXED + 1))
}

fix_add_context_restore() {
    local file="$1"
    # Remove existing partial context restore lines at end
    sed -i '/^ifdef::parent-context\[:context: {parent-context}\]$/d' "$file"
    sed -i '/^ifndef::parent-context\[:!context:\]$/d' "$file"
    # Remove trailing blank lines
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$file"
    # Append context restore
    printf '\nifdef::parent-context[:context: {parent-context}]\nifndef::parent-context[:!context:]\n' >> "$file"
    echo "  >> Fixed: added context restore as last lines"
    FIXED=$((FIXED + 1))
}

fix_remove_duplicate_context_save() {
    local file="$1"
    # Keep only the first ifdef::context[:parent-context line
    awk '/^ifdef::context\[:parent-context/ && ++n > 1 {next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "  >> Fixed: removed duplicate context save lines"
    FIXED=$((FIXED + 1))
}

fix_remove_duplicate_context_restore() {
    local file="$1"
    # Remove all occurrences, then re-add at the end via fix_add_context_restore
    sed -i '/^ifdef::parent-context\[:context: {parent-context}\]$/d' "$file"
    sed -i '/^ifndef::parent-context\[:!context:\]$/d' "$file"
    # Remove trailing blank lines
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$file"
    printf '\nifdef::parent-context[:context: {parent-context}]\nifndef::parent-context[:!context:]\n' >> "$file"
    echo "  >> Fixed: removed duplicate context restore lines"
    FIXED=$((FIXED + 1))
}

fix_id_add_context_suffix() {
    local file="$1"
    # Find [id="..."] that doesn't end with _{context}"] and add the suffix
    sed -i 's/\[id="\([^"]*[^}]\)"\]/[id="\1_{context}"]/' "$file"
    echo "  >> Fixed: added _{context} suffix to ID"
    FIXED=$((FIXED + 1))
}

fix_context_line() {
    local file="$1"
    local title_ln="$2"
    # Remove any existing :context: lines
    sed -i '/^:context:/d' "$file"
    # Derive value from ID (strip _{context} suffix)
    local id_value
    id_value=$(grep -m1 '\[id="' "$file" | sed 's/.*\[id="\([^"]*\)".*/\1/' | sed 's/_{context}$//')
    if [[ -n "$id_value" ]]; then
        sed -i "${title_ln}a\\\\n:context: ${id_value}" "$file"
        echo "  >> Fixed: set :context: ${id_value} after title"
        FIXED=$((FIXED + 1))
    fi
}

fix_prerequisites_heading() {
    local file="$1"
    sed -i 's/^\.Prerequisites$/== Prerequisites/' "$file"
    echo "  >> Fixed: .Prerequisites -> == Prerequisites"
    FIXED=$((FIXED + 1))
}

fix_additional_resources() {
    local file="$1"
    # Convert .Additional resources block title to [role="_additional-resources"] + == heading
    if grep -q '^\.Additional resources' "$file"; then
        sed -i 's/^\.Additional resources$/[role="_additional-resources"]\n== Additional resources/' "$file"
        echo "  >> Fixed: .Additional resources -> [role=\"_additional-resources\"] == Additional resources"
        FIXED=$((FIXED + 1))
    # Add missing role attribute before existing == Additional resources heading
    elif grep -q '^== Additional resources' "$file"; then
        sed -i '/^== Additional resources/i\[role="_additional-resources"]' "$file"
        echo "  >> Fixed: added [role=\"_additional-resources\"] before == Additional resources"
        FIXED=$((FIXED + 1))
    fi
}

for file in "${ASSEMBLY_FILES[@]}"; do
    [[ -f "$file" ]] || continue
    TOTAL=$((TOTAL + 1))
    V=0
    IS_MASTER=$([[ "$(basename "$file")" == "master.adoc" ]] && echo true || echo false)

    echo "Checking: $(basename "$file")"

    # Check 1: Content type must be ASSEMBLY on first line, not repeated
    FIRST_LINE=$(sed -n '1p' "$file")
    if [[ "$FIRST_LINE" != ":_mod-docs-content-type: ASSEMBLY" ]]; then
        CT=$(grep -m1 '^:_mod-docs-content-type:' "$file" | sed 's/:_mod-docs-content-type:[[:space:]]*//' | tr -d '[:space:]')
        if [[ -z "$CT" ]]; then
            echo "  ✗ Missing :_mod-docs-content-type: ASSEMBLY on first line"
        elif [[ "$CT" != "ASSEMBLY" ]]; then
            echo "  ✗ Content type is '$CT' (expected ASSEMBLY)"
        else
            echo "  ✗ :_mod-docs-content-type: ASSEMBLY must be on first line"
        fi
        V=$((V + 1))
        [[ "$FIX_MODE" == true ]] && fix_content_type_first_line "$file"
    fi
    CT_COUNT=$(grep -c '^:_mod-docs-content-type:' "$file" || true)
    if [[ $CT_COUNT -gt 1 ]]; then
        echo "  ✗ :_mod-docs-content-type: appears $CT_COUNT times (must not be repeated)"
        V=$((V + 1))
        [[ "$FIX_MODE" == true ]] && fix_remove_duplicate_content_type "$file"
    fi

    # Check 2: Has abstract
    grep -q '\[role="_abstract"\]' "$file" || { echo "  ✗ Missing [role=\"_abstract\"] introduction"; V=$((V + 1)); }

    # Check 3: Introduction length (50-300 chars, skip master.adoc which uses :abstract: attribute)
    if [[ "$IS_MASTER" == false ]]; then
        ABSTRACT_LN=$(lineno '\[role="_abstract"\]' "$file" | head -1)
        if [[ -n "$ABSTRACT_LN" ]]; then
            INTRO=$(sed -n "$((ABSTRACT_LN + 1))p" "$file")
            INTRO_LEN=${#INTRO}
            if [[ $INTRO_LEN -lt 50 ]]; then
                echo "  ⚠ Introduction too short (${INTRO_LEN} chars, recommend 50-300)"
            elif [[ $INTRO_LEN -gt 300 ]]; then
                echo "  ⚠ Introduction too long (${INTRO_LEN} chars, recommend 50-300)"
            fi
        fi
    fi

    # Check 4: Has ID with _{context} (skip for title-level master.adoc)
    if [[ "$IS_MASTER" == false ]]; then
        if ! grep -q '\[id=".*_{context}"\]' "$file"; then
            # Check if there's an [id="..."] without _{context}
            if grep -q '\[id="[^"]*"\]' "$file"; then
                echo "  ✗ ID missing _{context} suffix"
                V=$((V + 1))
                [[ "$FIX_MODE" == true ]] && fix_id_add_context_suffix "$file"
            else
                echo "  ✗ Missing [id=\"..._\{context\}\"] attribute"
                V=$((V + 1))
            fi
        fi
    fi

    # Check 5: :context: must be set after title, separated by a blank line (skip master.adoc)
    CONTEXT_LN=$(lineno "^:context:" "$file" | head -1)
    NEED_CTX_FIX=false
    if [[ -z "$CONTEXT_LN" ]]; then
        echo "  ✗ Missing :context: attribute"; V=$((V + 1))
        NEED_CTX_FIX=true
    elif [[ "$IS_MASTER" == false ]]; then
        TITLE_LN_CHK=$(lineno "^= " "$file" | head -1)
        if [[ -n "$TITLE_LN_CHK" ]]; then
            if [[ "$CONTEXT_LN" -le "$TITLE_LN_CHK" ]]; then
                echo "  ✗ :context: must appear after the title (= ...)"; V=$((V + 1))
                NEED_CTX_FIX=true
            else
                LINE_AFTER_TITLE=$(sed -n "$((TITLE_LN_CHK + 1))p" "$file")
                if [[ -n "$LINE_AFTER_TITLE" ]]; then
                    echo "  ✗ Missing blank line between title and :context:"; V=$((V + 1))
                    NEED_CTX_FIX=true
                fi
            fi
        fi
    fi
    if [[ "$FIX_MODE" == true && "$NEED_CTX_FIX" == true && "$IS_MASTER" == false ]]; then
        TITLE_LN_CHK=$(lineno "^= " "$file" | head -1)
        [[ -n "$TITLE_LN_CHK" ]] && fix_context_line "$file" "$TITLE_LN_CHK"
    fi

    # Check 6: Context save/restore required, not repeated (skip master.adoc — title-level entry point)
    if [[ "$IS_MASTER" == false ]]; then
        SECOND_LINE=$(sed -n '2p' "$file")
        if [[ "$SECOND_LINE" != ifdef::context* ]]; then
            echo "  ✗ Missing context save on line 2 (ifdef::context[:parent-context: {context}])"
            V=$((V + 1))
            [[ "$FIX_MODE" == true ]] && fix_add_context_save "$file"
        fi
        SAVE_COUNT=$(grep -c "^ifdef::context\[:parent-context" "$file" || true)
        if [[ $SAVE_COUNT -gt 1 ]]; then
            echo "  ✗ Context save appears $SAVE_COUNT times (must not be repeated)"; V=$((V + 1))
            [[ "$FIX_MODE" == true ]] && fix_remove_duplicate_context_save "$file"
        fi

        LAST_LINE=$(tail -1 "$file")
        PENULT_LINE=$(tail -2 "$file" | head -1)
        NEED_RESTORE=false
        if [[ "$PENULT_LINE" != 'ifdef::parent-context[:context: {parent-context}]' ]]; then
            echo "  ✗ Second-to-last line must be: ifdef::parent-context[:context: {parent-context}]"
            V=$((V + 1)); NEED_RESTORE=true
        fi
        if [[ "$LAST_LINE" != 'ifndef::parent-context[:!context:]' ]]; then
            echo "  ✗ Last line must be: ifndef::parent-context[:!context:]"
            V=$((V + 1)); NEED_RESTORE=true
        fi
        RESTORE_COUNT=$(grep -c "^ifdef::parent-context\[:context: {parent-context}\]" "$file" || true)
        if [[ $RESTORE_COUNT -gt 1 ]]; then
            echo "  ✗ Context restore appears $RESTORE_COUNT times (must not be repeated)"; V=$((V + 1))
            [[ "$FIX_MODE" == true ]] && fix_remove_duplicate_context_restore "$file"
        elif [[ "$FIX_MODE" == true && "$NEED_RESTORE" == true ]]; then
            fix_add_context_restore "$file"
        fi
    fi

    # Check 7: Prerequisites must use == heading, not .block title
    if grep -q "^\.Prerequisites" "$file"; then
        echo "  ✗ Uses .Prerequisites block title instead of == Prerequisites heading"
        V=$((V + 1))
        [[ "$FIX_MODE" == true ]] && fix_prerequisites_heading "$file"
    fi

    # Check 7b: Prerequisites must be followed by unnumbered list or include
    PREREQ_HEADING_LN=$(lineno "^== Prerequisites" "$file" | head -1)
    if [[ -n "$PREREQ_HEADING_LN" ]]; then
        # Find first non-empty line after == Prerequisites
        PREREQ_FIRST=$(awk "NR>$PREREQ_HEADING_LN && /^[^[:space:]]/ && !/^$/{print; exit}" "$file")
        if [[ -n "$PREREQ_FIRST" && "$PREREQ_FIRST" != "* "* && "$PREREQ_FIRST" != include::* ]]; then
            echo "  ✗ == Prerequisites must be followed by an unnumbered list (* ) or include::"; V=$((V + 1))
        fi

        # Check 7c: Prerequisites count (max 10)
        PREREQ_ITEMS=$(awk "NR>$PREREQ_HEADING_LN && /^== /{exit} NR>$PREREQ_HEADING_LN && /^\* /{n++} END{print n+0}" "$file")
        [[ $PREREQ_ITEMS -gt 10 ]] && { echo "  ⚠ Prerequisites has $PREREQ_ITEMS items (max 10 recommended)"; }
    fi

    # Check 8: No level 3+ subheadings
    grep -q "^===[[:space:]]" "$file" && { echo "  ✗ Contains level 3+ subheadings (=== or deeper)"; V=$((V + 1)); }

    # Check 9: Additional resources must use [role="_additional-resources"] + == heading
    NEED_AR_FIX=false
    if grep -q "^\.Additional resources" "$file"; then
        echo "  ✗ Uses .Additional resources block title (must use [role=\"_additional-resources\"] + == heading)"
        V=$((V + 1)); NEED_AR_FIX=true
    elif grep -q "^== Additional resources" "$file"; then
        if ! grep -q '\[role="_additional-resources"\]' "$file"; then
            echo "  ✗ == Additional resources heading missing [role=\"_additional-resources\"] attribute"
            V=$((V + 1)); NEED_AR_FIX=true
        fi
    fi
    [[ "$FIX_MODE" == true && "$NEED_AR_FIX" == true ]] && fix_additional_resources "$file"

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

        # Check 10: Prerequisites must be before first include
        PREREQ_LN=$(lineno "^== Prerequisites" "$file" | head -1)
        [[ -n "$PREREQ_LN" && "$PREREQ_LN" -gt "$FIRST_INC" ]] && { echo "  ✗ Prerequisites appears after include statements"; V=$((V + 1)); }

        # Check 11: Additional resources must be after last include
        RES_LN=$(grep -n "^\(\.Additional resources\|== Additional resources\)" "$file" | head -1 | cut -d: -f1)
        [[ -n "$RES_LN" && "$RES_LN" -lt "$LAST_INC" ]] && { echo "  ✗ Additional resources appears before include statements"; V=$((V + 1)); }

        # Check 12: No content between includes
        if [[ "$FIRST_INC" != "$LAST_INC" ]]; then
            BETWEEN=$(sed -n "$((FIRST_INC + 1)),$((LAST_INC - 1))p" "$file" | \
                grep -v -E "^$|^include::|^//|^ifdef::|^ifndef::|^endif::|^\[role=|^\.Additional resources|^== " || true)
            [[ -n "$BETWEEN" ]] && { echo "  ✗ Content between include statements ($(echo "$BETWEEN" | wc -l) lines)"; V=$((V + 1)); }
        fi
    fi

    [[ $V -eq 0 ]] && echo "  ✓ Structure compliant" || VIOLATIONS=$((VIOLATIONS + V))
    echo ""
done

echo "=== Summary ==="
echo "Assemblies checked: $TOTAL"
if [[ $VIOLATIONS -eq 0 ]]; then
    echo "✓ All assemblies have compliant structure"
    exit 0
fi
if [[ "$FIX_MODE" == true ]]; then
    echo "✓ Applied $FIXED fix(es) for $VIOLATIONS violation(s)"
    echo ""
    echo "Re-run without --fix to verify remaining issues."
else
    echo "✗ Found $VIOLATIONS violation(s)"
    echo ""
    echo "Run with --fix to apply automatic fixes:"
    echo "  $0 --fix $TARGET_FILE"
fi
exit 1
