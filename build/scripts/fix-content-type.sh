#!/bin/bash
# Fix content type metadata based on file content analysis (CQA requirement #11)
#
# Usage: ./fix-content-type.sh [file]
#   file: Optional. If provided, fixes that file and all its includes recursively
#         Example: ./fix-content-type.sh titles/install-rhdh-ocp/master.adoc
#           Processes: master.adoc → assemblies → all included modules (recursive)
#         If not provided, processes all .adoc files in artifacts/, assemblies/, modules/, and titles/
#
# Content type detection logic:
# - ASSEMBLY: File includes one or more modules with proc-, ref-, or con- prefix, OR assembly- filename prefix
# - PROCEDURE: File has .Procedure section followed by steps, OR proc- filename prefix
# - CONCEPT: File has con- filename prefix (no distinctive content pattern)
# - REFERENCE: File has ref- filename prefix (no distinctive content pattern)
# - SNIPPET: File has snip- filename prefix (no distinctive content pattern)
#
# This script automatically:
# - Adds or updates :_mod-docs-content-type: metadata
# - Ensures metadata is on the first line of the file
# - Removes duplicate occurrences of the metadata

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Function to extract included files from a given file
get_includes() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi

    # Extract include:: statements and resolve relative paths
    grep "^include::" "$file" 2>/dev/null | sed 's/^include:://' | sed 's/\[.*//' | while read -r include_path; do
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
            # Make path relative to REPO_ROOT
            local normalized_path
            normalized_path=$(realpath --relative-to="$REPO_ROOT" "$resolved_path" 2>/dev/null) || normalized_path="$resolved_path"
            echo "$normalized_path"
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

# Function to detect content type from file content
detect_content_type() {
    local file="$1"
    local basename_file
    basename_file=$(basename "$file" .adoc)

    local content_type=""
    local has_filename_violation=false

    # Check if file includes modules with proc-, ref-, or con- prefix
    # This makes it an ASSEMBLY
    if grep "^include::" "$file" 2>/dev/null | grep -qE "include::.*(proc-|ref-|con-)"; then
        content_type="ASSEMBLY"
    fi

    # Check if file has .Procedure section (sufficient for content-based detection)
    # Structure validation (checking for proper list items) is done separately in validate_procedure_structure()
    if [[ -z "$content_type" ]] && grep -q "^\.Procedure" "$file" 2>/dev/null; then
        content_type="PROCEDURE"
    fi

    # If content type detected from content, check filename compliance
    if [[ -n "$content_type" ]]; then
        # Check if filename uses alternative prefix for this type
        if [[ "$content_type" == "PROCEDURE" ]]; then
            if [[ "$basename_file" == proc_* ]] || [[ "$basename_file" == procedure-* ]] || [[ "$basename_file" == procedure_* ]]; then
                has_filename_violation=true
            fi
        fi
        # ASSEMBLY and other types don't have alternative prefixes to check

        if [[ "$has_filename_violation" == true ]]; then
            echo "${content_type}:filename-violation"
        else
            echo "$content_type"
        fi
        return 0
    fi

    # No content pattern matched - fall back to filename-based detection
    # These cannot be reliably detected from content patterns alone

    if [[ "$basename_file" == assembly-* ]]; then
        echo "ASSEMBLY"
        return 0
    fi

    # Standard prefixes (correct naming)
    if [[ "$basename_file" == proc-* ]]; then
        echo "PROCEDURE"
        return 0
    fi

    if [[ "$basename_file" == con-* ]]; then
        echo "CONCEPT"
        return 0
    fi

    if [[ "$basename_file" == ref-* ]]; then
        echo "REFERENCE"
        return 0
    fi

    if [[ "$basename_file" == snip-* ]]; then
        echo "SNIPPET"
        return 0
    fi

    # Alternative prefixes (filename violations but still detectable)
    if [[ "$basename_file" == proc_* ]] || [[ "$basename_file" == procedure-* ]] || [[ "$basename_file" == procedure_* ]]; then
        echo "PROCEDURE:filename-violation"
        return 0
    fi

    if [[ "$basename_file" == con_* ]] || [[ "$basename_file" == concept-* ]] || [[ "$basename_file" == concept_* ]]; then
        echo "CONCEPT:filename-violation"
        return 0
    fi

    if [[ "$basename_file" == ref_* ]] || [[ "$basename_file" == reference-* ]] || [[ "$basename_file" == reference_* ]]; then
        echo "REFERENCE:filename-violation"
        return 0
    fi

    if [[ "$basename_file" == snip_* ]]; then
        echo "SNIPPET:filename-violation"
        return 0
    fi

    # Cannot determine - return empty
    echo ""
    return 0
}

# Function to get current content type from file (must be on first line)
get_current_content_type() {
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

# Function to count total occurrences of content type metadata in file
count_content_type_occurrences() {
    local file="$1"
    local count
    count=$(grep -c "^:_mod-docs-content-type:" "$file" 2>/dev/null || true)
    if [[ -z "$count" ]]; then
        echo "0"
        return 0
    else
        echo "$count"
        return 0
    fi
}

# Function to remove all content type metadata from file
remove_all_content_type_metadata() {
    local file="$1"
    sed -i.bak '/^:_mod-docs-content-type:/d' "$file"
    rm -f "${file}.bak"
    return 0
}

# Function to fix PROCEDURE structure - convert single numbered step to unnumbered
fix_procedure_structure() {
    local file="$1"

    # Check if file has .Procedure section
    if ! grep -q "^\.Procedure" "$file" 2>/dev/null; then
        return 1
    fi

    # Get content after .Procedure section
    local after_procedure
    after_procedure=$(grep -A 50 "^\.Procedure" "$file" 2>/dev/null | tail -n +2)

    # Check for include statements (don't fix files with includes - they're valid)
    local include_count
    include_count=$(echo "$after_procedure" | grep -c "^include::" || true)

    if [[ $include_count -gt 0 ]]; then
        # Has includes - don't try to fix
        return 1
    fi

    # Check for single unnumbered list item (starts with *)
    local unnumbered_count
    unnumbered_count=$(echo "$after_procedure" | grep -c "^\* " || true)

    # Check for numbered list items (starts with one or more dots followed by space)
    local numbered_count
    numbered_count=$(echo "$after_procedure" | grep -cE "^\\.+ " || true)

    # Fix if exactly 1 numbered step (convert to unnumbered)
    if [[ $numbered_count -eq 1 && $unnumbered_count -eq 0 ]]; then
        # Find and replace the single numbered step with unnumbered
        sed -i.bak '/^\.Procedure/,/^[^[:space:]]/{s/^\(\.\.\?\.* \)/* /}' "$file"
        rm -f "${file}.bak"
        return 0
    fi

    return 1
}

# Function to validate PROCEDURE structure
validate_procedure_structure() {
    local file="$1"

    # Check if file has .Procedure section
    if ! grep -q "^\.Procedure" "$file" 2>/dev/null; then
        echo "Missing .Procedure section"
        return 1
    fi

    # Get content after .Procedure section
    local after_procedure
    after_procedure=$(grep -A 50 "^\.Procedure" "$file" 2>/dev/null | tail -n +2)

    # Check for include statements (valid pattern - procedure steps in snippets)
    local include_count
    include_count=$(echo "$after_procedure" | grep -c "^include::" || true)

    # Check for single unnumbered list item (starts with *)
    local unnumbered_count
    unnumbered_count=$(echo "$after_procedure" | grep -c "^\* " || true)

    # Check for numbered list items (starts with one or more dots followed by space)
    local numbered_count
    numbered_count=$(echo "$after_procedure" | grep -cE "^\\.+ " || true)

    # Valid patterns:
    # 1. One or more include statements (procedure steps in snippets, with or without additional steps)
    # 2. Exactly one unnumbered item (single bullet)
    # 3. Two or more numbered items (numbered steps)
    if [[ $include_count -gt 0 ]]; then
        # Valid: has include statements - any combination with includes is valid
        return 0
    elif [[ $unnumbered_count -eq 1 && $numbered_count -eq 0 ]]; then
        # Valid: single unnumbered item
        return 0
    elif [[ $numbered_count -ge 2 ]]; then
        # Valid: multiple numbered items (at least 2)
        return 0
    elif [[ $numbered_count -eq 1 && $unnumbered_count -eq 0 ]]; then
        # Invalid: only one numbered item without includes (should be multiple or use unnumbered)
        echo ".Procedure section has only 1 numbered step (should be multiple numbered steps or 1 unnumbered item)"
        return 1
    else
        # Invalid or unknown structure - be permissive and accept it
        return 0
    fi
}

# Function to process a single file
process_file() {
    local file="$1"

    # Skip attributes.adoc files - they are not modular doc modules
    local basename_file
    basename_file=$(basename "$file")
    if [[ "$basename_file" == "attributes.adoc" ]]; then
        return 0
    fi

    # master.adoc files are not modular doc modules and should not have content type
    if [[ "$basename_file" == "master.adoc" ]]; then
        local occurrence_count
        occurrence_count=$(count_content_type_occurrences "$file")

        if [[ "$occurrence_count" -eq 0 ]]; then
            # Compliant - no output
            return 0
        else
            echo ""
            echo "📝 $file"
            echo "  - Remove content type metadata (master.adoc should not have content type)"
            remove_all_content_type_metadata "$file"
            echo ""
            return 0
        fi
    fi

    # Detect content type from content
    local detected_type_raw
    detected_type_raw=$(detect_content_type "$file")

    # Skip if we can't detect a type
    if [[ -z "$detected_type_raw" ]]; then
        echo "? $file (cannot determine content type)"
        return 0
    fi

    # Check for filename violation
    local detected_type
    local filename_violation=false
    if [[ "$detected_type_raw" == *":filename-violation" ]]; then
        detected_type="${detected_type_raw%:filename-violation}"
        filename_violation=true
    else
        detected_type="$detected_type_raw"
    fi

    # Get current content type (only from first line)
    local current_type
    current_type=$(get_current_content_type "$file")

    # Count total occurrences of content type metadata
    local occurrence_count
    occurrence_count=$(count_content_type_occurrences "$file")

    # Check if everything is correct:
    # - Detected type matches current type
    # - Exactly 1 occurrence
    # - It's on the first line (which we already know if current_type is set)
    if [[ "$current_type" == "$detected_type" ]] && [[ "$occurrence_count" -eq 1 ]]; then
        # Compliant - check for warnings
        local has_warnings=false

        # Check for filename violation
        if [[ "$filename_violation" == true ]]; then
            if [[ "$has_warnings" == false ]]; then
                echo ""
                echo "⚠️  $file"
                has_warnings=true
            fi
            local basename_file
            basename_file=$(basename "$file" .adoc)
            echo "  Filename violation: Use standard prefix format (e.g., proc- not proc_ or procedure-)"
            echo "    Current: ${basename_file}.adoc"
        fi

        # Fix and validate PROCEDURE structure if applicable
        if [[ "$detected_type" == "PROCEDURE" ]]; then
            # Try to fix single numbered step issue first
            local was_fixed=false
            if fix_procedure_structure "$file"; then
                was_fixed=true
                echo ""
                echo "📝 $file"
                echo "  * Convert single numbered step to unnumbered item"
                echo ""
                return 0
            fi

            # Validate PROCEDURE structure
            local validation_msg
            validation_msg=$(validate_procedure_structure "$file")
            if [[ -n "$validation_msg" ]]; then
                if [[ "$has_warnings" == false ]]; then
                    echo ""
                    echo "⚠️  $file"
                    has_warnings=true
                fi
                echo "  $validation_msg"
            fi
        fi

        if [[ "$has_warnings" == true ]]; then
            echo ""
        fi
        return 0
    fi

    # Changes needed - show header
    echo ""
    echo "📝 $file"

    # Track what we're fixing
    local fixes=()

    # Determine what needs fixing
    if [[ -z "$current_type" ]]; then
        if [[ "$occurrence_count" -gt 0 ]]; then
            fixes+=("Move content type to first line")
        else
            fixes+=("Add :_mod-docs-content-type: ${detected_type}")
        fi
    else
        if [[ "$current_type" != "$detected_type" ]]; then
            fixes+=("Content type: ${current_type} → ${detected_type}")
        fi
    fi

    if [[ "$occurrence_count" -gt 1 ]]; then
        fixes+=("Remove $((occurrence_count - 1)) duplicate(s)")
    fi

    # Remove all existing content type metadata
    if [[ "$occurrence_count" -gt 0 ]]; then
        remove_all_content_type_metadata "$file"
    fi

    # Add correct metadata on first line
    sed -i.bak "1s/^/:_mod-docs-content-type: ${detected_type}\n\n/" "$file"
    rm -f "${file}.bak"

    # Show what was fixed
    for fix in "${fixes[@]}"; do
        if [[ "$fix" == "Add"* ]]; then
            echo "  + $fix"
        else
            echo "  * $fix"
        fi
    done

    # Show filename violation warning if applicable
    if [[ "$filename_violation" == true ]]; then
        local basename_file
        basename_file=$(basename "$file" .adoc)
        echo "  ⚠️  Filename violation: Use standard prefix format (e.g., proc- not proc_ or procedure-)"
        echo "    Current: ${basename_file}.adoc"
    fi

    # Fix and validate PROCEDURE structure if applicable
    if [[ "$detected_type" == "PROCEDURE" ]]; then
        # Try to fix single numbered step issue first
        if fix_procedure_structure "$file"; then
            echo "  * Convert single numbered step to unnumbered item"
        fi

        # Validate PROCEDURE structure
        local validation_msg
        validation_msg=$(validate_procedure_structure "$file")
        if [[ -n "$validation_msg" ]]; then
            echo "  $validation_msg"
        fi
    fi

    echo ""
}

# Color codes for summary
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== Fix Content Type Metadata Based on File Content ==="
echo ""

# Determine which files to process
FILES_TO_PROCESS=()

if [[ $# -eq 1 ]]; then
    # Process specified file and all its includes
    TARGET_FILE="$1"
    if [[ ! -f "$TARGET_FILE" ]]; then
        echo "Error: File not found: $TARGET_FILE" >&2
        exit 1
    fi
    echo "Processing file and includes: $TARGET_FILE"
    echo ""
    collect_files "$TARGET_FILE" FILES_TO_PROCESS
else
    # Process all .adoc files in artifacts/, assemblies/, modules/, and titles/ directories
    while IFS= read -r file; do
        FILES_TO_PROCESS+=("$file")
    done < <(find artifacts assemblies modules titles -name "*.adoc" -type f 2>/dev/null | sort)
fi

# Process each file
PROCESSED=0
COMPLIANT=0
CHANGED=0
CANNOT_DETERMINE=0
FILENAME_VIOLATIONS=0
MISSING_PROCEDURE_SECTION=0
INVALID_PROCEDURE_STRUCTURE=0

for file in "${FILES_TO_PROCESS[@]}"; do
    PROCESSED=$((PROCESSED + 1))

    # Check if file was modified (by checking if it shows a change message)
    OUTPUT=$(process_file "$file")

    if [[ "$OUTPUT" == *"📝"* ]]; then
        CHANGED=$((CHANGED + 1))
        echo "$OUTPUT"
    elif [[ "$OUTPUT" == *"?"* ]]; then
        CANNOT_DETERMINE=$((CANNOT_DETERMINE + 1))
        echo "$OUTPUT"
    elif [[ "$OUTPUT" == *"⚠️"* ]]; then
        # Validation warning - still compliant but has structural issues
        COMPLIANT=$((COMPLIANT + 1))

        # Track violation types
        if [[ "$OUTPUT" == *"Filename violation"* ]]; then
            FILENAME_VIOLATIONS=$((FILENAME_VIOLATIONS + 1))
        fi
        if [[ "$OUTPUT" == *"Missing .Procedure section"* ]]; then
            MISSING_PROCEDURE_SECTION=$((MISSING_PROCEDURE_SECTION + 1))
        fi
        if [[ "$OUTPUT" == *".Procedure section has only 1 numbered step"* ]] || [[ "$OUTPUT" == *".Procedure section not followed by proper list structure"* ]]; then
            INVALID_PROCEDURE_STRUCTURE=$((INVALID_PROCEDURE_STRUCTURE + 1))
        fi

        echo "$OUTPUT"
    else
        # No output = compliant
        COMPLIANT=$((COMPLIANT + 1))
    fi
done

echo ""
echo "=== Summary ==="
echo "Files processed: $PROCESSED"
echo "Compliant content type attribute: $COMPLIANT"

# Show violation breakdown if any violations found
TOTAL_VIOLATIONS=$((FILENAME_VIOLATIONS + MISSING_PROCEDURE_SECTION + INVALID_PROCEDURE_STRUCTURE))
if [[ $TOTAL_VIOLATIONS -gt 0 ]]; then
    echo ""
    echo "Violation breakdown:"
    if [[ $FILENAME_VIOLATIONS -gt 0 ]]; then
        echo "  - Filename violations: $FILENAME_VIOLATIONS"
    fi
    if [[ $MISSING_PROCEDURE_SECTION -gt 0 ]]; then
        echo "  - Missing .Procedure section: $MISSING_PROCEDURE_SECTION"
    fi
    if [[ $INVALID_PROCEDURE_STRUCTURE -gt 0 ]]; then
        echo "  - Invalid .Procedure structure: $INVALID_PROCEDURE_STRUCTURE"
    fi
fi

if [[ $CHANGED -gt 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ Updated $CHANGED file(s)${NC}"
fi
if [[ $CANNOT_DETERMINE -gt 0 ]]; then
    echo ""
    echo "? Cannot determine content type for $CANNOT_DETERMINE file(s)"
fi
