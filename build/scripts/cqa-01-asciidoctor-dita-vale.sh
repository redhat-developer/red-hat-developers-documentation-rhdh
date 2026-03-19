#!/bin/bash
# cqa-01-asciidoctor-dita-vale.sh - Validates AsciiDoc DITA compliance using Vale (CQA #1)
# Usage: ./cqa-01-asciidoctor-dita-vale.sh [--output line|JSON] <file-path>

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_FORMAT="line"
TARGET_FILE=""

for arg in "$@"; do
    case "$arg" in
        --output) OUTPUT_FORMAT="__NEXT__" ;;
        *)
            if [[ "$OUTPUT_FORMAT" == "__NEXT__" ]]; then
                OUTPUT_FORMAT="$arg"
            elif [[ -z "$TARGET_FILE" ]]; then
                TARGET_FILE="$arg"
            else
                echo "Error: unexpected argument: $arg" >&2
                echo "Usage: $0 [--output line|JSON] <file-path>" >&2
                exit 1
            fi
            ;;
    esac
done

[[ -n "$TARGET_FILE" ]] || { echo "Usage: $0 [--output line|JSON] <file-path>" >&2; exit 1; }
[[ -f "$TARGET_FILE" ]] || { echo "Error: File not found: $TARGET_FILE" >&2; exit 1; }
[[ -f ".vale-dita-only.ini" ]] || { echo "Error: .vale-dita-only.ini not found" >&2; exit 1; }

# Get all included files, excluding attributes.adoc (false positives for product names)
mapfile -t FILES < <("$SCRIPT_DIR/list-all-included-files-starting-from.sh" "$TARGET_FILE" | tr ' ' '\n' | grep -v '/attributes\.adoc$' | grep -v '^$')

[[ ${#FILES[@]} -gt 0 ]] || { echo "Error: No files found to validate" >&2; exit 1; }

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
