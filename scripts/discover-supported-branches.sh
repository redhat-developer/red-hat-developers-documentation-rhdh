#!/bin/bash

# List the branches the weekly update workflows should target, as a JSON
# array on stdout: main plus the three newest release-X.Y branches, minus
# any past its maintenance-support end date from the Product Life Cycles
# API (the data behind
# https://access.redhat.com/support/policy/updates/developerhub).
# For a manual run, validate and list the single requested branch.
#
# Usage: discover-supported-branches.sh
# Env:   EVENT_NAME    schedule (default) or workflow_dispatch
#        INPUT_BRANCH  the branch input, for workflow_dispatch
#        REPOSITORY_URL  defaults to this repository
# Requires: git, jq, curl, python3.

set -euo pipefail

REPOSITORY_URL="${REPOSITORY_URL:-https://github.com/redhat-developer/red-hat-developers-documentation-rhdh.git}"
EVENT_NAME="${EVENT_NAME:-schedule}"

if [[ "$EVENT_NAME" == "schedule" ]]; then
  refs="$(git ls-remote --heads "$REPOSITORY_URL" 'refs/heads/release-*')"
  mapfile -t releases < <(
    printf '%s\n' "$refs" |
      sed 's#.*refs/heads/##' |
      grep -E '^release-[0-9]+\.[0-9]+$' |
      sort -V |
      tail -n 3
  )

  ((${#releases[@]} > 0)) || {
    echo "No release-X.Y branches found" >&2
    exit 1
  }

  # A release leaves its maintenance window - goes EOL - about when the
  # second newer minor GA's: with 2.1 live, 1.9 is EOL. Drop branches past
  # their maintenance-support end date so EOL releases stop getting
  # automated update PRs.
  lifecycle_json="$(
    curl -sf --retry 3 --retry-delay 30 \
      "https://access.redhat.com/product-life-cycles/api/v1/products?name=Red+Hat+Developer+Hub"
  )" || {
    echo "[WARN] Product Life Cycles API unreachable; keeping the three newest branches." >&2
    lifecycle_json=""
  }
  today="$(date -u +%F)"
  supported=()
  for branch in "${releases[@]}"; do
    version="${branch#release-}"
    eol=""
    if [[ -n "$lifecycle_json" ]]; then
      eol="$(
        jq -er --arg version "$version" '
          .data[0].versions[] | select(.name == $version) | .phases[]
          | select(.name == "Maintenance support") | .date | split("T")[0]
        ' <<<"$lifecycle_json" 2>/dev/null
      )" || eol=""
    fi
    # Unknown version (not in the API yet) stays: only a confirmed past
    # maintenance-support date drops a branch.
    if [[ -n "$eol" && "$today" > "$eol" ]]; then
      echo "Skipping $branch: maintenance support ended $eol (EOL)." >&2
      continue
    fi
    supported+=("$branch")
  done
  ((${#supported[@]} > 0)) || {
    echo "No supported release-X.Y branches found" >&2
    exit 1
  }
  branches=(main "${supported[@]}")
else
  [[ "${INPUT_BRANCH:-}" =~ ^(main|release-[0-9]+\.[0-9]+)$ ]] || {
    echo "Invalid branch: ${INPUT_BRANCH:-empty}" >&2
    exit 1
  }
  git ls-remote --exit-code --heads \
    "$REPOSITORY_URL" "refs/heads/$INPUT_BRANCH" >/dev/null
  branches=("$INPUT_BRANCH")
fi

python3 -c 'import json, sys; print(json.dumps(sys.argv[1:]))' "${branches[@]}"
