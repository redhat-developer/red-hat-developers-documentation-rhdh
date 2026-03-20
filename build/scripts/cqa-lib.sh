#!/bin/bash
# cqa-lib.sh — Shared library for CQA scripts
# Source this file from any cqa-*.sh script:
#   source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
#
# Provides:
#   - Argument parsing (--fix, --all, --title PATTERN, --format checklist|json)
#   - File discovery (cqa_collect_files, cqa_get_content_type)
#   - Block range helpers (cqa_compute_block_ranges, cqa_is_in_block)
#   - Output helpers (cqa_pass, cqa_fail_autofix, cqa_fail_manual, cqa_fixed,
#                     cqa_delegated, cqa_file_header, cqa_summary)
#   - SARIF JSON output
#
# After sourcing, scripts get these variables:
#   CQA_FIX_MODE     - true/false
#   CQA_ALL_MODE     - true/false
#   CQA_TITLE_PATTERN - glob pattern for --title
#   CQA_FORMAT        - "checklist" or "json"
#   CQA_TARGET_FILE   - path to target file (empty if --all)
#   CQA_TARGET_FILES  - array of master.adoc files to process
#   CQA_REPO_ROOT     - absolute path to repository root
#   CQA_SCRIPT_DIR    - absolute path to build/scripts/

# Prevent double-sourcing
[[ -n "${_CQA_LIB_LOADED+x}" ]] && return 0
_CQA_LIB_LOADED=1

readonly _CQA_FMT_CHECKLIST="checklist"

set -e

# ── Repository root and script directory ──
CQA_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CQA_REPO_ROOT="$(cd "$CQA_SCRIPT_DIR/../.." && pwd)"
cd "$CQA_REPO_ROOT"

# ── Argument parsing ──
CQA_FIX_MODE=false
CQA_ALL_MODE=false
CQA_TITLE_PATTERN=""
CQA_FORMAT="$_CQA_FMT_CHECKLIST"
CQA_TARGET_FILE=""
# shellcheck disable=SC2034  # Used by cqa-01
CQA_OUTPUT_FORMAT=""  # legacy --output line|JSON for cqa-01
declare -a CQA_TARGET_FILES=()

cqa_parse_args() {
    local script_name="$1"
    shift

    local expect_title=false
    local expect_output=false

    for arg in "$@"; do
        if [[ "$expect_title" == true ]]; then
            CQA_TITLE_PATTERN="$arg"
            expect_title=false
            continue
        fi
        if [[ "$expect_output" == true ]]; then
            # shellcheck disable=SC2034
            CQA_OUTPUT_FORMAT="$arg"
            expect_output=false
            continue
        fi
        case "$arg" in
            --fix)    CQA_FIX_MODE=true ;;
            --all)    CQA_ALL_MODE=true ;;
            --title)  expect_title=true ;;
            --format)
                shift_next=true
                # handled below
                ;;
            --format=*)
                CQA_FORMAT="${arg#--format=}" ;;
            --output)
                expect_output=true ;;
            -h|--help)
                _cqa_usage "$script_name"
                exit 0
                ;;
            *)
                if [[ "$shift_next" == true ]]; then
                    CQA_FORMAT="$arg"
                    shift_next=false
                elif [[ -z "$CQA_TARGET_FILE" ]]; then
                    CQA_TARGET_FILE="$arg"
                else
                    echo "Error: unexpected argument: $arg" >&2
                    _cqa_usage "$script_name"
                    exit 1
                fi
                ;;
        esac
    done

    # Validate format
    case "$CQA_FORMAT" in
        "$_CQA_FMT_CHECKLIST"|json) ;;
        *) echo "Error: --format must be '$_CQA_FMT_CHECKLIST' or 'json'" >&2; exit 1 ;;
    esac

    # Resolve targets
    if [[ "$CQA_ALL_MODE" == true ]]; then
        _cqa_discover_all_titles
    elif [[ -n "$CQA_TARGET_FILE" ]]; then
        if [[ ! -f "$CQA_TARGET_FILE" ]]; then
            echo "Error: File not found: $CQA_TARGET_FILE" >&2
            exit 1
        fi
        CQA_TARGET_FILES=("$CQA_TARGET_FILE")
    else
        _cqa_usage "$script_name"
        exit 1
    fi
}

_cqa_usage() {
    local script_name="$1"
    echo "Usage: $script_name [--fix] [--all | --title PATTERN | <file-path>] [--format checklist|json]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --fix              Apply automatic fixes" >&2
    echo "  --all              Process all titles" >&2
    echo "  --title PATTERN    Process titles matching glob pattern" >&2
    echo "  --format FORMAT    Output format: checklist (default) or json (SARIF)" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $script_name titles/install-rhdh-ocp/master.adoc" >&2
    echo "  $script_name --fix --all" >&2
    echo "  $script_name --title 'install*' --format json" >&2
    return 0
}

_cqa_discover_all_titles() {
    local pattern="${CQA_TITLE_PATTERN:-*}"
    local seen_realpaths=()

    while IFS= read -r master; do
        local real_path
        real_path=$(realpath "$master" 2>/dev/null) || real_path="$master"

        # Skip symlink duplicates
        local is_dup=false
        for seen in "${seen_realpaths[@]}"; do
            if [[ "$seen" == "$real_path" ]]; then
                is_dup=true
                break
            fi
        done
        [[ "$is_dup" == true ]] && continue

        seen_realpaths+=("$real_path")
        CQA_TARGET_FILES+=("$master")
    done < <(find titles/ -maxdepth 2 -name "master.adoc" -path "titles/${pattern}/master.adoc" 2>/dev/null | sort)
    return 0
}

# ── File discovery ──
# Replaces list-all-included-files-starting-from.sh and custom collect_files()
# Uses realpath dedup to handle symlinks correctly

declare -A _CQA_SEEN_FILES=()

cqa_collect_files() {
    local start_file="$1"
    _CQA_SEEN_FILES=()
    _CQA_COLLECTED_FILES=()
    _cqa_collect_recursive "$start_file"
    return 0
}

_cqa_collect_recursive() {
    local file="$1"

    [[ -f "$file" ]] || return 0

    # Resolve to repo-relative path
    local rel_path
    rel_path=$(realpath --relative-to="$CQA_REPO_ROOT" "$file" 2>/dev/null) || rel_path="$file"

    # Dedup by realpath (handles symlinks)
    local real_path
    real_path=$(realpath "$file" 2>/dev/null) || real_path="$rel_path"

    [[ -n "${_CQA_SEEN_FILES[$real_path]+x}" ]] && return 0
    _CQA_SEEN_FILES[$real_path]=1

    _CQA_COLLECTED_FILES+=("$rel_path")

    # Extract and resolve includes
    local dir
    dir=$(dirname "$rel_path")

    while IFS= read -r line; do
        local include_path
        include_path=$(echo "$line" | sed 's/^include:://' | sed 's/\[.*//')

        local resolved
        if [[ "$include_path" == /* ]]; then
            resolved="$include_path"
        else
            resolved="$dir/$include_path"
        fi

        [[ -f "$resolved" ]] && _cqa_collect_recursive "$resolved"
    done < <(grep "^include::" "$rel_path" 2>/dev/null || true)
}

# Get the collected files array (call after cqa_collect_files)
cqa_get_collected_files() {
    echo "${_CQA_COLLECTED_FILES[@]}"
}

# ── Content type ──

cqa_get_content_type() {
    local file="$1"
    local first_line
    first_line=$(head -1 "$file" 2>/dev/null)
    if [[ "$first_line" =~ ^:_mod-docs-content-type:[[:space:]]*(.*[^[:space:]])[[:space:]]*$ ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
    return 0
}

# ── Block range helpers ──
# Pre-compute source/listing block ranges for a file to skip content inside them

declare -A _CQA_BLOCK_RANGES=()

cqa_compute_block_ranges() {
    local file="$1"

    [[ -n "${_CQA_BLOCK_RANGES[$file]+x}" ]] && return 0

    local ranges=""
    local in_block=false
    local block_start=0
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^----+$ ]] || [[ "$line" =~ ^\.\.\.\.+$ ]] || [[ "$line" =~ ^\+\+\+\++$ ]]; then
            if [[ "$in_block" == false ]]; then
                in_block=true
                block_start=$line_num
            else
                in_block=false
                ranges="$ranges $block_start:$line_num"
            fi
        fi
    done < "$file"

    _CQA_BLOCK_RANGES[$file]="$ranges"
}

cqa_is_in_block() {
    local file="$1"
    local line_num="$2"

    local ranges="${_CQA_BLOCK_RANGES[$file]}"
    for range in $ranges; do
        local start="${range%%:*}"
        local end="${range##*:}"
        if [[ $line_num -ge $start ]] && [[ $line_num -le $end ]]; then
            return 0
        fi
    done
    return 1
}

# ── Output formatting ──
# Standardized output as actionable checklist

# Colors (only for checklist format, suppressed in json mode)
if [[ "$CQA_FORMAT" != "json" ]] && [[ -t 1 ]]; then
    _C_RED='\033[0;31m'
    _C_GREEN='\033[0;32m'
    _C_YELLOW='\033[1;33m'
    _C_CYAN='\033[0;36m'
    _C_NC='\033[0m'
else
    _C_RED='' _C_GREEN='' _C_YELLOW='' _C_CYAN='' _C_NC=''
fi

# SARIF accumulator for json mode
declare -a _CQA_SARIF_RESULTS=()
_CQA_SARIF_TOOL_NAME=""
_CQA_SARIF_TOOL_VERSION="1.0.0"

cqa_set_tool_info() {
    _CQA_SARIF_TOOL_NAME="$1"
    _CQA_SARIF_TOOL_VERSION="${2:-1.0.0}"
}

# Counters
_CQA_TOTAL_FILES=0
_CQA_FILES_WITH_ISSUES=0
_CQA_TOTAL_AUTOFIX=0
_CQA_TOTAL_FIXED=0
_CQA_TOTAL_MANUAL=0
_CQA_TOTAL_DELEGATED=0
_CQA_TOTAL_PASS=0
_CQA_CURRENT_FILE=""
_CQA_CURRENT_FILE_HAS_ISSUES=false

cqa_reset_counters() {
    _CQA_TOTAL_FILES=0
    _CQA_FILES_WITH_ISSUES=0
    _CQA_TOTAL_AUTOFIX=0
    _CQA_TOTAL_FIXED=0
    _CQA_TOTAL_MANUAL=0
    _CQA_TOTAL_DELEGATED=0
    _CQA_TOTAL_PASS=0
    return 0
}

# Start processing a new file
cqa_file_start() {
    local file="$1"
    _CQA_TOTAL_FILES=$((_CQA_TOTAL_FILES + 1))
    _CQA_CURRENT_FILE="$file"
    _CQA_CURRENT_FILE_HAS_ISSUES=false
    return 0
}

# File header (printed on first issue for that file)
_cqa_ensure_file_header() {
    if [[ "$_CQA_CURRENT_FILE_HAS_ISSUES" == false ]]; then
        _CQA_CURRENT_FILE_HAS_ISSUES=true
        _CQA_FILES_WITH_ISSUES=$((_CQA_FILES_WITH_ISSUES + 1))
        if [[ "$CQA_FORMAT" == "$_CQA_FMT_CHECKLIST" ]]; then
            echo ""
            echo "### $_CQA_CURRENT_FILE"
        fi
    fi
    return 0
}

# Report a passing check
cqa_pass() {
    local line="${1:-}"
    local desc="$2"
    _CQA_TOTAL_PASS=$((_CQA_TOTAL_PASS + 1))
    # SARIF: passes are not reported
    return 0
}

# Report an autofixable issue (report mode) or a fixed issue (fix mode)
cqa_fail_autofix() {
    local file="${1:-$_CQA_CURRENT_FILE}"
    local line="${2:-}"
    local desc="$3"
    local fix_desc="${4:-$desc}"

    _cqa_ensure_file_header

    if [[ "$CQA_FIX_MODE" == true ]]; then
        _CQA_TOTAL_FIXED=$((_CQA_TOTAL_FIXED + 1))
        if [[ "$CQA_FORMAT" == "$_CQA_FMT_CHECKLIST" ]]; then
            if [[ -n "$line" ]]; then
                echo -e "- [x] ${_C_GREEN}[FIXED]${_C_NC} ${file}: Line ${line}: ${fix_desc}"
            else
                echo -e "- [x] ${_C_GREEN}[FIXED]${_C_NC} ${file}: ${fix_desc}"
            fi
        fi
    else
        _CQA_TOTAL_AUTOFIX=$((_CQA_TOTAL_AUTOFIX + 1))
        if [[ "$CQA_FORMAT" == "$_CQA_FMT_CHECKLIST" ]]; then
            if [[ -n "$line" ]]; then
                echo -e "- [ ] ${_C_YELLOW}[AUTOFIX]${_C_NC} ${file}: Line ${line}: ${desc}"
            else
                echo -e "- [ ] ${_C_YELLOW}[AUTOFIX]${_C_NC} ${file}: ${desc}"
            fi
        fi
    fi

    if [[ "$CQA_FORMAT" == "json" ]]; then
        _cqa_sarif_add "$file" "$line" "warning" "$desc" "autofix"
    fi
    return 0
}

# Report a manual-only issue
cqa_fail_manual() {
    local file="${1:-$_CQA_CURRENT_FILE}"
    local line="${2:-}"
    local desc="$3"

    _cqa_ensure_file_header
    _CQA_TOTAL_MANUAL=$((_CQA_TOTAL_MANUAL + 1))

    if [[ "$CQA_FORMAT" == "$_CQA_FMT_CHECKLIST" ]]; then
        if [[ -n "$line" ]]; then
            echo -e "- [ ] ${_C_RED}[MANUAL]${_C_NC} ${file}: Line ${line}: ${desc}"
        else
            echo -e "- [ ] ${_C_RED}[MANUAL]${_C_NC} ${file}: ${desc}"
        fi
    fi

    if [[ "$CQA_FORMAT" == "json" ]]; then
        _cqa_sarif_add "$file" "$line" "error" "$desc" "manual"
    fi
    return 0
}

# Report a delegated issue (handled by another CQA script)
# Args: file line target_cqa desc [fix_type]
# fix_type: "autofix" (default) or "manual"
cqa_delegated() {
    local file="${1:-$_CQA_CURRENT_FILE}"
    local line="${2:-}"
    local target_cqa="$3"
    local desc="$4"
    local fix_type="${5:-autofix}"

    _cqa_ensure_file_header
    _CQA_TOTAL_DELEGATED=$((_CQA_TOTAL_DELEGATED + 1))

    local fix_label
    if [[ "$fix_type" == "manual" ]]; then
        fix_label=" MANUAL"
    else
        fix_label=" AUTOFIX"
    fi

    if [[ "$CQA_FORMAT" == "$_CQA_FMT_CHECKLIST" ]]; then
        if [[ -n "$line" ]]; then
            echo -e "- [ ] ${_C_CYAN}[-> CQA-${target_cqa}${fix_label}]${_C_NC} ${file}: Line ${line}: ${desc}"
        else
            echo -e "- [ ] ${_C_CYAN}[-> CQA-${target_cqa}${fix_label}]${_C_NC} ${file}: ${desc}"
        fi
    fi

    if [[ "$CQA_FORMAT" == "json" ]]; then
        _cqa_sarif_add "$file" "$line" "note" "Delegated to CQA-${target_cqa}: $desc" "delegated"
    fi
    return 0
}

# Mark file as all-passed (call if no issues were found for the file)
cqa_file_pass() {
    local file="${1:-$_CQA_CURRENT_FILE}"
    # Suppress per-file pass output — only errors are shown
    return 0
}

# Print section header (once per script invocation in --all mode)
_CQA_HEADER_PRINTED=false
cqa_header() {
    local cqa_num="$1"
    local title="$2"
    local target="${3:-}"

    if [[ "$CQA_FORMAT" == "$_CQA_FMT_CHECKLIST" ]]; then
        if [[ "$CQA_ALL_MODE" == true ]]; then
            # In --all mode, print the header only once
            if [[ "$_CQA_HEADER_PRINTED" == false ]]; then
                echo "## CQA-${cqa_num}: ${title}"
                if [[ "$CQA_FIX_MODE" == true ]]; then
                    echo -e "${_C_YELLOW}Mode: --fix${_C_NC}"
                fi
                echo ""
                _CQA_HEADER_PRINTED=true
            fi
        else
            echo "## CQA-${cqa_num}: ${title}"
            if [[ -n "$target" ]]; then
                echo "Processing: ${target}"
            fi
            if [[ "$CQA_FIX_MODE" == true ]]; then
                echo -e "${_C_YELLOW}Mode: --fix${_C_NC}"
            fi
            echo ""
        fi
    fi

    cqa_set_tool_info "cqa-${cqa_num}"
    return 0
}

# Print summary
cqa_summary() {
    if [[ "$CQA_FORMAT" == "json" ]]; then
        _cqa_sarif_emit
        return
    fi

    echo ""
    echo "### Summary"
    echo "Files: ${_CQA_TOTAL_FILES} checked, ${_CQA_FILES_WITH_ISSUES} with issues"

    if [[ "$CQA_FIX_MODE" == true ]]; then
        echo "Fixed: ${_CQA_TOTAL_FIXED} automatically"
        local remaining=$((_CQA_TOTAL_MANUAL + _CQA_TOTAL_DELEGATED))
        if [[ $remaining -gt 0 ]]; then
            echo "Remaining: ${remaining} (${_CQA_TOTAL_MANUAL} manual, ${_CQA_TOTAL_DELEGATED} delegated)"
        fi
    else
        local total_issues=$((_CQA_TOTAL_AUTOFIX + _CQA_TOTAL_MANUAL + _CQA_TOTAL_DELEGATED))
        if [[ $total_issues -gt 0 ]]; then
            echo "Violations: ${total_issues} total (${_CQA_TOTAL_AUTOFIX} autofixable, ${_CQA_TOTAL_MANUAL} manual, ${_CQA_TOTAL_DELEGATED} delegated)"
            if [[ $_CQA_TOTAL_AUTOFIX -gt 0 ]]; then
                echo "Run with --fix to auto-resolve ${_CQA_TOTAL_AUTOFIX} issues."
            fi
        else
            echo -e "${_C_GREEN}All checks passed.${_C_NC}"
        fi
    fi
}

# Return appropriate exit code
cqa_exit_code() {
    local remaining=$((_CQA_TOTAL_MANUAL + _CQA_TOTAL_DELEGATED))
    if [[ "$CQA_FIX_MODE" == true ]]; then
        [[ $remaining -gt 0 ]] && echo 1 || echo 0
    else
        local total=$((_CQA_TOTAL_AUTOFIX + _CQA_TOTAL_MANUAL + _CQA_TOTAL_DELEGATED))
        [[ $total -gt 0 ]] && echo 1 || echo 0
    fi
    return 0
}

# ── SARIF output ──

_cqa_sarif_add() {
    local file="$1"
    local line="$2"
    local level="$3"  # error, warning, note
    local message="$4"
    local kind="${5:-fail}"  # autofix, manual, delegated

    local line_num="${line:-1}"

    # Escape JSON strings
    message="${message//\\/\\\\}"
    message="${message//\"/\\\"}"
    file="${file//\\/\\\\}"
    file="${file//\"/\\\"}"

    _CQA_SARIF_RESULTS+=("{
      \"ruleId\": \"${_CQA_SARIF_TOOL_NAME}.${kind}\",
      \"level\": \"${level}\",
      \"message\": { \"text\": \"${message}\" },
      \"locations\": [{
        \"physicalLocation\": {
          \"artifactLocation\": { \"uri\": \"${file}\" },
          \"region\": { \"startLine\": ${line_num} }
        }
      }],
      \"properties\": { \"fixability\": \"${kind}\" }
    }")
    return 0
}

_cqa_sarif_emit() {
    local results=""
    local first=true
    for r in "${_CQA_SARIF_RESULTS[@]}"; do
        if [[ "$first" == true ]]; then
            results="$r"
            first=false
        else
            results="${results},${r}"
        fi
    done

    cat <<SARIF_EOF
{
  "\$schema": "https://raw.githubusercontent.com/oasis-tcs/sarif-spec/main/sarif-2.1/schema/sarif-schema-2.1.0.json",
  "version": "2.1.0",
  "runs": [{
    "tool": {
      "driver": {
        "name": "${_CQA_SARIF_TOOL_NAME}",
        "version": "${_CQA_SARIF_TOOL_VERSION}",
        "informationUri": "https://github.com/redhat-developer/red-hat-developers-documentation-rhdh"
      }
    },
    "results": [${results}]
  }]
}
SARIF_EOF
    return 0
}

# ── Delegation metadata ──
# Scripts declare what they delegate to other scripts
# Format: "check_name:target_cqa_number"
# shellcheck disable=SC2034  # Used by individual CQA scripts
declare -a CQA_DELEGATES_TO=()

# ── Common file skip helpers ──

cqa_should_skip_file() {
    local file="$1"
    local bn
    bn=$(basename "$file")

    # Skip non-adoc
    [[ "$file" != *.adoc ]] && return 0

    # Skip attributes.adoc
    [[ "$bn" == "attributes.adoc" ]] && return 0

    return 1
}

# ── Multi-title runner ──
# Wraps a script's main logic to run across --all targets

cqa_run_for_each_title() {
    local callback="$1"  # function name to call with each target file

    if [[ "$CQA_FORMAT" == "json" ]]; then
        # JSON: accumulate all results, emit once at end
        for target in "${CQA_TARGET_FILES[@]}"; do
            cqa_collect_files "$target"
            "$callback" "$target"
        done
        _cqa_sarif_emit
    else
        if [[ ${#CQA_TARGET_FILES[@]} -eq 1 ]]; then
            cqa_collect_files "${CQA_TARGET_FILES[0]}"
            "$callback" "${CQA_TARGET_FILES[0]}"
            cqa_summary
        else
            # Multiple titles: run each, then grand summary
            local grand_files=0 grand_issues=0 grand_autofix=0 grand_fixed=0 grand_manual=0 grand_delegated=0
            for target in "${CQA_TARGET_FILES[@]}"; do
                cqa_reset_counters
                cqa_collect_files "$target" || true
                "$callback" "$target" || true

                grand_files=$((grand_files + _CQA_TOTAL_FILES))
                grand_issues=$((grand_issues + _CQA_FILES_WITH_ISSUES))
                grand_autofix=$((grand_autofix + _CQA_TOTAL_AUTOFIX))
                grand_fixed=$((grand_fixed + _CQA_TOTAL_FIXED))
                grand_manual=$((grand_manual + _CQA_TOTAL_MANUAL))
                grand_delegated=$((grand_delegated + _CQA_TOTAL_DELEGATED))
            done

            echo ""
            echo "### Summary"
            echo "Files: ${grand_files} checked, ${grand_issues} with issues"
            if [[ "$CQA_FIX_MODE" == true ]]; then
                echo "Fixed: ${grand_fixed} automatically"
                echo "Remaining: $((grand_manual + grand_delegated)) (${grand_manual} manual, ${grand_delegated} delegated)"
            else
                local total=$((grand_autofix + grand_manual + grand_delegated))
                echo "Violations: ${total} total (${grand_autofix} autofixable, ${grand_manual} manual, ${grand_delegated} delegated)"
            fi
        fi
    fi
    return 0
}
