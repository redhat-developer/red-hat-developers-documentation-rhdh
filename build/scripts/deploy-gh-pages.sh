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

MAX_RETRIES=3
RETRY_DELAYS=(0 27 133)

DEPLOY_DIR="$(mktemp -d)"
trap 'rm -rf "$DEPLOY_DIR"' EXIT

cd "$DEPLOY_DIR"
git init -q
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

for attempt in $(seq 1 "$MAX_RETRIES"); do
  echo "Deploy attempt $attempt/$MAX_RETRIES"

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

  cp -a "$PUBLISH_DIR"/. .
  git add -A

  if git diff --cached --quiet; then
    echo "No changes to deploy"
    exit 0
  fi

  git commit -q -m "$COMMIT_MSG"

  if git push origin gh-pages; then
    echo "Deployed successfully (attempt $attempt)"
    exit 0
  fi

  echo "Push rejected (attempt $attempt/$MAX_RETRIES)"

  if [[ $attempt -lt $MAX_RETRIES ]]; then
    jitter=$((RANDOM % 10))
    wait=$(( RETRY_DELAYS[attempt] + jitter ))
    echo "Retrying in ${wait}s..."
    sleep "$wait"
  fi
done

echo "ERROR: Deploy failed after $MAX_RETRIES attempts"
exit 1
