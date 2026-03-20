#!/bin/bash
# cqa.sh — Run all CQA checks in optimal workflow order
#
# Usage: ./build/scripts/cqa.sh [--fix] [--all] [--title PATTERN] <file-path>
#
# Runs all 17 CQA scripts in the order defined by cqa-main-workflow.md.
# Passes all arguments through to each script.
#
# Examples:
#   ./build/scripts/cqa.sh titles/install-rhdh-ocp/master.adoc
#   ./build/scripts/cqa.sh --fix --all
#   ./build/scripts/cqa.sh --fix titles/install-rhdh-ocp/master.adoc

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# CQA scripts in optimal workflow order (matches cqa-main-workflow.md)
CQA_SCRIPTS=(
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
    "cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh"
)

if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    echo "Usage: $0 [--fix] [--all | --title PATTERN | <file-path>]"
    echo ""
    echo "Runs all 17 CQA checks in optimal workflow order."
    echo "All arguments are passed through to each CQA script."
    echo ""
    echo "Options:"
    echo "  --fix              Apply automatic fixes"
    echo "  --all              Process all titles"
    echo "  --title PATTERN    Process titles matching glob pattern"
    echo ""
    echo "Examples:"
    echo "  $0 titles/install-rhdh-ocp/master.adoc"
    echo "  $0 --fix --all"
    exit 0
fi

total=0
passed=0
failed=0

for script in "${CQA_SCRIPTS[@]}"; do
    script_path="${SCRIPT_DIR}/${script}"
    if [[ ! -x "$script_path" ]]; then
        echo "WARNING: Script not found or not executable: $script_path" >&2
        continue
    fi

    total=$((total + 1))
    echo ""
    echo "========================================"

    if "$script_path" "$@"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
    fi
done

echo ""
echo "========================================"
echo "## CQA Summary"
echo "Scripts run: $total | Passed: $passed | Failed: $failed"

if [[ $failed -gt 0 ]]; then
    exit 1
fi
