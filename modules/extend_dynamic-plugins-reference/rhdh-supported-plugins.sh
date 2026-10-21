#!/bin/bash

# Set consistent locale for sorting across different systems
export LC_ALL=C

# Fetch the supported tables from Quay and the community table from GHCR.

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

norm="\033[0;39m"
green="\033[1;32m"
blue="\033[1;34m"
red="\033[1;31m"
orange="\033[1;35m"

QUIET=1; # suppress debug output

BRANCH=main
SKIP_SUPPORTED_TABLES=0
SKIP_COMMUNITY_TABLE=0

SUPPORTED_CATALOG_INDEX="${SUPPORTED_CATALOG_INDEX:-quay.io/rhdh/plugin-catalog-index}"
COMMUNITY_CATALOG_INDEX="${COMMUNITY_CATALOG_INDEX:-ghcr.io/redhat-developer/rhdh-plugin-export-overlays/plugin-catalog-index}"

debug() {
  if [[ $QUIET -eq 0 ]]; then
    echo -e "${orange}[DEBUG] $1${norm}"
  fi
}

usage() {
  cat <<EOF

Fetch dynamic plugin tables from the supported and community catalog indexes:
* $SUPPORTED_CATALOG_INDEX
* $COMMUNITY_CATALOG_INDEX

Both indexes must match the documentation branch's RHDH major.minor version.
Use --skip-supported-tables or --skip-community-table to skip either source.

Requires:
* skopeo
* jq 1.6+

Usage:

$0 -b stable-ref-branch [options]

Options:
  -b, --ref-branch          : Branch against which plugin versions should be incremented, like release-1.y; default: main
  --skip-supported-tables   : Skip re-generating supported dynamic plugin tables and .csv
  --skip-community-table    : Skip re-generating the community dynamic plugins table and .csv
  -v                        : more verbose output
  -h, --help                : Show this help

Examples:

  $0 -b release-2.1                                  # Fetch both supported and community tables (default behavior)
  $0 -b release-2.1 --skip-community-table           # Skip fetching community table
  $0 -b main        --skip-supported-tables          # Skip fetching supported tables

EOF
}

if [[ "$#" -lt 1 ]]; then usage; exit 1; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-b'|'--ref-branch') BRANCH="$2"; shift 1;;        # reference branch, eg., 1.1.x
    '--skip-supported-tables') SKIP_SUPPORTED_TABLES=1;;
    '--skip-community-table') SKIP_COMMUNITY_TABLE=1;;
    '-v') QUIET=0;;
    '-h'|'--help') usage; exit 0;;
    *) echo "Unknown parameter used: $1."; usage; exit 1;;
  esac
  shift 1
done

if [[ ! $BRANCH ]]; then usage; exit 1; fi
if [[ $SKIP_SUPPORTED_TABLES -eq 1 && $SKIP_COMMUNITY_TABLE -eq 1 ]]; then
  echo -e "${red}[ERROR] Cannot skip both supported and community tables.${norm}" >&2
  exit 1;
fi
if [[ $BRANCH != main && ! $BRANCH =~ ^release-[0-9]+\.[0-9]+$ ]]; then
  echo -e "${red}[ERROR] Expected main or release-X.Y: $BRANCH${norm}" >&2
  exit 1
fi

for tool in skopeo jq tar; do
  command -v "$tool" >/dev/null 2>&1 || { echo "[ERROR] $tool is required" >&2; exit 1; }
done

catalogindextmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$catalogindextmpdir"' EXIT
INDEX_TAG="${BRANCH#release-}"
if [[ $BRANCH == main ]]; then
  INDEX_TAG=next
fi
SUPPORTED_IMAGE="${SUPPORTED_CATALOG_INDEX}:${INDEX_TAG}"
COMMUNITY_IMAGE="${COMMUNITY_CATALOG_INDEX}:${INDEX_TAG}"
SUPPORTED_FILES=(con-preinstalled-dynamic-plugins.adoc ref-deprecated-plugins.adoc
  ref-ga-plugins.adoc ref-technology-preview-plugins.adoc rhdh-supported-plugins.csv)
COMMUNITY_FILES=(ref-community-supported-plugins.adoc rhdh-community-plugins.csv)
MANIFEST="$SCRIPT_DIR/catalog-index-sources.json"

rhdh_minor() {
  [[ $1 =~ ^([0-9]+)\.([0-9]+)(\.[0-9]+)?$ ]] || return 1
  printf '%s.%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
}

#######################################
# Resolves a catalog index image tag to a digest and extracts that image.
# Removes the downloaded archive and unpacked layers after extraction.
# Arguments:
#   $1: Tagged catalog index image reference.
#   $2: Destination directory for metadata and extracted files.
# Outputs:
#   Writes fetch progress to stdout.
#   Creates $2/inspect.json, $2/digest, and extracted files under $2/catalog-index.
# Returns:
#   0 on success; nonzero if inspection, download, or extraction fails.
#######################################
fetch_catalog_index() {
  local image="$1" destination="$2" digest layer

  if ! command -v skopeo >/dev/null 2>&1; then
    echo -e "${red}[ERROR] skopeo is required but not found.${norm}" >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo -e "${red}[ERROR] jq is required but not found.${norm}" >&2
    exit 1
  fi

  mkdir -p "$destination/unpack" "$destination/catalog-index" || return 1
  skopeo inspect --no-tags "docker://$image" > "$destination/inspect.json" || return 1
  digest=$(jq -er '.Digest | select(test("^sha256:[0-9a-f]{64}$"))' "$destination/inspect.json") || return 1
  printf '%s\n' "$digest" > "$destination/digest"
  echo -e "${green}Fetching $image@$digest...${norm}"

  skopeo copy "docker://${image%:*}@$digest" "docker-archive:$destination/image.tar" || return 1
  tar xf "$destination/image.tar" -C "$destination/unpack" || return 1
  jq -e '.[0].Layers | type == "array" and length > 0' "$destination/unpack/manifest.json" >/dev/null || return 1
  for layer in $(jq -r '.[0].Layers[]' "$destination/unpack/manifest.json"); do
    tar xf "$destination/unpack/$layer" -C "$destination/catalog-index" || return 1
  done
  rm -rf "$destination/image.tar" "$destination/unpack"
}

EXPECTED_RELEASE=""
if [[ $SKIP_SUPPORTED_TABLES -eq 0 ]]; then
  fetch_catalog_index "$SUPPORTED_IMAGE" "$catalogindextmpdir/supported" || exit 1
  SUPPORTED_VERSION=$(jq -er '.Labels["rhdh.version"] | strings' "$catalogindextmpdir/supported/inspect.json") || exit 1
  EXPECTED_RELEASE=$(rhdh_minor "$SUPPORTED_VERSION") || { echo "[ERROR] Invalid supported RHDH version: $SUPPORTED_VERSION" >&2; exit 1; }
fi

if [[ $SKIP_COMMUNITY_TABLE -eq 0 ]]; then
  fetch_catalog_index "$COMMUNITY_IMAGE" "$catalogindextmpdir/community" || exit 1
  COMMUNITY_INFO="$catalogindextmpdir/community/catalog-index/build-info.json"
  [[ -f $COMMUNITY_INFO ]] || { echo "[ERROR] Missing $COMMUNITY_INFO" >&2; exit 1; }
  COMMUNITY_VERSION=$(jq -er '."rhdh-version" | strings' "$COMMUNITY_INFO") || exit 1
  COMMUNITY_RELEASE=$(rhdh_minor "$COMMUNITY_VERSION") || { echo "[ERROR] Invalid community RHDH version: $COMMUNITY_VERSION" >&2; exit 1; }
  [[ -z $EXPECTED_RELEASE || $COMMUNITY_RELEASE == "$EXPECTED_RELEASE" ]] || { echo "[ERROR] $COMMUNITY_IMAGE has RHDH $COMMUNITY_VERSION, expected $EXPECTED_RELEASE" >&2; exit 1; }
  EXPECTED_RELEASE="$COMMUNITY_RELEASE"
fi
[[ $INDEX_TAG == next || $EXPECTED_RELEASE == "$INDEX_TAG" ]] || { echo "[ERROR] Catalog index has RHDH $EXPECTED_RELEASE, expected $INDEX_TAG" >&2; exit 1; }

# Validate both images before changing generated files.
for file in "${SUPPORTED_FILES[@]}"; do
  if [[ $SKIP_SUPPORTED_TABLES -eq 0 && ! -f "$catalogindextmpdir/supported/catalog-index/extend_dynamic-plugins-reference/$file" ]]; then
    echo "[ERROR] Missing supported catalog file: $file" >&2
    exit 1
  fi
done
if [[ $SKIP_COMMUNITY_TABLE -eq 0 ]]; then
  for file in "${COMMUNITY_FILES[@]}"; do
    if [[ ! -f "$catalogindextmpdir/community/catalog-index/extend_dynamic-plugins-reference/$file" ]]; then
      echo "[ERROR] Missing community catalog file: $file" >&2
      exit 1
    fi
  done
fi

# Update tracking manifest with new catalog index digests
# Keep the previous source record when this run skips an index.
SUPPORTED_ENTRY=null
COMMUNITY_ENTRY=null
if [[ -f $MANIFEST ]]; then
  SUPPORTED_ENTRY=$(jq -c '.sources.supported // null' "$MANIFEST") || exit 1
  COMMUNITY_ENTRY=$(jq -c '.sources.community // null' "$MANIFEST") || exit 1
fi

# Replace each fetched source record with its image, digest, and versions.
# The supported image stores its Backstage version in an image label.
if [[ $SKIP_SUPPORTED_TABLES -eq 0 ]]; then
  SUPPORTED_DIGEST=$(cat "$catalogindextmpdir/supported/digest")
  SUPPORTED_BACKSTAGE=$(jq -r '.Labels["backstage.version"] // ""' "$catalogindextmpdir/supported/inspect.json")
  SUPPORTED_ENTRY=$(jq -nc \
    --arg image "$SUPPORTED_IMAGE" \
    --arg digest "$SUPPORTED_DIGEST" \
    --arg rhdh "$SUPPORTED_VERSION" \
    --arg backstage "$SUPPORTED_BACKSTAGE" \
    '{image: $image, digest: $digest,
      rhdhVersion: $rhdh, backstageVersion: $backstage}') || exit 1
  printf 'Supported index: %s@%s (RHDH %s, Backstage %s)\n' \
    "${SUPPORTED_IMAGE%:*}" "$SUPPORTED_DIGEST" "$SUPPORTED_VERSION" "$SUPPORTED_BACKSTAGE"
fi

# The community image stores its Backstage version in build-info.json.
if [[ $SKIP_COMMUNITY_TABLE -eq 0 ]]; then
  COMMUNITY_DIGEST=$(cat "$catalogindextmpdir/community/digest")
  COMMUNITY_BACKSTAGE=$(jq -r '."backstage-version" // ""' "$COMMUNITY_INFO")
  COMMUNITY_ENTRY=$(jq -nc \
    --arg image "$COMMUNITY_IMAGE" \
    --arg digest "$COMMUNITY_DIGEST" \
    --arg rhdh "$COMMUNITY_VERSION" \
    --arg backstage "$COMMUNITY_BACKSTAGE" \
    '{image: $image, digest: $digest,
      rhdhVersion: $rhdh, backstageVersion: $backstage}') || exit 1
  printf 'Community index: %s@%s (RHDH %s, Backstage %s)\n' \
    "$COMMUNITY_CATALOG_INDEX" "$COMMUNITY_DIGEST" "$COMMUNITY_VERSION" "$COMMUNITY_BACKSTAGE"
fi

# Combine refreshed entries with preserved entries for skipped indexes.
# --argjson keeps each entry as a JSON object or null rather than a string.
jq -n \
  --arg branch "$BRANCH" \
  --arg release "$EXPECTED_RELEASE" \
  --argjson supported "$SUPPORTED_ENTRY" \
  --argjson community "$COMMUNITY_ENTRY" \
  '{
    branch: $branch,
    rhdhRelease: $release,
    sources: {supported: $supported, community: $community}
  }' \
  > "$catalogindextmpdir/manifest.json" || exit 1

if [[ $SKIP_SUPPORTED_TABLES -eq 0 ]]; then
  for file in "${SUPPORTED_FILES[@]}"; do
    cp "$catalogindextmpdir/supported/catalog-index/extend_dynamic-plugins-reference/$file" "$SCRIPT_DIR/$file" || exit 1
  done
fi
if [[ $SKIP_COMMUNITY_TABLE -eq 0 ]]; then
  for file in "${COMMUNITY_FILES[@]}"; do
    cp "$catalogindextmpdir/community/catalog-index/extend_dynamic-plugins-reference/$file" "$SCRIPT_DIR/$file" || exit 1
  done
fi
cp "$catalogindextmpdir/manifest.json" "$MANIFEST" || exit 1

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
