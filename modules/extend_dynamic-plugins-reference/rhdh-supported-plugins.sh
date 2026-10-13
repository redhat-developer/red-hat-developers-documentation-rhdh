#!/bin/bash

# Set consistent locale for sorting across different systems
export LC_ALL=C

# script to fetch dynamic plugin tables (including the community plugins table)
# from the catalog index image at quay.io/rhdh/plugin-catalog-index

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

CATALOG_INDEX_REGISTRY="${CATALOG_INDEX_REGISTRY:-quay.io/rhdh}"

debug() {
  if [[ $QUIET -eq 0 ]]; then
    echo -e "${orange}[DEBUG] $1${norm}"
  fi
}

usage() {
  cat <<EOF

Generate updated tables of dynamic plugins from the catalog index image:
* $CATALOG_INDEX_REGISTRY/plugin-catalog-index:${INDEX_TAG}

Both the dynamic plugin tables and the community plugins table are fetched from the catalog index image.
Use --skip-tables or --skip-community-table to skip fetching either set.

Requires:
* skopeo
* jq 1.6+

Usage:

$0 -b stable-ref-branch [options]

Options:
  -b, --ref-branch          : Branch against which plugin versions should be incremented, like release-1.y; default: main
  --skip-tables             : Skip fetching the dynamic plugin tables and .csv from the catalog index
  --skip-community-table    : Skip fetching the community plugins table from the catalog index
  -v                        : more verbose output
  -h, --help                : Show this help

Examples:

  $0 -b release-1.10
  $0 -b release-1.10 --skip-community-table   # Only fetch dynamic plugin tables
  $0 -b main        --skip-tables            # Only fetch community table

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
  local -a files=()

  if [[ $SKIP_TABLES -eq 0 ]]; then
    files+=(
      con-preinstalled-dynamic-plugins.adoc
      ref-deprecated-plugins.adoc
      ref-ga-plugins.adoc
      ref-technology-preview-plugins.adoc
      rhdh-supported-plugins.csv
    )
  fi

  if [[ $SKIP_COMMUNITY_TABLE -eq 0 ]]; then
    files+=(ref-community-supported-plugins.adoc)
  fi

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

# Fetch tables from catalog index if at least one set is requested
if [[ $SKIP_TABLES -eq 0 || $SKIP_COMMUNITY_TABLE -eq 0 ]]; then
    generate_dynamic_plugins_table
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
