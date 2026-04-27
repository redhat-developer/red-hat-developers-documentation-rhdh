#!/usr/bin/env bash
#
# Copyright (c) Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Deploy build output (titles-generated/) to the gh-pages branch.
#
# Flow:
#   1. Create a temp git repo, fetch gh-pages (shallow)
#   2. Copy --publish-dir content into the working tree
#   3. For branch deploys: clean up stale PR and branch directories
#   4. Regenerate index.html (branch list) and pulls.html (PR list)
#   5. Commit everything (content + cleanup + indexes) and push
#   6. On push rejection: rebase and retry (max 3 attempts)
#
# Branch deploys clean up merged/closed PR dirs and deleted branch dirs.
# PR deploys only update content and pulls.html — no cleanup.
#
# Usage: deploy-gh-pages.sh <publish_dir> [--message <msg>]
#
# Environment: GITHUB_TOKEN, GITHUB_REPOSITORY (set by GitHub Actions)

set -euo pipefail

MAX_RETRIES=3
RELEASE_NOTES_BASE="https://red-hat-developers-documentation.pages.redhat.com/red-hat-developer-hub-release-notes"

# ── Parse arguments ──────────────────────────────────────────────────────────

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
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
: "${GITHUB_REPOSITORY:?GITHUB_REPOSITORY is required}"

# Detect branch directory (first non-hidden top-level dir in publish dir)
BRANCH_DIR=""
for d in "$PUBLISH_DIR"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  [[ "$name" == .* ]] && continue
  BRANCH_DIR="$name"
  break
done

if [[ -z "$BRANCH_DIR" ]]; then
  echo "No top-level directory found in publish dir" >&2
  exit 1
fi

echo "PUBLISH_DIR: $PUBLISH_DIR"
echo "Branch directory: $BRANCH_DIR"

# ── Set up temp deploy repo ──────────────────────────────────────────────────

DEPLOY_DIR="$(mktemp -d)"
trap 'rm -rf "$DEPLOY_DIR"' EXIT

git -C "$DEPLOY_DIR" init -q
git -C "$DEPLOY_DIR" config user.name "github-actions[bot]"
git -C "$DEPLOY_DIR" config user.email "github-actions[bot]@users.noreply.github.com"

REPO_URL="https://github.com/${GITHUB_REPOSITORY}.git"
git -C "$DEPLOY_DIR" remote add origin "$REPO_URL"
# Auth via http.extraHeader keeps the token out of the remote URL (avoids leaking in logs)
CREDENTIALS="$(printf 'x-access-token:%s' "$GITHUB_TOKEN" | base64 -w0)"
git -C "$DEPLOY_DIR" config "http.${REPO_URL}.extraHeader" "Authorization: Basic ${CREDENTIALS}"

# ── Core functions ───────────────────────────────────────────────────────────

fetch_gh_pages() {
  git -C "$DEPLOY_DIR" fetch origin gh-pages --depth=1
  git -C "$DEPLOY_DIR" checkout -B gh-pages FETCH_HEAD
  return 0
}

apply_content() {
  cp -a "$PUBLISH_DIR"/. "$DEPLOY_DIR"/
  return 0
}

# ── Cleanup (branch deploys only) ────────────────────────────────────────────

get_pr_state() {
  local pr_number="$1"
  local owner="${GITHUB_REPOSITORY%%/*}"
  local repo="${GITHUB_REPOSITORY##*/}"
  local response status merged

  response="$(curl -sf \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/${owner}/${repo}/pulls/${pr_number}" 2>/dev/null)" || { echo "unknown"; return; }

  status="$(printf '%s' "$response" | grep -o '"state": *"[^"]*"' | head -1 | grep -o '"[^"]*"$' | tr -d '"')"
  merged="$(printf '%s' "$response" | grep -o '"merged": *[a-z]*' | head -1 | grep -o '[a-z]*$')"

  if [[ "$status" == "closed" ]]; then
    [[ "$merged" == "true" ]] && echo "merged" || echo "closed"
  else
    echo "${status:-unknown}"
  fi
}

cleanup() {
  # PR cleanup: remove directories for merged/closed PRs
  for d in "$DEPLOY_DIR"/pr-*/; do
    [[ -d "$d" ]] || continue
    local dir_name pr_number state
    dir_name="$(basename "$d")"
    pr_number="${dir_name#pr-}"
    [[ "$pr_number" =~ ^[0-9]+$ ]] || continue

    state="$(get_pr_state "$pr_number")"
    if [[ "$state" == "merged" || "$state" == "closed" ]]; then
      echo "Removing $dir_name (PR $state)"
      rm -rf "$d"
    fi
  done

  # Branch cleanup: remove directories for deleted remote branches
  local remote_branches
  remote_branches="$(git -C "$DEPLOY_DIR" ls-remote --heads origin 2>/dev/null | awk '{print $2}' | sed 's|refs/heads/||')"

  for d in "$DEPLOY_DIR"/*/; do
    [[ -d "$d" ]] || continue
    local dir_name
    dir_name="$(basename "$d")"
    [[ "$dir_name" == pr-* || "$dir_name" == .* ]] && continue

    if ! grep -qx "$dir_name" <<< "$remote_branches"; then
      echo "Removing $dir_name (branch no longer exists on remote)"
      rm -rf "$d"
    fi
  done
  return 0
}

# ── Index generation ─────────────────────────────────────────────────────────

# See also: getReleaseNotesLink() in build-orchestrator.js (per-title links)
release_notes_url() {
  local branch="$1"
  if [[ "$branch" == "main" ]]; then
    echo "${RELEASE_NOTES_BASE}/main/index.html"
  elif [[ "$branch" =~ ^release-([0-9]+)\.([0-9]+)$ ]]; then
    local major="${BASH_REMATCH[1]}" minor="${BASH_REMATCH[2]}"
    if (( major > 1 || minor >= 9 )); then
      echo "${RELEASE_NOTES_BASE}/release-${major}-${minor}/index.html"
    fi
  fi
  return 0
}

regenerate_indexes() {
  local branch_items="" pr_items=""

  for d in "$DEPLOY_DIR"/*/; do
    [[ -d "$d" ]] || continue
    local name
    name="$(basename "$d")"
    [[ "$name" == .* ]] && continue

    if [[ "$name" == pr-* ]]; then
      pr_items+="<li><a href=./${name}/index.html>${name}</a></li>"$'\n'
    else
      local entry="<li><a href=./${name}/index.html>${name}</a>"
      local rn_url
      rn_url="$(release_notes_url "$name")"
      [[ -n "$rn_url" ]] && entry+=" | <a href=\"${rn_url}\">Release Notes</a>"
      branch_items+="${entry}</li>"$'\n'
    fi
  done

  # Branch deploys regenerate both; PR deploys regenerate pulls.html only
  if [[ "$BRANCH_DIR" != pr-* ]]; then
    cat > "$DEPLOY_DIR/index.html" <<EOF
<html><head><title>RHDH Documentation - Documentation Branches</title></head>
<body>
<ul>
${branch_items}</ul>
</body></html>
EOF
  fi

  cat > "$DEPLOY_DIR/pulls.html" <<EOF
<html><head><title>RHDH Documentation - PR Previews</title></head>
<body>
<ul>
${pr_items}</ul>
</body></html>
EOF
  return 0
}

# ── Stage, commit, push ─────────────────────────────────────────────────────

stage_and_commit() {
  regenerate_indexes

  # Force-add publish entries and indexes (.gitignore may exclude them)
  local to_stage=()
  for e in "$PUBLISH_DIR"/*/; do
    [[ -d "$e" ]] || continue
    local name
    name="$(basename "$e")"
    [[ "$name" == .* ]] && continue
    to_stage+=("$name")
  done
  [[ -f "$DEPLOY_DIR/index.html" ]] && to_stage+=("index.html")
  [[ -f "$DEPLOY_DIR/pulls.html" ]] && to_stage+=("pulls.html")

  git -C "$DEPLOY_DIR" add --force -- "${to_stage[@]}"
  git -C "$DEPLOY_DIR" add -A

  if git -C "$DEPLOY_DIR" diff --cached --quiet; then
    echo "No changes to deploy"
    return 1
  fi

  echo "Staged files:"
  git -C "$DEPLOY_DIR" diff --cached --stat || true
  git -C "$DEPLOY_DIR" commit -q -m "$COMMIT_MSG"
}

# On push rejection (concurrent deploy), try rebase first.
# If rebase conflicts (e.g. both touched index.html), reset and rebuild.
try_rebase_and_push() {
  local attempt="$1"
  if git -C "$DEPLOY_DIR" pull --rebase origin gh-pages 2>/dev/null; then
    if git -C "$DEPLOY_DIR" push origin gh-pages 2>/dev/null; then
      echo "Deployed successfully (attempt $attempt, after rebase)"
      return 0
    fi
    echo "Push failed after rebase, will rebuild"
  else
    echo "Rebase conflict — resetting to remote"
    git -C "$DEPLOY_DIR" rebase --abort 2>/dev/null || true
  fi
  fetch_gh_pages
  return 1
}

# ── Main ─────────────────────────────────────────────────────────────────────

fetch_gh_pages
apply_content

# Cleanup runs once before retries (avoids redundant API calls)
if [[ "$BRANCH_DIR" != pr-* ]]; then
  cleanup
fi

for attempt in $(seq 1 "$MAX_RETRIES"); do
  if [[ "$attempt" -gt 1 ]]; then
    apply_content
  fi

  if ! stage_and_commit; then
    exit 0
  fi

  if git -C "$DEPLOY_DIR" push origin gh-pages 2>/dev/null; then
    echo "Deployed successfully (attempt $attempt)"
    exit 0
  fi

  echo "Push rejected (attempt $attempt/$MAX_RETRIES)"
  if [[ "$attempt" -lt "$MAX_RETRIES" ]]; then
    try_rebase_and_push "$attempt" && exit 0
  fi
done

echo "Deploy failed after $MAX_RETRIES attempts" >&2
exit 1
