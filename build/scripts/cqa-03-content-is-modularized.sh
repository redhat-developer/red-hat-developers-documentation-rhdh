#!/bin/bash
# cqa-03-content-is-modularized.sh - Validates content type metadata (CQA #3)
# Usage: ./cqa-03-content-is-modularized.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Content type metadata present and correct (:_mod-docs-content-type:)
#   - Content type on first line, not duplicated
#   - .Procedure and .Verification section list formatting
#
# Autofix:
#   - Adds/fixes content type metadata
#   - Normalizes section list formatting

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Helper functions invoked from _cqa03_check
_detect_content_type() {
    local file="$1"
    local bn
    bn=$(basename "$file" .adoc)

    # Content-based detection first
    if grep -q "^include::" "$file" 2>/dev/null && grep "^include::" "$file" | grep -qE "(proc-|ref-|con-)"; then
        echo "ASSEMBLY"; return
    fi
    if grep -q "^\.Procedure" "$file" 2>/dev/null; then
        echo "PROCEDURE"; return
    fi

    # Filename-based detection
    case "$bn" in
        assembly-*|master) echo "ASSEMBLY" ;;
        proc-*)            echo "PROCEDURE" ;;
        con-*)             echo "CONCEPT" ;;
        ref-*)             echo "REFERENCE" ;;
        snip-*)            echo "SNIPPET" ;;
        attributes)        echo "SNIPPET" ;;
        *)                 echo "" ;;
    esac
}

# shellcheck disable=SC2329
_count_type_occurrences() {
    grep -c "^:_mod-docs-content-type:" "$1" 2>/dev/null || echo "0"
}

# shellcheck disable=SC2329
_fix_content_type() {
    local file="$1" type="$2"
    sed -i '/^:_mod-docs-content-type:/d' "$file"
    sed -i "1s/^/:_mod-docs-content-type: ${type}\n\n/" "$file"
}

# shellcheck disable=SC2329
_fix_section_lists() {
    local file="$1" section="$2"

    grep -q "^\.${section}" "$file" 2>/dev/null || return 1

    local after
    after=$(awk "/^\\.${section}\$/{flag=1; next} flag && /^\\.(Prerequisites|Procedure|Verification|Troubleshooting|Next steps|Additional)/{exit} flag" "$file" 2>/dev/null)

    local includes unnumbered nested numbered
    includes=$(echo "$after" | grep -c "^include::" || true)
    unnumbered=$(echo "$after" | grep -c "^\* " || true)
    nested=$(echo "$after" | grep -c "^\*\* " || true)
    numbered=$(echo "$after" | grep -cE "^\\.+ " || true)

    [[ $includes -gt 0 ]] && return 1

    local fix_type=""
    if [[ $numbered -eq 1 && $unnumbered -eq 0 ]]; then
        fix_type="single-to-unnumbered"
    elif [[ $unnumbered -ge 1 && $numbered -ge 1 && $nested -eq 0 ]]; then
        fix_type="mixed-to-numbered"
    elif [[ $unnumbered -ge 2 && $numbered -eq 0 && $nested -eq 0 ]]; then
        fix_type="unnumbered-to-numbered"
    fi

    [[ -z "$fix_type" ]] && return 1

    if [[ "$CQA_FIX_MODE" == true ]]; then
        case "$fix_type" in
            single-to-unnumbered)
                sed -i "/^\.${section}/,/^[^[:space:]]/{s/^\(\.\.\?\.* \)/* /}" "$file" ;;
            mixed-to-numbered|unnumbered-to-numbered)
                sed -i "/^\.${section}\$/,/^\.(Prerequisites|Procedure|Verification|Troubleshooting|Next steps|Additional)/{/^\./!s/^\* /. /}" "$file" ;;
        esac
    fi

    local section_ln
    section_ln=$(grep -n "^\.${section}$" "$file" | head -1 | cut -d: -f1)

    case "$fix_type" in
        single-to-unnumbered)   cqa_fail_autofix "$file" "$section_ln" "Single numbered step in .${section} -- convert to unnumbered" "Converted to unnumbered" ;;
        mixed-to-numbered)      cqa_fail_autofix "$file" "$section_ln" "Mixed list in .${section} -- convert to numbered" "Converted to numbered" ;;
        unnumbered-to-numbered) cqa_fail_autofix "$file" "$section_ln" "Multiple unnumbered items in .${section} -- convert to numbered" "Converted to numbered" ;;
    esac
    return 0
}

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa03_check() {
    local target="$1"

    cqa_header "3" "Verify Content Type Metadata" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ -f "$file" ]] || continue

        cqa_file_start "$file"

        local detected
        detected=$(_detect_content_type "$file")
        if [[ -z "$detected" ]]; then
            continue
        fi

        local current
        current=$(cqa_get_content_type "$file")
        local occurrences
        occurrences=$(_count_type_occurrences "$file")
        local needs_fix=false

        if [[ "$current" != "$detected" ]] || [[ "$occurrences" -ne 1 ]]; then
            needs_fix=true
        fi

        if [[ "$needs_fix" == true ]]; then
            if [[ -z "$current" && "$occurrences" -eq 0 ]]; then
                cqa_fail_autofix "$file" "1" "Missing :_mod-docs-content-type: -- add ${detected}" "Added :_mod-docs-content-type: ${detected}"
            elif [[ -z "$current" && "$occurrences" -gt 0 ]]; then
                cqa_fail_autofix "$file" "1" "Content type not on first line -- move to line 1" "Moved to first line"
            elif [[ "$current" != "$detected" ]]; then
                cqa_fail_autofix "$file" "1" "Content type: ${current} -> ${detected}" "Changed to ${detected}"
            fi
            if [[ "$occurrences" -gt 1 ]]; then
                cqa_fail_autofix "$file" "" "Content type appears $occurrences times -- remove duplicates" "Removed $((occurrences - 1)) duplicate(s)"
            fi

            [[ "$CQA_FIX_MODE" == true ]] && _fix_content_type "$file" "$detected"
        fi

        # Fix and validate section lists for PROCEDURE files
        if [[ "$detected" == "PROCEDURE" ]]; then
            _fix_section_lists "$file" "Procedure" || true
            _fix_section_lists "$file" "Verification" || true

            # Validate PROCEDURE structure
            if grep -q "^\.Procedure" "$file" 2>/dev/null; then
                local after
                after=$(awk '/^\.Procedure$/{flag=1; next} flag && /^\.(Prerequisites|Verification|Troubleshooting|Next steps|Additional)/{exit} flag' "$file" 2>/dev/null)
                local numbered
                numbered=$(echo "$after" | grep -cE "^\\.+ " || true)
                local unnumbered
                unnumbered=$(echo "$after" | grep -c "^\* " || true)
                local includes
                includes=$(echo "$after" | grep -c "^include::" || true)
                # Skip single-step check if there are includes (they may contain additional steps)
                if [[ $numbered -eq 1 && $unnumbered -eq 0 && $includes -eq 0 ]]; then
                    local proc_ln
                    proc_ln=$(grep -n "^\.Procedure$" "$file" | head -1 | cut -d: -f1)
                    cqa_fail_manual "$file" "$proc_ln" ".Procedure has only 1 numbered step (should be multiple or 1 unnumbered)"
                fi
            fi
        fi

        if [[ "$needs_fix" == false ]] && [[ "$_CQA_CURRENT_FILE_HAS_ISSUES" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa03_check
exit "$(cqa_exit_code)"
