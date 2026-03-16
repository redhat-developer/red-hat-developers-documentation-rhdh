#!/bin/bash
# cqa-01-asciidoctor-dita-vale.sh
# Validates AsciiDoc DITA compliance using Vale (CQA #1)
#
# Reference: .claude/skills/cqa-01-asciidoctor-dita-vale.md
#
# Usage: ./cqa-01-asciidoctor-dita-vale.sh [--fix] <file-path>

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

if [[ ! -f ".vale-dita-only.ini" ]]; then
    echo "Error: .vale-dita-only.ini configuration file not found" >&2
    exit 1
fi

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT="."

# Function to get all included files
get_all_files() {
    local file="$1"
    "$REPO_ROOT/build/scripts/list-all-included-files-starting-from.sh" "$file"
}

echo "=== CQA #1: Validate AsciiDoc DITA Compliance with Vale ==="
echo ""
echo "Reference: .claude/skills/cqa-01-asciidoctor-dita-vale.md"
echo "Config: .vale-dita-only.ini"
echo ""

# Get all files, excluding attributes.adoc (defines attribute values
# using literal product names, which triggers false positives)
ALL_FILES=$(get_all_files "$TARGET_FILE" | tr ' ' '\n' | grep -v '/attributes\.adoc$' | tr '\n' ' ')

if [[ -z "$ALL_FILES" ]]; then
    echo "Error: No files found to validate" >&2
    exit 1
fi

# Count files
FILE_COUNT=$(echo "$ALL_FILES" | wc -w)
echo "Validating $FILE_COUNT file(s)..."
echo ""

# Run Vale with DITA-only config
# Note: Vale exit codes:
#   0 = no errors
#   1 = errors found
#   2 = usage error
# shellcheck disable=SC2086
vale --config .vale-dita-only.ini $ALL_FILES
VALE_EXIT=$?

echo ""
echo "=== Summary ==="

if [[ $VALE_EXIT -eq 0 ]]; then
    echo "✓ All files pass AsciiDoc DITA validation"
    echo ""
    echo "Target: 0 errors, acceptable warnings only"
    echo "See .claude/skills/cqa-01-asciidoctor-dita-vale.md for acceptable warning types"
    exit 0
elif [[ $VALE_EXIT -eq 1 ]]; then
    echo "✗ Vale found issues (see output above)"
    echo ""
    echo "Required: 0 errors"
    echo ""
    echo "All warnings must be fixed. Common fixes:"
    echo "  - AsciiDocDITA.BlockTitle: Restructure to avoid block titles"
    echo "  - AsciiDocDITA.CalloutList: Replace callouts with inline comments"
    echo "  - AsciiDocDITA.ConceptLink: Move inline links to .Additional resources"
    echo "  - AsciiDocDITA.DocumentId: Add [id=\"{context}\"] before heading in master.adoc"
    echo "  - AsciiDocDITA.RelatedLinks: .Additional resources must be link-only (no prose)"
    echo "  - AsciiDocDITA.TaskStep: Split description lists into separate procedures"
    echo ""
    echo "See .claude/skills/cqa-01-asciidoctor-dita-vale.md for details"
    exit 1
else
    echo "✗ Vale encountered an error (exit code: $VALE_EXIT)"
    exit $VALE_EXIT
fi
