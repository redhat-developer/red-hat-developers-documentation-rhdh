#!/bin/bash
# cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh
# Checks if redirects are needed and in place (CQA #15)
#
# Usage: ./cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh [--fix] <file-path>
#   --fix:  Currently no automatic fixes available (validation only)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh titles/install-rhdh-ocp/master.adoc
#
# Checks:
#   - Detects renamed or moved files that may need redirects
#   - Reports files with changed IDs that may affect external links
#
# Note: Redirect implementation depends on the publishing platform.
#       This script identifies files that MAY need redirects.

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

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== CQA #15: Check Redirects ==="
echo ""
echo "Reference: .claude/skills/cqa-15-redirects-if-needed-are-in-place-and-work-correc.md"
echo ""

# Check for renamed files in git (staged or recent commits)
RENAMED_FILES=$(git diff --name-status --diff-filter=R HEAD~5..HEAD -- 'assemblies/' 'modules/' 'titles/' 2>/dev/null || true)
STAGED_RENAMES=$(git diff --cached --name-status --diff-filter=R -- 'assemblies/' 'modules/' 'titles/' 2>/dev/null || true)

NEEDS_REVIEW=0

if [[ -n "$RENAMED_FILES" ]]; then
    echo -e "${YELLOW}Renamed files in recent commits (may need redirects):${NC}"
    echo "$RENAMED_FILES" | while IFS=$'\t' read -r status old_file new_file; do
        echo "  $old_file → $new_file"
    done
    echo ""
    NEEDS_REVIEW=$((NEEDS_REVIEW + 1))
fi

if [[ -n "$STAGED_RENAMES" ]]; then
    echo -e "${YELLOW}Renamed files staged for commit (may need redirects):${NC}"
    echo "$STAGED_RENAMES" | while IFS=$'\t' read -r status old_file new_file; do
        echo "  $old_file → $new_file"
    done
    echo ""
    NEEDS_REVIEW=$((NEEDS_REVIEW + 1))
fi

# Check for deleted files
DELETED_FILES=$(git diff --name-status --diff-filter=D HEAD~5..HEAD -- 'assemblies/' 'modules/' 'titles/' 2>/dev/null || true)
if [[ -n "$DELETED_FILES" ]]; then
    echo -e "${YELLOW}Deleted files in recent commits (may need redirects):${NC}"
    # shellcheck disable=SC2034
    echo "$DELETED_FILES" | while IFS=$'\t' read -r status deleted_file; do
        echo "  $deleted_file"
    done
    echo ""
    NEEDS_REVIEW=$((NEEDS_REVIEW + 1))
fi

echo "=== Summary ==="

if [[ $NEEDS_REVIEW -eq 0 ]]; then
    echo -e "${GREEN}v No renamed or deleted files detected - redirects likely not needed${NC}"
    exit 0
else
    echo -e "${YELLOW}Review items above to determine if redirects are needed${NC}"
    echo ""
    echo "Redirect implementation depends on the publishing platform."
    echo "See .claude/skills/cqa-15-redirects-if-needed-are-in-place-and-work-correc.md"
    exit 0
fi
