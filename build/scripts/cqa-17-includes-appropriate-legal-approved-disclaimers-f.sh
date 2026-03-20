#!/bin/bash
# cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh
# Validates Technology Preview and Developer Preview disclaimers (CQA #17)
#
# Usage: ./cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Files mentioning "Technology Preview" include the official disclaimer snippet
#   - Files mentioning "Developer Preview" include the official disclaimer snippet
#   - Disclaimer snippets are properly included (not hardcoded)
#
# Autofix (--fix stub):
#   - Reports [MANUAL] items as checklist (no auto-insert — snippet path varies)
#
# Skips:
#   - attributes.adoc files
#   - Snippet files (snip-*.adoc) — these ARE the disclaimers
#   - Content inside source/listing blocks

source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

_cqa17_check() {
    local target="$1"

    cqa_header "17" "Verify Legal Disclaimers for Preview Features" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
        [[ "$(basename "$file")" == snip-* ]] && continue

        cqa_file_start "$file"

        local file_has_issue=false

        # Check for Technology Preview mentions
        if grep -qi "technology preview" "$file" 2>/dev/null; then
            if ! grep -q "include::.*snip-.*tech.*preview\|include::.*snip-.*tp-\|{technology-preview}" "$file" 2>/dev/null; then
                local line_num
                line_num=$(grep -ni "technology preview" "$file" | head -1 | cut -d: -f1)
                cqa_fail_manual "$file" "$line_num" "Mentions 'Technology Preview' but may not include official disclaimer snippet"
                file_has_issue=true
            fi
        fi

        # Check for Developer Preview mentions
        if grep -qi "developer preview" "$file" 2>/dev/null; then
            if ! grep -q "include::.*snip-.*dev.*preview\|include::.*snip-.*dp-\|{developer-preview}" "$file" 2>/dev/null; then
                local line_num
                line_num=$(grep -ni "developer preview" "$file" | head -1 | cut -d: -f1)
                cqa_fail_manual "$file" "$line_num" "Mentions 'Developer Preview' but may not include official disclaimer snippet"
                file_has_issue=true
            fi
        fi

        if [[ "$file_has_issue" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa17_check
exit "$(cqa_exit_code)"
