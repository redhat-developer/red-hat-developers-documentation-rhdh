#!/bin/bash
#
# Copyright (c) 2025 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Utility script build html previews with referenced images
# Requires: asciidoctor - see https://docs.asciidoctor.org/asciidoctor/latest/install/linux-packaging/
# input: titles/
# output: titles-generated/ and titles-generated/$BRANCH/

# grep regex for title folders to exclude from processing below
EXCLUDED_TITLES="rhdh-plugins-reference"
BRANCH="main"

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '-b') BRANCH="$2"; shift 1;;
  esac
  shift 1
done

rm -fr titles-generated/;
mkdir -p titles-generated/"${BRANCH}";
echo "<html><head><title>Red Hat Developer Hub Documentation Preview - ${BRANCH}</title></head><body><ul>" > titles-generated/"${BRANCH}"/index.html;
# exclude the rhdh-plugins-reference as it's embedded in the admin guide
# shellcheck disable=SC2044,SC2013
set -e
for t in $(find titles -name master.adoc | sort -uV | grep -E -v "${EXCLUDED_TITLES}"); do
    d=${t%/*};
    dest=${d/titles/titles-generated\/${BRANCH}};
    rm -rf "$d/build" || true
    CMD="podman run --interactive --rm --tty \
          --volume "$(pwd)":/docs:Z \
          --workdir "/docs/$d" \
          quay.io/ivanhorvath/ccutil:amazing ccutil compile --format html-single --lang en-US";
    echo -e -n "\nBuilding $t into $dest ...\n  ";
    echo "${CMD}" | sed -r -e "s/\  +/ \\\\\n    /g"
    $CMD
    rm -rfv "$dest" || true
    mv -f "$d/build/tmp/en-US/html-single/" "$dest"
    # shellcheck disable=SC2013
    for im in $(grep images/ "$d/index.html" | grep -E -v 'mask-image|background|fa-icons|jupumbra' | sed -r -e "s#.+(images/[^\"]+)\".+#\1#"); do
        # echo "  Copy $im ...";
        IMDIR="$d/${im%/*}/"
        mkdir -p "${IMDIR}"; rsync -q "$im" "${IMDIR}";
    done
    # shellcheck disable=SC2044
    for f in $(find "$d/" -type f); do echo "    $f"; done
    echo "<li><a href=${d/titles-generated\/${BRANCH}/.}>${d/titles-generated\/${BRANCH}\//}</a></li>" >> titles-generated/"${BRANCH}"/index.html;
done
echo "</ul></body></html>" >> titles-generated/"${BRANCH}"/index.html

# shellcheck disable=SC2143
if [[ $BRANCH == "pr-"* ]]; then
  # fetch the existing https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/index.html to add prs and branches
  curl -sSL https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/pulls.html -o titles-generated/pulls.html
  if [[ -z $(grep "./${BRANCH}/index.html" titles-generated/pulls.html) ]]; then
      echo "Building root index for $BRANCH in titles-generated/pulls.html ...";
      echo "<li><a href=./${BRANCH}/index.html>${BRANCH}</a></li>" >> titles-generated/pulls.html
  fi
else
  # fetch the existing https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/index.html to add prs and branches
  curl -sSL https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/index.html -o titles-generated/index.html
  if [[ -z $(grep "./${BRANCH}/index.html" titles-generated/index.html) ]]; then
      echo "Building root index for $BRANCH in titles-generated/index.html ...";
      echo "<li><a href=./${BRANCH}/index.html>${BRANCH}</a></li>" >> titles-generated/index.html
  fi
fi
