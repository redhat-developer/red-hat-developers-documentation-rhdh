#!/bin/bash
# workflow-completion-check.sh
#
# Stop hook: blocks Claude from stopping while a workflow is still running.
# Checks each progress file for incomplete steps.
#
# Exit codes:
#   0 = allow stop
#   2 = block stop (reason sent to stderr)
#
# Requires: jq

set -u

INPUT=$(cat)

if ! cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null; then
  echo "Cannot access project directory; cannot verify workflow status." >&2
  exit 2
fi

# Look for progress files
shopt -s nullglob
PROGRESS_FILES=(.claude/docs/*/workflow/*.json)
shopt -u nullglob
if [ ${#PROGRESS_FILES[@]} -eq 0 ]; then
  exit 0
fi

for pfile in "${PROGRESS_FILES[@]}"; do
  WORKFLOW_STATUS=$(jq -r '.status' "$pfile" 2>/dev/null)

  # Skip workflows that aren't running
  if [ "$WORKFLOW_STATUS" != "in_progress" ]; then
    continue
  fi

  TICKET=$(jq -r '.ticket' "$pfile")
  WORKFLOW_TYPE=$(jq -r '.workflow_type' "$pfile")

  # Anti-loop guard: per-workflow counter prevents infinite blocking.
  COUNTER_FILE="${pfile}.stop_count"
  if [ -f "$COUNTER_FILE" ]; then
    COUNT=$(cat "$COUNTER_FILE")
  else
    COUNT=0
  fi
  if [ "$COUNT" -ge 5 ]; then
    rm -f "$COUNTER_FILE"
    continue
  fi

  # Get step order from the progress file
  mapfile -t STEP_ORDER < <(jq -r '.step_order[]' "$pfile" 2>/dev/null)

  if [ ${#STEP_ORDER[@]} -eq 0 ]; then
    # Fall back to alphabetical key order
    mapfile -t STEP_ORDER < <(jq -r '.steps | keys[]' "$pfile" 2>/dev/null)
  fi

  # Find the first incomplete step
  NEXT_STEP=""
  for step in "${STEP_ORDER[@]}"; do
    STEP_STATUS=$(jq -r --arg s "$step" '.steps[$s].status // "missing"' "$pfile")
    case "$STEP_STATUS" in
      completed|skipped|deferred) continue ;;
      *) NEXT_STEP="$step"; break ;;
    esac
  done

  if [ -n "$NEXT_STEP" ]; then
    echo "$((COUNT + 1))" > "$COUNTER_FILE"
    echo "Documentation workflow '$WORKFLOW_TYPE' for $TICKET is not complete. Next step: $NEXT_STEP. Continue the workflow." >&2
    exit 2
  fi

  # All steps done — clean up counter
  rm -f "$COUNTER_FILE"
done

# No incomplete workflows found — allow stop
exit 0
