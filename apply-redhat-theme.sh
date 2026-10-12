#!/usr/bin/env bash
set -e

# Red Hat Documentation Theme Applicator
# Usage: ./apply-redhat-theme.sh <path-to-zip-file>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$SCRIPT_DIR/redhat-theme"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <path-to-zip-file>"
    echo ""
    echo "Example:"
    echo "  $0 ~/Downloads/rhdh-1-10-navigation.zip"
    echo ""
    echo "This will create a new file with '-themed' appended to the original name"
    exit 1
}

if [ $# -eq 0 ]; then
    usage
fi

ZIP_FILE="$1"

# Check if zip file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: File not found: $ZIP_FILE"
    exit 1
fi

# Check if theme directory exists
if [ ! -d "$THEME_DIR" ]; then
    echo "Error: Theme directory not found: $THEME_DIR"
    echo "Make sure the 'redhat-theme' directory is in the same location as this script."
    exit 1
fi

# Get absolute path and basename
ZIP_FILE=$(cd "$(dirname "$ZIP_FILE")" && pwd)/$(basename "$ZIP_FILE")
ZIP_DIR=$(dirname "$ZIP_FILE")
ZIP_BASENAME=$(basename "$ZIP_FILE" .zip)
OUTPUT_ZIP="${ZIP_DIR}/${ZIP_BASENAME}-themed.zip"

echo -e "${BLUE}=== Red Hat Documentation Theme Applicator ===${NC}"
echo ""
echo -e "${BLUE}Input:${NC}  $ZIP_FILE"
echo -e "${BLUE}Output:${NC} $OUTPUT_ZIP"
echo ""

# Create temporary working directory
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo -e "${GREEN}[1/5]${NC} Extracting zip file..."
unzip -q "$ZIP_FILE" -d "$TEMP_DIR"

echo -e "${GREEN}[2/5]${NC} Copying theme CSS..."
cp "$THEME_DIR/redhat-docs-theme.css" "$TEMP_DIR/"

echo -e "${GREEN}[3/5]${NC} Applying theme to HTML files..."
python3 "$THEME_DIR/add-theme.py" "$TEMP_DIR"

echo -e "${GREEN}[4/5]${NC} Copying README..."
cp "$THEME_DIR/README.md" "$TEMP_DIR/"

echo -e "${GREEN}[5/5]${NC} Creating themed zip file..."
cd "$TEMP_DIR"
zip -r "$OUTPUT_ZIP" . -q

# Count HTML files
HTML_COUNT=$(find "$TEMP_DIR" -name "*.html" | wc -l | tr -d ' ')

echo ""
echo -e "${GREEN}✓ Success!${NC}"
echo ""
echo "Results:"
echo "  - Updated $HTML_COUNT HTML files"
echo "  - Added redhat-docs-theme.css"
echo "  - Added README.md"
echo ""
echo -e "${YELLOW}Output saved to:${NC}"
echo "  $OUTPUT_ZIP"
echo ""
echo "You can now extract and use the themed documentation."
