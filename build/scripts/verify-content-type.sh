#!/bin/bash
# Verify that information is conveyed using the correct content type (CQA requirement #11)
#
# Requirements per CQA.md:
# - Concepts: explain what something is, why it matters
# - Procedures: step-by-step instructions (numbered steps)
# - References: tables, lists, specifications, sizing guides
#
# This script focuses on the most concrete verification:
# - PROCEDURE modules MUST contain numbered steps (. at line start)

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== CQA Requirement #11: Verify Content Type Usage ==="
echo ""

# Find all .adoc files with content type metadata
VIOLATIONS=0
CHECKED=0

while IFS= read -r file; do
    # Extract content type and trim trailing whitespace
    CONTENT_TYPE=$(grep "^:_mod-docs-content-type:" "$file" | sed 's/^:_mod-docs-content-type: *//' | sed 's/ *$//')

    if [[ -z "$CONTENT_TYPE" ]]; then
        continue
    fi

    CHECKED=$((CHECKED + 1))

    case "$CONTENT_TYPE" in
        PROCEDURE)
            # Verify that procedure has steps (numbered or unnumbered) or includes snippets
            # Look for:
            # - Lines starting with one or more dots followed by space (numbered: '. ', '.. ', '... ')
            # - Lines starting with '* ' (unnumbered for single-step procedures)
            # - Include statements after .Procedure section (steps in snippets)
            if grep -q "^\(\.\.* \|\* \)" "$file" || \
               (grep -q "^\.Procedure" "$file" && grep -A 10 "^\.Procedure" "$file" | grep -q "^include::"); then
                echo -e "${GREEN}✓${NC} $file (PROCEDURE with steps)"
            else
                echo -e "${RED}✗${NC} $file"
                echo "  Content type: PROCEDURE"
                echo "  Issue: No steps found (procedures must have numbered/unnumbered lists or include snippets)"
                echo ""
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
            ;;
        CONCEPT)
            # Concepts should explain "what" and "why" - harder to verify automatically
            # Just confirm the content type is present
            echo -e "${GREEN}✓${NC} $file (CONCEPT)"
            ;;
        REFERENCE)
            # References should have tables/lists - could check for |=== or * but less strict
            echo -e "${GREEN}✓${NC} $file (REFERENCE)"
            ;;
        ASSEMBLY)
            # Assemblies are collections of modules
            # They MUST include other modules using the include:: directive
            if grep -q "^include::" "$file"; then
                echo -e "${GREEN}✓${NC} $file (ASSEMBLY)"
            else
                echo -e "${RED}✗${NC} $file"
                echo "  Content type: ASSEMBLY"
                echo "  Issue: Assemblies must include modules using include:: directive"
                echo ""
                VIOLATIONS=$((VIOLATIONS + 1))
            fi
            ;;
        SNIPPET)
            # Snippets are reusable content fragments
            # They CANNOT include structural elements like module-level anchor IDs or H1 headings
            # Module-level IDs typically appear in first 10 lines and use format [id="..."]
            if (head -10 "$file" | grep -q '^\[id=".*"]') || grep -q "^= " "$file"; then
                echo -e "${RED}✗${NC} $file"
                echo "  Content type: SNIPPET"
                echo "  Issue: Snippets cannot include module-level anchor IDs or H1 headings"
                echo ""
                VIOLATIONS=$((VIOLATIONS + 1))
            else
                echo -e "${GREEN}✓${NC} $file (SNIPPET)"
            fi
            ;;
        *)
            echo -e "${YELLOW}?${NC} $file"
            echo "  Content type: $CONTENT_TYPE (unknown type)"
            echo ""
            VIOLATIONS=$((VIOLATIONS + 1))
            ;;
    esac
done < <(find . -name "*.adoc" -type f \
    -not -path "./build/*" \
    -not -path "./.git/*" \
    -not -path "./node_modules/*" \
    | sort)

echo ""
echo "=== Summary ==="
echo "Files checked: $CHECKED"
if [[ $VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✓ All files use correct content type${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $VIOLATIONS violation(s)${NC}"
    exit 1
fi
