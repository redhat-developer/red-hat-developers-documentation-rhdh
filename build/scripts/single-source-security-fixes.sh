#!/bin/bash
#
# Copyright (c) 2024 Red Hat, Inc.
# This program, and the accompanying materials are made
# available under the terms of the Apache Public License 2.0,
# available at http://www.apache.org/licenses/
#
# SPDX-License-Identifier: Apache-2.0

# Fail and stop on first error
set -e
destination=modules/release-notes/snip-common-vulnerabilities-and-exposures.adoc
rm "$destination"
# Output
exec &>> "$destination"
for cve in $(cat cve-list.txt)
do
  echo "link:https://access.redhat.com/security/cve/$cve[$cve]::"
  curl -s "https://access.redhat.com/hydra/rest/securitydata/cve/$cve.json" | jq -r '.details[-1]' | head -n 2
  echo ""
done
