#!/usr/bin/env bash
#
# Copyright (c) Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
set -e

# Update CQA reference materials
# Frequency: Weekly minimum (7 days), daily maximum (1 day)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
RESOURCES_DIR="$PROJECT_ROOT/.claude/resources"
VALE_TIMESTAMP="$PROJECT_ROOT/.claude/.vale-sync-timestamp"

update_if_old() {
  local file=$1 url=$2 name=$3

  if [[ ! -f "$file" ]]; then
    echo "[$name] Creating..."
    curl -sL "$url" -o "$file"
    echo "[$name] Created"
    return
  fi

  local days=$(( ($(date +%s) - $(stat -c %Y "$file")) / 86400 ))

  if [[ $days -lt 1 ]]; then
    echo "[$name] Skip (updated today)"
    return
  fi

  if [[ $days -ge 7 ]]; then
    echo "[$name] Updating (${days} days old)..."
    curl -sL "$url" -o "$file"
    echo "[$name] Updated"
  else
    echo "[$name] Skip (${days} days old, < 7 days threshold)"
  fi
}

echo "=== Updating CQA Resources ==="
echo

# Update Red Hat Supplementary Style Guide
update_if_old \
  "$RESOURCES_DIR/red-hat-ssg.md" \
  "https://redhat-documentation.github.io/supplementary-style-guide/ssg.md" \
  "SSG"

# Update Red Hat Peer Review Guide
update_if_old \
  "$RESOURCES_DIR/red-hat-peer-review.md" \
  "https://redhat-documentation.github.io/peer-review/" \
  "Peer Review"

# Update Red Hat Modular Documentation Guide
update_if_old \
  "$RESOURCES_DIR/red-hat-modular-docs.md" \
  "https://redhat-documentation.github.io/modular-docs/" \
  "Modular Docs"

# Update Vale styles
if [[ -f "$VALE_TIMESTAMP" ]]; then
  days=$(( ($(date +%s) - $(cat "$VALE_TIMESTAMP")) / 86400 ))

  if [[ $days -lt 1 ]]; then
    echo "[Vale] Skip (synced today)"
  elif [[ $days -ge 7 ]]; then
    echo "[Vale] Syncing (${days} days since last sync)..."
    vale sync
    date +%s > "$VALE_TIMESTAMP"
    echo "[Vale] Synced"
  else
    echo "[Vale] Skip (${days} days since last sync, < 7 days threshold)"
  fi
else
  echo "[Vale] Syncing (never synced before)..."
  vale sync
  date +%s > "$VALE_TIMESTAMP"
  echo "[Vale] Synced"
fi

echo
echo "=== Update Complete ==="
