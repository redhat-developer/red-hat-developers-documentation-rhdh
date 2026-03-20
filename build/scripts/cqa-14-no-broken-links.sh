#!/bin/bash
# cqa-14-no-broken-links.sh
# Validates no broken links exist (CQA #14)
#
# Usage: ./cqa-14-no-broken-links.sh [--fix] [--all] <file-path>
#
# Checks:
#   - include:: targets exist
#   - Image references point to existing files
#
# Autofix (--fix stub):
#   - Reports [MANUAL] items (fixing broken links requires human judgment on correct target)
#
# Note: For full link validation including external URLs, run build-ccutil.sh

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa14_check() {
    local target="$1"

    cqa_header "14" "Verify No Broken Links" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue

        cqa_file_start "$file"

        local file_has_issue=false
        local file_dir
        file_dir=$(dirname "$file")

        # Check 1: Broken include:: references
        while IFS= read -r line; do
            local include_path
            include_path=$(echo "$line" | sed 's/^include:://' | sed 's/\[.*//')
            # Skip lines with attribute substitutions
            [[ "$include_path" == *"{"* ]] && continue
            local local_path="$file_dir/$include_path"
            if [[ ! -f "$local_path" ]]; then
                local line_num
                line_num=$(grep -n "include::${include_path}" "$file" | head -1 | cut -d: -f1)
                cqa_fail_manual "$file" "$line_num" "Broken include: $include_path"
                file_has_issue=true
            fi
        done < <(grep "^include::" "$file" 2>/dev/null || true)

        # Check 2: Broken image references
        while IFS=: read -r line_num line_content; do
            [[ -z "$line_content" ]] && continue
            local image_path
            image_path=$(echo "$line_content" | sed -E 's/.*image::?([^[]*)\[.*/\1/')
            [[ "$image_path" == *"{"* ]] && continue
            if [[ -n "$image_path" ]] && [[ ! -f "$file_dir/$image_path" ]] && [[ ! -f "$image_path" ]]; then
                cqa_fail_manual "$file" "$line_num" "Broken image: $image_path"
                file_has_issue=true
            fi
        done < <(grep -n "image::.*\[" "$file" 2>/dev/null || true)

        if [[ "$file_has_issue" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa14_check
exit "$(cqa_exit_code)"
