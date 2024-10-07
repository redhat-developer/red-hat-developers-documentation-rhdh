#!/bin/bash
#
# Copyright (c) 2024 Red Hat, Inc.
# This program, and the accompanying materials are made
# available under the terms of the Apache Public License 2.0,
# available at http://www.apache.org/licenses/
#
# SPDX-License-Identifier: Apache-2.0

# Single-source the release notes Fixed security issues section from Red Hat Security Data API.
# See: https://docs.redhat.com/en/documentation/red_hat_security_data_api/1.0/html/red_hat_security_data_api/cve

# Fail and stop on first error
set -e

product_version="$(grep ':product-bundle-version:' artifacts/attributes.adoc | cut -d' ' -f2 )"

single_source_from_security_data () {
  # Assert that the list file exists.
  if [ ! -f ${list} ]
  then
    echo "ERROR: The ${list} file is missing"
    exit 1
  fi
  # Cleanup the destination files.
  rm -f "$destination"
  # Send output to the destination file.
  exec &>> "$destination"
  echo "= ${title}"
  for cve in $(cat ${list} | sort | uniq)
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
}

title="{product} dependency updates"
destination="modules/release-notes/snip-common-vulnerabilities-and-exposures-product-${product_version}.adoc"
list="build/cve-lists/cve-list-product-${product_version}.txt"
single_source_from_security_data

title="RHEL 9 platform RPM updates"
list="build/cve-lists/cve-list-rpm-${product_version}.txt"
destination="modules/release-notes/snip-common-vulnerabilities-and-exposures-rpm-${product_version}.adoc"
single_source_from_security_data
