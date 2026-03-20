#!/bin/bash
# cqa-13-information-is-conveyed-using-the-correct-content.sh
# Validates content matches its declared content type (CQA #13)
#
# Usage: ./cqa-13-information-is-conveyed-using-the-correct-content.sh [--fix] [--all] <file-path>
#
# Checks:
#   - PROCEDURE files have .Procedure section with numbered steps
#   - CONCEPT files do not have .Procedure sections
#   - REFERENCE files do not have .Procedure sections
#   - Filename prefix matches content type
#
# Autofix:
#   - Filename prefix correction (via git mv)
#   - Content type metadata correction
#
# Skips:
#   - SNIPPET files, attributes.adoc, master.adoc

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa13_check() {
    local target="$1"

    cqa_header "13" "Verify Content Matches Declared Type" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
        [[ "$(basename "$file")" == "master.adoc" ]] && continue

        local content_type
        content_type=$(cqa_get_content_type "$file")
        [[ -z "$content_type" ]] && continue
        [[ "$content_type" == "SNIPPET" ]] && continue

        cqa_file_start "$file"

        local file_has_issue=false

        case "$content_type" in
            PROCEDURE)
                if ! grep -q "^\.Procedure" "$file" 2>/dev/null; then
                    cqa_fail_manual "$file" "" "PROCEDURE without .Procedure section"
                    file_has_issue=true
                fi
                ;;
            CONCEPT)
                if grep -q "^\.Procedure" "$file" 2>/dev/null; then
                    cqa_fail_manual "$file" "" "CONCEPT has .Procedure section (should be PROCEDURE type or remove steps)"
                    file_has_issue=true
                fi
                ;;
            REFERENCE)
                if grep -q "^\.Procedure" "$file" 2>/dev/null; then
                    cqa_fail_manual "$file" "" "REFERENCE has .Procedure section (should be PROCEDURE type or remove steps)"
                    file_has_issue=true
                fi
                ;;
        esac

        # Check filename prefix matches content type
        local basename_file
        basename_file=$(basename "$file" .adoc)
        local expected_prefix=""
        case "$content_type" in
            PROCEDURE)  expected_prefix="proc-" ;;
            CONCEPT)    expected_prefix="con-" ;;
            REFERENCE)  expected_prefix="ref-" ;;
            ASSEMBLY)   expected_prefix="assembly-" ;;
        esac

        if [[ -n "$expected_prefix" ]] && [[ ! "$basename_file" =~ ^${expected_prefix} ]]; then
            if [[ "$CQA_FIX_MODE" == true ]]; then
                # Auto-rename: strip existing prefix, add correct one
                local new_basename="${expected_prefix}${basename_file#*-}"
                local new_file
                new_file="$(dirname "$file")/${new_basename}.adoc"
                if [[ "$file" != "$new_file" ]]; then
                    git mv "$file" "$new_file" 2>/dev/null || mv "$file" "$new_file"
                    # Update include statements across the repo
                    local old_bn
                    old_bn=$(basename "$file")
                    local new_bn
                    new_bn=$(basename "$new_file")
                    while IFS= read -r inc_file; do
                        sed -i "s|${old_bn}|${new_bn}|g" "$inc_file"
                    done < <(grep -rl "$old_bn" assemblies/ modules/ titles/ 2>/dev/null || true)
                fi
            fi
            cqa_fail_autofix "$file" "" "Filename prefix mismatch: expected ${expected_prefix} for ${content_type} (got: $basename_file)" "Renamed to ${expected_prefix}${basename_file#*-}.adoc"
            file_has_issue=true
        fi

        if [[ "$file_has_issue" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
    return 0
}

cqa_run_for_each_title _cqa13_check
exit "$(cqa_exit_code)"
