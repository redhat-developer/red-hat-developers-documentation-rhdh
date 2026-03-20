#!/bin/bash
# cqa-08-short-description-content.sh
# Validates short description content quality (CQA #8)
#
# Usage: ./cqa-08-short-description-content.sh [--fix] [--all] <file-path>
#
# Checks:
#   - No self-referential language ("This section...", "This document...")
#   - Abstract present (has [role="_abstract"] marker)
#   - Abstract not empty
#
# Autofix:
#   - Removes self-referential prefixes ("This section describes" -> "")
#
# Skips:
#   - SNIPPET files
#   - attributes.adoc and master.adoc files

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# Self-referential patterns to detect
SELF_REF_PATTERNS=(
    "This section"
    "This document"
    "This chapter"
    "This guide"
    "This module"
    "This assembly"
    "This topic"
    "The following section"
    "The following document"
    "Here we"
    "Here you will"
    "In this section"
    "In this document"
)

# Self-referential prefixes that can be auto-removed
SELF_REF_REMOVABLE=(
    "This section describes "
    "This section explains "
    "This section provides "
    "This document describes "
    "This document explains "
    "This topic describes "
    "This topic explains "
    "In this section, you "
    "In this section, we "
)

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa08_check() {
    local target="$1"

    cqa_header "8" "Verify Short Description Content Quality" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
        [[ "$(basename "$file")" == "master.adoc" ]] && continue

        local content_type
        content_type=$(cqa_get_content_type "$file")
        [[ -z "$content_type" ]] && continue
        [[ "$content_type" == "SNIPPET" ]] && continue

        cqa_file_start "$file"

        # Check for [role="_abstract"] marker
        if ! grep -q '\[role="_abstract"\]' "$file" 2>/dev/null; then
            cqa_delegated "$file" "" "9" "Missing [role=\"_abstract\"] marker"
            continue
        fi

        # Extract the abstract text (line after [role="_abstract"])
        local abstract_line
        abstract_line=$(grep -n '\[role="_abstract"\]' "$file" | head -1 | cut -d: -f1)
        local abstract_text
        abstract_text=$(sed -n "$((abstract_line + 1))p" "$file" 2>/dev/null)

        # Check if abstract is empty
        if [[ -z "$abstract_text" ]] || [[ "$abstract_text" =~ ^[[:space:]]*$ ]]; then
            cqa_fail_manual "$file" "$((abstract_line + 1))" "Empty abstract (no text after [role=\"_abstract\"])"
            continue
        fi

        # Check for self-referential language in abstract
        local found_self_ref=false
        for pattern in "${SELF_REF_PATTERNS[@]}"; do
            if echo "$abstract_text" | grep -qi "$pattern" 2>/dev/null; then
                found_self_ref=true
                # Check if this is auto-removable
                local can_autofix=false
                for removable in "${SELF_REF_REMOVABLE[@]}"; do
                    if echo "$abstract_text" | grep -qi "^${removable}" 2>/dev/null; then
                        can_autofix=true
                        if [[ "$CQA_FIX_MODE" == true ]]; then
                            # Remove the self-referential prefix, capitalize next word
                            local next_line=$((abstract_line + 1))
                            sed -i "${next_line}s/${removable}//I" "$file"
                            # Capitalize first letter of remaining text
                            local remaining
                            remaining=$(sed -n "${next_line}p" "$file")
                            local first_char="${remaining:0:1}"
                            local upper_char
                            upper_char=$(echo "$first_char" | tr '[:lower:]' '[:upper:]')
                            sed -i "${next_line}s/^${first_char}/${upper_char}/" "$file"
                            cqa_fail_autofix "$file" "$next_line" "Self-referential: \"$pattern\"" "Removed self-referential prefix"
                        else
                            cqa_fail_autofix "$file" "$((abstract_line + 1))" "Self-referential language in abstract: \"$pattern\"" "Remove prefix"
                        fi
                        break
                    fi
                done
                if [[ "$can_autofix" == false ]]; then
                    cqa_fail_manual "$file" "$((abstract_line + 1))" "Self-referential language in abstract: \"$pattern\" -- rewrite needed"
                fi
            fi
        done

        if [[ "$found_self_ref" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
    return 0
}

cqa_run_for_each_title _cqa08_check
exit "$(cqa_exit_code)"
