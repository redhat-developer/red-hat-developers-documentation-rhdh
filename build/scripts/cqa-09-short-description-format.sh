#!/bin/bash
# cqa-09-short-description-format.sh
# Validates short description formatting (CQA-9)
#
# Usage: ./cqa-09-short-description-format.sh [--fix] [--all] <file-path>
#
# Checks:
#   - [role="_abstract"] marker present
#   - No empty line after [role="_abstract"]
#   - Abstract length: 50-300 characters
#
# Autofix:
#   - Removes blank line after [role="_abstract"]
#   - Inserts [role="_abstract"] marker when missing (before first paragraph after title)
#
# Skips:
#   - SNIPPET files

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa09_check() {
    local target="$1"

    cqa_header "9" "Verify short description format" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue

        local content_type
        content_type=$(cqa_get_content_type "$file")
        [[ -z "$content_type" ]] && continue
        [[ "$content_type" == "SNIPPET" ]] && continue

        cqa_file_start "$file"

        # Check for [role="_abstract"]
        if ! grep -q '^\[role="_abstract"\]' "$file"; then
            if [[ "$CQA_FIX_MODE" == true ]]; then
                # Find the first non-empty, non-metadata line after the title
                local title_ln
                title_ln=$(grep -n "^= " "$file" | head -1 | cut -d: -f1)
                if [[ -n "$title_ln" ]]; then
                    local insert_ln=$((title_ln + 1))
                    local next_content
                    next_content=$(sed -n "${insert_ln}p" "$file")
                    # Skip past :context:, :attr:, blank lines, [id=...] etc.
                    while [[ "$next_content" =~ ^: ]] || [[ -z "$next_content" ]] || [[ "$next_content" =~ ^\[id= ]] || [[ "$next_content" =~ ^ifdef:: ]]; do
                        insert_ln=$((insert_ln + 1))
                        next_content=$(sed -n "${insert_ln}p" "$file")
                        # Safety: don't go past end of file
                        [[ $insert_ln -gt $(wc -l < "$file") ]] && break
                    done
                    # Insert [role="_abstract"] before the first content line
                    sed -i "${insert_ln}i\\[role=\"_abstract\"]" "$file"
                    cqa_fail_autofix "$file" "$insert_ln" "Missing [role=\"_abstract\"] marker" "Inserted [role=\"_abstract\"] before first paragraph"
                fi
            else
                cqa_fail_autofix "$file" "" "Missing [role=\"_abstract\"] marker" "Insert marker before first paragraph"
            fi
            continue
        fi

        # Get line number of [role="_abstract"]
        local abstract_line
        abstract_line=$(grep -n '^\[role="_abstract"\]' "$file" | head -1 | cut -d: -f1)
        local next_line=$((abstract_line + 1))
        local next_content
        next_content=$(sed -n "${next_line}p" "$file")

        # Check if next line is empty (violation)
        if [[ -z "$next_content" ]]; then
            if [[ "$CQA_FIX_MODE" == true ]]; then
                sed -i "${next_line}d" "$file"
                cqa_fail_autofix "$file" "$next_line" "Empty line after [role=\"_abstract\"]" "Removed blank line"
            else
                cqa_fail_autofix "$file" "$next_line" "Empty line after [role=\"_abstract\"] (abstract must start on next line)"
            fi
            continue
        fi

        # Extract abstract text (can be multi-line, ends at first empty line or next section)
        local abstract_text=""
        local ln=$next_line
        while true; do
            local line_content
            line_content=$(sed -n "${ln}p" "$file")
            # Stop at empty line, section marker, or include statement
            if [[ -z "$line_content" ]] || [[ "$line_content" =~ ^\. ]] || [[ "$line_content" =~ ^include:: ]]; then
                break
            fi
            abstract_text="${abstract_text}${line_content} "
            ln=$((ln + 1))
        done

        # Clean and count
        abstract_text=$(echo "$abstract_text" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr -s ' ')

        # If abstract is a single attribute reference like {abstract}, resolve it
        if [[ "$abstract_text" =~ ^\{([a-z][-a-z0-9]*)\}$ ]]; then
            local attr_name="${BASH_REMATCH[1]}"
            local attr_value
            attr_value=$(grep -m1 "^:${attr_name}:" "$file" 2>/dev/null | sed "s/^:${attr_name}: *//" || true)
            if [[ -n "$attr_value" ]]; then
                abstract_text="$attr_value"
            fi
        fi

        local char_count=${#abstract_text}

        if [[ $char_count -lt 50 ]]; then
            cqa_fail_manual "$file" "$next_line" "Abstract too short (${char_count} chars, minimum 50)"
        elif [[ $char_count -gt 300 ]]; then
            cqa_fail_manual "$file" "$next_line" "Abstract too long (${char_count} chars, maximum 300)"
        else
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa09_check
exit "$(cqa_exit_code)"
