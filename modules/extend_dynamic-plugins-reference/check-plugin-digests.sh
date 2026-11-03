#!/bin/bash

# RHIDP-18434: report dynamic plugin artifacts whose pinned digest no longer matches
# the digest currently published under the artifact tag in the generated tables.
#
# Each generated table row pins an immutable reference such as
#   oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-acr@sha256:5d7d...
# and names the mutable artifact tag in the next column, for example bs_1.54.9__1.28.1.
# If the tag has been rebuilt since the table was generated, the pinned digest and
# creation time differ from the tag's current digest and creation time.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

norm="\033[0;39m"
red="\033[1;31m"
blue="\033[1;34m"

JOBS=8
ARCH=amd64
OS=linux
WARN_ONLY=0
VERBOSE=0
TRIGGER=0
FILES=()

usage() {
  cat <<EOF

Compare pinned plugin digests with the current digest published under each artifact tag.

Options:
  -f, --file FILE    Generated table(s) to check - use one flag per file
                     Default: -f ref-community-supported-plugins.adoc -f ref-ga-plugins.adoc -f
                     ref-technology-preview-plugins.adoc -f ref-other-installable-plugins.adoc
  -j, --jobs N       Parallel skopeo inspections (default: $JOBS)
      --arch ARCH    Platform whose manifest digest is compared (default: $ARCH)
      --os OS        Platform whose manifest digest is compared (default: $OS)
      --all          Print matching rows too
      --output FILE  Also write the markdown report to FILE (default: report.md)
      --warn-only    Exit 0 even when digests differ (report only)
      --trigger      Dispatch the GitHub catalog index and documentation workflows
                     with gh, using TRIGGER_DOCS_REF as the documentation branch
                     (default: release-2.1)
  -h, --help         Show this help

Exit codes: 0 no drift, 1 drift found, 2 usage or tool error.

Examples:
  ./modules/extend-dynamic-plugins-reference/check-plugin-digests.sh
EOF
}

while (($# > 0)); do
  case $1 in
    -f | --file)
      FILES+=("$2")
      shift 2
      ;;
    -j | --jobs)
      JOBS=$2
      shift 2
      ;;
    --arch)
      ARCH=$2
      shift 2
      ;;
    --os)
      OS=$2
      shift 2
      ;;
    --all) VERBOSE=1; shift ;;
    --output)
      OUTPUT_FILE=$2
      shift 2
      ;;
    --warn-only) WARN_ONLY=1; shift ;;
    --trigger) TRIGGER=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *)
      echo -e "${red}[ERROR] Unknown option: $1${norm}" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if ((${#FILES[@]} == 0)); then
  for candidate in ref-community-supported-plugins ref-ga-plugins \
    ref-technology-preview-plugins ref-other-installable-plugins; do
    [[ -f $SCRIPT_DIR/$candidate.adoc ]] && FILES+=("$candidate.adoc")
  done
fi

for tool in skopeo jq sort; do
  command -v "$tool" >/dev/null 2>&1 || { echo -e "${red}[ERROR] $tool is required. Must install it to proceed.${norm}" >&2; exit 2; }
done

[[ $JOBS =~ ^[1-9][0-9]*$ ]] || { echo -e "${red}[ERROR] --jobs must be a positive integer.${norm}" >&2; exit 2; }

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# Emit repository, pinned digest, artifact tag, and source table for every row
# that pins a digest and names the tag in a following table cell.
extract_pins() {
  awk '
    function trim(value) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", value); return value }

    BEGIN { OFS = "\t" }

    {
      line = $0

      if (match(line, /oci:\/\/[^`@[:space:]]+@sha256:[0-9a-f]+/)) {
        reference = substr(line, RSTART, RLENGTH)
        reference = substr(reference, 7)
        separator = index(reference, "@")
        repository = substr(reference, 1, separator - 1)
        digest = substr(reference, separator + 1)
        have_pin = 1
        next
      }

      # A single-cell row holds the artifact tag, for example |bs_1.54.9__1.28.1.
      # Plugin names (|*ACR*) and required variables (`TOKEN`) are not tags.
      if (line ~ /^\|[^|]+$/ && line !~ /[`*]/) {
        cell = trim(substr(line, 2))
        if (have_pin && cell ~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
          print repository, digest, cell, FILENAME
          have_pin = 0
        }
        next
      }

      # Some tables put the tag in the last cell of a multi-cell plugin row.
      if (line ~ /^\|/ && split(line, cells, "|") >= 3 && have_pin) {
        candidate = trim(cells[length(cells)])
        if (candidate ~ /^[A-Za-z0-9][A-Za-z0-9._-]*$/) {
          print repository, digest, candidate, FILENAME
          have_pin = 0
        }
      }
    }
  ' "$1"
}

for file in "${FILES[@]}"; do
  [[ -f $file ]] || file="$SCRIPT_DIR/$file"
  if [[ ! -f $file ]]; then
    echo -e "${red}[ERROR] Table not found: $file${norm}" >&2
    exit 2
  fi
  extract_pins "$file"
done > "$TMP_DIR/pins.tsv"

if [[ ! -s $TMP_DIR/pins.tsv ]]; then
  echo -e "${red}[ERROR] No pinned plugin digests found in the selected tables.${norm}" >&2
  exit 2
fi

PIN_COUNT=$(wc -l < "$TMP_DIR/pins.tsv")
echo -e "${blue}Checking $PIN_COUNT pinned plugin artifacts...${norm}"

# Inspect one reference and cache its image digest, creation time, and platform
# manifest digest. Tables pin single-platform manifest digests while tags usually
# publish a multi-architecture index, so the platform manifest digest is what has
# to match. Failures are cached too.
inspect_ref() {
  local ref=$1
  local cache raw image manifest
  cache="$TMP_DIR/inspect/$(printf '%s' "$ref" | tr -c 'A-Za-z0-9._-' '_').json"
  [[ -s $cache ]] && return 0

  if ! raw=$(skopeo inspect --no-tags --raw "docker://$ref" 2>"$cache.err"); then
    printf 'INSPECT_FAILED\t%s\n' "$(tr '\n' ' ' < "$cache.err")" > "$cache"
    return 0
  fi

  manifest=$(jq -r --arg arch "$ARCH" --arg os "$OS" '
    if (.manifests | type) == "array" and (.manifests | length) > 0 then
      ((.manifests[] | select(.platform.architecture == $arch and .platform.os == $os) | .digest)
        // .manifests[0].digest)
    else empty end
  ' <<<"$raw" 2>/dev/null)

  image=$(skopeo inspect --no-tags "docker://$ref" 2>>"$cache.err" |
    jq -r '[.Digest // "", .Created // ""] | @tsv' 2>/dev/null)

  if [[ -z $image ]]; then
    printf 'INSPECT_FAILED\t%s\n' "$(tr '\n' ' ' < "$cache.err")" > "$cache"
    return 0
  fi

  [[ -n $manifest ]] || manifest=${image%%$'\t'*}
  printf '%s\t%s\n' "$image" "$manifest" > "$cache"
}

mkdir -p "$TMP_DIR/inspect"
awk -F'\t' '{ print $1 "@" $2; print $1 ":" $3 }' "$TMP_DIR/pins.tsv" \
  | sort -u > "$TMP_DIR/refs.txt"

running=0
while read -r ref; do
  inspect_ref "$ref" &
  running=$((running + 1))
  if ((running >= JOBS)); then
    wait -n
    running=$((running - 1))
  fi
done < "$TMP_DIR/refs.txt"
wait

# Seconds since epoch for an ISO 8601 timestamp, so nanosecond precision does not
# break the comparison. Returns an empty string for unknown values.
epoch() {
  jq -rn --arg value "${1:-}" '
    if $value == "" then "" else ($value | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601) end
  ' 2>/dev/null
}

result_file="$TMP_DIR/results.tsv"
: > "$result_file"

while IFS=$'\t' read -r repository digest tag source; do
  pinned_ref="$repository@$digest"
  tag_ref="$repository:$tag"
  pinned_cache="$TMP_DIR/inspect/$(printf '%s' "$pinned_ref" | tr -c 'A-Za-z0-9._-' '_').json"
  tag_cache="$TMP_DIR/inspect/$(printf '%s' "$tag_ref" | tr -c 'A-Za-z0-9._-' '_').json"

  if grep -q '^INSPECT_FAILED' "$pinned_cache" 2>/dev/null; then
    verdict=PINNED_UNRESOLVABLE
    pinned_digest=$digest
    pinned_created=""
    tag_digest=""
    tag_created=""
  elif grep -q '^INSPECT_FAILED' "$tag_cache" 2>/dev/null; then
    verdict=TAG_UNRESOLVABLE
    IFS=$'\t' read -r _ pinned_created pinned_digest < "$pinned_cache"
    tag_digest=""
    tag_created=""
  else
    IFS=$'\t' read -r _ pinned_created pinned_digest < "$pinned_cache"
    IFS=$'\t' read -r _ tag_created tag_digest < "$tag_cache"

    if [[ $pinned_digest == "$tag_digest" ]]; then
      verdict=OK
    else
      pinned_epoch=$(epoch "$pinned_created")
      tag_epoch=$(epoch "$tag_created")
      if [[ -n $pinned_epoch && -n $tag_epoch ]] && ((tag_epoch > pinned_epoch)); then
        # The tag was rebuilt after the table was generated: the index is stale.
        verdict=STALE_PIN
      elif [[ -n $pinned_epoch && -n $tag_epoch ]] && ((tag_epoch < pinned_epoch)); then
        # The pinned artifact is newer than the tag: the tag was not republished.
        verdict=PIN_NEWER_THAN_TAG
      else
        verdict=DIGEST_MISMATCH
      fi
    fi
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$verdict" "${repository##*/}" "$tag" \
    "${pinned_digest:-n/a}" "${pinned_created:-unknown}" \
    "${tag_digest:-n/a}" "${tag_created:-unknown}" \
    "$source" "$repository" >> "$result_file"
done < "$TMP_DIR/pins.tsv"

total=$(wc -l < "$result_file")
drift=$(awk -F'\t' '$1 != "OK"' "$result_file" | wc -l)
stale=$(awk -F'\t' '$1 == "STALE_PIN"' "$result_file" | wc -l)
mismatch=$(awk -F'\t' '$1 == "DIGEST_MISMATCH" || $1 == "PIN_NEWER_THAN_TAG"' "$result_file" | wc -l)
unresolvable=$(awk -F'\t' '$1 ~ /_UNRESOLVABLE$/' "$result_file" | wc -l)

report_file="$TMP_DIR/report.md"

{
  echo "## Dynamic plugin digest check"
  echo
  if ((drift > 0)); then
    echo "**$drift of $total** pinned plugin artifacts no longer match their artifact tag."
    echo
    ((stale > 0)) && echo "- $stale were rebuilt under the tag after the tables were generated."
    ((mismatch > 0)) && echo "- $mismatch differ without a newer tag build time (re-tagged or older tag)."
    ((unresolvable > 0)) && echo "- $unresolvable reference either the pinned digest or the tag failed to resolve."
    echo
    echo "Sources: $(awk -F'\t' '$1 != "OK" { print $8 }' "$result_file" | sort -u | tr '\n' ' ')"
  else
    echo "All **$total** pinned plugin artifacts match their artifact tag."
  fi
  echo

  awk -F'\t' -v verbose="$VERBOSE" '
    function when(value) {
      if (value == "" || value == "unknown") return "unknown"
      gsub(/T/, " ", value)
      return substr(value, 1, 16)
    }
    BEGIN {
      print "| Verdict | Plugin image | Tag | Pinned built (UTC) | Tag built (UTC) | Pinned digest | Tag digest |"
      print "| --- | --- | --- | --- | --- | --- | --- |"
    }
    verbose == 1 || $1 != "OK" {
      printf "| %s | %s | %s | %s | %s | `%s` | `%s` |\n", $1, $2, $3, when($5), when($7), $4, $6
    }
  ' "$result_file"

  if ((drift > 0)); then
    cat <<'EOF'

### Next steps

1. Rebuild the community catalog index for the matching branch (`main` or `release-2.y`):
   [generate-catalog-index.yaml](https://github.com/redhat-developer/rhdh-plugin-export-overlays/actions/workflows/generate-catalog-index.yaml)

   ```bash
   branch="release-2.1"
   gh workflow run generate-catalog-index.yaml \
     --repo redhat-developer/rhdh-plugin-export-overlays --ref "$branch"
   ```

2. Rebuild the downstream community index with the "update index" pipeline:
   [pipeline schedules](https://gitlab.cee.redhat.com/rhidp/rhdh-plugin-catalog/-/pipeline_schedules)

   ```bash
   branch="release-2.1"
   glab ci run -R rhidp/rhdh-plugin-catalog -b "$branch" \
     --variables "PIPELINE_JOB:update-index,ALWAYS_CLONE:false,SEND_SLACK_NOTICE:on_failure,CATALOG_STRICT_VALIDATION:true,CATALOG_ALLOW_VERSION_REGRESSION:false,CATALOG_ALLOW_FALLBACK_TAGS:false"
   ```

3. Regenerate the plugin tables from the rebuilt index:
   [generate-supported-plugins-pr.yml](https://github.com/redhat-developer/red-hat-developers-documentation-rhdh/actions/workflows/generate-supported-plugins-pr.yml)

   ```bash
   branch="release-2.1"
   gh workflow run generate-supported-plugins-pr.yml \
     --repo redhat-developer/red-hat-developers-documentation-rhdh \
     --ref "$branch" -f branch="$branch"
   ```

Re-run this script after step 3 to confirm every pinned digest matches its tag.
EOF
  fi
} > "$report_file"

[[ -n ${OUTPUT_FILE:-} ]] || OUTPUT_FILE=report.md
cp "$report_file" "$OUTPUT_FILE"
cat "$report_file"
echo
echo -e "${blue}Report also written to $OUTPUT_FILE${norm}"


if ((TRIGGER == 1)); then
  command -v gh >/dev/null 2>&1 || { echo -e "${red}[ERROR] gh is required for --trigger.${norm}" >&2; exit 2; }
  docs_ref=${TRIGGER_DOCS_REF:-release-2.1}
  echo
  echo -e "${blue}Dispatching workflows for $docs_ref...${norm}"
  gh workflow run generate-catalog-index.yaml \
    --repo redhat-developer/rhdh-plugin-export-overlays --ref main || exit 2
  gh workflow run generate-supported-plugins-pr.yml \
    --repo redhat-developer/red-hat-developers-documentation-rhdh \
    --ref "$docs_ref" -f "branch=$docs_ref" || exit 2
  echo "Started both workflows. The downstream community index still needs the GitLab 'update index' schedule."
fi

if ((drift > 0 && WARN_ONLY == 0)); then
  exit 1
fi
exit 0
