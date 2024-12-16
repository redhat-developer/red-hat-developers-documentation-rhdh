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
import os
import re

import jinja2
import yaml
from jira import JIRA
from setuptools.dist import sequence

# Define location for product attributes, templates, and generated files.
script_dir = os.path.normpath(
  os.path.normpath(
    os.path.dirname(
      __file__
    )
  )
)
root_dir = os.path.normpath(script_dir + '/../..')
attributes_file = root_dir + '/artifacts/attributes.adoc'
config_file = script_dir + '/single-source-release-notes.jira2asciidoc.yml'
asciidoc_modules_dir = script_dir
# Load Jinja2 templates.
env = jinja2.Environment(
  loader=jinja2.FileSystemLoader(
    asciidoc_modules_dir
  ), autoescape=True)

# Load attributes.adoc to get the product version (y-stream and z-stream).
with open(attributes_file) as file:
  attributes = {}
  for lines in file:
    if re.search(':', lines):
      items = lines.rsplit(':', 2)
      attributes[items[1]] = items[2].strip()

product_version_minor = attributes["product-version"]
product_version_patch = attributes["product-bundle-version"]

# Load the configuration file to get the sections and their Jira queries.
with open(config_file) as file:
  config = yaml.safe_load(file)
# Configure access to Jira using kerberos if defined.
jira = JIRA(
  server=config['jira']['server'],
  token_auth=os.environ.get(
    'JIRA_TOKEN'
  )
)

# Delete old snip files.
fileList = glob.glob(
  asciidoc_modules_dir + '/snip-*-rhidp-*.adoc'
)
for filePath in fileList:
  os.remove(filePath)

# Generate the release notes and known issues asciidoc and files
for section in config['sections']:
  # Search in Jira for issues to publish defined in jira_query
  query = section["query"].format(
    version_minor=product_version_minor,
    version_patch=product_version_patch
  )
  print(query)
  issues = jira.search_issues(query)
  # Create the asciidoc file
  asciidoc_file = open(
    asciidoc_modules_dir + '/ref-release-notes-' + section["id"] + '.adoc',
    'w'
  )
  asciidoc_template = env.get_template(
    'single-source-release-notes-template.adoc.jinja'
  )
  print(
    asciidoc_template.render(
      id=section["id"],
      title=section["title"],
      introduction=section["description"],
      vars=issues,
      template=section["template"]
    ),
    file=asciidoc_file
  )
# Report final status
print(
  'INFO: Single-sourced release notes from Jira for version {version} in {dir}'
  .format(
    version=product_version_patch,
    dir=asciidoc_modules_dir
  )
)
