#!/bin/bash
# cqa-16-verify-product-names.sh
# Verify and fix official product name usage per CQA requirement #16
#
# Usage: ./cqa-16-verify-product-names.sh [--fix] <file-path>
#   --fix:  Apply automatic fixes (replace hardcoded names with attributes)
#   file:   Processes the specified file and all its includes recursively
#   Example: ./cqa-16-verify-product-names.sh titles/install-rhdh-ocp/master.adoc
#     Processes: master.adoc → assemblies → all included modules (recursive)
#
# Checks for hardcoded product names that should use AsciiDoc attributes.
# See .vale-styles/DeveloperHub/Attributes.yml for the full list.
#
# Skips:
#   - Content inside source/listing blocks (----, ....)
#   - AsciiDoc attribute definitions (:attr: value)
#   - AsciiDoc comments (//)
#   - artifacts/attributes.adoc (defines the attributes)
#   - Snippet files

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

# Parse arguments
FIX_MODE=false
TARGET_FILE=""

for arg in "$@"; do
    case "$arg" in
        --fix) FIX_MODE=true ;;
        *)
            if [[ -z "$TARGET_FILE" ]]; then
                TARGET_FILE="$arg"
            else
                echo "Error: unexpected argument: $arg" >&2
                echo "Usage: $0 [--fix] <file-path>" >&2
                exit 1
            fi
            ;;
    esac
done

if [[ -z "$TARGET_FILE" ]]; then
    echo "Usage: $0 [--fix] <file-path>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 titles/install-rhdh-ocp/master.adoc" >&2
    echo "  $0 --fix titles/install-rhdh-ocp/master.adoc" >&2
    exit 1
fi

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "Error: File not found: $TARGET_FILE" >&2
    exit 1
fi

# Function to extract included files from a given file
get_includes() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi

    grep "^include::" "$file" 2>/dev/null | sed 's/^include:://' | sed 's/\[.*//' | while read -r include_path; do
        local dir
        dir=$(dirname "$file")
        local resolved_path

        if [[ "$include_path" == /* ]]; then
            resolved_path="$include_path"
        elif [[ "$include_path" == ../* ]]; then
            resolved_path="$dir/$include_path"
        else
            resolved_path="$dir/$include_path"
        fi

        if [[ -f "$resolved_path" ]]; then
            # shellcheck disable=SC2269
            resolved_path=$(realpath --relative-to="$REPO_ROOT" "$resolved_path" 2>/dev/null) || resolved_path="$resolved_path"
            echo "$resolved_path"
        fi
    done
}

# Function to recursively collect all files to process
collect_files() {
    local file="$1"
    local var_name="$2"

    local current_files
    eval "current_files=(\"\${${var_name}[@]}\")"

    for existing_file in "${current_files[@]}"; do
        if [[ "$existing_file" == "$file" ]]; then
            return
        fi
    done

    eval "${var_name}+=('$file')"

    while IFS= read -r included_file; do
        collect_files "$included_file" "$var_name"
    done < <(get_includes "$file")
}

# Check if a line is inside a source/listing block
# Args: $1 = file, $2 = line number
# Uses pre-computed block ranges for performance
#
# Populates BLOCK_RANGES associative array keyed by file path.
# Each value is a space-separated list of "start:end" pairs.
declare -A BLOCK_RANGES

compute_block_ranges() {
    local file="$1"

    if [[ -n "${BLOCK_RANGES[$file]+x}" ]]; then
        return
    fi

    local ranges=""
    local in_block=false
    local block_start=0
    local line_num=0

    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^----+$ ]] || [[ "$line" =~ ^\.\.\.\.+$ ]]; then
            if [[ "$in_block" == false ]]; then
                in_block=true
                block_start=$line_num
            else
                in_block=false
                ranges="$ranges $block_start:$line_num"
            fi
        fi
    done < "$file"

    BLOCK_RANGES[$file]="$ranges"
}

is_in_block() {
    local file="$1"
    local line_num="$2"

    local ranges="${BLOCK_RANGES[$file]}"
    for range in $ranges; do
        local start end
        start="${range%%:*}"
        end="${range##*:}"
        if [[ $line_num -ge $start ]] && [[ $line_num -le $end ]]; then
            return 0
        fi
    done
    return 1
}

# Define product name patterns and their replacements
# Format: "pattern|replacement|strip_attrs|parent_pattern"
#   pattern:        Literal text to search for
#   replacement:    Suggested attribute (for reporting)
#   strip_attrs:    Comma-separated attribute names to strip when filtering false positives
#   parent_pattern: Longer pattern that contains this one (to avoid double-flagging)
#
# IMPORTANT: Patterns are checked in order. Longer patterns MUST come first
# to avoid partial matches (e.g., "Red Hat OpenShift Container Platform"
# before "OpenShift Container Platform").
PATTERNS=(
    # Red Hat Platforms (longest first)
    'Red Hat Advanced Developer Suite|{rhads-brand-name}|rhads-brand-name|'
    'Red Hat OpenShift Container Platform|{ocp-brand-name}|ocp-brand-name|'
    'Red Hat Trusted Profile Analyzer|{rhtpa-brand-name}|rhtpa-brand-name|'
    'Red Hat Trusted Artifact Signer|{rhtas-brand-name}|rhtas-brand-name|'
    'Red Hat Advanced Cluster Security|{rhacs-brand-name}|rhacs-brand-name|'
    'Red Hat Developer Lightspeed|{ls-brand-name}|ls-brand-name|'
    'Red Hat OpenShift Serverless|{rhoserverless-brand-name}|rhoserverless-brand-name|'
    'Red Hat OpenShift Dedicated|{osd-brand-name}|osd-brand-name|'
    'Red Hat OpenShift Logging|{logging-brand-name}|logging-brand-name|'
    'Red Hat Container Registry|{rhcr}|rhcr|'
    'Red Hat Ecosystem Catalog|{rhec}|rhec|'
    'Red Hat Build of Keycloak|{rhbk-brand-name}|rhbk-brand-name|'
    'Red Hat Enterprise Linux|{rhel}|rhel|'
    'Red Hat OpenShift AI|{rhoai-brand-name}|rhoai-brand-name|'
    'Red Hat Developer Hub|{product} or {product-short}|product,product-short|'
    'OpenShift AI Connector|{openshift-ai-connector-name}|openshift-ai-connector-name,openshift-ai-connector-name-short|'
    'Red Hat Developer|{rhdeveloper-name}|rhdeveloper-name|Red Hat Developer Hub'
    'OpenShift Container Platform|{ocp-short}|ocp-short,ocp-brand-name|Red Hat OpenShift Container Platform'
    'OpenShift Data Foundation|{odf-name}|odf-name|'
    'Developer Lightspeed|{ls-short}|ls-short,ls-brand-name|Red Hat Developer Lightspeed'
    'Lightspeed Core Service|{lcs-name}|lcs-name|'
    'Trusted Profile Analyzer|{rhtpa-short}|rhtpa-short,rhtpa-brand-name|Red Hat Trusted Profile Analyzer'
    'Trusted Artifact Signer|{rhtas-short}|rhtas-short,rhtas-brand-name|Red Hat Trusted Artifact Signer'
    'Advanced Cluster Security|{rhacs-short}|rhacs-short,rhacs-brand-name|Red Hat Advanced Cluster Security'
    'OpenShift Dedicated|{osd-short}|osd-short,osd-brand-name|Red Hat OpenShift Dedicated'
    'OpenShift Logging|{logging-short}|logging-short,logging-brand-name|Red Hat OpenShift Logging'
    'Developer Hub|{product-short}|product-short,product,product-very-short|Red Hat Developer Hub'
    'RHDH Local|{product-local-very-short}|product-local-very-short|'
    'RHDH|{product-very-short}|product-very-short|'
    'RHOCP|{ocp-very-short}|ocp-very-short|'
    'RHOAI|{rhoai-short}|rhoai-short|'
    'RHBK|{rhbk}|rhbk|'
    'ACS|{rhacs-very-short}|rhacs-very-short|'
    'LCS|{lcs-short}|lcs-short|'
    'TAS|{rhtas-very-short}|rhtas-very-short|'
    'TPA|{rhtpa-very-short}|rhtpa-very-short|'
    'Backstage|{backstage} or {product-custom-resource-type}|backstage,product-custom-resource-type|'
    # Partner Platforms (longest first)
    'Microsoft Azure Kubernetes Service|{aks-brand-name}|aks-brand-name|'
    'Amazon Elastic Kubernetes Service|{eks-brand-name}|eks-brand-name|'
    'Elastic Kubernetes Service|{eks-name}|eks-name,eks-brand-name|Amazon Elastic Kubernetes Service'
    'Azure Kubernetes Service|{aks-name}|aks-name,aks-brand-name|Microsoft Azure Kubernetes Service'
    'Google Kubernetes Engine|{gke-brand-name}|gke-brand-name|'
    'Amazon Web Services|{aws-brand-name}|aws-brand-name|'
    'AWS|{aws-short}|aws-short|'
    'Microsoft Azure|{azure-brand-name}|azure-brand-name|Microsoft Azure Kubernetes Service'
    'Azure|{azure-short}|azure-short|Microsoft Azure'
    'AKS|{aks-short}|aks-short|'
    'EKS|{eks-short}|eks-short|'
    'GKE|{gke-short}|gke-short|'
    'Google Cloud|{gcp-brand-name}|gcp-brand-name|Google Cloud Platform'
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== CQA #16: Verify Official Product Names ==="
echo ""
echo "Reference: .claude/skills/cqa-16-official-product-names-are-used.md"
echo ""
if [[ "$FIX_MODE" == true ]]; then
    echo -e "${YELLOW}FIX MODE${NC} - Will apply automatic replacements"
    echo ""
fi

# Collect files
FILES_TO_PROCESS=()
collect_files "$TARGET_FILE" FILES_TO_PROCESS

TOTAL_VIOLATIONS=0
FILES_WITH_VIOLATIONS=0
FILES_CHECKED=0
FILES_FIXED=0

for file in "${FILES_TO_PROCESS[@]}"; do
    # Skip non-.adoc files
    [[ "$file" != *.adoc ]] && continue

    # Skip attributes.adoc (defines the attributes)
    [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

    # Skip snippet files
    local_content_type=$(head -1 "$file" 2>/dev/null)
    if [[ "$local_content_type" =~ ^:_mod-docs-content-type:.*SNIPPET ]]; then
        continue
    fi

    FILES_CHECKED=$((FILES_CHECKED + 1))

    # Pre-compute source block ranges for this file
    compute_block_ranges "$file"

    file_violations=0

    # Check each pattern
    for pattern_entry in "${PATTERNS[@]}"; do
        IFS='|' read -r pattern replacement strip_attrs parent_pattern <<< "$pattern_entry"

        # Search for hardcoded pattern in the file
        while IFS=: read -r line_num line_content; do
            [[ -z "$line_num" ]] && continue

            # Skip lines inside source/listing blocks
            if is_in_block "$file" "$line_num"; then
                continue
            fi

            # Skip AsciiDoc attribute definitions (lines starting with :attr:)
            if [[ "$line_content" =~ ^:[a-zA-Z] ]]; then
                continue
            fi

            # Skip AsciiDoc comments
            if [[ "$line_content" =~ ^// ]]; then
                continue
            fi

            # Strip attribute references to avoid false positives
            # e.g., a line with {product-short} should not flag "Developer Hub"
            stripped="$line_content"
            IFS=',' read -ra attrs <<< "$strip_attrs"
            for attr in "${attrs[@]}"; do
                stripped="${stripped//\{${attr}\}/}"
            done
            if ! echo "$stripped" | grep -q "$pattern"; then
                continue
            fi

            # If this pattern is a substring of a parent pattern,
            # check if the match is actually part of the parent
            if [[ -n "$parent_pattern" ]]; then
                if echo "$line_content" | grep -q "$parent_pattern"; then
                    # Remove parent pattern occurrences and check if standalone match remains
                    standalone="${line_content//$parent_pattern/}"
                    if ! echo "$standalone" | grep -q "$pattern"; then
                        continue
                    fi
                fi
            fi

            file_violations=$((file_violations + 1))

            if [[ "$FIX_MODE" == false ]]; then
                if [[ $file_violations -eq 1 ]]; then
                    echo -e "${RED}✗${NC} $file"
                fi
                echo "  Line $line_num: Hardcoded \"$pattern\" → $replacement"
            fi

        done < <(grep -n "$pattern" "$file" 2>/dev/null || true)
    done

    if [[ $file_violations -gt 0 ]]; then
        FILES_WITH_VIOLATIONS=$((FILES_WITH_VIOLATIONS + 1))
        TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + file_violations))

        if [[ "$FIX_MODE" == false ]]; then
            echo ""
        fi

        if [[ "$FIX_MODE" == true ]]; then
            # Apply fixes: process patterns longest first (already ordered)
            cp "$file" "${file}.bak"
            local_fixed=false

            for pattern_entry in "${PATTERNS[@]}"; do
                IFS='|' read -r pattern replacement _ _ <<< "$pattern_entry"

                # Determine the fix attribute (first one if multiple suggested)
                # "or" separates alternatives; use the first one for auto-fix
                fix_attr="${replacement%% or *}"

                if grep -q "$pattern" "$file"; then
                    # Skip attribute definitions and comments
                    sed -i "/^:/!{/^\/\//!s/$pattern/$fix_attr/g}" "$file"
                    local_fixed=true
                fi
            done

            # Fix double-bracing artifacts from nested replacements
            sed -i 's/{{/{/g; s/}}/}/g' "$file"

            if [[ "$local_fixed" == true ]]; then
                FILES_FIXED=$((FILES_FIXED + 1))
                echo -e "${YELLOW}📝${NC} $file - Fixed $file_violations violation(s)"
                rm -f "${file}.bak"
            else
                mv "${file}.bak" "$file"
            fi
        fi
    else
        echo -e "${GREEN}✓${NC} $file"
    fi
done

echo ""
echo "=== Summary ==="
echo "Files checked: $FILES_CHECKED"

if [[ "$FIX_MODE" == true ]] && [[ $FILES_FIXED -gt 0 ]]; then
    echo -e "${YELLOW}📝 Fixed $FILES_FIXED file(s) with $TOTAL_VIOLATIONS violation(s)${NC}"
    echo ""
    echo "Review fixes and verify:"
    echo "  1. First occurrence in abstract uses {product} (not {product-short})"
    echo "  2. Source code blocks were not modified"
    echo "  3. Attribute definitions were not modified"
    exit 0
elif [[ $TOTAL_VIOLATIONS -eq 0 ]]; then
    echo -e "${GREEN}✓ All files use official product name attributes${NC}"
    exit 0
else
    echo -e "${RED}✗ Found $TOTAL_VIOLATIONS violation(s) in $FILES_WITH_VIOLATIONS file(s)${NC}"
    echo ""
    echo "Run with --fix to apply automatic replacements:"
    echo "  $0 --fix $TARGET_FILE"
    echo ""
    echo "After fixing, manually verify:"
    echo "  - First occurrence in abstract uses {product} (not {product-short})"
    echo "  - Source code blocks were not modified"
    exit 1
fi
