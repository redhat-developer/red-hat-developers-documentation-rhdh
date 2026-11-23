#!/bin/bash

# Approve a bot pull request as rhdh-gh-app[bot] and enable squash automerge.
#
# GITHUB_TOKEN pushes emit no pull_request_target events, so a workflow that
# pushes and opens its own pull request cannot rely on an event-driven
# approver; call this from the same run instead. An app-token approval by
# rhdh-gh-app[bot] counts toward the required review; a GITHUB_TOKEN
# approval would not.
#
# Usage: approve-and-automerge.sh HEAD_BRANCH BASE_BRANCH [SQUASH_BODY]
# Requires: gh, jq, GH_TOKEN (rhdh-gh-app token), GITHUB_REPOSITORY.

set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 HEAD_BRANCH BASE_BRANCH [SQUASH_BODY]" >&2
  exit 1
fi

branch="$1"
target="$2"
body="${3:-Automated update.}"

if ! pr_json=$(gh pr view "$branch" --repo "$GITHUB_REPOSITORY" --json number,title,state 2>/dev/null); then
  echo "No pull request for $branch; nothing to approve."
  exit 0
fi
number=$(jq -er .number <<<"$pr_json")
title=$(jq -er .title <<<"$pr_json")
state=$(jq -er .state <<<"$pr_json")
if [[ "$state" != "OPEN" ]]; then
  echo "Pull request for $branch is $state; not approving."
  exit 0
fi

gh pr review "$branch" --repo "$GITHUB_REPOSITORY" --approve \
  --body "Auto-approved: automated update of $target." || \
  echo "Already approved; keeping the existing review."

# Explicit subject and body keep any [skip ci] in the branch's commit
# messages out of the squash commit on the target branch, so the target
# branch's push-triggered workflows still run.
# Auto-merge only exists for protected branches - GitHub rejects
# enablePullRequestAutoMerge on an unprotected base branch - so fall back
# to merging directly (run 45267387335, release-2.1).
if ! gh pr merge "$branch" --repo "$GITHUB_REPOSITORY" --auto --squash \
  --subject "${title} (#${number})" \
  --body "$body"; then
  echo "Auto-merge unavailable; merging directly."
  gh pr merge "$branch" --repo "$GITHUB_REPOSITORY" --squash \
    --subject "${title} (#${number})" \
    --body "$body"
fi
