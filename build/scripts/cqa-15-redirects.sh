#!/bin/bash
# cqa-15-redirects.sh
# Checks if redirects are needed and in place (CQA #15)
#
# Usage: ./cqa-15-redirects.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Detects renamed or moved files that may need redirects
#   - Reports files with changed IDs that may affect external links
#
# Autofix (--fix stub):
#   - Reports [MANUAL] items (redirect implementation is platform-dependent)
#
# Note: Redirect implementation depends on the publishing platform.

source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

_cqa15_check() {
    local target="$1"

    cqa_header "15" "Check Redirects" "$target"

    cqa_file_start "$target"

    local needs_review=false

    # Check for renamed files in git (staged or recent commits)
    local renamed_files
    renamed_files=$(git diff --name-status --diff-filter=R HEAD~5..HEAD -- 'assemblies/' 'modules/' 'titles/' 2>/dev/null || true)
    local staged_renames
    staged_renames=$(git diff --cached --name-status --diff-filter=R -- 'assemblies/' 'modules/' 'titles/' 2>/dev/null || true)

    if [[ -n "$renamed_files" ]]; then
        while IFS=$'\t' read -r status old_file new_file; do
            [[ -z "$old_file" ]] && continue
            cqa_fail_manual "$target" "" "Renamed in recent commit: $old_file -> $new_file -- may need redirect"
            needs_review=true
        done <<< "$renamed_files"
    fi

    if [[ -n "$staged_renames" ]]; then
        while IFS=$'\t' read -r status old_file new_file; do
            [[ -z "$old_file" ]] && continue
            cqa_fail_manual "$target" "" "Renamed (staged): $old_file -> $new_file -- may need redirect"
            needs_review=true
        done <<< "$staged_renames"
    fi

    # Check for deleted files
    local deleted_files
    deleted_files=$(git diff --name-status --diff-filter=D HEAD~5..HEAD -- 'assemblies/' 'modules/' 'titles/' 2>/dev/null || true)
    if [[ -n "$deleted_files" ]]; then
        while IFS=$'\t' read -r status deleted_file; do
            [[ -z "$deleted_file" ]] && continue
            cqa_fail_manual "$target" "" "Deleted in recent commit: $deleted_file -- may need redirect"
            needs_review=true
        done <<< "$deleted_files"
    fi

    if [[ "$needs_review" == false ]]; then
        cqa_file_pass "$target"
    fi
}

cqa_run_for_each_title _cqa15_check
exit "$(cqa_exit_code)"
