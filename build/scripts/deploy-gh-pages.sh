#!/usr/bin/env bash
#
# Copyright (c) Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Deploy files to the gh-pages branch with retry on push rejection.
# Replaces peaceiris/actions-gh-pages to handle concurrent builds.
#
# Usage: deploy-gh-pages.sh <publish_dir> [--message <msg>]
#
# Environment: GITHUB_TOKEN, GITHUB_REPOSITORY (set by GitHub Actions)

set -euo pipefail

PUBLISH_DIR="${1:?Usage: deploy-gh-pages.sh <publish_dir> [--message <msg>]}"
shift

COMMIT_MSG="Deploy to GitHub Pages"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --message) COMMIT_MSG="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

PUBLISH_DIR="$(cd "$PUBLISH_DIR" && pwd)"

: "${GITHUB_TOKEN:?GITHUB_TOKEN is required (set by GitHub Actions)}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required (set by GitHub Actions)}"

# ── Diagnostics: log PUBLISH_DIR contents before deploying ──
echo "PUBLISH_DIR: $PUBLISH_DIR"
echo "Top-level entries in PUBLISH_DIR:"
find "$PUBLISH_DIR" -maxdepth 1 -not -path "$PUBLISH_DIR" -printf '%f\n'

MAX_RETRIES=3
DEPLOY_DIR="$(mktemp -d)"
trap 'rm -rf "$DEPLOY_DIR"' EXIT

cd "$DEPLOY_DIR"
git init -q
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# ── Fetch gh-pages and prepare working tree ──
fetch_output=$(git fetch origin gh-pages --depth=1 2>&1) && fetch_ok=true || fetch_ok=false
if [[ "$fetch_ok" == "true" ]]; then
  git checkout -B gh-pages FETCH_HEAD
elif echo "$fetch_output" | grep -qi "not found\|couldn't find\|no such remote ref"; then
  echo "gh-pages branch does not exist, creating orphan"
  git checkout --orphan gh-pages
  git rm -rf . 2>/dev/null || true
else
  echo "ERROR: Failed to fetch gh-pages: $fetch_output" >&2
  exit 1
fi

# ── Copy content and stage ──
cp -a "$PUBLISH_DIR"/. .

# Force-add only the files from PUBLISH_DIR (bypasses .gitignore)
publish_entries=()
while IFS= read -r entry; do
  publish_entries+=("$entry")
done < <(find "$PUBLISH_DIR" -maxdepth 1 -not -path "$PUBLISH_DIR" -printf '%f\n')

echo "Staging ${#publish_entries[@]} entries from PUBLISH_DIR..."
git add --force -- "${publish_entries[@]}"

if git diff --cached --quiet; then
  echo "No changes to deploy"
  exit 0
fi

echo "Staged files:"
git diff --cached --stat

git commit -q -m "$COMMIT_MSG"

# ── Push with pull-before-push retry ──
for attempt in $(seq 1 "$MAX_RETRIES"); do
  if git push origin gh-pages; then
    echo "Deployed successfully (attempt $attempt)"
    exit 0
  fi

  echo "Push rejected (attempt $attempt/$MAX_RETRIES)"
  if [[ $attempt -lt $MAX_RETRIES ]]; then
    echo "Pulling remote changes before retrying..."
    git pull --rebase origin gh-pages
  fi
done

echo "ERROR: Deploy failed after $MAX_RETRIES attempts"
exit 1
