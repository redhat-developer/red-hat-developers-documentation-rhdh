#!/bin/bash
# cqa-02-assembly-structure.sh - Validates assembly structure compliance (CQA #2)
# Usage: ./cqa-02-assembly-structure.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Content type ASSEMBLY on first line, not repeated
#   - [role="_abstract"] introduction present
#   - Introduction length (50-300 chars for non-master files)
#   - ID with _{context} suffix
#   - :context: attribute after title
#   - Context save/restore directives (non-master assemblies)
#   - .Prerequisites as == heading (not block title)
#   - .Additional resources with [role="_additional-resources"]
#   - No level 3+ subheadings
#   - No content between includes
#
# Autofix: content type, context save/restore, ID suffix, :context:, prerequisites heading,
#          additional resources format

source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# Helper: get line number of first match
_lineno() { grep -n "$1" "$2" 2>/dev/null | head -1 | cut -d: -f1; }

_fix_content_type_first_line() {
    local file="$1"
    sed -i '/^:_mod-docs-content-type:/d' "$file"
    sed -i '1s/^/:_mod-docs-content-type: ASSEMBLY\n/' "$file"
}

_fix_add_context_save() {
    local file="$1"
    sed -i '1a\ifdef::context[:parent-context: {context}]' "$file"
}

_fix_add_context_restore() {
    local file="$1"
    sed -i '/^ifdef::parent-context\[:context: {parent-context}\]$/d' "$file"
    sed -i '/^ifndef::parent-context\[:!context:\]$/d' "$file"
    sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$file"
    printf '\nifdef::parent-context[:context: {parent-context}]\nifndef::parent-context[:!context:]\n' >> "$file"
}

_fix_context_line() {
    local file="$1" title_ln="$2"
    sed -i '/^:context:/d' "$file"
    local id_value
    id_value=$(grep -m1 '\[id="' "$file" | sed 's/.*\[id="\([^"]*\)".*/\1/' | sed 's/_{context}$//')
    if [[ -n "$id_value" ]]; then
        sed -i "${title_ln}a\\\\n:context: ${id_value}" "$file"
    fi
}

_cqa02_check() {
    local target="$1"

    cqa_header "2" "Verify Assembly Structure" "$target"

    # Filter to assembly files only
    local assembly_files=()
    for f in "${_CQA_COLLECTED_FILES[@]}"; do
        if echo "$f" | grep -qE "assemblies/.*\.adoc$|titles/.*/master\.adoc$"; then
            assembly_files+=("$f")
        fi
    done

    if [[ ${#assembly_files[@]} -eq 0 ]]; then
        echo "No assembly files found."
        return
    fi

    for file in "${assembly_files[@]}"; do
        [[ -f "$file" ]] || continue

        cqa_file_start "$file"
        local is_master=$([[ "$(basename "$file")" == "master.adoc" ]] && echo true || echo false)

        # Check 1: Content type on first line
        local first_line
        first_line=$(sed -n '1p' "$file")
        if [[ "$first_line" != ":_mod-docs-content-type: ASSEMBLY" ]]; then
            if [[ "$CQA_FIX_MODE" == true ]]; then
                _fix_content_type_first_line "$file"
            fi
            cqa_fail_autofix "$file" "1" "Content type ASSEMBLY not on first line" "Fixed content type on line 1"
        fi
        local ct_count
        ct_count=$(grep -c '^:_mod-docs-content-type:' "$file" || true)
        if [[ $ct_count -gt 1 ]]; then
            if [[ "$CQA_FIX_MODE" == true ]]; then
                awk '/^:_mod-docs-content-type:/ && ++n > 1 {next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            fi
            cqa_fail_autofix "$file" "" "Content type appears $ct_count times" "Removed duplicates"
        fi

        # Check 2: Has abstract
        if ! grep -q '\[role="_abstract"\]' "$file"; then
            cqa_delegated "$file" "" "9" "Missing [role=\"_abstract\"] introduction"
        fi

        # Check 3: Introduction length (non-master)
        if [[ "$is_master" == false ]]; then
            local abstract_ln
            abstract_ln=$(_lineno '\[role="_abstract"\]' "$file")
            if [[ -n "$abstract_ln" ]]; then
                local intro
                intro=$(sed -n "$((abstract_ln + 1))p" "$file")
                local intro_len=${#intro}
                if [[ $intro_len -lt 50 ]]; then
                    cqa_delegated "$file" "$((abstract_ln + 1))" "9" "Introduction too short (${intro_len} chars, recommend 50-300)" "manual"
                elif [[ $intro_len -gt 300 ]]; then
                    cqa_delegated "$file" "$((abstract_ln + 1))" "9" "Introduction too long (${intro_len} chars, recommend 50-300)" "manual"
                fi
            fi
        fi

        # Check 4: ID with _{context} (non-master)
        if [[ "$is_master" == false ]]; then
            if ! grep -q '\[id=".*_{context}"\]' "$file"; then
                if grep -q '\[id="[^"]*"\]' "$file"; then
                    if [[ "$CQA_FIX_MODE" == true ]]; then
                        sed -i 's/\[id="\([^"]*[^}]\)"\]/[id="\1_{context}"]/' "$file"
                    fi
                    cqa_fail_autofix "$file" "" "ID missing _{context} suffix" "Added _{context} suffix"
                else
                    cqa_fail_manual "$file" "" "Missing [id=\"..._{context}\"] attribute"
                fi
            fi
        fi

        # Check 5: :context: after title (non-master)
        local context_ln
        context_ln=$(_lineno "^:context:" "$file")
        local need_ctx_fix=false
        if [[ -z "$context_ln" ]]; then
            cqa_fail_autofix "$file" "" "Missing :context: attribute" "Added :context:"
            need_ctx_fix=true
        elif [[ "$is_master" == false ]]; then
            local title_ln_chk
            title_ln_chk=$(_lineno "^= " "$file")
            if [[ -n "$title_ln_chk" ]]; then
                if [[ "$context_ln" -le "$title_ln_chk" ]]; then
                    cqa_fail_autofix "$file" "$context_ln" ":context: must appear after the title" "Moved :context: after title"
                    need_ctx_fix=true
                fi
            fi
        fi
        if [[ "$CQA_FIX_MODE" == true && "$need_ctx_fix" == true && "$is_master" == false ]]; then
            local title_ln_chk
            title_ln_chk=$(_lineno "^= " "$file")
            [[ -n "$title_ln_chk" ]] && _fix_context_line "$file" "$title_ln_chk"
        fi

        # Check 6: Context save/restore (non-master)
        if [[ "$is_master" == false ]]; then
            local second_line
            second_line=$(sed -n '2p' "$file")
            if [[ "$second_line" != ifdef::context* ]]; then
                if [[ "$CQA_FIX_MODE" == true ]]; then
                    _fix_add_context_save "$file"
                fi
                cqa_fail_autofix "$file" "2" "Missing context save on line 2" "Added context save"
            fi
            local save_count
            save_count=$(grep -c "^ifdef::context\[:parent-context" "$file" || true)
            if [[ $save_count -gt 1 ]]; then
                if [[ "$CQA_FIX_MODE" == true ]]; then
                    awk '/^ifdef::context\[:parent-context/ && ++n > 1 {next} 1' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
                fi
                cqa_fail_autofix "$file" "" "Context save appears $save_count times" "Removed duplicates"
            fi

            local last_line penult_line need_restore=false
            last_line=$(tail -1 "$file")
            penult_line=$(tail -2 "$file" | head -1)
            if [[ "$penult_line" != 'ifdef::parent-context[:context: {parent-context}]' ]]; then
                cqa_fail_autofix "$file" "" "Missing context restore (second-to-last line)" "Added context restore"
                need_restore=true
            fi
            if [[ "$last_line" != 'ifndef::parent-context[:!context:]' ]]; then
                cqa_fail_autofix "$file" "" "Missing context restore (last line)" "Added context restore"
                need_restore=true
            fi
            if [[ "$CQA_FIX_MODE" == true && "$need_restore" == true ]]; then
                _fix_add_context_restore "$file"
            fi
        fi

        # Check 7: Prerequisites must use == heading
        if grep -q "^\.Prerequisites" "$file"; then
            local prereq_ln
            prereq_ln=$(_lineno "^\.Prerequisites" "$file")
            if [[ "$CQA_FIX_MODE" == true ]]; then
                sed -i 's/^\.Prerequisites$/== Prerequisites/' "$file"
            fi
            cqa_fail_autofix "$file" "$prereq_ln" "Uses .Prerequisites block title instead of == heading" "Changed to == Prerequisites"
        fi

        # Check 8: No level 3+ subheadings
        if grep -q "^===[[:space:]]" "$file"; then
            local sub_ln
            sub_ln=$(grep -n "^===[[:space:]]" "$file" | head -1 | cut -d: -f1)
            cqa_fail_manual "$file" "$sub_ln" "Contains level 3+ subheadings (=== or deeper)"
        fi

        # Check 9: Additional resources format
        local need_ar_fix=false
        if grep -q "^\.Additional resources" "$file"; then
            local ar_ln
            ar_ln=$(_lineno "^\.Additional resources" "$file")
            if [[ "$CQA_FIX_MODE" == true ]]; then
                sed -i 's/^\.Additional resources$/[role="_additional-resources"]\n== Additional resources/' "$file"
            fi
            cqa_fail_autofix "$file" "$ar_ln" "Uses .Additional resources block title" "Changed to [role] + == heading"
        elif grep -q "^== Additional resources" "$file"; then
            if ! grep -q '\[role="_additional-resources"\]' "$file"; then
                local ar_ln
                ar_ln=$(_lineno "^== Additional resources" "$file")
                if [[ "$CQA_FIX_MODE" == true ]]; then
                    sed -i '/^== Additional resources/i\[role="_additional-resources"]' "$file"
                fi
                cqa_fail_autofix "$file" "$ar_ln" "Missing [role=\"_additional-resources\"] attribute" "Added role attribute"
            fi
        fi

        # Check 10: No content between includes
        local title_ln
        title_ln=$(_lineno "^= " "$file")
        if [[ -n "$title_ln" ]]; then
            local -a include_lns
            mapfile -t include_lns < <(tail -n +"$title_ln" "$file" | grep -n "^include::" | grep -v "artifacts/" | cut -d: -f1 | while read -r n; do echo $((title_ln + n - 1)); done)
            if [[ ${#include_lns[@]} -gt 1 ]]; then
                local first_inc=${include_lns[0]}
                local last_inc=${include_lns[-1]}
                local between
                between=$(sed -n "$((first_inc + 1)),$((last_inc - 1))p" "$file" | \
                    grep -v -E "^$|^include::|^//|^ifdef::|^ifndef::|^endif::|^\[role=|^\.Additional resources|^== " || true)
                if [[ -n "$between" ]]; then
                    local between_count
                    between_count=$(echo "$between" | wc -l)
                    cqa_fail_manual "$file" "$first_inc" "Content between include statements ($between_count lines)"
                fi
            fi
        fi

        if [[ "$_CQA_CURRENT_FILE_HAS_ISSUES" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa02_check
exit "$(cqa_exit_code)"
