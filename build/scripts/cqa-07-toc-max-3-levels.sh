#!/bin/bash
# cqa-07-toc-max-3-levels.sh
# Validates TOC depth does not exceed 3 levels (CQA-7)
#
# Usage: ./cqa-07-toc-max-3-levels.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Heading depth must not exceed 3 levels (= == ===)
#   - Level 4+ (==== or deeper) is a violation
#
# Autofix:
#   - Promotes ==== to === when it's the only level 4+ in the file
#
# Skips:
#   - Content inside source/listing blocks (----, ....)
#   - attributes.adoc files

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa07_check() {
    local target="$1"

    cqa_header "7" "Verify TOC Depth (Max 3 Levels)" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

        cqa_file_start "$file"
        cqa_compute_block_ranges "$file"

        local local_max=0
        local violation_lines=()
        local violation_line_nums=()
        local line_num=0

        # shellcheck disable=SC2094  # cqa_is_in_block reads cached data, not $file
        while IFS= read -r line; do
            line_num=$((line_num + 1))

            if cqa_is_in_block "$file" "$line_num"; then
                continue
            fi

            # Check for headings (= followed by space)
            if [[ "$line" =~ ^(=+)[[:space:]] ]]; then
                local depth=${#BASH_REMATCH[1]}
                if [[ $depth -gt $local_max ]]; then
                    local_max=$depth
                fi
                if [[ $depth -gt 3 ]]; then
                    violation_lines+=("Level $depth: $line")
                    violation_line_nums+=("$line_num")
                fi
            fi
        done < "$file"

        if [[ ${#violation_lines[@]} -gt 0 ]]; then
            # Autofix: promote ==== to === when safe
            if [[ "$CQA_FIX_MODE" == true && ${#violation_line_nums[@]} -le 3 ]]; then
                for i in "${!violation_line_nums[@]}"; do
                    local vln="${violation_line_nums[$i]}"
                    local vline
                    vline=$(sed -n "${vln}p" "$file")
                    # Replace leading ==== (or more) with ===
                    if [[ "$vline" =~ ^===+[[:space:]] ]]; then
                        sed -i "${vln}s/^=\{4,\}/===/" "$file"
                        cqa_fail_autofix "$file" "$vln" "${violation_lines[$i]}" "Promoted to level 3 (===)"
                    fi
                done
            else
                for i in "${!violation_lines[@]}"; do
                    if [[ "$CQA_FIX_MODE" == true ]]; then
                        cqa_fail_manual "$file" "${violation_line_nums[$i]}" "${violation_lines[$i]} -- too many deep headings for safe auto-promote"
                    else
                        cqa_fail_autofix "$file" "${violation_line_nums[$i]}" "${violation_lines[$i]}" "Promote to level 3 (===)"
                    fi
                done
            fi
        else
            cqa_file_pass "$file"
        fi
    done
    return 0
}

cqa_run_for_each_title _cqa07_check
exit "$(cqa_exit_code)"
