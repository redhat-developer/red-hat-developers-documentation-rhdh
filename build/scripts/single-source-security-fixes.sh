#!/bin/bash
#
# Copyright (c) 2024 Red Hat, Inc.
# This program, and the accompanying materials are made
# available under the terms of the Apache Public License 2.0,
# available at http://www.apache.org/licenses/
#
# SPDX-License-Identifier: Apache-2.0

# Fail and stop on first error

if [[ $# -lt 1 ]] || [[ ! -f modules/release-notes/cve-list-$1.txt ]]; then
  echo "Usage:

To process the contents of modules/release-notes/cve-list-\$version.txt, use the appropriate file version:

$0 x.y.z

Example:

$0 1.2.5"
  exit
else 
  version="$1"
fi

set -e
destination=/tmp/snip-common-vulnerabilities-and-exposures.adoc; rm -f "$destination"

echo;echo "Paste the following fragment into the file modules/release-notes/con-relnotes-fixed-issues.adoc"
echo; echo "----------------

=== Fixed security issues in {product} 1.2.5

This section lists fixed security issues with {product} 1.2.5:
"

while IFS="" read -r cve || [ -n "$cve" ]
do
  if [[ ${cve} != "#"* ]] && [[ $cve != "" ]]; then # commented or blank lines
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
  fi
done < "modules/release-notes/cve-list-$version.txt"
echo "----------------"
