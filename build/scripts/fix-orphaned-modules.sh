#!/bin/bash
# Find and optionally delete orphaned modules (files not included anywhere)
#
# Usage: ./fix-orphaned-modules.sh [--execute]
#   --execute: Actually delete orphaned files (default is dry-run mode)
#
# This script finds all .adoc files in artifacts/, assemblies/, and modules/
# directories that are not referenced by any include:: statement in .adoc files
#
# By default, runs in dry-run mode showing what would be deleted.
# Use --execute flag to actually delete the orphaned files.

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Parse arguments
EXECUTE=false
if [[ "$1" == "--execute" ]]; then
    EXECUTE=true
fi

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=== Find Orphaned Modules and Resources ==="
echo ""

if [[ "$EXECUTE" == "false" ]]; then
    echo -e "${YELLOW}DRY-RUN MODE${NC} - No files will be deleted"
    echo "Run with --execute flag to actually delete orphaned files"
    echo ""
fi

# Find all .adoc files that could be included
echo "Collecting files to check..."
FILES_TO_CHECK=()

# Find all .adoc files in target directories
while IFS= read -r file; do
    FILES_TO_CHECK+=("$file")
done < <(find artifacts assemblies modules -name "*.adoc" -type f 2>/dev/null | sort)

echo "Found ${#FILES_TO_CHECK[@]} files to check"
echo ""

# Function to check if a file is included anywhere
is_file_included() {
    local target_file="$1"
    local basename=$(basename "$target_file")

    # Search for include:: statements that reference this file
    # We need to check:
    # 1. Direct filename match
    # 2. Relative path matches with exact filename
    # 3. Includes using attributes in path (like {docdir}/file.adoc)
    # 4. Includes using attributes in filename (like proc-something-{platform-id}-etc.adoc)

    # First, try direct basename match (handles most cases)
    if grep -r "^include::" . --include="*.adoc" 2>/dev/null | grep -q "$basename"; then
        return 0  # File is included
    fi

    # Handle attribute substitution in filename (e.g., {platform-id}, {context})
    # Common patterns: eks/aks/gke/ocp for platform-id, various contexts
    # Create a regex pattern by replacing potential attribute values with attribute pattern
    local pattern="$basename"

    # Replace common platform identifiers with {platform-id} pattern
    pattern=$(echo "$pattern" | sed 's/-\(eks\|aks\|gke\|ocp\|ocp-short\|osd-gcp\)-/-{[^}]*}-/g')

    # If pattern is different from basename, search for it
    if [[ "$pattern" != "$basename" ]]; then
        if grep -r "^include::" . --include="*.adoc" 2>/dev/null | grep -E "$pattern" | grep -qv "^//" ; then
            return 0  # File is included with attribute substitution
        fi
    fi

    return 1  # File is not included
}

# Find orphaned files
echo "Checking for orphaned files..."
ORPHANED_FILES=()
TOTAL=0
CHECKED=0

for file in "${FILES_TO_CHECK[@]}"; do
    TOTAL=$((TOTAL + 1))

    # Skip if file doesn't exist
    if [[ ! -f "$file" ]]; then
        continue
    fi

    CHECKED=$((CHECKED + 1))

    # Show progress every 50 files
    if [[ $((CHECKED % 50)) -eq 0 ]]; then
        echo "  Checked $CHECKED/$TOTAL files..."
    fi

    # Check if file is included anywhere
    if ! is_file_included "$file"; then
        ORPHANED_FILES+=("$file")
    fi
done

echo "  Checked $CHECKED/$TOTAL files"
echo ""

# Report findings
if [[ ${#ORPHANED_FILES[@]} -eq 0 ]]; then
    echo -e "${GREEN}✓ No orphaned files found${NC}"
    exit 0
fi

echo -e "${YELLOW}Found ${#ORPHANED_FILES[@]} orphaned file(s):${NC}"
echo ""

for file in "${ORPHANED_FILES[@]}"; do
    echo "  $file"
done

echo ""

# Delete files if in execute mode
if [[ "$EXECUTE" == "true" ]]; then
    echo -e "${RED}DELETING ORPHANED FILES...${NC}"
    echo ""

    DELETED=0
    for file in "${ORPHANED_FILES[@]}"; do
        # Check if file is tracked by git
        if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
            echo "  git rm $file"
            git rm "$file" 2>/dev/null || rm -f "$file"
        else
            echo "  rm $file"
            rm -f "$file"
        fi
        DELETED=$((DELETED + 1))
    done

    echo ""
    echo -e "${GREEN}✓ Deleted $DELETED orphaned file(s)${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review the changes: git status"
    echo "  2. If correct, commit: git add -A && git commit -m 'Remove orphaned modules'"
    echo "  3. If incorrect, revert: git checkout ."
else
    echo -e "${YELLOW}DRY-RUN MODE${NC} - No files were deleted"
    echo ""
    echo "To delete these files, run:"
    echo "  ./build/scripts/fix-orphaned-modules.sh --execute"
fi

echo ""
echo "=== Summary ==="
echo "Total files checked: $CHECKED"
echo "Orphaned files found: ${#ORPHANED_FILES[@]}"
if [[ "$EXECUTE" == "true" ]]; then
    echo -e "${GREEN}Status: Files deleted${NC}"
else
    echo -e "${YELLOW}Status: Dry-run (no changes made)${NC}"
fi
