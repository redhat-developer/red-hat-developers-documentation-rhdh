#!/bin/bash
# cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh
# Validates Technology Preview and Developer Preview disclaimers (CQA-17)
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

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2317,SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa17_check() {
    local target="$1"

    cqa_header "17" "Verify legal disclaimers for preview features" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
        [[ "$(basename "$file")" == snip-* ]] && continue

        cqa_file_start "$file"

        local file_has_issue=false

        # Pre-compute block ranges to skip source/listing blocks
        cqa_compute_block_ranges "$file"

        # Check for Technology Preview mentions (outside source blocks)
        # Detects both raw text and {technology-preview} attribute usage
        local has_tp_mention=false
        while IFS=: read -r tp_ln _; do
            [[ -z "$tp_ln" ]] && continue
            cqa_is_in_block "$file" "$tp_ln" && continue
            has_tp_mention=true
            break
        done < <(grep -ni "technology preview\|{technology-preview}" "$file" 2>/dev/null || true)

        if [[ "$has_tp_mention" == true ]] && ! grep -q "include::.*snip-.*tech.*preview\|include::.*snip-.*tp-\|access.redhat.com/support/offerings/techpreview" "$file" 2>/dev/null; then
            local line_num
            line_num=$(grep -ni "technology preview\|{technology-preview}" "$file" | head -1 | cut -d: -f1)
            cqa_fail_manual "$file" "$line_num" "Mentions 'Technology Preview' but may not include official disclaimer snippet"
            file_has_issue=true
        fi

        # Check for Developer Preview mentions (outside source blocks)
        # Detects both raw text and {developer-preview} attribute usage
        local has_dp_mention=false
        while IFS=: read -r dp_ln _; do
            [[ -z "$dp_ln" ]] && continue
            cqa_is_in_block "$file" "$dp_ln" && continue
            has_dp_mention=true
            break
        done < <(grep -ni "developer preview\|{developer-preview}" "$file" 2>/dev/null || true)

        if [[ "$has_dp_mention" == true ]] && ! grep -q "include::.*snip-.*dev.*preview\|include::.*snip-.*dp-\|access.redhat.com/support/offerings/devpreview" "$file" 2>/dev/null; then
            local line_num
            line_num=$(grep -ni "developer preview\|{developer-preview}" "$file" | head -1 | cut -d: -f1)
            cqa_fail_manual "$file" "$line_num" "Mentions 'Developer Preview' but may not include official disclaimer snippet"
            file_has_issue=true
        fi

        if [[ "$file_has_issue" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
    return 0
}

cqa_run_for_each_title _cqa17_check
exit "$(cqa_exit_code)"
