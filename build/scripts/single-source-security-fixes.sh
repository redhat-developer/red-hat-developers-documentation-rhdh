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
# Cleanup the destination files
rm "$destination"
# Send output to the destination file
exec &>> "$destination"
for cve in $(cat cve-list.txt)
do
  # Start the list.
  echo "link:https://access.redhat.com/security/cve/$cve[$cve]::"
  # Call the API to return a list of details.
  # Red Hat is last if there is one.
  # Red Hat details is single line.
  # MITRE details are multiline.
  # We keep Red Hat details if present.
  # We keep only the first two lines on MITRE details.
  curl -s "https://access.redhat.com/hydra/rest/securitydata/cve/$cve.json" | jq -r '.details[-1]' | head -n 2
  # Add a separation
  echo ""
done
