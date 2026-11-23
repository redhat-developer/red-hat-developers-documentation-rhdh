#!/bin/bash

# Update version attributes in artifacts/attributes.adoc from upstream sources.
# See RHIDP-19177 for the source-per-attribute design.
#
# Maintained branches: main and release-2.* only.
#
# Sources (read from the same-stream upstream branch as -b):
#   :product-version:, :product-chart-version:
#       rhdh            package.json "version"
#   :product-version-next:
#                       derived X.Y + 0.1
#   :product-backstage-version:
#                       rhdh            backstage.json "version"
#   :orchestrator-plugin-version:
#                       quay.io/rhdh/plugin-catalog-index imageTag prefix
#   :ocp-version-min:, :ocp-version:
#                       https://access.redhat.com/support/policy/updates/developerhub
#   :kubernetes-version:
#                       derived from ocp-version-min: OCP 4.x -> k8s 1.(x+13),
#                       OCP 5.x -> k8s 1.(x+36)
#   :rhoserverless-logic-version:
#                       max(rhdh-chart orchestrator-infra startingCSV,
#                           rhdh-operator KN_CLI_URL pin)
#   :rhoserverless-version:
#                       minor from rhdh-operator docs/orchestrator.md Version
#                       Compatibility, latest z from
#                       quay.io/redhat-user-workloads/ocp-serverless-tenant tags
#
# Not touched (static, see comments in attributes.adoc): :keycloak-version:,
# :ansible-automation-platform-version:, :osd-version:.
#
# Every computed value must be >= the current one; a decrease fails the run
# instead of downgrading the docs.

set -euo pipefail

BRANCH=""
ATTRIBUTES_FILE="artifacts/attributes.adoc"

RHDH_RAW="https://raw.githubusercontent.com/redhat-developer/rhdh"
RHDH_OPERATOR_RAW="https://raw.githubusercontent.com/redhat-developer/rhdh-operator"
RHDH_CHART_RAW="https://raw.githubusercontent.com/redhat-developer/rhdh-chart"
LIFECYCLE_URL="https://access.redhat.com/support/policy/updates/developerhub"
CATALOG_INDEX="quay.io/rhdh/plugin-catalog-index"
SERVERLESS_BUNDLE_REPO_PREFIX="quay.io/redhat-user-workloads/ocp-serverless-tenant/serverless-operator"

usage() {
  cat <<EOF
Usage: $0 -b <branch>

  -b <branch>  Docs branch to update: main or release-X.Y

Modifies $ATTRIBUTES_FILE in the working tree; review with git diff and
revert with git checkout. The workflow, not this script, opens the PR.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -b|--ref-branch) BRANCH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ "$BRANCH" =~ ^(main|release-[0-9]+\.[0-9]+)$ ]] || {
  echo "Branch must be main or release-X.Y, got: ${BRANCH:-empty}" >&2
  exit 1
}

[[ -f "$ATTRIBUTES_FILE" ]] || {
  echo "Missing $ATTRIBUTES_FILE (run from the repository root)" >&2
  exit 1
}

trap 'rm -rf "$workdir"' EXIT
# version_gt A B: true when A > B (semver-ish, numeric compare per segment)
version_gt() {
  local a="$1" b="$2"
  [[ "$a" != "$b" ]] && [[ "$(printf '%s\n%s\n' "$a" "$b" | sort -V | tail -1)" == "$a" ]]
}

# curl wrapper: enforce HTTPS when following redirects (SonarCloud S4423).
fetch() {
  curl --proto '=https' --tlsv1.2 -fsSL "$@"
}

current_value() {
  local key="$1"
  awk -v key=":${key}:" '$1 == key { print $2; exit }' "$ATTRIBUTES_FILE"
}

set_value() {
  local key="$1" value="$2"
  if [[ "$(current_value "$key")" == "$value" ]]; then
    return 0
  fi
  sed -i -E "s|^(:${key}:).*$|\1 ${value}|" "$ATTRIBUTES_FILE"
  CHANGED=1
}

# Guarded set: refuse a downgrade, keep the run failing loudly.
guard_and_set() {
  local key="$1" value="$2" current
  current="$(current_value "$key")"
  if [[ -n "$current" && "$current" != "$value" ]] && version_gt "$current" "$value"; then
    echo "REFUSING DOWNGRADE: :${key}: ${current} -> ${value}" >&2
    exit 1
  fi
  set_value "$key" "$value"
}

# ---------------------------------------------------------------------------
# rhdh product versions
# ---------------------------------------------------------------------------
pkg_version="$(fetch "$RHDH_RAW/$BRANCH/package.json" | jq -r .version)"
[[ "$pkg_version" =~ ^([0-9]+)\.([0-9]+)\.[0-9]+$ ]] || {
  echo "Unparseable rhdh package.json version: $pkg_version" >&2; exit 1;
}
product_major="${BASH_REMATCH[1]}"
product_minor="${BASH_REMATCH[2]}"
product_version="${product_major}.${product_minor}"
product_version_next="${product_major}.$((10#${product_minor} + 1))"

backstage_version="$(fetch "$RHDH_RAW/$BRANCH/backstage.json" | jq -r .version)"
[[ "$backstage_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Unparseable backstage.json version: $backstage_version" >&2; exit 1;
}

# ---------------------------------------------------------------------------
# Orchestrator plugin version: catalog index imageTag prefix before "--"
# ---------------------------------------------------------------------------
orchestrator_version=""
workdir="$(mktemp -d)"
for tag in "$pkg_version" "$product_version" "${product_version}.0"; do
  if skopeo copy "docker://${CATALOG_INDEX}:${tag}" "dir:$workdir/idx" >/dev/null 2>&1; then
    # The dir transport stores blobs by digest; the index.json we need sits
    # inside the gzip layer, not the config JSON.
    for blob in "$workdir"/idx/*; do
      [[ -f "$blob" ]] || continue
      base="$(basename "$blob")"
      [[ "$base" == "manifest.json" || "$base" == "version" ]] && continue
      rm -rf "$workdir/layer" && mkdir -p "$workdir/layer"
      if tar -xzf "$blob" -C "$workdir/layer" 2>/dev/null \
         && [[ -f "$workdir/layer/index.json" ]]; then
        image_tag="$(jq -r '."red-hat-developer-hub-backstage-plugin-orchestrator".imageTag // empty' \
          "$workdir/layer/index.json")"
        if [[ "$image_tag" =~ ^([0-9]+\.[0-9]+\.[0-9]+)-- ]]; then
          orchestrator_version="${BASH_REMATCH[1]}"
          break 2
        fi
      fi
    done
  fi
  rm -rf "$workdir/idx"
done
[[ -n "$orchestrator_version" ]] || {
  echo "Could not read orchestrator imageTag from $CATALOG_INDEX (tried tags: $pkg_version, $product_version, ${product_version}.0)" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# OCP versions from the RHDH lifecycle page
# ---------------------------------------------------------------------------
ocp_min="" ocp_max=""
lifecycle_html_file="$workdir/lifecycle.html"
fetch "$LIFECYCLE_URL" -o "$lifecycle_html_file"
ocp_out="$(python3 - "$product_version" "$lifecycle_html_file" <<'PY'
import re
import sys

product_version = sys.argv[1]
with open(sys.argv[2]) as f:
    text = f.read()
text = re.sub(r"<[^>]+>", " ", text)
text = re.sub(r"\s+", " ", text)

sections = re.findall(r"(\d+\.\d+) OpenShift Container Platform ((?:\d+\.\d+(?:, )?)+)", text)
if not sections:
    sys.exit(1)

section = next(((v, ocp) for v, ocp in sections if v == product_version), sections[0])
if section[0] != product_version:
    print(f"NOTE: no lifecycle section for {product_version}, falling back to {section[0]}", file=sys.stderr)
ocp = [v.strip() for v in section[1].split(",")]
print(ocp[0])
print(ocp[-1])
PY
)" || { echo "Could not parse OCP versions from $LIFECYCLE_URL" >&2; exit 1; }
ocp_min="$(printf '%s\n' "$ocp_out" | sed -n 1p)"
ocp_max="$(printf '%s\n' "$ocp_out" | sed -n 2p)"
[[ "$ocp_min" =~ ^[0-9]+\.[0-9]+$ && "$ocp_max" =~ ^[0-9]+\.[0-9]+$ ]] || {
  echo "Could not parse OCP versions from $LIFECYCLE_URL" >&2; exit 1;
}

# Kubernetes version: OCP 4.x -> k8s 1.(x+13), OCP 5.x -> k8s 1.(x+36)
[[ "$ocp_min" =~ ^([0-9]+)\.([0-9]+)$ ]] || {
  echo "Unparseable ocp-version-min: $ocp_min" >&2; exit 1;
}
ocp_major="${BASH_REMATCH[1]}"
case "$ocp_major" in
  4) kubernetes_version="1.$((10#${BASH_REMATCH[2]} + 13))" ;;
  5) kubernetes_version="1.$((10#${BASH_REMATCH[2]} + 36))" ;;
  *) echo "Unknown OCP major $ocp_major; no k8s mapping formula" >&2; exit 1 ;;
esac

# ---------------------------------------------------------------------------
# OpenShift Serverless Logic: greater of chart startingCSV and operator KN_CLI pin
# ---------------------------------------------------------------------------
chart_csv="$(fetch \
  "$RHDH_CHART_RAW/$BRANCH/charts/orchestrator-infra/values.yaml" \
  | sed -n 's/.*startingCSV: logic-operator\.v\([0-9.]*\).*/\1/p' | head -1)"
kn_cli_version="$(fetch \
  "$RHDH_OPERATOR_RAW/$BRANCH/bundle/rhdh/manifests/rhdh-plugin-deps_v1_configmap.yaml" \
  | sed -n 's#.*serverless-logic/\([0-9.]*\)/kn-workflow.*#\1#p' | head -1)"
[[ "$chart_csv" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Unparseable rhdh-chart startingCSV: ${chart_csv:-empty}" >&2; exit 1;
}
[[ "$kn_cli_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || {
  echo "Unparseable rhdh-operator KN_CLI pin: ${kn_cli_version:-empty}" >&2; exit 1;
}
serverless_logic_version="$(printf '%s\n%s\n' "$chart_csv" "$kn_cli_version" | sort -V | tail -1)"

# ---------------------------------------------------------------------------
# OpenShift Serverless: minor from the operator's Version Compatibility doc,
# latest z from the tenant registry
# ---------------------------------------------------------------------------
serverless_minor="$(fetch "$RHDH_OPERATOR_RAW/$BRANCH/docs/orchestrator.md" \
  | sed -n 's/.*OpenShift Serverless version .\([0-9][0-9]*\.[0-9][0-9]*\).*/\1/p' | head -1)"
[[ "$serverless_minor" =~ ^[0-9]+\.[0-9]+$ ]] || {
  echo "Could not read the OpenShift Serverless minor from rhdh-operator $BRANCH docs/orchestrator.md" >&2
  exit 1
}
serverless_minor_nodot="${serverless_minor//./}"
serverless_version="$(skopeo list-tags \
  "docker://${SERVERLESS_BUNDLE_REPO_PREFIX}-${serverless_minor_nodot}/serverless-openshift-kn-operator" \
  | jq -r '.Tags[]' | grep -E "^${serverless_minor//./\\.}" \
  | grep -v -E "[0-9]{10}|-source|sha256-|build-" | sort -V | tail -1)"
[[ "$serverless_version" =~ ^${serverless_minor//./\\.}\.[0-9]+$ ]] || {
  echo "Could not compute latest $serverless_minor.z from the serverless-operator registry tags" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Apply
# ---------------------------------------------------------------------------
CHANGED=0
guard_and_set product-version "$product_version"
# :product-bundle-version: is left to the plugin tables workflow
# (rhdh-supported-plugins.sh), which syncs it from the rhdh-operator CSV.
# The rhdh repo's package.json lags the operator CSV on release branches
# (2.1.0 vs 2.1.1), so setting it here would fail the no-decrease guard
# right after the Monday tables run bumped it.
guard_and_set product-chart-version "$pkg_version"
# The successor release is only computable on main: on a release branch the
# next version is frozen history (1.10 was followed by 2.0, not 1.11).
if [[ "$BRANCH" == "main" ]]; then
  guard_and_set product-version-next "$product_version_next"
fi
guard_and_set product-backstage-version "$backstage_version"
guard_and_set orchestrator-plugin-version "$orchestrator_version"
guard_and_set ocp-version-min "$ocp_min"
guard_and_set ocp-version "$ocp_max"
guard_and_set kubernetes-version "$kubernetes_version"
guard_and_set rhoserverless-version "$serverless_version"
guard_and_set rhoserverless-version-major "$serverless_minor"
guard_and_set rhoserverless-logic-version "$serverless_logic_version"

if [[ "$CHANGED" -eq 0 ]]; then
  echo "No changes needed for $BRANCH."
  exit 0
fi

git diff -- "$ATTRIBUTES_FILE"
echo "Updated $ATTRIBUTES_FILE for $BRANCH."
