#!/usr/bin/env python3
"""
Copyright (c) 2024 Red Hat, Inc.
This program, and the accompanying materials are made
available under the terms of the Apache Public License 2.0,
available at http://www.apache.org/licenses/

SPDX-License-Identifier: Apache-2.0

Prerequisites:
$ pip3 install --requirement requirements.txt

Generate the AsciiDoc files for the release notes and known issues from JIRA content.
"""
import glob
import jinja2
import os
import yaml
from jira import JIRA

# Define location for product attributes, templates, and generated files.
root_dir = os.path.normpath(
  os.path.normpath(
    os.path.dirname(
      __file__
    )
  ) + '/../..'
)
product_attributes = root_dir + '/artifacts/product-attributes.adoc'
templates_dir = root_dir + '/build/templates/'
assemblies_dir = root_dir + '/assemblies/'
modules_dir = root_dir + '/modules/release-notes/'
# Load Jinja2 templates.
env = jinja2.Environment(
  loader=jinja2.FileSystemLoader(
    templates_dir
  )
)
# Load configuration file
with open(
  root_dir + '/jira2asciidoc.yml',
  'r'
) as file:
  config = yaml.safe_load(file)
# Load AsciiDoc attributes.
product_version_minor_glob = config['product']['version']['minor_glob']
product_version_patch = config['product']['version']['patch']
# Configure access to Jira using kerberos
jira = JIRA(
  server=config['jira']['server'],
  token_auth=os.environ.get(
    'JIRA_TOKEN'
  )
)
# Delete old file files.
fileList = glob.glob(
  modules_dir + 'snip-*.adoc'
)
for filePath in fileList:
  os.remove(filePath)
# Generate the release notes and known issues assemblies and files
for section in config['sections']:
  # Search in Jira for issues to publish defined in jira_query
  query = section["query"].format(
    version_minor_glob=product_version_minor_glob,
    version_patch=product_version_patch
  )
  print(query)
  issues = jira.search_issues(query)
  # Create the assembly file
  assembly_file = open(
    assemblies_dir + 'assembly-release-notes-' + section["id"] + '.adoc',
    'w'
  )
  assembly_template = env.get_template(
    'assembly.adoc.jinja'
  )
  print(
    assembly_template.render(
      assembly_id=section["id"],
      assembly_title=section["title"],
      assembly_introduction=section["description"],
      vars=issues,
    ),
    file=assembly_file
  )
  # Create the file files
  for issue in issues:
    # Collect values from these fields:
    issue_key = format(issue.key)  # Issue id
    issue_rn_status = format(issue.fields.customfield_12310213)  # Release Note Status
    issue_rn_text = format(issue.fields.customfield_12317313)  # Release Note Text
    issue_rn_type = format(issue.fields.customfield_12320850)  # Release Note Type
    issue_template = section["template"]
    issue_title = format(issue.fields.summary)  # Issue title
    # Define AsciiDoc file id, file, and content
    file_id = format(issue_rn_type + "-" + issue_key).lower().replace(" ", "-")
    snippet_file = open(
      modules_dir + 'snip-' + file_id + '.adoc',
      'w'
    )
    snippet_template = env.get_template(
      'snippet-' + issue_template + '.adoc.jinja2'
    )
    print(
      snippet_template.render(
        id=file_id,
        key=issue_key,
        text=issue_rn_text,
        title=issue_title,
      ),
      file=snippet_file
    )
# Report final status
print(
  'INFO: Single-sourced release notes from Jira for version {version} in {dir}'
  .format(
    version=product_version_patch,
    dir=modules_dir
  )
)
