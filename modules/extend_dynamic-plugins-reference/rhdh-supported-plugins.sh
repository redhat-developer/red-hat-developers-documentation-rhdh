#!/bin/bash

# Set consistent locale for sorting across different systems
export LC_ALL=C

# script to generate rhdh-supported-plugins.adoc from content in
# https://github.com/redhat-developer/rhdh/tree/main/catalog-entities/extensions/packages/
# and optionally generate ref-community-supported-plugins.adoc from
# https://github.com/redhat-developer/rhdh-plugin-export-overlays

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

norm="\033[0;39m"
green="\033[1;32m"
blue="\033[1;34m"
red="\033[1;31m"
orange="\033[1;35m"

QUIET=1; # suppress debug output

BRANCH=main
SKIP_TABLES=0
SKIP_COMMUNITY_TABLE=0

overlaysRepo="https://github.com/redhat-developer/rhdh-plugin-export-overlays"

CATALOG_INDEX_REGISTRY="${CATALOG_INDEX_REGISTRY:-quay.io/rhdh}"

debug() {
  if [[ $QUIET -eq 0 ]]; then
    echo -e "${orange}[DEBUG] $1${norm}"
  fi
}

  if ! command -v yq >/dev/null 2>&1; then
    echo -e "${red}[ERROR] yq is required but not found. Please install yq (jq wrapper, NOT the mikefarah version) from https://kislyuk.github.io/yq/${norm}"
    exit 1
  elif yq --help 2>&1 | grep -q mikefarah; then
    echo -e "${red}[ERROR] mikefarah version of yq found. Please install the jq wrapper from https://kislyuk.github.io/yq/ ${norm}"
    exit 1
  fi

usage() {
  cat <<EOF

Generate an updated table of dynamic plugins from content in:
* $CATALOG_INDEX_REGISTRY/plugin-catalog-index:${INDEX_TAG}
* $overlaysRepo:${OVERLAYS_BRANCH}

By default, both repos are processed. Use --skip-tables or --skip-community-table to skip either.

Requires:
* skopeo
* jq 1.6+
* yq from https://pypi.org/project/yq/ - not the mikefarah version

Usage:

$0 -b stable-ref-branch [options]

Options:
  -b, --ref-branch          : Branch against which plugin versions should be incremented, like release-1.y; default: main
  --skip-tables             : Skip re-generating dynamic plugin tables and .csv
  --skip-community-table    : Skip re-generating the community plugins table
  -v                        : more verbose output
  -h, --help                : Show this help

Examples:

  $0 -b release-1.10
  $0 -b release-1.10 --clean
  $0 -b release-1.10 --skip-community-table   # Only regen dynamic plugin tables
  $0 -b main        --skip-tables            # Only regen community table

EOF
}

if [[ "$#" -lt 1 ]]; then usage; exit 1; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-b'|'--ref-branch') BRANCH="$2"; shift 1;;        # reference branch, eg., 1.1.x
    '--skip-tables') SKIP_TABLES=1;;
    '--skip-community-table') SKIP_COMMUNITY_TABLE=1;;
    '-v') QUIET=0;;
    '-h'|'--help') usage; exit 0;;
    *) echo "Unknown parameter used: $1."; usage; exit 1;;
  esac
  shift 1
done

if [[ ! $BRANCH ]]; then usage; exit 1; fi

catalogindextmpdir="/tmp/plugin-catalog-index_${BRANCH}"

INDEX_TAG="${BRANCH#release-}"
if [[ $INDEX_TAG == "main" ]]; then
  INDEX_TAG="next"
fi

# Set temp directory paths based on BRANCH
overlaystmpdir="/tmp/rhdh-plugin-export-overlays_$BRANCH" # for catalog metadata

# need this for BOTH the community table generation AND the dynamic plugin tables generation
if [[ ! -d "$overlaystmpdir" ]]; then
    echo -e "${green}Cloning $overlaysRepo (branch: $BRANCH)...${norm}"
    pushd /tmp >/dev/null || exit
        git clone "$overlaysRepo" --depth 1 -b "$BRANCH" "rhdh-plugin-export-overlays_${BRANCH}" --quiet
    popd >/dev/null || exit
fi

fetch_catalog_index() {
  local image="${CATALOG_INDEX_REGISTRY}/plugin-catalog-index:${INDEX_TAG}"
  if ! command -v skopeo >/dev/null 2>&1; then
    echo -e "${red}[ERROR] skopeo is required but not found.${norm}" >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo -e "${red}[ERROR] jq is required but not found.${norm}" >&2
    exit 1
  fi
  echo -e "${green}Fetching $image...${norm}"
  rm -rf "$catalogindextmpdir"
  mkdir -p "$catalogindextmpdir"
  local archive="${catalogindextmpdir}/image.tar"
  local unpack="${catalogindextmpdir}/unpack"
  skopeo copy "docker://${image}" "docker-archive:${archive}"
  mkdir -p "$unpack"
  tar xf "$archive" -C "$unpack"
  for layer in $(jq -r '.[0].Layers[]' "$unpack/manifest.json"); do
    tar xf "$unpack/$layer" -C "$catalogindextmpdir"
  done
  rm -rf "$unpack" "$archive"
}

generate_dynamic_plugins_table() {
  fetch_catalog_index
  local src="${catalogindextmpdir}/extend_dynamic-plugins-reference"
  local -a files=(
    con-preinstalled-dynamic-plugins.adoc
    ref-deprecated-plugins.adoc
    ref-ga-plugins.adoc
    ref-technology-preview-plugins.adoc
    rhdh-supported-plugins.csv
  )
  ls "${catalogindextmpdir}"
  if [[ ! -d "$src" ]]; then
    echo -e "${red}[ERROR] Missing directory in catalog index image: $src${norm}" >&2
    exit 1
  fi
  for f in "${files[@]}"; do
    if [[ ! -f "$src/$f" ]]; then
      echo -e "${red}[ERROR] Missing file in catalog index image: $src/$f${norm}" >&2
      exit 1
    fi
    cp "$src/$f" "${SCRIPT_DIR}/$f"
    echo -e "${green}Copied $f from catalog index${norm}"
  done
}

# Call function if not skipped
if [[ $SKIP_TABLES -eq 0 ]]; then
    generate_dynamic_plugins_table
fi

# ============================================================================
# Generate ref-community-supported-plugins.adoc from rhdh-plugin-export-overlays
# ============================================================================

# Extract ${VAR_NAME} placeholders from spec.appConfigExamples[0].content for docs tables.
get_required_variables() {
    local metadata_file="$1"
    local Required_Variables=""
    local appConfig
    appConfig=$(yq -r '.spec.appConfigExamples[0].content // empty' "$metadata_file" 2>/dev/null)
    if [[ -n "$appConfig" && "$appConfig" != "null" ]]; then
        # Extract ${VARIABLE_NAME} patterns
        # shellcheck disable=SC2016
        while IFS= read -r var; do
            [[ -n "$var" ]] && Required_Variables="${Required_Variables}\`${var}\`\\n\\n"
        done < <(echo "$appConfig" | grep -o '\${[^}]*}' | sed 's/\${//g' | sed 's/}//g' | LC_ALL=C sort -u)
    fi
    printf '%s' "$Required_Variables"
}

generate_community_table() {
    if [[ ! -d "$overlaystmpdir" ]]; then
        echo -e "${red}[ERROR] Overlays repo not found: $overlaystmpdir${norm}"
        return 1
    fi

    echo -e "${green}Generating community plugins table from $overlaystmpdir (branch: $BRANCH)${norm}"

    COMMUNITY_TABLE_FILE="/tmp/community_table_${BRANCH}.txt"
    BUNDLED_PLUGINS_FILE="/tmp/bundled_plugins_${BRANCH}.txt"

    rm -f "$COMMUNITY_TABLE_FILE" "$BUNDLED_PLUGINS_FILE"
    touch "$COMMUNITY_TABLE_FILE" "$BUNDLED_PLUGINS_FILE"

    # Read the community packages list
    COMMUNITY_PACKAGES_FILE="$overlaystmpdir/rhdh-community-packages.txt"

    if [[ ! -f "$COMMUNITY_PACKAGES_FILE" ]]; then
        echo -e "${red}[ERROR] Community packages file not found: $COMMUNITY_PACKAGES_FILE${norm}"
        return 1
    fi

    community_count=0

    # Track processed plugins to avoid duplicates using a temp file
    PROCESSED_PLUGINS_FILE="/tmp/processed_plugins_${BRANCH}.txt"
    rm -f "$PROCESSED_PLUGINS_FILE"
    touch "$PROCESSED_PLUGINS_FILE"

    # Process each line in the community packages file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Parse the workspace path (e.g., "jenkins/plugins/jenkins" or "gitlab/packages/gitlab")
        workspace_path="$line"

        # Extract workspace name (first part before /)
        workspace_name="${workspace_path%%/*}"

        # Find metadata files in this workspace
        metadata_dir="$overlaystmpdir/workspaces/$workspace_name/metadata"

        if [[ ! -d "$metadata_dir" ]]; then
            if [[ $QUIET -eq 0 ]]; then
                echo -e "${blue}[WARN] Metadata directory not found for workspace: $workspace_name${norm}"
            fi
            continue
        fi

        if [[ $QUIET -eq 0 ]]; then
            echo -e "${blue}[WARN] Check overlay metadata: $metadata_dir${norm}"
        fi
        # Process each metadata YAML file in the workspace
        for metadata_file in "$metadata_dir"/*.yaml; do
            [[ ! -f "$metadata_file" ]] && continue

            # Extract data from the metadata file
            plugin_title=$(yq -r '.metadata.title // ""' "$metadata_file")
            plugin_name=$(yq -r '.metadata.name // ""' "$metadata_file")
            plugin_version=$(yq -r '.spec.version // ""' "$metadata_file")
            dynamic_artifact=$(yq -r '.spec.dynamicArtifact // ""' "$metadata_file")
            support=$(yq -r '.spec.support // "unknown"' "$metadata_file")
            Required_Variables=$(get_required_variables "$metadata_file")

            # Skip if not a community plugin or no dynamic artifact
            [[ "$support" != "community" && "$support" != "dev-preview" ]] && continue
            [[ -z "$dynamic_artifact" || "$dynamic_artifact" == "null" ]] && continue
            [[ "$dynamic_artifact" != "oci://ghcr.io"* ]] && continue

            # Skip if already processed (avoid duplicates)
            if grep -qF "$plugin_name" "$PROCESSED_PLUGINS_FILE" 2>/dev/null; then
                continue
            fi

            # only include this plugin if its metadata matches the entry we're looking for 
            echo "$plugin_name" >> "$PROCESSED_PLUGINS_FILE"


            # Extract new path - get the base URL without the version/integrity part
            # Format: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-jenkins:bs_1.45.3__0.26.0
            # We want: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-jenkins:<tag>
            # Remove the tag to get the base path
            artifact_without_hash="${dynamic_artifact%%!*}"
            new_path_base="${artifact_without_hash%:*}"
            new_path="${new_path_base}:<tag>"

            # Format title for display
            display_title="${plugin_title:-$plugin_name}"

            if [[ $QUIET -eq 0 ]]; then
                echo    " * Plugin: $display_title"
                echo    "   Version: $plugin_version"
                printf  '   Path: %s\n\n%b\n' "$new_path" "$Required_Variables"
            fi

            # Add to community table (sorted by title)
            # shellcheck disable=SC2028
            echo "${display_title}||*${display_title}*\n|${plugin_version}|\`${new_path}\`\n\n${Required_Variables}\`" >> "$COMMUNITY_TABLE_FILE"

            community_count=$((community_count + 1))
        done
    done < "$COMMUNITY_PACKAGES_FILE"

    # Cleanup processed plugins tracking file
    rm -f "$PROCESSED_PLUGINS_FILE"


    # LC_ALL=C sort the community table by plugin title and format for adoc
    COMMUNITY_TABLE_SORTED="/tmp/community_table_sorted_${BRANCH}.txt"
    if [[ -f "$COMMUNITY_TABLE_FILE" ]]; then
        LC_ALL=C sort -t '|' -k1,1 "$COMMUNITY_TABLE_FILE" | while read -r line; do
            echo -e "${line#*||}\n" >> "$COMMUNITY_TABLE_SORTED"
        done
    fi

    # Generate the community supported plugins adoc file from template
    community_template="${0/rhdh-supported-plugins.sh/ref-community-supported-plugins.template.adoc}"
    community_output="${0/rhdh-supported-plugins.sh/ref-community-supported-plugins.adoc}"


    # Replace placeholders in template
    sed -e "/%%COMMUNITY_TABLE_CONTENT%%/{r $COMMUNITY_TABLE_SORTED" -e 'd;}' \
        -e "s/%%COMMUNITY_TABLE_COUNT%%/$community_count/g" \
        "$community_template" > "$community_output"

    echo -e "${green}Generated $community_output with $community_count migrated plugins${norm}"


    # Cleanup temp files
    rm -f "$COMMUNITY_TABLE_FILE" "$COMMUNITY_TABLE_SORTED" "$BUNDLED_PLUGINS_FILE"
}

# Call function if not skipped
if [[ $SKIP_COMMUNITY_TABLE -eq 0 ]]; then
    generate_community_table
fi

# summary of changes since last time
SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)
pushd "$SCRIPT_DIR" >/dev/null || exit
    updates=$(git diff "ref*plugins*.adoc" "con-preinstalled-dynamic-plugins.adoc" | grep -E -v "\+\+|@@" | grep "+")
    if [[ $updates ]]; then
        echo "$(echo "$updates" | wc -l) Changes include:"; echo "$updates"
    fi
popd >/dev/null || exit

# see https://issues.redhat.com/browse/RHIDP-3187 - only GA plugins should be enabled by default
if [[ -f "${ENABLED_PLUGINS}.errors" ]]; then echo;LC_ALL=C sort -u "${ENABLED_PLUGINS}.errors"; fi

# clean up CQA warnings
pushd "${SCRIPT_DIR}"/../.. >/dev/null || exit
  for d in \
    ref-community-supported-plugins.adoc \
    ref-deprecated-plugins.adoc \
    ref-other-installable-plugins.adoc \
    ref-ga-plugins.adoc \
    ref-technology-preview-plugins.adoc \
    ; do
    if [[ -f "modules/extend_dynamic-plugins-reference/$d" ]]; then
      # remove empty files
      if [[ $(cat modules/extend_dynamic-plugins-reference/$d) == ":_mod-docs-content-type: REFERENCE" ]]; then
        echo -e "${blue}[WARN] File modules/extend_dynamic-plugins-reference/$d is empty, so has been deleted."
        rm -f modules/extend_dynamic-plugins-reference/$d
        continue
      fi
      # fix product references
      node build/scripts/cqa/index.js --check 16 --fix modules/extend_dynamic-plugins-reference/$d >/dev/null 2>&1
    fi
  done
popd >/dev/null || exit

# cleanup
rm -f "$ENABLED_PLUGINS" "${ENABLED_PLUGINS}.errors"
rm -rf "$TEMP_DIR"

warnings=$(grep -c "WARN" "/tmp/warnings_${BRANCH}.txt" 2>/dev/null || echo "0")
if [[ $warnings -gt 0 ]]; then
    echo; echo -e "${blue}[WARN] $warnings warnings collected in /tmp/warnings_${BRANCH}.txt ! Consider upgrading upstream project to newer plugin versions !${norm}"
fi