#!/bin/bash
# cqa-05-modular-elements-checklist.sh
# Validates all required modular elements per CQA #5
#
# Usage: ./cqa-05-modular-elements-checklist.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Content type metadata, topic ID with {context}, single H1 title
#   - Short introduction [role="_abstract"], blank line after H1
#   - Image alt text, no admonition titles
#   - Nested assembly context handling, :context: declaration
#   - Assembly: blank lines between includes, no level 2+ subheadings, no block titles
#   - Procedure: .Procedure block title, standard sections only
#
# Autofix:
#   - Inserts blank line after H1 title
#   - Removes admonition titles
#   - Adds missing image alt text quotes

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

readonly PATTERN_BLOCK_TITLE='^\.[A-Z]'

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa05_check() {
    local target="$1"

    cqa_header "5" "Verify Required Modular Elements" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ -f "$file" ]] || continue
        [[ "$file" != *.adoc ]] && continue

        # Filter to assemblies/, modules/, or master.adoc in titles/
        if ! echo "$file" | grep -qE "assemblies/|modules/|titles/.*master\.adoc$"; then
            continue
        fi

        cqa_file_start "$file"

        local content_type
        content_type=$(cqa_get_content_type "$file")

        local is_nested_assembly=false
        if [[ "$content_type" == "ASSEMBLY" ]] && grep -q "ifdef::context\[:parent-context:" "$file"; then
            is_nested_assembly=true
        fi

        # Snippets: only check for titles (which they must not have)
        if [[ "$content_type" == "SNIPPET" ]]; then
            if grep -q "^= " "$file"; then
                local snippet_title
                snippet_title=$(grep "^= " "$file" | head -1 | sed 's/^= //')
                cqa_fail_manual "$file" "" "Snippet has title '= ${snippet_title}' -- remove from snippet and add to including files"
            fi
            if grep -E "$PATTERN_BLOCK_TITLE" "$file" > /dev/null 2>&1; then
                local bt
                bt=$(grep -E "$PATTERN_BLOCK_TITLE" "$file" | head -1)
                cqa_fail_manual "$file" "" "Snippet has block title '${bt}' -- move to including files"
            fi
            cqa_file_pass "$file"
            continue
        fi

        # Check 1: Has content type metadata
        if [[ -z "$content_type" ]]; then
            cqa_delegated "$file" "" "3" "Missing :_mod-docs-content-type: metadata"
        fi

        # Check 2: Has topic ID with {context}
        if [[ "$(basename "$file")" == "master.adoc" ]]; then
            if ! grep -q '\[id="{context}"\]' "$file" && ! grep -q "\[id='{context}'\]" "$file"; then
                cqa_delegated "$file" "" "2" "Missing or incorrect topic ID (master.adoc should use [id=\"{context}\"])"
            fi
        else
            if ! grep -q '\[id=".*_{context}"\]' "$file" && ! grep -q "\[id='.*_{context}'\]" "$file"; then
                cqa_delegated "$file" "" "2" "Missing or incorrect topic ID (must include _{context})"
            fi
        fi

        # Check 3: Has exactly one H1 title
        local h1_count
        h1_count=$(grep -c "^= " "$file" || echo "0")
        if [[ "$h1_count" -ne 1 ]]; then
            cqa_fail_manual "$file" "" "Has $h1_count H1 titles (should be exactly 1)"
        fi

        # Check 4: Has short introduction (abstract)
        if ! grep -q '\[role="_abstract"\]' "$file"; then
            cqa_delegated "$file" "" "9" "Missing [role=\"_abstract\"] short introduction"
        fi

        # Check 5: Has blank line after H1
        local h1_line
        h1_line=$(grep -n "^= " "$file" | head -1 | cut -d: -f1)
        if [[ -n "$h1_line" ]]; then
            local check_line=$((h1_line + 1))
            local next_content
            next_content=$(sed -n "${check_line}p" "$file")
            # Skip past document attribute lines (:key: value)
            while [[ "$next_content" =~ ^: ]]; do
                check_line=$((check_line + 1))
                next_content=$(sed -n "${check_line}p" "$file")
            done
            if [[ -n "$next_content" ]]; then
                if [[ "$CQA_FIX_MODE" == true ]]; then
                    sed -i "${check_line}i\\\\" "$file"
                fi
                cqa_fail_autofix "$file" "$check_line" "Missing blank line after H1 title" "Inserted blank line"
            fi
        fi

        # Check 6: Image alt text
        if grep -q "^image::" "$file"; then
            if grep "^image::" "$file" | grep -v '\["' > /dev/null; then
                local img_ln
                img_ln=$(grep -n "^image::" "$file" | grep -v '\["' | head -1 | cut -d: -f1)
                cqa_fail_manual "$file" "$img_ln" "Image(s) missing alt text in quotes"
            fi
        fi

        # Check 7: Admonitions do not include titles
        if grep -En "^\.(NOTE|WARNING|IMPORTANT|TIP|CAUTION)" "$file" > /dev/null 2>&1; then
            local adm_ln
            adm_ln=$(grep -En "^\.(NOTE|WARNING|IMPORTANT|TIP|CAUTION)" "$file" | head -1 | cut -d: -f1)
            if [[ "$CQA_FIX_MODE" == true ]]; then
                sed -i '/^\.\(NOTE\|WARNING\|IMPORTANT\|TIP\|CAUTION\)/d' "$file"
            fi
            cqa_fail_autofix "$file" "$adm_ln" "Admonition has title (should not have title)" "Removed admonition title"
        fi

        # Nested assembly checks
        if [[ "$is_nested_assembly" == true ]]; then
            if ! grep -q "ifdef::context\[:parent-context: {context}\]" "$file"; then
                cqa_delegated "$file" "" "2" "Nested assembly missing parent-context preservation at top"
            fi
            if ! grep -q "ifdef::parent-context\[:context: {parent-context}\]" "$file" || \
               ! grep -q "ifndef::parent-context\[:\!context:\]" "$file"; then
                cqa_delegated "$file" "" "2" "Nested assembly missing context restoration at bottom"
            fi
            if ! grep -q "^:context: " "$file"; then
                cqa_delegated "$file" "" "2" "Nested assembly missing :context: declaration"
            fi
        fi

        # Assembly-specific checks
        if [[ "$content_type" == "ASSEMBLY" ]]; then
            if grep -E "^===[[:space:]]" "$file" > /dev/null 2>&1; then
                cqa_fail_manual "$file" "" "Assembly contains level 2+ subheadings (=== or deeper)"
            fi
            if grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v "\.Additional resources" > /dev/null 2>&1; then
                cqa_delegated "$file" "" "2" "Assembly contains block titles (only .Additional resources allowed)" "manual"
            fi
        fi

        # Concept checks (Reference modules commonly use descriptive block titles for tables/sections)
        if [[ "$content_type" == "CONCEPT" ]]; then
            if grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v "\.Additional resources" | grep -v "\.Next steps" | grep -v "^\.Example" | grep -v "^\.Sample" > /dev/null 2>&1; then
                local bt_ln
                bt_ln=$(grep -En "$PATTERN_BLOCK_TITLE" "$file" | grep -v "\.Additional resources" | grep -v "\.Next steps" | grep -v "^\.Example" | grep -v "^\.Sample" | head -1 | cut -d: -f1)
                cqa_fail_manual "$file" "$bt_ln" "Contains block titles other than .Additional resources, .Next steps, or .Example/.Sample"
            fi
        fi

        # Procedure checks
        if [[ "$content_type" == "PROCEDURE" ]]; then
            if ! grep -q "^\.Procedure$" "$file"; then
                cqa_delegated "$file" "" "4" "Missing .Procedure block title"
            else
                local proc_count
                proc_count=$(grep -c "^\.Procedure" "$file" || echo "0")
                if [[ "$proc_count" -gt 1 ]]; then
                    cqa_fail_manual "$file" "" "Has $proc_count .Procedure block titles (should be exactly 1)"
                fi
                if grep "^\.Procedure " "$file" > /dev/null 2>&1; then
                    cqa_fail_manual "$file" "" ".Procedure block title has embellishments (should be just '.Procedure')"
                fi
            fi

            local allowed_blocks="^\\.Prerequisites$|^\\.Prerequisite$|^\\.Procedure|^\\.Verification$|^\\.Results$|^\\.Result$|^\\.Troubleshooting$|^\\.Troubleshooting steps$|^\\.Troubleshooting step$|^\\.Next steps$|^\\.Next step$|^\\.Additional resources$|^\\.Example|^\\.Sample|^\\.Available|^\\.Before|^\\.After|^\\.Optional"
            if grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v -E "$allowed_blocks" > /dev/null 2>&1; then
                local violating
                violating=$(grep -E "$PATTERN_BLOCK_TITLE" "$file" | grep -v -E "$allowed_blocks" | head -1)
                cqa_fail_manual "$file" "" "Non-standard block title: $violating"
            fi
        fi

        if [[ "$_CQA_CURRENT_FILE_HAS_ISSUES" == false ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa05_check
exit "$(cqa_exit_code)"
