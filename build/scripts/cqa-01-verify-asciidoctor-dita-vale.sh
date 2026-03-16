#!/bin/bash
# cqa-01-verify-asciidoctor-dita-vale.sh
# Validates AsciiDoc DITA compliance using Vale (CQA #1)
#
# Reference: .claude/skills/cqa-01-asciidoctor-dita-vale.md
#
# Usage: ./cqa-01-verify-asciidoctor-dita-vale.sh <path-to-master.adoc>

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path-to-master.adoc>"
    echo ""
    echo "Example:"
    echo "  $0 titles/integrating-with-github/master.adoc"
    exit 1
fi

TARGET_FILE="$1"

if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: File not found: $TARGET_FILE"
    exit 1
fi

if [ ! -f ".vale-dita-only.ini" ]; then
    echo "Error: .vale-dita-only.ini configuration file not found"
    exit 1
fi

# Get repository root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || REPO_ROOT="."

# Function to get all included files
get_all_files() {
    local file="$1"
    "$REPO_ROOT/build/scripts/list-all-included-files-starting-from" "$file"
}

echo "=== CQA #1: Validate AsciiDoc DITA Compliance with Vale ==="
echo ""
echo "Reference: .claude/skills/cqa-01-asciidoctor-dita-vale.md"
echo "Config: .vale-dita-only.ini"
echo ""

# Get all files
ALL_FILES=$(get_all_files "$TARGET_FILE")

if [ -z "$ALL_FILES" ]; then
    echo "Error: No files found to validate"
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
vale --config .vale-dita-only.ini $ALL_FILES
VALE_EXIT=$?

echo ""
echo "=== Summary ==="

if [ $VALE_EXIT -eq 0 ]; then
    echo "✓ All files pass AsciiDoc DITA validation"
    echo ""
    echo "Target: 0 errors, acceptable warnings only"
    echo "See .claude/skills/cqa-01-asciidoctor-dita-vale.md for acceptable warning types"
    exit 0
elif [ $VALE_EXIT -eq 1 ]; then
    echo "✗ Vale found issues (see output above)"
    echo ""
    echo "Required: 0 errors"
    echo "Acceptable: DITA-specific warnings for callouts, false positives"
    echo ""
    echo "Common fixes:"
    echo "  - Fix DITA violations (missing abstracts, incorrect structure)"
    echo "  - Review warnings to determine if they are acceptable"
    echo ""
    echo "See .claude/skills/cqa-01-asciidoctor-dita-vale.md for details"
    exit 1
else
    echo "✗ Vale encountered an error (exit code: $VALE_EXIT)"
    exit $VALE_EXIT
fi
