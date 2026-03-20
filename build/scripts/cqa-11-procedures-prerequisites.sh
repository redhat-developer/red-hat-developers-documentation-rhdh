#!/bin/bash
# cqa-11-procedures-prerequisites.sh
# Validates procedure prerequisites requirements (CQA #11)
#
# Usage: ./cqa-11-procedures-prerequisites.sh [--fix] [--all] <file-path>
#
# Checks:
#   - .Prerequisites label used (not .Prerequisite singular)
#   - Prerequisites use bulleted list (not numbered)
#   - No more than 10 prerequisites per procedure
#
# Autofix:
#   - .Prerequisite -> .Prerequisites
#   - Numbered list -> bulleted list in prerequisites section
#
# Skips:
#   - Non-PROCEDURE files
#   - attributes.adoc and master.adoc files

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa11_check() {
    local target="$1"

    cqa_header "11" "Verify Procedure Prerequisites" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
        [[ "$(basename "$file")" == "master.adoc" ]] && continue

        local content_type
        content_type=$(cqa_get_content_type "$file")
        [[ -z "$content_type" ]] && continue
        [[ "$content_type" != "PROCEDURE" ]] && continue

        cqa_file_start "$file"

        local file_has_issue=false

        # Check 1: Singular .Prerequisite (should be .Prerequisites)
        if grep -q "^\.Prerequisite$" "$file" 2>/dev/null; then
            local prereq_ln
            prereq_ln=$(grep -n "^\.Prerequisite$" "$file" | head -1 | cut -d: -f1)
            if [[ "$CQA_FIX_MODE" == true ]]; then
                sed -i 's/^\.Prerequisite$/.Prerequisites/' "$file"
            fi
            cqa_fail_autofix "$file" "$prereq_ln" ".Prerequisite should be .Prerequisites (plural)" "Fixed: .Prerequisite -> .Prerequisites"
            file_has_issue=true
        fi

        # Check 2: Count prerequisites (max 10)
        if grep -q "^\.Prerequisites" "$file" 2>/dev/null; then
            local prereq_items
            prereq_items=$(awk '/^\.Prerequisites/{flag=1; next} flag && /^\.(Procedure|Verification|Troubleshooting|Next steps|Additional)/{exit} flag && /^\* /{count++} END{print count+0}' "$file" 2>/dev/null)
            if [[ $prereq_items -gt 10 ]]; then
                cqa_fail_manual "$file" "" "Too many prerequisites: $prereq_items (max 10) -- combine or prioritize"
                file_has_issue=true
            fi

            # Check 3: Prerequisites using numbered list (should be bulleted)
            local numbered_prereqs
            numbered_prereqs=$(awk '/^\.Prerequisites/{flag=1; next} flag && /^\.(Procedure|Verification|Troubleshooting|Next steps|Additional)/{exit} flag && /^\. /{count++} END{print count+0}' "$file" 2>/dev/null)
            if [[ $numbered_prereqs -gt 0 ]]; then
                if [[ "$CQA_FIX_MODE" == true ]]; then
                    # Convert numbered list items to bulleted in prerequisites section
                    sed -i '/^\.Prerequisites$/,/^\.\(Procedure\|Verification\|Troubleshooting\|Next steps\|Additional\)/{/^\.Prerequisites$/!{/^\.\(Procedure\|Verification\|Troubleshooting\|Next steps\|Additional\)/!s/^\. /* /}}' "$file"
                fi
                local prereq_ln
                prereq_ln=$(grep -n "^\.Prerequisites" "$file" | head -1 | cut -d: -f1)
                cqa_fail_autofix "$file" "$prereq_ln" "Prerequisites use numbered list ($numbered_prereqs items) -- should use bullets (*)" "Converted numbered to bulleted list"
                file_has_issue=true
            fi
        fi

        if [[ "$file_has_issue" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa11_check
exit "$(cqa_exit_code)"
