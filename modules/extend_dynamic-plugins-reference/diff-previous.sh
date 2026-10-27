#!/bin/bash

# Set consistent locale for sorting across different systems
export LC_ALL=C

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

norm="\033[0;39m"
green="\033[1;32m"
red="\033[1;31m"

BRANCH=main
DIFF_PREVIOUS=0
DIFF_REF=""
OUTPUT="$SCRIPT_DIR/ref-dynamic-plugin-changes.adoc"

usage() {
  cat <<EOF

Compare the generated dynamic plugin .csv files in this checkout with files
from a shallow checkout of another Git ref. The comparison includes plugin
availability, name, version, support level, and delivery method changes.

Requires:
* git
* awk
* sort -V

Usage:

$0 -b stable-ref-branch (--diff-previous | --diff TAG)

Options:
  -b, --ref-branch : Current documentation branch, like release-2.1; default: main
  --diff-previous  : Compare with the previous release-X.Y branch. For main,
                     compare with the latest release-X.Y branch.
  --diff TAG       : Compare with a specific tag or Git ref, like 1.10.5
  -h, --help       : Show this help

Examples:

  $0 -b release-2.1 --diff-previous
  $0 -b release-2.1 --diff 1.10.5
  $0 -b main --diff-previous

EOF
}

if [[ "$#" -lt 1 ]]; then usage; exit 1; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-b'|'--ref-branch')
      if [[ -z ${2:-} || ${2:-} == -* ]]; then echo -e "${red}[ERROR] $1 requires a value.${norm}" >&2; usage; exit 1; fi
      BRANCH="$2"; shift 1;;
    '--diff-previous') DIFF_PREVIOUS=1;;
    '--diff')
      if [[ -z ${2:-} || ${2:-} == -* ]]; then echo -e "${red}[ERROR] --diff requires a value.${norm}" >&2; usage; exit 1; fi
      DIFF_REF="$2"; shift 1;;
    '-h'|'--help') usage; exit 0;;
    *) echo -e "${red}[ERROR] Unknown parameter used: $1.${norm}" >&2; usage; exit 1;;
  esac
  shift 1
done

if [[ $DIFF_PREVIOUS -eq 1 && $DIFF_REF ]]; then
  echo -e "${red}[ERROR] --diff-previous and --diff cannot be used together.${norm}" >&2
  usage
  exit 1
fi
if [[ $DIFF_PREVIOUS -eq 0 && ! $DIFF_REF ]]; then
  echo -e "${red}[ERROR] Specify either --diff-previous or --diff TAG.${norm}" >&2
  usage
  exit 1
fi
if [[ $BRANCH != main && ! $BRANCH =~ ^release-[0-9]+\.[0-9]+$ ]]; then
  echo -e "${red}[ERROR] Expected main or release-X.Y, but got: $BRANCH${norm}" >&2
  exit 1
fi

for tool in git awk sort mktemp; do
  command -v "$tool" >/dev/null 2>&1 || { echo "[ERROR] $tool is required. Must install it to proceed." >&2; exit 1; }
done

REPO_ROOT=$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null) || {
  echo -e "${red}[ERROR] $SCRIPT_DIR is not in a Git checkout.${norm}" >&2
  exit 1
}
REMOTE_URL=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null) || {
  echo -e "${red}[ERROR] Cannot resolve the origin remote.${norm}" >&2
  exit 1
}

comparisontmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$comparisontmpdir"' EXIT

if [[ $DIFF_PREVIOUS -eq 1 ]]; then
  if ! git ls-remote --heads "$REMOTE_URL" 'refs/heads/release-*' > "$comparisontmpdir/release-refs"; then
    echo -e "${red}[ERROR] Cannot list release branches from origin.${norm}" >&2
    exit 1
  fi

  mapfile -t RELEASE_BRANCHES < <(
    awk '{sub("refs/heads/", "", $2); if ($2 ~ /^release-[0-9]+\.[0-9]+$/) print $2}' \
      "$comparisontmpdir/release-refs" | sort -V
  )
  if [[ ${#RELEASE_BRANCHES[@]} -eq 0 ]]; then
    echo -e "${red}[ERROR] No release-X.Y branches found on origin.${norm}" >&2
    exit 1
  fi

  if [[ $BRANCH == main ]]; then
    PREVIOUS_REF=${RELEASE_BRANCHES[${#RELEASE_BRANCHES[@]}-1]}
  else
    PREVIOUS_REF=""
    CURRENT_FOUND=0
    for release_branch in "${RELEASE_BRANCHES[@]}"; do
      if [[ $release_branch == "$BRANCH" ]]; then
        CURRENT_FOUND=1
        break
      fi
      PREVIOUS_REF=$release_branch
    done
    if [[ $CURRENT_FOUND -eq 0 ]]; then
      echo -e "${red}[ERROR] $BRANCH is not a release branch on origin.${norm}" >&2
      exit 1
    fi
    if [[ ! $PREVIOUS_REF ]]; then
      echo -e "${red}[ERROR] No release branch exists before $BRANCH.${norm}" >&2
      exit 1
    fi
  fi
else
  PREVIOUS_REF=$DIFF_REF
fi

echo -e "${green}Comparing $BRANCH with $PREVIOUS_REF...${norm}"
if ! git clone --quiet --depth 1 --single-branch --branch "$PREVIOUS_REF" \
  "$REMOTE_URL" "$comparisontmpdir/previous"; then
  echo -e "${red}[ERROR] Cannot create a shallow checkout for $PREVIOUS_REF.${norm}" >&2
  exit 1
fi

PREVIOUS_DIR="$comparisontmpdir/previous/modules/extend_dynamic-plugins-reference"
CURRENT_CSVS=()
PREVIOUS_CSVS=()
for csv in "$SCRIPT_DIR"/rhdh-*-plugins.csv; do
  [[ -f $csv ]] && CURRENT_CSVS+=("$csv")
done
for csv in "$PREVIOUS_DIR"/rhdh-*-plugins.csv; do
  [[ -f $csv ]] && PREVIOUS_CSVS+=("$csv")
done
if [[ ${#CURRENT_CSVS[@]} -eq 0 ]]; then
  echo -e "${red}[ERROR] No generated plugin .csv files found in $SCRIPT_DIR.${norm}" >&2
  exit 1
fi
if [[ ${#PREVIOUS_CSVS[@]} -eq 0 ]]; then
  echo -e "${red}[ERROR] No generated plugin .csv files found at $PREVIOUS_REF.${norm}" >&2
  exit 1
fi

normalize_csv() {
  local destination="$1"
  shift
  awk '
    function parse_csv(line, fields,    count, i, character, value, quoted) {
      delete fields
      count = 1
      value = ""
      quoted = 0
      sub(/\r$/, "", line)
      for (i = 1; i <= length(line); i++) {
        character = substr(line, i, 1)
        if (quoted) {
          if (character == "\"") {
            if (substr(line, i + 1, 1) == "\"") {
              value = value "\""
              i++
            } else {
              quoted = 0
            }
          } else {
            value = value character
          }
        } else if (character == "\"") {
          quoted = 1
        } else if (character == ",") {
          fields[count++] = value
          value = ""
        } else {
          value = value character
        }
      }
      fields[count] = value
      return quoted ? -1 : count
    }

    function delivery_method(path) {
      if (path ~ /^oci:\/\//) return "OCI artifact"
      if (path ~ /^\.\/dynamic-plugins\/dist\//) return "Embedded wrapper"
      if (path == "") return "Not specified"
      return "Other"
    }

    FNR == 1 {
      delete column
      field_count = parse_csv($0, field)
      if (field_count < 1) {
        print "[ERROR] Invalid CSV header in " FILENAME > "/dev/stderr"
        exit 2
      }
      for (i = 1; i <= field_count; i++) column[field[i]] = i
      required[1] = "Name"
      required[2] = "Plugin"
      required[3] = "Version"
      required[4] = "Support Level"
      required[5] = "Path"
      for (i = 1; i <= 5; i++) {
        if (!(required[i] in column)) {
          print "[ERROR] Missing CSV column " required[i] " in " FILENAME > "/dev/stderr"
          exit 2
        }
      }
      next
    }

    NF {
      field_count = parse_csv($0, field)
      if (field_count < 1) {
        print "[ERROR] Invalid CSV row " FNR " in " FILENAME > "/dev/stderr"
        exit 2
      }
      print field[column["Plugin"]], field[column["Name"]], field[column["Version"]], \
        field[column["Support Level"]], delivery_method(field[column["Path"]])
    }
  ' OFS="$(printf '\034')" "$@" > "$destination"
}

normalize_csv "$comparisontmpdir/previous.csv" "${PREVIOUS_CSVS[@]}" || exit 1
normalize_csv "$comparisontmpdir/current.csv" "${CURRENT_CSVS[@]}" || exit 1

FIELD_SEPARATOR=$(printf '\034')
awk -F "$FIELD_SEPARATOR" -v OFS="$FIELD_SEPARATOR" \
  -v previous_file="$comparisontmpdir/previous.csv" '
  function remember(side, key,    seen_key) {
    seen_key = side SUBSEP key
    if (seen[seen_key]++) {
      print "[ERROR] Duplicate plugin package in " side " CSV files: " key > "/dev/stderr"
      duplicate = 1
    }
  }

  FILENAME == previous_file {
    remember("previous", $1)
    previous[$1] = 1
    for (i = 2; i <= 5; i++) previous_value[$1, i] = $i
    next
  }
  {
    remember("current", $1)
    current[$1] = 1
    for (i = 2; i <= 5; i++) current_value[$1, i] = $i
  }

  END {
    if (duplicate) exit 2
    label[2] = "Name"
    label[3] = "Version"
    label[4] = "Support level"
    label[5] = "Delivery method"

    for (plugin in previous) {
      if (!(plugin in current)) {
        print plugin, 0, "Availability", "Included", "Not included"
        continue
      }
      for (i = 2; i <= 5; i++) {
        if (previous_value[plugin, i] != current_value[plugin, i]) {
          print plugin, i, label[i], previous_value[plugin, i], current_value[plugin, i]
        }
      }
    }
    for (plugin in current) {
      if (!(plugin in previous)) print plugin, 0, "Availability", "Not included", "Included"
    }
  }
' "$comparisontmpdir/previous.csv" "$comparisontmpdir/current.csv" \
  > "$comparisontmpdir/changes.unsorted" || exit 1

sort -t "$FIELD_SEPARATOR" -k1,1 -k2,2n "$comparisontmpdir/changes.unsorted" \
  > "$comparisontmpdir/changes" || exit 1
CHANGE_COUNT=$(wc -l < "$comparisontmpdir/changes")
CHANGE_COUNT=${CHANGE_COUNT//[[:space:]]/}

awk -F "$FIELD_SEPARATOR" -v previous_ref="$PREVIOUS_REF" -v current_ref="$BRANCH" \
  -v change_count="$CHANGE_COUNT" '
  function escape(value) {
    gsub(/\|/, "\\|", value)
    return value
  }

  BEGIN {
    print ":_mod-docs-content-type: REFERENCE"
    print ""
    print "// Generated by diff-previous.sh. Do not edit this file directly."
    print ""
    print "[id=\"dynamic-plugin-changes_{context}\"]"
    print "= Dynamic plugin changes between " previous_ref " and " current_ref
    print ""
    print "[role=\"_abstract\"]"
    print "The following table lists " change_count " dynamic plugin changes between `" previous_ref "` and `" current_ref "`."
    print ""
    print "[%header,cols=\"2,1,2,2\"]"
    print "|==="
    print "|*Plugin package* |*Changed field* |*" escape(previous_ref) "* |*" escape(current_ref) "*"
  }

  {
    print "|`" escape($1) "` |" escape($3) " |" escape($4) " |" escape($5)
  }

  END {
    if (NR == 0) print "4+|No dynamic plugin changes were found."
    print "|==="
  }
' "$comparisontmpdir/changes" > "$comparisontmpdir/output.adoc" || exit 1

mv "$comparisontmpdir/output.adoc" "$OUTPUT" || exit 1
echo -e "${green}Wrote $CHANGE_COUNT changes to $OUTPUT${norm}"
