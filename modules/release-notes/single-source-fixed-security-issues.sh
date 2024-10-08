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

# get the z-stream version from the bundle-version attribute. Note that while chart-version could be larger, this is the correct value for CVE tracking
# if a different version is passed in than the value in 'product-bundle-version', generate content for that version instead
if [[ $1 ]]; then product_version="$1"; else product_version="$(grep ':product-bundle-version:' artifacts/attributes.adoc | cut -d' ' -f2 )"; fi

single_source_from_security_data () {
  sectionname="fixed-security-issues-in-${section}-${product_version}"
  dirname=$(dirname ${BASH_SOURCE})
  destination="${dirname}/snip-${sectionname}.adoc"
  list="${dirname}/list-${sectionname}.txt"
  # Assert that the list file exists.
  if [ ! -f ${list} ]
  then
    echo "ERROR: The ${list} file is missing. You must create it to proceed. For a given version, can collect the list of CVEs from a JIRA query like https://issues.redhat.com/issues/?jql=labels%3DSecurityTracking+and+project%3DRHIDP+and+fixversion%3D1.3.1 or list of Erratas from https://errata.devel.redhat.com/advisory/filters/4213"
    exit 1
  fi
  echo -e "= ${title}" > "$destination"
  while IFS="" read -r cve || [ -n "$cve" ]; do
    if [[ ${cve} != "#"* ]] && [[ $cve != "" ]]; then # skip commented and blank lines
      # Start the list.
      echo -e "\nlink:https://access.redhat.com/security/cve/$cve[$cve]::" >> "$destination"
      # Call the API to return a list of details.
      # Red Hat is last if there is one.
      # Red Hat details is single line.
      # MITRE details are multiline.
      # We keep Red Hat details if present.
      # We keep only the first two lines on MITRE details.
      curl -s "https://access.redhat.com/hydra/rest/securitydata/cve/$cve.json" | jq -r '.details[-1]' | head -n 2 >> "$destination"
  fi
  done < "$list"
  echo "include::${destination}[leveloffset=+2]"
}

title="{product} dependency updates"
section="product"
single_source_from_security_data

title="RHEL 9 platform RPM updates"
section="rpm"
single_source_from_security_data

echo "INFO: Verify that the assemblies/assembly-release-notes-fixed-security-issues.adoc file contains aforementioned required include statements."
