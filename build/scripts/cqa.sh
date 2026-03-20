#!/bin/bash
# cqa.sh — Run all CQA checks in optimal workflow order
#
# Usage: ./build/scripts/cqa.sh [--fix] [--all] [--title PATTERN] [--format checklist|json] <file-path>
#
# Runs all 18 CQA scripts in the order defined by cqa-main-workflow.md.
# Passes all arguments through to each script.
#
# With --all (checklist mode): displays a compact summary checklist.
# With --format json: outputs a single merged SARIF JSON document.
# With a single file: shows full per-file output from each script.
#
# Examples:
#   ./build/scripts/cqa.sh titles/install-rhdh-ocp/master.adoc
#   ./build/scripts/cqa.sh --fix --all
#   ./build/scripts/cqa.sh --all
#   ./build/scripts/cqa.sh --all --format json

source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# CQA scripts in optimal workflow order (matches cqa-main-workflow.md)
CQA_SCRIPTS=(
    "cqa-00-orphaned-modules.sh"
    "cqa-03-content-is-modularized.sh"
    "cqa-13-information-is-conveyed-using-the-correct-content.sh"
    "cqa-10-titles-are-brief-complete-and-descriptive.sh"
    "cqa-08-short-description-content.sh"
    "cqa-09-short-description-format.sh"
    "cqa-11-procedures-prerequisites.sh"
    "cqa-02-assembly-structure.sh"
    "cqa-05-modular-elements-checklist.sh"
    "cqa-04-modules-use-official-templates.sh"
    "cqa-06-assemblies-use-the-official-template-assemblies-ar.sh"
    "cqa-07-toc-max-3-levels.sh"
    "cqa-16-official-product-names-are-used.sh"
    "cqa-01-asciidoctor-dita-vale.sh"
    "cqa-12-content-is-grammatically-correct-and-follows-rules.sh"
    "cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh"
    "cqa-14-no-broken-links.sh"
    "cqa-15-redirects.sh"
)

# Build argument list to pass through (reconstruct from parsed values)
pass_args=()
[[ "$CQA_FIX_MODE" == true ]] && pass_args+=("--fix")
[[ "$CQA_ALL_MODE" == true ]] && pass_args+=("--all")
[[ -n "$CQA_TITLE_PATTERN" ]] && pass_args+=("--title" "$CQA_TITLE_PATTERN")
[[ -n "$CQA_TARGET_FILE" ]] && pass_args+=("$CQA_TARGET_FILE")

total=0
passed=0
failed=0

# ── JSON/SARIF mode: merge all scripts into one SARIF document ──
if [[ "$CQA_FORMAT" == "json" ]]; then
    all_runs=""

    for script in "${CQA_SCRIPTS[@]}"; do
        script_path="${CQA_SCRIPT_DIR}/${script}"
        [[ -x "$script_path" ]] || continue

        total=$((total + 1))

        # Run script in JSON mode, capture SARIF output
        sarif_output=$("$script_path" "${pass_args[@]}" --format json 2>/dev/null || true)

        # Extract the runs array content (the single run object)
        run_object=$(echo "$sarif_output" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    runs = d.get('runs', [])
    if runs:
        print(json.dumps(runs[0]))
except:
    pass
" 2>/dev/null || true)

        if [[ -n "$run_object" ]]; then
            if [[ -n "$all_runs" ]]; then
                all_runs="${all_runs},${run_object}"
            else
                all_runs="$run_object"
            fi
        fi
    done

    # Emit merged SARIF
    cat <<SARIF_EOF
{
  "\$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [${all_runs}]
}
SARIF_EOF
    exit 0
fi

# ── Summary checklist mode (--all) ──
if [[ "$CQA_ALL_MODE" == true ]]; then
    echo "## CQA Summary Checklist"
    echo ""

    for script in "${CQA_SCRIPTS[@]}"; do
        script_path="${CQA_SCRIPT_DIR}/${script}"
        [[ -x "$script_path" ]] || continue

        total=$((total + 1))

        # Extract CQA number from filename
        cqa_num=$(echo "$script" | sed 's/^cqa-0*\([0-9]*\).*/\1/')

        # Run script, capture output
        output=$("$script_path" "${pass_args[@]}" 2>&1 || true)

        # Extract the CQA header line for the check name
        cqa_name=$(echo "$output" | grep "^## CQA #" | head -1 | sed 's/^## CQA #[0-9]*: //')

        # Collect issue lines (AUTOFIX, MANUAL, FIXED, delegated) — file path is included by cqa-lib.sh
        script_issues=$(echo "$output" | grep -E '^- \[ \] \[' | grep -E '\[AUTOFIX\]|\[MANUAL\]|\[-> CQA' || true)

        if [[ -z "$script_issues" ]]; then
            echo "- [x] **CQA #${cqa_num}:** ${cqa_name}"
            passed=$((passed + 1))
        else
            echo "- [ ] **CQA #${cqa_num}:** ${cqa_name}"
            failed=$((failed + 1))

            echo "$script_issues" | sed 's/^- \[ \] //' | while IFS= read -r line; do
                echo "    - ${line}"
            done
        fi
    done

    echo ""
    echo "---"
    echo "**Total:** ${total} checks | ${passed} passed | ${failed} with issues"

    [[ $failed -gt 0 ]] && exit 1
    exit 0
fi

# ── Verbose mode (single title): show full output from each script ──
for script in "${CQA_SCRIPTS[@]}"; do
    script_path="${CQA_SCRIPT_DIR}/${script}"
    if [[ ! -x "$script_path" ]]; then
        echo "WARNING: Script not found or not executable: $script_path" >&2
        continue
    fi

    total=$((total + 1))
    echo ""
    echo "========================================"

    if "$script_path" "${pass_args[@]}"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
done

echo ""
echo "========================================"
echo "## CQA Summary"
echo "Scripts run: $total | Passed: $passed | Failed: $failed"

[[ $failed -gt 0 ]] && exit 1
