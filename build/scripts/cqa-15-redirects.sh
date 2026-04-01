#!/bin/bash
# cqa-15-redirects.sh
# Checks if redirects are needed and in place (CQA-15)
#
# Usage: ./cqa-15-redirects.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Detects :title: changes in master.adoc (published title changes)
#   - Detects deleted master.adoc files (title removed)
#
# Autofix (--fix stub):
#   - Reports [MANUAL] items (redirect implementation is platform-dependent)

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa15_check() {
    local target="$1"

    cqa_header "15" "Check redirects" "$target"

    cqa_file_start "$target"

    local needs_review=false

    # Check for deleted master.adoc files
    local deleted_titles
    deleted_titles=$(git diff --name-status --diff-filter=D HEAD~5..HEAD -- 'titles/*/master.adoc' 2>/dev/null || true)
    if [[ -n "$deleted_titles" ]]; then
        while IFS=$'\t' read -r _status deleted_file; do
            [[ -z "$deleted_file" ]] && continue
            cqa_fail_manual "$target" "" "Title removed: $(dirname "$deleted_file") -- needs redirect"
            needs_review=true
        done <<< "$deleted_titles"
    fi

    # Check if :title: changed in master.adoc
    if [[ "$(basename "$target")" == "master.adoc" ]]; then
        local title_diff
        title_diff=$(git diff HEAD~5..HEAD -- "$target" 2>/dev/null | grep -E '^[-+]:title:' | grep -v '^[-+][-+][-+]' || true)
        if [[ -n "$title_diff" ]]; then
            local old_title new_title
            old_title=$(echo "$title_diff" | grep '^-:title:' | sed 's/^-:title: *//' | head -1)
            new_title=$(echo "$title_diff" | grep '^+:title:' | sed 's/^+:title: *//' | head -1)
            if [[ -n "$old_title" && -n "$new_title" && "$old_title" != "$new_title" ]]; then
                cqa_fail_manual "$target" "" "Title changed: '$old_title' -> '$new_title' -- may need redirect"
                needs_review=true
            fi
        fi
    fi

    if [[ "$needs_review" == false ]]; then
        cqa_file_pass "$target"
    fi
    return 0
}

cqa_run_for_each_title _cqa15_check
exit "$(cqa_exit_code)"
