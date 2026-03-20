#!/bin/bash
# cqa-04-modules-use-official-templates.sh
# Verify modules use official Red Hat modular documentation templates (CQA #4)
#
# Usage: ./cqa-04-modules-use-official-templates.sh [--fix] [--all] <file-path>
#
# Checks:
#   - PROCEDURE modules must not have custom subheadings (===)
#   - PROCEDURE modules must have a .Procedure section
#   - .Prerequisite (singular) should be .Prerequisites (plural)
#   - All modules must have an intro paragraph ([role="_abstract"])
#   - CONCEPT modules must not have .Procedure sections
#
# Autofix:
#   - .Prerequisite -> .Prerequisites
#   - Inserts missing [role="_abstract"] marker
#   - Inserts missing .Procedure section before first numbered list
#
# Skips:
#   - ASSEMBLY and SNIPPET files
#   - master.adoc and attributes.adoc files

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa04_check() {
    local target="$1"

    cqa_header "4" "Verify Module Templates" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
        [[ "$(basename "$file")" == "master.adoc" ]] && continue

        local content_type
        content_type=$(cqa_get_content_type "$file")
        [[ -z "$content_type" ]] && continue
        [[ "$content_type" == "ASSEMBLY" ]] && continue
        [[ "$content_type" == "SNIPPET" ]] && continue

        cqa_file_start "$file"
        cqa_compute_block_ranges "$file"

        # Check 1: PROCEDURE modules must not have custom subheadings (===)
        if [[ "$content_type" == "PROCEDURE" ]]; then
            while IFS=: read -r line_num line_content; do
                [[ -z "$line_num" ]] && continue
                cqa_is_in_block "$file" "$line_num" && continue
                cqa_fail_manual "$file" "$line_num" "Custom subheading in PROCEDURE: $line_content -- extract to separate module"
            done < <(grep -n "^=== " "$file" 2>/dev/null || true)
        fi

        # Check 2: PROCEDURE modules must have .Procedure section
        if [[ "$content_type" == "PROCEDURE" ]]; then
            if ! grep -q "^\.Procedure" "$file" 2>/dev/null; then
                if [[ "$CQA_FIX_MODE" == true ]]; then
                    # Find the first ordered list item and insert .Procedure before it
                    local first_ol
                    first_ol=$(grep -n '^\. ' "$file" | head -1 | cut -d: -f1)
                    if [[ -n "$first_ol" ]]; then
                        sed -i "${first_ol}i\\\\.Procedure" "$file"
                        cqa_fail_autofix "$file" "$first_ol" "Missing .Procedure section" "Inserted .Procedure before first numbered list"
                    else
                        cqa_fail_manual "$file" "" "Missing .Procedure section (no numbered list found to insert before)"
                    fi
                else
                    cqa_fail_autofix "$file" "" "Missing .Procedure section" "Insert .Procedure before numbered steps"
                fi
            fi
        fi

        # Check 3: .Prerequisite should be .Prerequisites (plural)
        if [[ "$content_type" == "PROCEDURE" ]]; then
            while IFS=: read -r line_num line_content; do
                [[ -z "$line_num" ]] && continue
                cqa_is_in_block "$file" "$line_num" && continue
                if [[ "$line_content" == ".Prerequisite" ]]; then
                    if [[ "$CQA_FIX_MODE" == true ]]; then
                        sed -i "${line_num}s/^\.Prerequisite$/.Prerequisites/" "$file"
                    fi
                    cqa_fail_autofix "$file" "$line_num" ".Prerequisite should be .Prerequisites (plural)" "Changed to .Prerequisites"
                fi
            done < <(grep -n "^\.Prerequisite$" "$file" 2>/dev/null || true)
        fi

        # Check 4: All modules must have an intro paragraph
        if ! grep -q '\[role="_abstract"\]' "$file" 2>/dev/null; then
            cqa_delegated "$file" "" "9" "Missing [role=\"_abstract\"] intro paragraph"
        fi

        # Check 5: CONCEPT modules must not have .Procedure sections
        if [[ "$content_type" == "CONCEPT" ]]; then
            if grep -q "^\.Procedure" "$file" 2>/dev/null; then
                cqa_fail_manual "$file" "" "CONCEPT module has .Procedure section (move to a PROCEDURE module)"
            fi
        fi

        if [[ "$_CQA_CURRENT_FILE_HAS_ISSUES" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
    return 0
}

cqa_run_for_each_title _cqa04_check
exit "$(cqa_exit_code)"
