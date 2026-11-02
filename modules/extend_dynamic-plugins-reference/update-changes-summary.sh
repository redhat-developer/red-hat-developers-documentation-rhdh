#!/usr/bin/env bash
# Recompute the change-summary sentence in the preinstalled dynamic plugin
# comparison table from the table's own rows, so the counts cannot drift.
#
# Usage: update-changes-summary.sh [FILE]
set -euo pipefail

FILE="${1:-$(dirname "$0")/ref-preinstalled-dynamic-plugin-changes-1-10-6-to-2-1-0.adoc}"
SENTENCE="The following table lists the plugins that are enabled by default in one release but not the other."

read -r removed added promoted total < <(awk -F'|' '
  /^\|`/ {
    change = $NF
    if (change ~ /^[[:space:]]*Removed/) removed++
    else if (change ~ /^[[:space:]]*Added/) added++
    else if (change ~ /^[[:space:]]*Promoted/) promoted++
    total++
  }
  END { printf "%d %d %d %d\n", removed + 0, added + 0, promoted + 0, total + 0 }
' "$FILE")

if [[ "$((removed + added + promoted))" -ne "$total" ]]; then
  printf 'Unrecognized Change value in %s: %d rows, %d categorized\n' \
    "$FILE" "$total" "$((removed + added + promoted))" >&2
  exit 1
fi

if [[ $total -eq 1 ]]; then
  counts="There is 1 change in this release: $removed removed, $added added, $promoted promoted."
else
  counts="There are $total changes in this release: $removed removed, $added added, $promoted promoted."
fi

tmp="$(mktemp)"
awk -v sentence="$SENTENCE" -v counts="$counts" '
  found { print; next }
  (at = index($0, sentence)) {
    # Drop any previously appended counts so re-running stays idempotent.
    print substr($0, 1, at - 1) sentence " " counts
    found = 1
    next
  }
  { print }
  END { if (!found) { print "missing summary sentence: " sentence > "/dev/stderr"; exit 1 } }
' "$FILE" > "$tmp"

if command -v diff > /dev/null && ! diff -q "$FILE" "$tmp" > /dev/null; then
  cat "$tmp" > "$FILE"
  printf 'updated %s\n' "$FILE"
else
  printf 'unchanged %s\n' "$FILE"
fi
rm -f "$tmp"
