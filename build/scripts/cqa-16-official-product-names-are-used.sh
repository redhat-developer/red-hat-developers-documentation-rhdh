#!/bin/bash
# cqa-16-official-product-names-are-used.sh
# Verify and fix official product name usage per CQA requirement #16
#
# Usage: ./cqa-16-official-product-names-are-used.sh [--fix] [--all] <file-path>
#
# Checks for hardcoded product names that should use AsciiDoc attributes.
# See .vale-styles/DeveloperHub/Attributes.yml for the full list.
#
# Autofix:
#   - Replaces hardcoded names with attribute references
#
# Skips:
#   - Content inside source/listing blocks (----, ....)
#   - AsciiDoc attribute definitions (:attr: value)
#   - AsciiDoc comments (//)
#   - artifacts/attributes.adoc (defines the attributes)
#   - Snippet files

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# Define product name patterns and their replacements
# Format: "pattern|replacement|strip_attrs|parent_pattern"
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

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa16_check() {
    local target="$1"

    cqa_header "16" "Verify official product names" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue

        local local_content_type
        local_content_type=$(head -1 "$file" 2>/dev/null)
        if [[ "$local_content_type" =~ ^:_mod-docs-content-type:.*SNIPPET ]]; then
            continue
        fi

        cqa_file_start "$file"
        cqa_compute_block_ranges "$file"

        local file_violations=0

        # Check each pattern
        for pattern_entry in "${PATTERNS[@]}"; do
            IFS='|' read -r pattern replacement strip_attrs parent_pattern <<< "$pattern_entry"

            while IFS=: read -r line_num line_content; do
                [[ -z "$line_num" ]] && continue

                # Skip lines inside source/listing blocks
                if cqa_is_in_block "$file" "$line_num"; then
                    continue
                fi

                # Skip attribute definitions and comments
                [[ "$line_content" =~ ^:[a-zA-Z] ]] && continue
                [[ "$line_content" =~ ^// ]] && continue

                # Strip attribute references to avoid false positives
                local stripped="$line_content"
                IFS=',' read -ra attrs <<< "$strip_attrs"
                for attr in "${attrs[@]}"; do
                    stripped="${stripped//\{${attr}\}/}"
                done
                if ! echo "$stripped" | grep -q "$pattern"; then
                    continue
                fi

                # If this pattern is a substring of a parent pattern, check for parent
                if [[ -n "$parent_pattern" ]]; then
                    if echo "$line_content" | grep -q "$parent_pattern"; then
                        local standalone="${line_content//$parent_pattern/}"
                        if ! echo "$standalone" | grep -q "$pattern"; then
                            continue
                        fi
                    fi
                fi

                file_violations=$((file_violations + 1))
                cqa_fail_autofix "$file" "$line_num" "Hardcoded \"$pattern\" -> $replacement" "Replaced with $replacement"

            done < <(grep -n "$pattern" "$file" 2>/dev/null || true)
        done

        if [[ $file_violations -gt 0 && "$CQA_FIX_MODE" == true ]]; then
            # Apply fixes: process patterns longest first (already ordered)
            for pattern_entry in "${PATTERNS[@]}"; do
                IFS='|' read -r pattern replacement _ _ <<< "$pattern_entry"
                local fix_attr="${replacement%% or *}"
                if grep -q "$pattern" "$file"; then
                    sed -i "/^:/!{/^\/\//!s/$pattern/$fix_attr/g}" "$file"
                fi
            done
            # Fix double-bracing artifacts
            sed -i 's/{{/{/g; s/}}/}/g' "$file"
        fi

        if [[ $file_violations -eq 0 ]]; then
            cqa_file_pass "$file"
        fi
    done
}

cqa_run_for_each_title _cqa16_check
exit "$(cqa_exit_code)"
