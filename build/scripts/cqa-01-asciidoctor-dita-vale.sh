#!/bin/bash
# cqa-01-asciidoctor-dita-vale.sh - Validates AsciiDoc DITA compliance using Vale (CQA #1)
# Usage: ./cqa-01-asciidoctor-dita-vale.sh [--fix] [--output line|JSON] <file-path>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_FORMAT="line"
FIX_MODE=false
TARGET_FILE=""

for arg in "$@"; do
    case "$arg" in
        --fix) FIX_MODE=true ;;
        --output) OUTPUT_FORMAT="__NEXT__" ;;
        *)
            if [[ "$OUTPUT_FORMAT" == "__NEXT__" ]]; then
                OUTPUT_FORMAT="$arg"
            elif [[ -z "$TARGET_FILE" ]]; then
                TARGET_FILE="$arg"
            else
                echo "Error: unexpected argument: $arg" >&2
                echo "Usage: $0 [--fix] [--output line|JSON] <file-path>" >&2
                exit 1
            fi
            ;;
    esac
done

[[ -n "$TARGET_FILE" ]] || { echo "Usage: $0 [--fix] [--output line|JSON] <file-path>" >&2; exit 1; }
[[ -f "$TARGET_FILE" ]] || { echo "Error: File not found: $TARGET_FILE" >&2; exit 1; }
[[ -f ".vale-dita-only.ini" ]] || { echo "Error: .vale-dita-only.ini not found" >&2; exit 1; }

# Get all included files, excluding attributes.adoc (false positives for product names)
mapfile -t FILES < <("$SCRIPT_DIR/list-all-included-files-starting-from.sh" "$TARGET_FILE" | tr ' ' '\n' | grep -v '/attributes\.adoc$' | grep -v '^$')

[[ ${#FILES[@]} -gt 0 ]] || { echo "Error: No files found to validate" >&2; exit 1; }

# --- Fix mode ---
if [[ "$FIX_MODE" == true ]]; then
    echo "=== CQA #1: Vale AsciiDoc DITA Compliance — $TARGET_FILE ==="
    echo "FIX MODE — Scanning ${#FILES[@]} file(s) for auto-fixable issues..."
    FIXED=0

    # Get Vale issues as JSON
    VALE_JSON=$(vale --config .vale-dita-only.ini --output JSON "${FILES[@]}" 2>/dev/null || true)

    # Parse Vale JSON into file:line:check triples
    ISSUES_TSV=$(echo "$VALE_JSON" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for f, issues in d.items():
        for i in issues:
            print(f\"{f}\t{i['Line']}\t{i['Check']}\")
except: pass
" 2>/dev/null)

    # Fix AuthorLine: insert blank line after title
    while IFS=$'\t' read -r file line check; do
        [[ "$check" == "AsciiDocDITA.AuthorLine" ]] || continue
        TITLE_LN=$((line - 1))
        TITLE_CONTENT=$(sed -n "${TITLE_LN}p" "$file")
        if [[ "$TITLE_CONTENT" == "= "* ]]; then
            sed -i "${TITLE_LN}a\\\\" "$file"
            echo "  >> Fixed AuthorLine: $file:$line — added blank line after title"
            FIXED=$((FIXED + 1))
        fi
    done <<< "$ISSUES_TSV"

    # Fix CalloutList: convert callout list items to description list items
    # <1> Some text  →  <1>:: Some text
    while IFS=$'\t' read -r file line check; do
        [[ "$check" == "AsciiDocDITA.CalloutList" ]] || continue
        LINE_CONTENT=$(sed -n "${line}p" "$file")
        if [[ "$LINE_CONTENT" =~ ^\<[0-9]+\>[[:space:]] ]]; then
            sed -i "${line}s/^<\([0-9]*\)> /<\1>:: /" "$file"
            echo "  >> Fixed CalloutList: $file:$line — converted to description list"
            FIXED=$((FIXED + 1))
        fi
    done <<< "$ISSUES_TSV"

    # Fix BlockTitle: convert invalid block titles to lead-in sentences
    # .Some title  →  Some title:
    # Skip standard block titles: .Prerequisites, .Procedure, .Verification, .Additional resources
    while IFS=$'\t' read -r file line check; do
        [[ "$check" == "AsciiDocDITA.BlockTitle" ]] || continue
        LINE_CONTENT=$(sed -n "${line}p" "$file")
        # Skip if next line is a block delimiter (table, example, source) — those are valid
        NEXT_LINE=$(sed -n "$((line + 1))p" "$file")
        if [[ "$NEXT_LINE" == "|==="* || "$NEXT_LINE" == "===="* || "$NEXT_LINE" == "----"* || "$NEXT_LINE" == "[source"* || "$NEXT_LINE" == "image::"* ]]; then
            continue
        fi
        if [[ "$LINE_CONTENT" == "."* ]]; then
            TITLE_TEXT="${LINE_CONTENT#.}"
            sed -i "${line}s/^\..*/${TITLE_TEXT}:/" "$file"
            echo "  >> Fixed BlockTitle: $file:$line — converted to lead-in sentence"
            FIXED=$((FIXED + 1))
        fi
    done <<< "$ISSUES_TSV"

    # Fix TaskContents: add .Procedure before the first numbered steps list
    while IFS=$'\t' read -r file line check; do
        [[ "$check" == "AsciiDocDITA.TaskContents" ]] || continue
        # Find the first ordered list item (. Step or . Step)
        FIRST_OL=$(grep -n '^\. ' "$file" | head -1 | cut -d: -f1)
        if [[ -n "$FIRST_OL" ]]; then
            sed -i "$((FIRST_OL))i\\\\.Procedure" "$file"
            echo "  >> Fixed TaskContents: $file — added .Procedure before line $FIRST_OL"
            FIXED=$((FIXED + 1))
        fi
    done <<< "$ISSUES_TSV"

    # Fix TaskStep: two cases depending on context
    # 1. After .Procedure before first step: remove the blank line + offending content marker
    # 2. After a list: attach to preceding step with + continuation
    # Process files in reverse line order to avoid line number shifts
    declare -A TASKSTEP_FILES
    while IFS=$'\t' read -r file line check; do
        [[ "$check" == "AsciiDocDITA.TaskStep" ]] || continue
        TASKSTEP_FILES["$file"]+="$line "
    done <<< "$ISSUES_TSV"
    for file in "${!TASKSTEP_FILES[@]}"; do
        # Sort lines in reverse order
        for line in $(echo "${TASKSTEP_FILES[$file]}" | tr ' ' '\n' | sort -rn); do
            [[ -z "$line" ]] && continue
            # Check if previous line is empty
            PREV_LN=$((line - 1))
            PREV_CONTENT=$(sed -n "${PREV_LN}p" "$file")
            if [[ -z "$PREV_CONTENT" ]]; then
                # Look further back to find context: is this after .Procedure?
                PREV_PREV_LN=$((line - 2))
                PREV_PREV_CONTENT=$(sed -n "${PREV_PREV_LN}p" "$file")
                if [[ "$PREV_PREV_CONTENT" == ".Procedure" ]]; then
                    # After .Procedure before first step: just remove the blank line
                    sed -i "${PREV_LN}d" "$file"
                    echo "  >> Fixed TaskStep: $file:$line — removed blank line after .Procedure"
                    FIXED=$((FIXED + 1))
                else
                    # After a list: attach to preceding step with +
                    sed -i "${PREV_LN}s/^$/+/" "$file"
                    echo "  >> Fixed TaskStep: $file:$line — attached to preceding step with +"
                    FIXED=$((FIXED + 1))
                fi
            fi
        done
    done

    if [[ $FIXED -eq 0 ]]; then
        echo "No auto-fixable issues found."
    else
        echo "Applied $FIXED fix(es). Re-run without --fix to verify."
    fi
    exit 0
fi

# --- Report mode ---
if [[ "$OUTPUT_FORMAT" == "JSON" ]]; then
    # JSON mode: only Vale JSON on stdout, nothing else
    vale --config .vale-dita-only.ini --output JSON "${FILES[@]}"
    exit $?
fi

echo "=== CQA #1: Vale AsciiDoc DITA Compliance — $TARGET_FILE ==="
echo "Validating ${#FILES[@]} file(s)..."

# Vale returns 1 when issues are found
if vale --config .vale-dita-only.ini --output "$OUTPUT_FORMAT" "${FILES[@]}"; then
    echo "✓ All files pass AsciiDoc DITA validation (0 errors, 0 warnings, 0 suggestions)"
else
    VALE_EXIT=$?
    if [[ $VALE_EXIT -eq 1 ]]; then
        echo "✗ Vale found issues. All DITA warnings must be fixed."
    else
        echo "✗ Vale encountered an error (exit code: $VALE_EXIT)"
    fi
    exit $VALE_EXIT
fi
