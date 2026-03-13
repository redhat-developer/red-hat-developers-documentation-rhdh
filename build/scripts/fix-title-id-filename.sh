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
# STEP 0: Ensure content type metadata exists (CQA requirement #2)
# - Reads module type from :_mod-docs-content-type: metadata (first line)
# - If metadata is missing, runs fix-content-type.sh to add it automatically
# STEP 1: Fix titles FIRST - Title is source of truth (CQA requirement #8)
#   - Procedures: Use imperative form ("Install" not "Installing")
#   - Concepts: Use noun phrases ("High availability" not "Achieve high availability")
#   - References: Use noun phrases ("Configuration options" not "Configure options")
#   - Assemblies with procedures: Use imperative form ("Install" not "Installing")
#   - Assemblies without procedures: Use noun phrases ("API reference" not "Configure API")
# STEP 2: Update IDs and context to match title
# STEP 3: Update all xrefs pointing to changed ID
# STEP 4: Rename file to match title (using prefix from content type)
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
        local repo_root
        repo_root=$(cd "$(dirname "$file")" && git rev-parse --show-toplevel 2>/dev/null) || repo_root="."

        # Resolve relative path from file's directory
        local dir
        dir=$(dirname "$file")
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
            # shellcheck disable=SC2269  # Intentional fallback to original path if realpath fails
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

# Function to get content type from file (always first line)
get_content_type() {
    local file="$1"
    local first_line
    first_line=$(head -1 "$file" 2>/dev/null)
    if [[ "$first_line" =~ ^:_mod-docs-content-type:[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    else
        echo ""
        return 0
    fi
}

# Function to resolve an attribute value
# Args: $1 = attribute name (without braces), $2 = file to search first
# Returns: resolved value or original attribute name if not found
resolve_attribute() {
    local attr_name="$1"
    local search_file="$2"
    local attr_value=""

    # First, try to find in the current file
    if [[ -f "$search_file" ]]; then
        attr_value=$(grep "^:${attr_name}:" "$search_file" 2>/dev/null | head -1 | sed "s/^:${attr_name}:[[:space:]]*//" | sed 's/[[:space:]]*$//')
    fi

    # If not found, try artifacts/attributes.adoc
    if [[ -z "$attr_value" ]] && [[ -f "artifacts/attributes.adoc" ]]; then
        attr_value=$(grep "^:${attr_name}:" "artifacts/attributes.adoc" 2>/dev/null | head -1 | sed "s/^:${attr_name}:[[:space:]]*//" | sed 's/[[:space:]]*$//')
    fi

    # If still not found, return the attribute name
    if [[ -z "$attr_value" ]]; then
        echo "$attr_name"
    else
        echo "$attr_value"
    fi
}

# Function to expand all attributes in a string
# Args: $1 = string with attributes, $2 = file to search first
expand_attributes() {
    local input="$1"
    local search_file="$2"
    local output="$input"

    # Find all {attribute} patterns and expand them iteratively
    while [[ "$output" =~ \{([^}]+)\} ]]; do
        local attr_name="${BASH_REMATCH[1]}"
        local attr_value
        attr_value=$(resolve_attribute "$attr_name" "$search_file")

        # Replace {attribute} with its value
        output="${output//\{$attr_name\}/$attr_value}"
    done

    echo "$output"
}

# Function to process a single file
process_file() {
    local FILE="$1"

# Determine module type from content type metadata (always)
CONTENT_TYPE=$(get_content_type "$FILE")

if [[ -z "$CONTENT_TYPE" ]]; then
    # No content type metadata - run fix-content-type.sh to add it
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    echo "  ! Running fix-content-type.sh to add missing metadata..."
    "$SCRIPT_DIR/fix-content-type.sh" "$FILE" > /dev/null 2>&1 || true

    # Re-read content type after fixing
    CONTENT_TYPE=$(get_content_type "$FILE")

    # If still no content type, skip this file
    if [[ -z "$CONTENT_TYPE" ]]; then
        echo "? $FILE (cannot determine content type even after running fix-content-type.sh)"
        return 0
    fi
fi

# Determine prefix and expected form based on content type
case "$CONTENT_TYPE" in
    PROCEDURE)
        PREFIX="proc-"
        MODULE_TYPE="PROCEDURE"
        EXPECTED_FORM="imperative"
        ;;
    CONCEPT)
        PREFIX="con-"
        MODULE_TYPE="CONCEPT"
        EXPECTED_FORM="noun phrase"
        ;;
    REFERENCE)
        PREFIX="ref-"
        MODULE_TYPE="REFERENCE"
        EXPECTED_FORM="noun phrase"
        ;;
    ASSEMBLY)
        PREFIX="assembly-"
        MODULE_TYPE="ASSEMBLY"
        # Assemblies use imperative form IF they include procedures, otherwise noun phrases
        if grep -q "include::.*proc-.*\.adoc" "$FILE"; then
            EXPECTED_FORM="imperative"
        else
            EXPECTED_FORM="noun phrase"
        fi
        ;;
    SNIPPET)
        PREFIX="snip-"
        MODULE_TYPE="SNIPPET"
        EXPECTED_FORM="any"
        ;;
    *)
        echo "? $FILE (unknown content type: $CONTENT_TYPE)"
        return 0
        ;;
esac

# Track if any changes will be made
WILL_CHANGE=false

# STEP 0: Add content type metadata if missing
ADDED_METADATA=false
if ! grep -q "^:_mod-docs-content-type:" "$FILE"; then
    ADDED_METADATA=true
    WILL_CHANGE=true
fi

# Extract current title (H1 heading) and expand attributes
TITLE_RAW=$(grep "^= " "$FILE" | head -1 | sed 's/^= //')
if [ -z "$TITLE_RAW" ]; then
    echo "Error: No title found in $FILE (looking for '= Title')"
    exit 1
fi

# Expand any attributes in the title (e.g., {title} → actual title value)
TITLE=$(expand_attributes "$TITLE_RAW" "$FILE")

# STEP 1: Check if title needs fixing
FIXED_TITLE="$TITLE"
TITLE_CHANGED=false
if [ "$EXPECTED_FORM" = "imperative" ]; then
    # Extract first word (handling attributes)
    FIRST_WORD=$(echo "$TITLE" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')

    if [[ "$FIRST_WORD" =~ ing$ ]] && [[ ! "$FIRST_WORD" =~ ^\{.*\}$ ]]; then
        # Convert gerund to imperative
        # shellcheck disable=SC2001  # sed is appropriate for title transformations
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

        TITLE_CHANGED=true
        WILL_CHANGE=true
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
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9-]/-/g' | \
    sed 's/--*/-/g' | \
    sed 's/^-//;s/-$//')

# Expected filename
EXPECTED_FILENAME="${PREFIX}${EXPECTED_ID}.adoc"
NEW_FILE="$(dirname "$FILE")/$EXPECTED_FILENAME"

# Check if changes are needed
if [ "$CURRENT_ID" != "$EXPECTED_ID" ] || [ "$FILE" != "$NEW_FILE" ]; then
    WILL_CHANGE=true
fi

# If no changes needed, just show checkmark and return
if [ "$WILL_CHANGE" = false ]; then
    echo "✓ $FILE"
    return 0
fi

# Changes needed - show header
echo ""
echo "📝 $FILE"

# Apply content type metadata if needed
if [ "$ADDED_METADATA" = true ]; then
    sed -i.bak "1s/^/:_mod-docs-content-type: ${MODULE_TYPE}\n\n/" "$FILE"
    rm -f "${FILE}.bak"
    echo "  + Added :_mod-docs-content-type: ${MODULE_TYPE}"
fi

# Apply title changes if needed
if [ "$TITLE_CHANGED" = true ]; then
    # Actually update title in file
    OLD_TITLE=$(grep "^= " "$FILE" | head -1 | sed 's/^= //')
    sed -i.bak "s/^= ${OLD_TITLE}/= ${TITLE}/" "$FILE"
    rm -f "${FILE}.bak"
    echo "  * Title: ${OLD_TITLE} → ${TITLE}"
fi

# Update ID and context if changed
if [ "$CURRENT_ID" != "$EXPECTED_ID" ]; then
    if [ "$MODULE_TYPE" = "ASSEMBLY" ]; then
        # For assemblies, update both [id=...] and :context:
        sed -i.bak "s/\[id=\"[^\"]*_{context}\"\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
        sed -i.bak "s/\[id='[^']*_{context}'\]/[id='${EXPECTED_ID}_{context}']/" "$FILE"
        sed -i.bak "s/^:context: .*$/:context: ${EXPECTED_ID}/" "$FILE"
        echo "  * ID: ${CURRENT_ID} → ${EXPECTED_ID}"
        echo "  * Context: ${CURRENT_ID} → ${EXPECTED_ID}"
    else
        # For modules, just update [id=...]
        sed -i.bak "s/\[id=\"[^\"]*_{context}\"\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
        sed -i.bak "s/\[id='[^']*_{context}'\]/[id='${EXPECTED_ID}_{context}']/" "$FILE"
        echo "  * ID: ${CURRENT_ID} → ${EXPECTED_ID}"
    fi
    rm -f "${FILE}.bak"
fi

# Update xrefs if ID changed
if [ "$CURRENT_ID" != "$EXPECTED_ID" ]; then
    XREF_COUNT=0
    while read -r xref_file; do
        sed -i.bak "s/xref:${CURRENT_ID}_/xref:${EXPECTED_ID}_/g" "$xref_file"
        rm -f "${xref_file}.bak"
        XREF_COUNT=$((XREF_COUNT + 1))
    done < <(grep -rl "xref:${CURRENT_ID}_" assemblies/ modules/ titles/ 2>/dev/null)

    if [ $XREF_COUNT -gt 0 ]; then
        echo "  * Updated $XREF_COUNT xref(s)"
    fi
fi

# Rename file if needed
if [ "$FILE" != "$NEW_FILE" ]; then
    OLD_BASENAME=$(basename "$FILE")
    NEW_BASENAME=$(basename "$NEW_FILE")

    git mv "$FILE" "$NEW_FILE" 2>/dev/null || mv "$FILE" "$NEW_FILE"
    echo "  * File: $(basename "$FILE") → $NEW_BASENAME"

    # Update includes - use process substitution to avoid subshell
    INCLUDE_COUNT=0
    while read -r include_file; do
        if grep -q "include::.*${OLD_BASENAME}\[" "$include_file"; then
            sed -i.bak "s|include::\(.*\)${OLD_BASENAME}\[|include::\1${NEW_BASENAME}[|g" "$include_file"
            rm -f "${include_file}.bak"
            INCLUDE_COUNT=$((INCLUDE_COUNT + 1))
        fi
    done < <(find assemblies/ modules/ titles/ -name "*.adoc" -type f 2>/dev/null)

    if [ $INCLUDE_COUNT -gt 0 ]; then
        echo "  * Updated $INCLUDE_COUNT include(s)"
    fi

    FILE="$NEW_FILE"
fi
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
    echo "  STEP 0: Detect module type from :_mod-docs-content-type: metadata"
    echo "          (falls back to filename prefix if no metadata present)"
    echo "  STEP 1: Add :_mod-docs-content-type: metadata if missing"
    echo "  STEP 2: Fix title to use correct form (imperative for procedures/assemblies)"
    echo "  STEP 3: Calculate expected ID (title → lowercase, extract attribute names, hyphens)"
    echo "  STEP 4: Update [id=\"...\"] to match"
    echo "  STEP 5: Update :context: for assemblies"
    echo "  STEP 6: Rename file using git mv (with prefix from content type)"
    echo "  STEP 7: Update all xrefs and include statements"
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

    # Skip attributes.adoc and master.adoc files (special files)
    basename_file=$(basename "$file")
    if [[ "$basename_file" == "attributes.adoc" ]] || [[ "$basename_file" == "master.adoc" ]]; then
        SKIPPED_FILES+=("$file")
        continue
    fi

    # Check if file has content type metadata or module prefix
    content_type=$(get_content_type "$file")
    basename_no_ext=$(basename "$file" .adoc)

    if [[ -n "$content_type" ]] || [[ "$basename_no_ext" =~ ^(proc|con|ref|assembly|snip)- ]]; then
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
done

echo ""
echo "=== Summary ==="
echo "✓ Processed ${#MODULE_FILES[@]} module file(s)"
