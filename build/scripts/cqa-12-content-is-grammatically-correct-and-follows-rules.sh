#!/bin/bash
# cqa-12-content-is-grammatically-correct-and-follows-rules.sh
# Validates grammar and style using Vale (CQA #12)
#
# Usage: ./cqa-12-content-is-grammatically-correct-and-follows-rules.sh [--fix] [--all] <file-path>
#
# Checks:
#   - Runs Vale with .vale.ini (grammar, spelling, style, terminology)
#   - Reports errors, warnings, and suggestions
#
# Autofix:
#   - Passes --fix through to Vale (Vale supports --fix for some rules)
#
# Requires:
#   - vale CLI installed
#   - .vale.ini configuration file

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

[[ -f ".vale.ini" ]] || { echo "Error: .vale.ini configuration file not found" >&2; exit 1; }

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa12_check() {
    local target="$1"

    cqa_header "12" "Verify Grammar and Style (Vale)" "$target"

    # Filter out attributes.adoc from collected files
    local vale_files=()
    for f in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$f" != *.adoc ]] && continue
        [[ "$(basename "$f")" == "attributes.adoc" ]] && continue
        vale_files+=("$f")
    done

    if [[ ${#vale_files[@]} -eq 0 ]]; then
        echo "No files to validate."
        return
    fi

    cqa_file_start "$target"

    if [[ "$CQA_FORMAT" == "json" ]]; then
        # SARIF mode: get Vale JSON, convert to SARIF results
        local vale_json
        vale_json=$(vale --config .vale.ini --output JSON "${vale_files[@]}" 2>/dev/null || true)

        python3 -c "
import json, sys
try:
    d = json.loads('''$vale_json''')
    count = 0
    for f, issues in d.items():
        for i in issues:
            count += 1
            print(f\"{f}\t{i['Line']}\t{i['Severity']}\t{i['Check']}: {i['Message']}\")
    if count == 0:
        sys.exit(0)
    else:
        sys.exit(1)
except Exception as e:
    print(f'Error parsing Vale JSON: {e}', file=sys.stderr)
    sys.exit(2)
" 2>/dev/null | while IFS=$'\t' read -r file line _severity message; do
            cqa_fail_manual "$file" "$line" "$message"
        done
    else
        # Checklist mode: run Vale and format output
        if [[ "$CQA_FIX_MODE" == true ]]; then
            echo "Running Vale with grammar/style checks..."
            echo "(Vale --fix is not yet supported; showing issues for manual fix)"
            echo ""
        fi

        local vale_exit=0
        vale --config .vale.ini --output line "${vale_files[@]}" 2>/dev/null || vale_exit=$?

        if [[ $vale_exit -eq 0 ]]; then
            cqa_file_pass "$target"
        else
            echo ""
            cqa_fail_manual "$target" "" "Vale found grammar/style issues (see output above)"
        fi
    fi
}

cqa_run_for_each_title _cqa12_check
exit "$(cqa_exit_code)"
