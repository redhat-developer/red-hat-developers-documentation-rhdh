#!/bin/bash
# cqa-06-assemblies-use-the-official-template-assemblies-ar.sh
# Validates assemblies follow the official template and tell one user story (CQA #6)
#
# Usage: ./cqa-06-assemblies-use-the-official-template-assemblies-ar.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Assembly has exactly one user story (single focus topic)
#   - Assembly title present
#   - Not too many nested assembly includes (max 3)
#   - Module count reasonable (max 15)
#
# Autofix (--fix stub):
#   - Reports [MANUAL] items (splitting assemblies requires human judgment)
#
# Skips:
#   - Non-assembly files (PROCEDURE, CONCEPT, REFERENCE, SNIPPET)
#   - attributes.adoc files

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa06_check() {
    local target="$1"

    cqa_header "6" "Verify Assemblies Follow Official Template (One User Story)" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

        local content_type
        content_type=$(cqa_get_content_type "$file")
        [[ -z "$content_type" ]] && continue
        [[ "$content_type" != "ASSEMBLY" ]] && continue

        cqa_file_start "$file"

        local file_has_issue=false
        local include_count
        include_count=$(grep -c "^include::" "$file" 2>/dev/null || true)

        # Skip user story checks for master.adoc (title-level assemblies aggregate multiple user stories)
        if [[ "$(basename "$file")" != "master.adoc" ]]; then
            # Check for excessive nested assembly includes
            local assembly_includes
            assembly_includes=$(grep "^include::" "$file" 2>/dev/null | grep -c "assembly-" || true)
            if [[ $assembly_includes -gt 3 ]]; then
                cqa_fail_manual "$file" "" "Has $assembly_includes nested assembly includes (may cover multiple user stories, max 3)"
                file_has_issue=true
            fi

            # Check for excessive module count
            if [[ $include_count -gt 15 ]]; then
                cqa_fail_manual "$file" "" "Has $include_count includes (consider splitting -- may cover multiple user stories, max 15)"
                file_has_issue=true
            fi
        fi

        # Check assembly has a title
        if ! grep -q "^= " "$file" 2>/dev/null; then
            cqa_fail_manual "$file" "" "Missing assembly title (= Title)"
            file_has_issue=true
        fi

        if [[ "$file_has_issue" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa06_check
exit "$(cqa_exit_code)"
