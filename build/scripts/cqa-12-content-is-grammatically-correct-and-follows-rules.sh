#!/bin/bash
# cqa-12-content-is-grammatically-correct-and-follows-rules.sh
# Validates grammar and style using Vale (CQA #12)
#
# Usage: ./cqa-12-content-is-grammatically-correct-and-follows-rules.sh [--fix] <file-path>
#   --fix:  Currently no automatic fixes available (validation only)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-12-content-is-grammatically-correct-and-follows-rules.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - Runs Vale with .vale.ini (grammar, spelling, style, terminology)
#   - Reports errors, warnings, and suggestions
#
# Requires:
#   - vale CLI installed
#   - .vale.ini configuration file

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

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

if [[ ! -f ".vale.ini" ]]; then
    echo "Error: .vale.ini configuration file not found" >&2
    exit 1
fi

echo "=== CQA #12: Validate Grammar and Style with Vale ==="
echo ""
echo "Reference: .claude/skills/cqa-12-content-is-grammatically-correct-and-follows-rules.md"
echo "Config: .vale.ini"
echo ""

# Get all included files, excluding attributes.adoc (defines attribute values
# using literal product names, which intentionally triggers DeveloperHub.Attributes rules)
ALL_FILES=$("$REPO_ROOT/build/scripts/list-all-included-files-starting-from" "$TARGET_FILE" | tr ' ' '\n' | grep -v '/attributes\.adoc$' | tr '\n' ' ')

if [[ -z "$ALL_FILES" ]]; then
    echo "Error: No files found to validate" >&2
    exit 1
fi

# Count files
FILE_COUNT=$(echo "$ALL_FILES" | wc -w)
echo "Validating $FILE_COUNT file(s)..."
echo ""

# Run Vale with grammar/style config
# shellcheck disable=SC2086
vale --config .vale.ini $ALL_FILES
VALE_EXIT=$?

echo ""
echo "=== Summary ==="

if [[ $VALE_EXIT -eq 0 ]]; then
    echo "v All files pass grammar and style validation"
    echo ""
    echo "Target: 0 errors, acceptable warnings only"
    exit 0
elif [[ $VALE_EXIT -eq 1 ]]; then
    echo "x Vale found issues (see output above)"
    echo ""
    echo "Required: Fix all errors"
    echo "Recommended: Fix warnings"
    echo "Optional: Review suggestions"
    echo ""
    echo "See .claude/skills/cqa-12-content-is-grammatically-correct-and-follows-rules.md"
    exit 1
else
    echo "x Vale encountered an error (exit code: $VALE_EXIT)"
    exit "$VALE_EXIT"
fi
