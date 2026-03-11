#!/bin/bash
# fix-title-id-filename.sh
# Aligns title, ID, context, and filename per CQA.md rules
#
# Usage: ./fix-title-id-filename.sh <file-path>
#   Processes the specified file and all its includes recursively
#   Example: ./fix-title-id-filename.sh titles/install-rhdh-ocp/master.adoc
#     Processes: master.adoc → assemblies → all included modules (recursive)
#
# This script follows CQA.md Step 5 (Title/ID/Filename Compliance):
# STEP 0: Add content type metadata if missing (CQA requirement #2)
# STEP 1: Fix titles FIRST - Title is source of truth (CQA requirement #8)
#   - Procedures: Use imperative form ("Install" not "Installing")
#   - Concepts: Use noun phrases ("High availability" not "Achieve high availability")
#   - References: Use noun phrases ("Configuration options" not "Configure options")
#   - Assemblies with procedures: Use imperative form ("Install" not "Installing")
#   - Assemblies without procedures: Use noun phrases ("API reference" not "Configure API")
# STEP 2: Update IDs and context to match title
# STEP 3: Update all xrefs pointing to changed ID
# STEP 4: Rename file to match title
# STEP 5: Update all include statements

set -e

# Function to extract included files from a given file
get_includes() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi

    # Extract include:: statements and resolve relative paths
    grep "^include::" "$file" 2>/dev/null | sed 's/^include:://' | sed 's/\[.*//' | while read -r include_path; do
        # Get repository root (where .git is)
        local repo_root=$(cd "$(dirname "$file")" && git rev-parse --show-toplevel 2>/dev/null) || repo_root="."

        # Resolve relative path from file's directory
        local dir=$(dirname "$file")
        local resolved_path

        if [[ "$include_path" == /* ]]; then
            resolved_path="$include_path"
        elif [[ "$include_path" == ../* ]]; then
            resolved_path="$dir/$include_path"
        else
            resolved_path="$dir/$include_path"
        fi

        # Normalize and make relative to repo root
        if [[ -f "$resolved_path" ]]; then
            # Make path relative to repo root
            resolved_path=$(realpath --relative-to="$repo_root" "$resolved_path" 2>/dev/null) || resolved_path="$resolved_path"
            echo "$resolved_path"
        fi
    done
}

# Function to recursively collect all files to process
collect_files() {
    local file="$1"
    local var_name="$2"

    # Use eval to access the array by name
    local current_files
    eval "current_files=(\"\${${var_name}[@]}\")"

    # Skip if already processed
    for existing_file in "${current_files[@]}"; do
        if [[ "$existing_file" == "$file" ]]; then
            return
        fi
    done

    # Add file to array
    eval "${var_name}+=('$file')"

    # Get includes and process recursively
    while IFS= read -r included_file; do
        collect_files "$included_file" "$var_name"
    done < <(get_includes "$file")
}

# Function to process a single file
process_file() {
    local FILE="$1"

# Determine module type from filename prefix
BASENAME=$(basename "$FILE" .adoc)
if [[ "$BASENAME" == proc-* ]]; then
    PREFIX="proc-"
    MODULE_TYPE="PROCEDURE"
    EXPECTED_FORM="imperative"
elif [[ "$BASENAME" == con-* ]]; then
    PREFIX="con-"
    MODULE_TYPE="CONCEPT"
    EXPECTED_FORM="noun phrase"
elif [[ "$BASENAME" == ref-* ]]; then
    PREFIX="ref-"
    MODULE_TYPE="REFERENCE"
    EXPECTED_FORM="noun phrase"
elif [[ "$BASENAME" == assembly-* ]]; then
    PREFIX="assembly-"
    MODULE_TYPE="ASSEMBLY"
    # Assemblies use imperative form IF they include procedures, otherwise noun phrases
    if grep -q "include::.*proc-.*\.adoc" "$FILE"; then
        EXPECTED_FORM="imperative"
    else
        EXPECTED_FORM="noun phrase"
    fi
elif [[ "$BASENAME" == snip-* ]]; then
    PREFIX="snip-"
    MODULE_TYPE="SNIPPET"
    EXPECTED_FORM="any"
else
    echo "Error: Unknown module type for $FILE (filename must start with proc-, con-, ref-, assembly-, or snip-)"
    exit 1
fi

echo "=== Processing: $FILE ==="
echo "Module type:     $MODULE_TYPE"

# STEP 0: Add content type metadata if missing
if ! grep -q "^:_mod-docs-content-type:" "$FILE"; then
    echo "STEP 0: Adding missing content type metadata..."
    # Insert at the very beginning of the file
    sed -i.bak "1s/^/:_mod-docs-content-type: ${MODULE_TYPE}\n\n/" "$FILE"
    rm -f "${FILE}.bak"
    echo "  ✓ Added :_mod-docs-content-type: ${MODULE_TYPE}"
    echo ""
fi

# Extract current title (H1 heading)
TITLE=$(grep "^= " "$FILE" | head -1 | sed 's/^= //')
if [ -z "$TITLE" ]; then
    echo "Error: No title found in $FILE (looking for '= Title')"
    exit 1
fi

echo "Current title:   $TITLE"

# STEP 1: Fix title to use correct form (for procedures and assemblies only)
FIXED_TITLE="$TITLE"
if [ "$EXPECTED_FORM" = "imperative" ]; then
    # Check for gerund forms (ending in -ing) and convert to imperative
    # Common patterns:
    # - "Installing" → "Install"
    # - "Deploying" → "Deploy"
    # - "Configuring" → "Configure"
    # - "Creating" → "Create"
    
    # Extract first word (handling attributes)
    FIRST_WORD=$(echo "$TITLE" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
    
    if [[ "$FIRST_WORD" =~ ing$ ]] && [[ ! "$FIRST_WORD" =~ ^{.*}$ ]]; then
        # Convert gerund to imperative
        if [[ "$FIRST_WORD" == "Installing" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Installing /Install /')
        elif [[ "$FIRST_WORD" == "Deploying" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Deploying /Deploy /')
        elif [[ "$FIRST_WORD" == "Configuring" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Configuring /Configure /')
        elif [[ "$FIRST_WORD" == "Creating" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Creating /Create /')
        elif [[ "$FIRST_WORD" == "Setting" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Setting /Set /')
        elif [[ "$FIRST_WORD" == "Enabling" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Enabling /Enable /')
        elif [[ "$FIRST_WORD" == "Disabling" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Disabling /Disable /')
        elif [[ "$FIRST_WORD" == "Building" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Building /Build /')
        elif [[ "$FIRST_WORD" == "Running" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Running /Run /')
        elif [[ "$FIRST_WORD" == "Managing" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Managing /Manage /')
        elif [[ "$FIRST_WORD" == "Upgrading" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Upgrading /Upgrade /')
        elif [[ "$FIRST_WORD" == "Updating" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Updating /Update /')
        elif [[ "$FIRST_WORD" == "Adding" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Adding /Add /')
        elif [[ "$FIRST_WORD" == "Removing" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Removing /Remove /')
        elif [[ "$FIRST_WORD" == "Deleting" ]]; then
            FIXED_TITLE=$(echo "$TITLE" | sed 's/^Deleting /Delete /')
        else
            # Generic gerund removal: remove "ing" suffix
            BASE=$(echo "$FIRST_WORD" | sed 's/ing$//')
            FIXED_TITLE=$(echo "$TITLE" | sed "s/^${FIRST_WORD} /${BASE} /")
        fi
        
        echo "STEP 1: Fixing title form..."
        echo "  Old: $TITLE"
        echo "  New: $FIXED_TITLE"
        echo ""
        
        # Update title in file
        sed -i.bak "s/^= ${TITLE}/= ${FIXED_TITLE}/" "$FILE"
        rm -f "${FILE}.bak"
        TITLE="$FIXED_TITLE"
    fi
fi

# Extract current ID (before _{context})
CURRENT_ID=$(grep "\[id=" "$FILE" | head -1 | sed 's/.*\[id="//;s/.*\[id='"'"'//;s/_.*//')

# Convert title to expected ID:
# 1. Extract attribute names (preserve them): {product-short} → product-short
# 2. Lowercase everything
# 3. Replace non-alphanumeric with hyphens
# 4. Clean up multiple/leading/trailing hyphens
EXPECTED_ID=$(echo "$TITLE" | \
    sed 's/{/ /g; s/}/ /g' | \
    tr 'A-Z' 'a-z' | \
    sed 's/[^a-z0-9-]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//;s/-$//')

# Expected filename
EXPECTED_FILENAME="${PREFIX}${EXPECTED_ID}.adoc"
NEW_FILE="$(dirname $FILE)/$EXPECTED_FILENAME"

echo "Expected title:  $TITLE ($EXPECTED_FORM form)"
echo "Current ID:      ${CURRENT_ID}_{context}"
echo "Expected ID:     ${EXPECTED_ID}_{context}"
echo "Current file:    $(basename $FILE)"
echo "Expected file:   $EXPECTED_FILENAME"
echo ""

if [ "$CURRENT_ID" = "$EXPECTED_ID" ] && [ "$FILE" = "$NEW_FILE" ]; then
    echo "✓ Already aligned - no changes needed"
    return 0
fi

# STEP 2: Update ID and context to match title
echo "STEP 2: Updating IDs..."
if [ "$MODULE_TYPE" = "ASSEMBLY" ]; then
    # For assemblies, update both [id=...] and :context:
    sed -i.bak "s/\[id=\"[^\"]*_{context}\"\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
    sed -i.bak "s/\[id='[^']*_{context}'\]/[id='${EXPECTED_ID}_{context}']/" "$FILE"
    sed -i.bak "s/^:context: .*$/:context: ${EXPECTED_ID}/" "$FILE"
    echo "  ✓ Updated [id=\"${EXPECTED_ID}_{context}\"]"
    echo "  ✓ Updated :context: ${EXPECTED_ID}"
else
    # For modules, just update [id=...]
    sed -i.bak "s/\[id=\"[^\"]*_{context}\"\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
    sed -i.bak "s/\[id='[^']*_{context}'\]/[id='${EXPECTED_ID}_{context}']/" "$FILE"
    echo "  ✓ Updated [id=\"${EXPECTED_ID}_{context}\"]"
fi
rm -f "${FILE}.bak"

# STEP 3: Update xrefs pointing to changed ID
if [ "$CURRENT_ID" != "$EXPECTED_ID" ]; then
    echo "STEP 3: Updating xrefs..."
    # Find all xrefs to the old ID and update them
    grep -rl "xref:${CURRENT_ID}_" assemblies/ modules/ titles/ 2>/dev/null | while read xref_file; do
        sed -i.bak "s/xref:${CURRENT_ID}_/xref:${EXPECTED_ID}_/g" "$xref_file"
        rm -f "${xref_file}.bak"
        echo "  ✓ Updated xrefs in $(basename $xref_file)"
    done
fi

# STEP 4: Rename file to match title
if [ "$FILE" != "$NEW_FILE" ]; then
    echo "STEP 4: Renaming file..."
    git mv "$FILE" "$NEW_FILE" 2>/dev/null || mv "$FILE" "$NEW_FILE"
    echo "  ✓ Renamed: $(basename $FILE) → $(basename $NEW_FILE)"
    
    # STEP 5: Update includes
    echo "STEP 5: Updating include statements..."
    OLD_BASENAME=$(basename "$FILE")
    NEW_BASENAME=$(basename "$NEW_FILE")
    
    find assemblies/ modules/ titles/ -name "*.adoc" -type f 2>/dev/null | while read include_file; do
        if grep -q "include::.*${OLD_BASENAME}\[" "$include_file"; then
            sed -i.bak "s|include::\(.*\)${OLD_BASENAME}\[|include::\1${NEW_BASENAME}[|g" "$include_file"
            rm -f "${include_file}.bak"
            echo "  ✓ Updated include in $(basename $include_file)"
        fi
    done
    
    FILE="$NEW_FILE"
fi

echo ""
echo "✓ DONE: $FILE is now CQA-compliant"
echo "  Content type: ${MODULE_TYPE}"
echo "  Title: $TITLE ($EXPECTED_FORM form)"
echo "  ID: ${EXPECTED_ID}_{context}"
if [ "$MODULE_TYPE" = "ASSEMBLY" ]; then
    echo "  Context: ${EXPECTED_ID}"
fi
echo "  File: $(basename $FILE)"
}

# Main script
if [ $# -ne 1 ]; then
    echo "Usage: $0 <file-path>"
    echo ""
    echo "Examples:"
    echo "  $0 modules/installation/proc-installing-the-operator.adoc"
    echo "  $0 titles/install-rhdh-ocp/master.adoc"
    echo "    (processes master.adoc → assemblies → all included modules recursively)"
    echo ""
    echo "This script aligns title, ID, context, and filename per CQA.md rules."
    echo "It processes the specified file and all its includes recursively."
    echo ""
    echo "It will:"
    echo "  STEP 0: Add :_mod-docs-content-type: metadata if missing"
    echo "  STEP 1: Fix title to use correct form (imperative for procedures/assemblies)"
    echo "  STEP 2: Calculate expected ID (title → lowercase, extract attribute names, hyphens)"
    echo "  STEP 3: Update [id=\"...\"] to match"
    echo "  STEP 4: Update :context: for assemblies"
    echo "  STEP 5: Rename file using git mv"
    echo "  STEP 6: Update all xrefs and include statements"
    exit 1
fi

TARGET_FILE="$1"

if [ ! -f "$TARGET_FILE" ]; then
    echo "Error: File not found: $TARGET_FILE"
    exit 1
fi

# Collect all files to process (target + includes)
ALL_FILES=()
collect_files "$TARGET_FILE" ALL_FILES

# Separate module files from non-module files
MODULE_FILES=()
SKIPPED_FILES=()

for file in "${ALL_FILES[@]}"; do
    # Skip non-.adoc files
    if [[ "$file" != *.adoc ]]; then
        continue
    fi

    # Check if file has module prefix
    basename_file=$(basename "$file" .adoc)
    if [[ "$basename_file" =~ ^(proc|con|ref|assembly|snip)- ]]; then
        MODULE_FILES+=("$file")
    else
        SKIPPED_FILES+=("$file")
    fi
done

# Show what will be processed
echo "=== Found ${#ALL_FILES[@]} file(s) in include tree ==="
if [[ ${#SKIPPED_FILES[@]} -gt 0 ]]; then
    echo "Skipping ${#SKIPPED_FILES[@]} non-module file(s): ${SKIPPED_FILES[*]}"
fi
echo "Processing ${#MODULE_FILES[@]} module file(s)"
echo ""

# Process each module file
for file in "${MODULE_FILES[@]}"; do
    process_file "$file"
    echo ""
    echo "---"
    echo ""
done

echo "✓ All ${#MODULE_FILES[@]} module file(s) processed successfully"
