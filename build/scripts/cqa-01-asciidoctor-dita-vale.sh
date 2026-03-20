#!/bin/bash
# cqa-01-asciidoctor-dita-vale.sh - Validates AsciiDoc DITA compliance using Vale (CQA #1)
# Usage: ./cqa-01-asciidoctor-dita-vale.sh [--fix] [--all] [--output line|JSON] <file-path>
#
# Checks:
#   - AsciiDoc DITA compliance via Vale with .vale-dita-only.ini
#
# Autofix:
#   - AuthorLine: insert blank line after title
#   - CalloutList: convert callout items to description list
#   - BlockTitle: convert invalid block titles to lead-in sentences
#   - TaskContents: add .Procedure before first numbered list
#   - TaskStep: fix blank lines around steps
#
# Delegates:
#   - ShortDescription -> CQA #8
#   - DocumentId -> CQA #10

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2034  # Used by delegation framework
CQA_DELEGATES_TO=("ShortDescription:8" "DocumentId:10")

[[ -f ".vale-dita-only.ini" ]] || { echo "Error: .vale-dita-only.ini not found" >&2; exit 1; }

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa01_check() {
    local target="$1"

    cqa_header "1" "Vale AsciiDoc DITA Compliance" "$target"

    # Collect files excluding attributes.adoc
    local vale_files=()
    for f in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$f" != *.adoc ]] && continue
        [[ "$(basename "$f")" == "attributes.adoc" ]] && continue
        vale_files+=("$f")
    done

    [[ ${#vale_files[@]} -gt 0 ]] || { echo "No files to validate."; return; }

    cqa_file_start "$target"

    # Legacy --output support for backward compat
    if [[ "$CQA_OUTPUT_FORMAT" == "JSON" ]]; then
        vale --config .vale-dita-only.ini --output JSON "${vale_files[@]}"
        return $?
    fi

    # --- Fix mode ---
    if [[ "$CQA_FIX_MODE" == true ]]; then
        local vale_json
        vale_json=$(vale --config .vale-dita-only.ini --output JSON "${vale_files[@]}" 2>/dev/null || true)

        local issues_tsv
        issues_tsv=$(echo "$vale_json" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for f, issues in d.items():
        for i in issues:
            print(f\"{f}\t{i['Line']}\t{i['Check']}\")
except: pass
" 2>/dev/null)

        # Fix AuthorLine
        while IFS=$'\t' read -r file line check; do
            [[ "$check" == "AsciiDocDITA.AuthorLine" ]] || continue
            local title_ln=$((line - 1))
            local title_content
            title_content=$(sed -n "${title_ln}p" "$file")
            if [[ "$title_content" == "= "* ]]; then
                sed -i "${title_ln}a\\\\" "$file"
                cqa_fail_autofix "$file" "$line" "AuthorLine: missing blank line after title" "Added blank line after title"
            fi
        done <<< "$issues_tsv"

        # Fix CalloutList
        while IFS=$'\t' read -r file line check; do
            [[ "$check" == "AsciiDocDITA.CalloutList" ]] || continue
            local line_content
            line_content=$(sed -n "${line}p" "$file")
            if [[ "$line_content" =~ ^\<[0-9]+\>[[:space:]] ]]; then
                sed -i "${line}s/^<\([0-9]*\)> /<\1>:: /" "$file"
                cqa_fail_autofix "$file" "$line" "CalloutList: invalid format" "Converted to description list"
            fi
        done <<< "$issues_tsv"

        # Fix BlockTitle
        while IFS=$'\t' read -r file line check; do
            [[ "$check" == "AsciiDocDITA.BlockTitle" ]] || continue
            local line_content
            line_content=$(sed -n "${line}p" "$file")
            local next_line
            next_line=$(sed -n "$((line + 1))p" "$file")
            # Skip if next line is a block delimiter (table, example, source, image)
            if [[ "$next_line" == "|==="* || "$next_line" == "===="* || "$next_line" == "----"* || "$next_line" == "[source"* || "$next_line" == "image::"* ]]; then
                cqa_fail_manual "$file" "$line" "BlockTitle before block element -- review manually"
                continue
            fi
            if [[ "$line_content" == "."* ]]; then
                local title_text="${line_content#.}"
                sed -i "${line}s/^\..*/${title_text}:/" "$file"
                cqa_fail_autofix "$file" "$line" "BlockTitle: invalid .Title format" "Converted to lead-in sentence"
            fi
        done <<< "$issues_tsv"

        # Fix TaskContents
        while IFS=$'\t' read -r file line check; do
            [[ "$check" == "AsciiDocDITA.TaskContents" ]] || continue
            local first_ol
            first_ol=$(grep -n '^\. ' "$file" | head -1 | cut -d: -f1)
            if [[ -n "$first_ol" ]]; then
                sed -i "$((first_ol))i\\\\.Procedure" "$file"
                cqa_fail_autofix "$file" "$first_ol" "TaskContents: missing .Procedure" "Added .Procedure before line $first_ol"
            fi
        done <<< "$issues_tsv"

        # Fix TaskStep (process in reverse line order)
        declare -A taskstep_files=()
        while IFS=$'\t' read -r file line check; do
            [[ "$check" == "AsciiDocDITA.TaskStep" ]] || continue
            taskstep_files["$file"]+="$line "
        done <<< "$issues_tsv"
        for file in "${!taskstep_files[@]}"; do
            for line in $(echo "${taskstep_files[$file]}" | tr ' ' '\n' | sort -rn); do
                [[ -z "$line" ]] && continue
                local prev_ln=$((line - 1))
                local prev_content
                prev_content=$(sed -n "${prev_ln}p" "$file")
                if [[ -z "$prev_content" ]]; then
                    local prev_prev_content
                    prev_prev_content=$(sed -n "$((line - 2))p" "$file")
                    if [[ "$prev_prev_content" == ".Procedure" ]]; then
                        sed -i "${prev_ln}d" "$file"
                        cqa_fail_autofix "$file" "$line" "TaskStep: blank line after .Procedure" "Removed blank line"
                    else
                        sed -i "${prev_ln}s/^$/+/" "$file"
                        cqa_fail_autofix "$file" "$line" "TaskStep: detached from preceding step" "Attached with + continuation"
                    fi
                fi
            done
        done

        # Handle delegated checks
        while IFS=$'\t' read -r file line check; do
            case "$check" in
                AsciiDocDITA.ShortDescription*)
                    cqa_delegated "$file" "$line" "8" "ShortDescription issue (run CQA #8)" "manual" ;;
                AsciiDocDITA.DocumentId*)
                    cqa_delegated "$file" "$line" "10" "DocumentId issue (run CQA #10)" "manual" ;;
                *) ;;
            esac
        done <<< "$issues_tsv"

        return 0
    fi

    # --- Report mode ---
    if [[ "$CQA_FORMAT" == "json" ]]; then
        local vale_json
        vale_json=$(vale --config .vale-dita-only.ini --output JSON "${vale_files[@]}" 2>/dev/null || true)
        # Parse and add to SARIF
        echo "$vale_json" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    for f, issues in d.items():
        for i in issues:
            check = i['Check']
            kind = 'autofix'
            target = ''
            fix_type = 'autofix'
            if 'ShortDescription' in check:
                kind = 'delegated'
                target = '8'
                fix_type = 'manual'
            elif 'DocumentId' in check:
                kind = 'delegated'
                target = '10'
                fix_type = 'manual'
            elif check in ('AsciiDocDITA.DocumentTitle', 'AsciiDocDITA.TaskTitle',
                           'AsciiDocDITA.ConceptLink', 'AsciiDocDITA.AssemblyContents',
                           'AsciiDocDITA.RelatedLinks', 'AsciiDocDITA.ExampleBlock'):
                kind = 'manual'
            print(f\"{f}\t{i['Line']}\t{kind}\t{target}\t{fix_type}\t{check}: {i['Message']}\")
except: pass
" 2>/dev/null | while IFS=$'\t' read -r file line kind delegate_to fix_type message; do
            case "$kind" in
                autofix) cqa_fail_autofix "$file" "$line" "$message" ;;
                manual)  cqa_fail_manual "$file" "$line" "$message" ;;
                delegated) cqa_delegated "$file" "$line" "$delegate_to" "$message" "$fix_type" ;;
            esac
        done
    else
        local vale_output
        vale_output=$(vale --config .vale-dita-only.ini --output line "${vale_files[@]}" 2>/dev/null || true)
        if [[ -z "$vale_output" ]]; then
            cqa_file_pass "$target"
        else
            local total_count
            total_count=$(echo "$vale_output" | wc -l)
            echo "$vale_output" | head -20
            echo ""
            cqa_fail_autofix "$target" "" "Vale found ${total_count} DITA compliance issues" "Run with --fix to auto-resolve"
        fi
    fi
    return 0
}

cqa_run_for_each_title _cqa01_check
exit "$(cqa_exit_code)"
