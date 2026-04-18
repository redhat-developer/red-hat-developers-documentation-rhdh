#!/usr/bin/env bash
#
# Copyright (c) Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# lint-scripts.sh — Run shellcheck on CQA scripts
#
# Usage: ./build/scripts/lint-scripts.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "## Lint: CQA scripts"
echo ""

errors=0
for script in "$SCRIPT_DIR"/*.sh; do
    if ! shellcheck -S warning -e SC2034,SC2329,SC1091 "$script" 2>/dev/null; then
        errors=$((errors + 1))
    fi
done

echo ""
if [[ $errors -eq 0 ]]; then
    echo "All scripts pass shellcheck."
else
    echo "$errors script(s) have shellcheck warnings."
fi

[[ $errors -gt 0 ]] && exit 1 || exit 0
