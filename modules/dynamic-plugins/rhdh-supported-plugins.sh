#!/bin/bash

# Set consistent locale for sorting across different systems
export LC_ALL=C

# script to generate rhdh-supported-plugins.adoc from content in
# https://github.com/redhat-developer/rhdh/tree/main/catalog-entities/extensions/packages/
# and optionally generate ref-community-plugins-migration.adoc from
# https://github.com/redhat-developer/rhdh-plugin-export-overlays

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

norm="\033[0;39m"
green="\033[1;32m"
blue="\033[1;34m"
red="\033[1;31m"
orange="\033[1;35m"

QUIET=1; # suppress debug output
DO_CLEAN=0

BRANCH=main
SKIP_TABLES=0
SKIP_MIGRATION=0

rhdhRepo="https://github.com/redhat-developer/rhdh"
overlaysRepo="https://github.com/redhat-developer/rhdh-plugin-export-overlays"

debug() {
  if [[ $QUIET -eq 0 ]]; then
    echo -e "${orange}[DEBUG] $1${norm}"
  fi
}

usage() {
  cat <<EOF

Generate an updated table of dynamic plugins from content in the following two repos, for the specified branch:
* $rhdhRepo
* $overlaysRepo

By default, both repos are processed. Use --skip-tables or --skip-migration to skip either.

Requires:
* jq 1.6+
* yq from https://pypi.org/project/yq/ - not the mikefarah version

Usage:

$0 -b stable-ref-branch [options]

Options:
  -b, --ref-branch    : Branch against which plugin versions should be incremented, like release-1.y; default: main
  --skip-tables       : Skip re-generating dynamic plugin tables and .csv
  --skip-migration    : Skip re-generating the migation guide
  --clean             : Force a clean GH checkout (do not reuse files on disk)
  -v                  : more verbose output
  -h, --help          : Show this help

Examples:

  $0 -b release-1.9
  $0 -b release-1.9 --clean
  $0 -b release-1.9 --skip-migration  # Only regen dynamic plugin tables
  $0 -b main        --skip-tables     # Only regen migration guide

EOF
}

if [[ "$#" -lt 1 ]]; then usage; exit 1; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--clean') DO_CLEAN=1;;
    '-b'|'--ref-branch') BRANCH="$2"; shift 1;;        # reference branch, eg., 1.1.x
    '--skip-tables') SKIP_TABLES=1;;
    '--skip-migration') SKIP_MIGRATION=1;;
    '-v') QUIET=0;;
    '-h'|'--help') usage; exit 0;;
    *) echo "Unknown parameter used: $1."; usage; exit 1;;
  esac
  shift 1
done

if [[ ! $BRANCH ]]; then usage; exit 1; fi

# Set temp directory paths based on BRANCH
rhdhtmpdir="/tmp/rhdh_$BRANCH" # for DPDY file
overlaystmpdir="/tmp/rhdh-plugin-export-overlays_$BRANCH" # for catalog metadata

if [[ $DO_CLEAN -eq 1 ]]; then
    rm -fr /tmp/plugin-versions_"${BRANCH}".txt "${rhdhtmpdir}" "${overlaystmpdir}"
fi

# fetch rhdh repo - not needed when regenerating migration table
if [[ $SKIP_TABLES -eq 0 ]]; then
    if [[ ! -d "${rhdhtmpdir}" ]]; then
        echo -e "${green}Cloning $rhdhRepo (branch: $BRANCH)...${norm}"
        pushd /tmp >/dev/null || exit
            git clone "$rhdhRepo" --depth 1 -b "$BRANCH" "rhdh_$BRANCH" --quiet
        popd >/dev/null || exit
    fi
fi

# need this for BOTH the migration table generation AND the dynamic plugin tables generation
if [[ ! -d "$overlaystmpdir" ]]; then
    echo -e "${green}Cloning $overlaysRepo (branch: $BRANCH)...${norm}"
    pushd /tmp >/dev/null || exit
        git clone "$overlaysRepo" --depth 1 -b "$BRANCH" "rhdh-plugin-export-overlays_${BRANCH}" --quiet
    popd >/dev/null || exit
fi

# thanks to https://stackoverflow.com/questions/42925485/making-a-script-that-transforms-sentences-to-title-case
# shellcheck disable=SC2048 disable=SC2086
titlecase() {
    for f in ${*} ; do \
        case $f in
            aap) echo -n "Ansible Automation Platform (AAP) ";;
            # UPPERCASE these exceptions
            acr|cd|ocm|rbac) echo -n "$(echo "$f" | tr '[:lower:]' '[:upper:]') ";;
            # MixedCase exceptions
            argocd) echo -n "Argo CD ";;
            github) echo -n "GitHub ";;
            gitlab) echo -n "GitLab ";;
            jfrog) echo -n "JFrog ";;
            msgraph) echo -n "MS Graph ";;
            pagerduty) echo -n "PagerDuty ";;
            servicenow) echo -n "ServiceNow ";;
            sonarqube) echo -n "SonarQube ";;
            techdocs) echo -n "TechDocs ";;
            # Uppercase the first letter
            *)
                first_char=$(echo "$f" | cut -c1 | tr '[:lower:]' '[:upper:]')
                rest_chars=$(echo "$f" | cut -c2-)
                echo -n "${first_char}${rest_chars} "
                ;;
        esac;
    done; echo;
}

generate_dynamic_plugins_table() {
  # generate a list of plugin:version mapping from the following files
  # * dynamic-plugins/imports/package.json#.peerDependencies or .dependencies
  # * packages/app/package.json#.dependencies
  # * packages/backend/package.json#.dependencies
  pluginVersFile=/tmp/plugin-versions_"${BRANCH}".txt
  if [[ -f "${rhdhtmpdir}"/dynamic-plugins/imports/package.json ]]; then
      jq -r '.peerDependencies' "${rhdhtmpdir}"/dynamic-plugins/imports/package.json | grep -E -v "\"\*\"|\{|\}" | grep "@" | tr -d "," > "$pluginVersFile"
  fi
  jq -r '.dependencies' "${rhdhtmpdir}"/packages/{app,backend}/package.json | grep -E -v "\"\*\"|\{|\}" | grep "@" | tr -d "," >> "$pluginVersFile"
  # Use LC_ALL=C for consistent sorting across different locales
  cat "$pluginVersFile" | sort -u > "$pluginVersFile".out; mv -f "$pluginVersFile".out "$pluginVersFile"

  rm -fr /tmp/warnings_"${BRANCH}".txt

  # create temporary files instead of associative arrays
  TEMP_DIR="/tmp/rhdh-processing_${BRANCH}"
  mkdir -p "$TEMP_DIR"
  rm -f "$TEMP_DIR"/*.tmp

  # process YAML files from overlays/workspaces/*/metadata/*.yaml
  yamls=$(find "${overlaystmpdir}"/workspaces/*/metadata/ -maxdepth 1 -name "*.yaml")
  c=0
  tot=0
  for y in $yamls; do
      [[ $(basename "$y") == "all.yaml" ]] && continue
      (( tot++ )) || true
  done

  # string listing the enabled-by-default plugins to add to con-preinstalled-dynamic-plugins.template.adoc
  ENABLED_PLUGINS="/tmp/ENABLED_PLUGINS_${BRANCH}.txt"; rm -f "$ENABLED_PLUGINS"; touch "$ENABLED_PLUGINS"

  for y in $yamls; do
      [[ $(basename "$y") == "all.yaml" ]] && continue
      (( c++ )) || true
      echo -e "${green}[$c/$tot] Processing $y${norm}"
      Required_Variables=""

      # extract content from YAML
      Name=$(yq -r '.metadata.name' "$y")

      # Use .spec.packageName, or if not set use .metadata.name
      Plugin=$(yq -r '.spec.packageName // .metadata.name' "$y")

      debug ".spec.packageName | .metadata.name: $Plugin"

      # If Plugin is still not a proper npm package name, try to construct it
      if [[ $Plugin != "@"* ]] && [[ $Plugin == "$Name" ]]; then
          Plugin="$(echo "${Plugin}" | sed -r -e 's/([^-]+)-(.+)/\@\1\/\2/' \
              -e 's|janus/idp-|janus-idp/|' \
              -e 's|red/hat-developer-hub-|red-hat-developer-hub/|' \
              -e 's|backstage/community-|backstage-community/|' \
              -e 's|parfuemerie/douglas-|parfuemerie-douglas/|')"
      fi

      # Extract lifecycle and path from YAML spec
      Lifecycle=$(yq -r '.spec.lifecycle // "unknown"' "$y")

      # Use the actual dynamicArtifact path from YAML
      Path=$(yq -r '.spec.dynamicArtifact // ""' "$y")

      # Fallback to constructed path if not found
      if [[ ! $Path || $Path == "null" ]]; then
          Path="$(echo "${Plugin/@/}" | tr "/" "-")"
          Path="./dynamic-plugins/dist/${Path}-dynamic"
          # remove dupe suffixes
          Path="${Path/-dynamic-dynamic/-dynamic}"
      fi

      # DEPRECATED :: Filter 0: Only dynamic plugin artifacts under dist root (frontend or backend) or @redhat NRRC registry
      # Accept both patterns:
      #  - Frontend: ./dynamic-plugins/dist/<name>
      #  - Backend:  ./dynamic-plugins/dist/<name>-dynamic
      #  - NRRC registry: @redhat/<package>@version (applies to Orchestrator plugins from 1.8 and earlier)
      #  this change was made since FE plugins were not being included in the .csv file
      [[ $Path == ./dynamic-plugins/dist/* ]] || [[ $Path == "@redhat"* ]] || \

      # Filter 1: Include quay and r.a.r.c references to RHDH dynamic plugins
      [[ $Path == "oci://quay.io/rhdh/"* ]] || [[ $Path == "oci://registry.access.redhat.com/rhdh/"* ]] || \
        { debug "Skip[1] Path = $Path\n"; continue; }

      # Filter 2: Exclude oci://ghcr.io/ community paths;
      [[ $Path == "oci://ghcr.io/"* ]] && \
        { debug "Skip[2] Path = $Path\n"; continue; }

      # DEPRECATED :: Filter 3: Handle @redhat packages - exclude unless they have dynamicArtifact from NRRC registry
      # Plugin = @red-hat-developer-hub/backstage-plugin-orchestrator
      # .spec.dynamicArtifact = oci://quay.io/rhdh/red-hat-developer-hub-backstage-plugin-orchestrator-backend-module-loki@sha256:779f888d47a9b87ad81a13897e171fe4a6a67498a937d7560026dd081361a3b2
      [[ $Plugin == "@redhat"* ]] && [[ $(yq -r '.spec.dynamicArtifact // ""' "$y") == "@redhat"* ]] && \
        { debug "Skip[3] Plugin = $Plugin\n"; continue; }

      # shellcheck disable=SC2016
      found_in_default_config1=$(yq -r --arg Path "${Path%-dynamic}" '.plugins[] | select(.package == $Path)' "${rhdhtmpdir}"/dynamic-plugins.default.yaml)
      # shellcheck disable=SC2016
      found_in_default_config2=$(yq -r --arg Path "${Path}"           '.plugins[] | select(.package == $Path)' "${rhdhtmpdir}"/dynamic-plugins.default.yaml)

      Path2=$(echo "$found_in_default_config2" | jq -r '.package') # with -dynamic suffix
      if [[ $Path2 ]]; then
          Path=$Path2
      else
          Path=$(echo "$found_in_default_config1" | jq -r '.package') # without -dynamic suffix
      fi

      # For extensions YAML files, skip the default config check for inclusion
      if [[ "$y" == *"/metadata/"* ]]; then
          # Process extensions packages regardless of default config
          debug "Processing extensions package: $Name"
      elif [[ ! $Path ]]; then
          continue
      fi

      if [[ $Path ]] || [[ "$y" == *"/metadata/"* ]]; then
          # Extract role and version from YAML - updated paths
          Role=$(yq -r '.spec.backstage.role // "unknown"' "$y")
          VersionJQ=$(yq -r '.spec.version // "0.0.0"' "$y")
          # check this version against other references to the plugin in
          # * dynamic-plugins/imports/package.json#.peerDependencies or .dependencies
          # * packages/app/package.json#.dependencies
          # * packages/backend/package.json#.dependencies
          # echo "[DEBUG] Check version of $Name is really $VersionJQ (from Path = $Path)..."
          match=$(grep "\"$Name\": \"" $pluginVersFile || true)
          Version=$VersionJQ
          if [[ $match ]]; then
              Version=$(echo "${match}" | sed -r -e "s/.+\": \"([0-9.]+)\"/\1/")
              if [[ "$Version" != "$VersionJQ" ]]; then
                  echo -e "${blue}[WARN] ! Using $pluginVersFile version = $Version, not $VersionJQ from $Path ${norm}" | tee -a /tmp/warnings_"${BRANCH}".txt
              fi
          fi

          # check if there's a newer version at npmjs.com and warn if so
          # for tags and associated repo digests (git head)
          # curl -sSLko- https://registry.npmjs.org/@janus-idp%2fcli | jq -r '.versions[]|(.version+", "+.gitHead)' | sort -uV
          # for timestamp when tag is created
          # curl -sSLko- https://registry.npmjs.org/@janus-idp%2fcli | jq -r '.time' | grep -v -E "created|modified|{|}" | sort -uV
          # echo "Searching for ${Plugin/\//%2f} at npmjs.org..."
          allVersionsPublished="$(curl -sSLko- "https://registry.npmjs.org/${Plugin/\//%2f}" | jq -r '.versions[].version')"
          # echo "Found $allVersionsPublished"
          # clean out any pre-release versions
          latestXYRelease="$(echo "$allVersionsPublished" | grep -v -E -- "next|alpha|-" | grep -E "^${Version%.*}" | sort -u | tail -1)"
          # echo "[DEBUG] Latest x.y version at https://registry.npmjs.org/${Plugin/\//%2f} : $latestXYRelease"
          if [[ "$latestXYRelease" != "$Version" ]]; then
              echo -e "${blue}[WARN] Can upgrade $Version to https://www.npmjs.com/package/$Plugin/v/$latestXYRelease ${norm}" | tee -a /tmp/warnings_"${BRANCH}".txt
              # echo | tee -a /tmp/warnings_"${BRANCH}".txt
          fi

          # Extract support level from YAML metadata
          Support_Level="Community Support"
          # Check for Red Hat authorship and support level
          author=$(yq -r '.spec.author // "unknown"' "$y")
          support=$(yq -r '.spec.support // "unknown"' "$y")

          if [[ $author == "Red Hat"* ]]; then
              if [[ $support == "production"* ]] || [[ $support == "generally-available"* ]]; then
                  Support_Level="Production"
              elif [[ $support == "tech-preview"* ]]; then
                  Support_Level="Red Hat Tech Preview"
              fi
          fi

          # compute Default from dynamic-plugins.default.yaml
          # shellcheck disable=SC2016
          disabled=$(yq -r --arg Path "${Path/-dynamic/}" '.plugins[] | select(.package == $Path) | .disabled' "${rhdhtmpdir}"/dynamic-plugins.default.yaml)
          # shellcheck disable=SC2016
          if [[ ! $disabled ]]; then disabled=$(yq -r --arg Path "${Path}" '.plugins[] | select(.package == $Path) | .disabled' "${rhdhtmpdir}"/dynamic-plugins.default.yaml); fi
          # echo "Using Path = $Path got disabled = $disabled"
          # null or false == enabled by default
          Default="Enabled"
          if [[ $disabled == "true" ]]; then
              Default="Disabled"
          else
              if [[ $Support_Level == "Production" ]]; then
                  # see https://issues.redhat.com/browse/RHIDP-3187 - only Production-level support (GA) plugins should be enabled by default
                  echo "* \`${Plugin}\`" >> "$ENABLED_PLUGINS"
              elif [[ ${Support_Level} == "Red Hat Tech Preview" ]]; then
                  # as discussed in RHDH SOS on Jul 14, we are now opening the door for TP plugins to be on by default.
                  # PM (Ben) and Support (Tim) are cool with this as long as the docs clearly state
                  # what is TP, and how to disable the TP content
                  echo -e "${blue}[WARN] $Plugin is enabled by default but is only $Support_Level ${norm}" | tee -a ${ENABLED_PLUGINS}.errors
                  echo "* \`${Plugin}\`" >> "$ENABLED_PLUGINS"
              else
                  echo -e "${red}[ERROR] $Plugin should not be enabled by default as its support level is $Support_Level${norm}" | tee -a ${ENABLED_PLUGINS}.errors
              fi
          fi

          # compute Required_Variables from appConfigExamples in YAML
          Required_Variables=""
          appConfig=$(yq -r '.spec.appConfigExamples[0].content // empty' "$y" 2>/dev/null)
          if [[ -n "$appConfig" && "$appConfig" != "null" ]]; then
              # Extract ${VARIABLE_NAME} patterns
              vars=$(echo "$appConfig" | grep -o '\${[^}]*}' | sed 's/\${//g' | sed 's/}//g' | sort -u)
              for var in $vars; do
                  Required_Variables="${Required_Variables}\`$var\`\n\n"
              done
          fi
          Required_Variables_CSV=$(echo -e "$Required_Variables" | tr -s "\n" ";")
          # not currently used due to policy and support concern with upstream content linked from downstream doc
          # URL="https://www.npmjs.com/package/$Plugin"

          # Build a human-readable name from the package
          # Start with package name without scope (e.g., "backstage-plugin-quickstart")
          pkg_no_scope="${Plugin#@}"
          pkg_no_scope="${pkg_no_scope#*/}"

          # Special cases for specific plugins
          case "$Plugin" in
              *pagerduty*) PrettyName="PagerDuty" ;;
              *redhat-argocd*) PrettyName="Argo CD (Red Hat)" ;;
              *scaffolder-backend-argocd*) PrettyName="Argo CD" ;;
              *notifications-backend-module-email*) PrettyName="Notifications" ;;
              *)
                  # Strip common vendor/prefix tokens and backend suffix
                  ProcessedName=$(echo "$pkg_no_scope" | sed -r \
                      -e 's@^backstage-community-@@' \
                      -e 's@^red-hat-developer-hub-@@' \
                      -e 's@^redhat-@@' \
                      -e 's@^roadiehq-@@' \
                      -e 's@^immobiliarelabs-@@' \
                      -e 's@^parfuemerie-douglas-@@' \
                      -e 's@^backstage-plugin-@@' \
                      -e 's@^plugin-@@' \
                      -e 's@^catalog-backend-module-@@' \
                      -e 's@^plugin-catalog-backend-module-@@' \
                      -e 's@^scaffolder-backend-module-@@' \
                      -e 's@-backend$@@' \
                  )
                  PrettyName="$(titlecase "${ProcessedName//-/ }")"
                  ;;
          esac
          # Trim trailing whitespace from PrettyName
          PrettyName="$(echo -e "$PrettyName" | sed -E 's/[[:space:]]+$//')"

          # useful console output
          if [[ $QUIET -eq 0 ]]; then
            for col in Name PrettyName Role Plugin Version Support_Level Lifecycle Path Required_Variables Default; do
                debug " * $col = ${!col}"
            done
          fi

          # save in an array sorted by name, then role, with frontend before backend plugins (for consistency with 1.1 markup)
          RoleSort=1; if [[ $Role != *"front"* ]]; then RoleSort=2; Role="Backend"; else Role="Frontend"; fi
          if [[ $Plugin == *"scaffolder"* ]]; then RoleSort=3; fi

          # TODO include missing data fields for Provider and Description - see https://issues.redhat.com/browse/RHIDP-3496 and https://issues.redhat.com/browse/RHIDP-3440

          # Use temporary files to allow sorting later
          key="$PrettyName-$RoleSort-$Role-$Plugin"
          adoc_content="|$PrettyName |\`https://npmjs.com/package/$Plugin/v/$Version[$Plugin]\` |$Version \n|\`$Path\`\n\n$Required_Variables"
          csv_content="\"$PrettyName\",\"$Plugin\",\"$Role\",\"$Version\",\"$Support_Level\",\"$Lifecycle\",\"$Path\",\"${Required_Variables_CSV}\",\"$Default\""

          # split into three tables based on support level
          if [[ ${Lifecycle} == "deprecated" ]]; then
              echo "$key|$adoc_content" >> "$TEMP_DIR/adoc.deprecated.tmp"
          elif [[ ${Support_Level} == "Production" ]]; then
              echo "$key|$adoc_content" >> "$TEMP_DIR/adoc.production.tmp"
          elif [[ ${Support_Level} == "Red Hat Tech Preview" ]]; then
              echo "$key|$adoc_content" >> "$TEMP_DIR/adoc.tech-preview.tmp"
          else
              echo "$key|$adoc_content" >> "$TEMP_DIR/adoc.community.tmp"
          fi

          # Group CSV by support level
          SupportSort=3
          if [[ ${Lifecycle} == "deprecated" ]]; then
              SupportSort=4
          elif [[ ${Support_Level} == "Production" ]]; then
              SupportSort=1
          elif [[ ${Support_Level} == "Red Hat Tech Preview" ]]; then
              SupportSort=2
          fi
          csv_key="$SupportSort-$PrettyName-$RoleSort-$Role-$Plugin"
          echo "$csv_key|$csv_content" >> "$TEMP_DIR/csv.tmp"
      else
          (( tot-- )) || true
          echo -e "${blue}        Skip: not in rhdh/dynamic-plugins.default.yaml !${norm}"
      fi
      echo
  done

  c=0
  debug "Creating .csv ..."

  # create .csv file with header
  echo -e "\"Name\",\"Plugin\",\"Role\",\"Version\",\"Support Level\",\"Lifecycle\",\"Path\",\"Required Variables\",\"Default\"" > "${0/.sh/.csv}"

  num_plugins=()
  # Process temporary files
  # 1) Production
  temp_file="$TEMP_DIR/adoc.production.tmp"
  out_file="${0/.sh/.ref-rh-supported-plugins}"
  rm -f "$out_file"
  count=0
  if [[ -f "$temp_file" ]]; then
      sort "$temp_file" | while IFS='|' read -r key content; do
          (( count = count + 1 ))
          debug " * [$count] $key [ ${out_file##*/} ]"
          echo -e "$content" >> "$out_file"
      done
      count=$(wc -l < "$temp_file")
  fi
  # shellcheck disable=SC2206
  num_plugins+=($count)

  # 2) Tech Preview
  temp_file="$TEMP_DIR/adoc.tech-preview.tmp"
  out_file="${0/.sh/.ref-rh-tech-preview-plugins}"
  rm -f "$out_file"
  count=0
  if [[ -f "$temp_file" ]]; then
      sort "$temp_file" | while IFS='|' read -r key content; do
          (( count = count + 1 ))
          debug " * [$count] $key [ ${out_file##*/} ]"
          echo -e "$content" >> "$out_file"
      done
      count=$(wc -l < "$temp_file")
  fi
  # shellcheck disable=SC2206
  num_plugins+=($count)

  # 3) Community
  temp_file="$TEMP_DIR/adoc.community.tmp"
  out_file="${0/.sh/.ref-community-plugins}"
  rm -f "$out_file"
  count=0
  if [[ -f "$temp_file" ]]; then
      sort "$temp_file" | while IFS='|' read -r key content; do
          (( count = count + 1 ))
          debug " * [$count] $key [ ${out_file##*/} ]"
          echo -e "$content" >> "$out_file"
      done
      count=$(wc -l < "$temp_file")
  fi
  # shellcheck disable=SC2206
  num_plugins+=($count)

  # 3) Deprecated
  temp_file="$TEMP_DIR/adoc.deprecated.tmp"
  out_file="${0/.sh/.ref-deprecated-plugins}"
  rm -f "$out_file"
  count=0
  if [[ -f "$temp_file" ]]; then
      sort "$temp_file" | while IFS='|' read -r key content; do
          (( count = count + 1 ))
          debug " * [$count] $key [ ${out_file##*/} ]"
          echo -e "$content" >> "$out_file"
      done
      count=$(wc -l < "$temp_file")
  fi
  # shellcheck disable=SC2206
  num_plugins+=($count)

  # Process CSV: sort by SupportSort (1,2,3,4) then PrettyName, and omit techdocs
  if [[ -f "$TEMP_DIR/csv.tmp" ]]; then
      debug
      sort -t '|' -k1,1 -k2,2 "$TEMP_DIR/csv.tmp" | while IFS='|' read -r key content; do
          # RHIDP-4196 omit techdocs plugins from the .csv
          if [[ $key != *"techdocs"* ]]; then
              echo -e "$content" >> "${0/.sh/.csv}"
          else
              debug "Omit plugin $key from .csv file"
          fi
      done
  fi

  debug

  # merge the content from the 4 .adocX files into the .template.adoc file, replacing the TABLE_CONTENT markers
  count=1
  index=0
  empties=0
  for d in ref-rh-supported-plugins ref-rh-tech-preview-plugins ref-community-plugins ref-deprecated-plugins; do
      (( index = count - 1 ))
      this_num_plugins=${num_plugins[$index]}
      echo -n -e "${green}[$count] Processing $d ${norm}..."
      if [[ $this_num_plugins -gt 0 ]]; then
        adocfile="${0/.sh/.${d}}"
        sed -e "/%%TABLE_CONTENT_${count}%%/{r $adocfile" -e 'd;}' \
            -e "s/\%\%COUNT_${count}\%\%/$this_num_plugins/" \
            "${0/rhdh-supported-plugins.sh/${d}.template.adoc}" > "${0/rhdh-supported-plugins.sh/${d}.adoc}"
        rm -f "$adocfile"
        echo ""
      else
        echo -e "${blue} no plugins to include: ${d}.adoc emptied.${norm}"
        (( empties = empties + 1 ))
        echo "" > "${0/rhdh-supported-plugins.sh/${d}.adoc}"
      fi
      (( count = count + 1 ))
  done

  if [[ $empties -gt 2 ]]; then
    echo -e "${red}[ERROR] multiple tables have been emptied! Something bad has happened."
    exit 1
  fi

  # inject ENABLED_PLUGINS into con-preinstalled-dynamic-plugins.template.adoc
  sed -e "/%%ENABLED_PLUGINS%%/{r $ENABLED_PLUGINS" -e 'd;}' \
      "${0/rhdh-supported-plugins.sh/con-preinstalled-dynamic-plugins.template.adoc}" > "${0/rhdh-supported-plugins.sh/con-preinstalled-dynamic-plugins.adoc}"
}

# Call function if not skipped
if [[ $SKIP_TABLES -eq 0 ]]; then
    generate_dynamic_plugins_table
fi

# ============================================================================
# Generate ref-community-plugins-migration.adoc from rhdh-plugin-export-overlays
# ============================================================================
generate_migration_table() {
    if [[ ! -d "$overlaystmpdir" ]]; then
        echo -e "${red}[ERROR] Overlays repo not found: $overlaystmpdir${norm}"
        return 1
    fi

    echo -e "${green}Generating community plugins migration table from $overlaystmpdir (branch: $BRANCH)${norm}"

    MIGRATION_TABLE_FILE="/tmp/migration_table_${BRANCH}.txt"
    BUNDLED_PLUGINS_FILE="/tmp/bundled_plugins_${BRANCH}.txt"

    rm -f "$MIGRATION_TABLE_FILE" "$BUNDLED_PLUGINS_FILE"
    touch "$MIGRATION_TABLE_FILE" "$BUNDLED_PLUGINS_FILE"

    # Read the community packages list
    COMMUNITY_PACKAGES_FILE="$overlaystmpdir/rhdh-community-packages.txt"

    if [[ ! -f "$COMMUNITY_PACKAGES_FILE" ]]; then
        echo -e "${red}[ERROR] Community packages file not found: $COMMUNITY_PACKAGES_FILE${norm}"
        return 1
    fi

    migration_count=0

    # Track processed plugins to avoid duplicates using a temp file
    PROCESSED_PLUGINS_FILE="/tmp/processed_plugins_${BRANCH}.txt"
    rm -f "$PROCESSED_PLUGINS_FILE"
    touch "$PROCESSED_PLUGINS_FILE"

    # Process each line in the community packages file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Parse the workspace path (e.g., "jenkins/plugins/jenkins" or "gitlab/packages/gitlab")
        workspace_path="$line"

        # Extract workspace name (first part before /)
        workspace_name="${workspace_path%%/*}"

        # Find metadata files in this workspace
        metadata_dir="$overlaystmpdir/workspaces/$workspace_name/metadata"

        if [[ ! -d "$metadata_dir" ]]; then
            if [[ $QUIET -eq 0 ]]; then
                echo -e "${blue}[WARN] Metadata directory not found for workspace: $workspace_name${norm}"
            fi
            continue
        fi

        # Process each metadata YAML file in the workspace
        for metadata_file in "$metadata_dir"/*.yaml; do
            [[ ! -f "$metadata_file" ]] && continue

            # Extract data from the metadata file
            plugin_title=$(yq -r '.metadata.title // ""' "$metadata_file")
            plugin_name=$(yq -r '.metadata.name // ""' "$metadata_file")
            dynamic_artifact=$(yq -r '.spec.dynamicArtifact // ""' "$metadata_file")
            support=$(yq -r '.spec.support // "unknown"' "$metadata_file")

            # Skip if not a community plugin or no dynamic artifact
            [[ "$support" != "community" ]] && continue
            [[ -z "$dynamic_artifact" || "$dynamic_artifact" == "null" ]] && continue
            [[ "$dynamic_artifact" != "oci://ghcr.io"* ]] && continue

            # Skip if already processed (avoid duplicates)
            if grep -qF "$plugin_name" "$PROCESSED_PLUGINS_FILE" 2>/dev/null; then
                continue
            fi
            echo "$plugin_name" >> "$PROCESSED_PLUGINS_FILE"

            # Construct old path from plugin name
            old_path="./dynamic-plugins/dist/${plugin_name}"

            # Extract new path - get the base URL without the version/integrity part
            # Format: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-jenkins:bs_1.45.3__0.26.0!backstage-community-plugin-jenkins
            # We want: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-jenkins:<tag>
            # First remove everything after the ! (integrity hash), then remove the tag to get base
            artifact_without_hash="${dynamic_artifact%%!*}"
            new_path_base="${artifact_without_hash%:*}"
            new_path="${new_path_base}:<tag>"

            # Format title for display
            display_title="${plugin_title:-$plugin_name}"

            if [[ $QUIET -eq 0 ]]; then
                echo " * Migration: $display_title"
                echo "   Old: $old_path"
                echo "   New: $new_path"
            fi

            # Add to migration table (sorted by title)
            # shellcheck disable=SC2028
            echo "${display_title}||*${display_title}*\n|\`${old_path}\`\n|\`${new_path}\`" >> "$MIGRATION_TABLE_FILE"

            migration_count=$((migration_count + 1))
        done
    done < "$COMMUNITY_PACKAGES_FILE"

    # Cleanup processed plugins tracking file
    rm -f "$PROCESSED_PLUGINS_FILE"

    # Add known bundled plugins - these are hardcoded as they require manual tracking
    # These plugins continue to be bundled in 1.9 while transitioning to ghcr.io
    # Format matches migration table: Plugin Name | Old Path | New Path
    # shellcheck disable=SC2129
    echo -e "|*Quay*\n|\`./dynamic-plugins/dist/backstage-community-plugin-quay\`\n|\`oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-quay:<tag>\`\n" >> "$BUNDLED_PLUGINS_FILE"
    echo -e "|*Scaffolder Backend Module Quay*\n|\`./dynamic-plugins/dist/backstage-community-plugin-scaffolder-backend-module-quay-dynamic\`\n|\`oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-scaffolder-backend-module-quay:<tag>\`\n" >> "$BUNDLED_PLUGINS_FILE"
    echo -e "|*Tekton*\n|\`./dynamic-plugins/dist/backstage-community-plugin-tekton\`\n|\`oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/backstage-community-plugin-tekton:<tag>\`\n" >> "$BUNDLED_PLUGINS_FILE"
    echo -e "|*Scaffolder Backend ArgoCD*\n|\`./dynamic-plugins/dist/roadiehq-scaffolder-backend-argocd-dynamic\`\n|\`oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/roadiehq-scaffolder-backend-argocd:<tag>\`\n" >> "$BUNDLED_PLUGINS_FILE"
    echo -e "${green}Found $migration_count community plugins to migrate${norm}"

    # Sort the migration table by plugin title and format for adoc
    MIGRATION_TABLE_SORTED="/tmp/migration_table_sorted_${BRANCH}.txt"
    if [[ -f "$MIGRATION_TABLE_FILE" ]]; then
        sort -t '|' -k1,1 "$MIGRATION_TABLE_FILE" | while IFS='||' read -r key content; do
            echo -e "$content\n" >> "$MIGRATION_TABLE_SORTED"
        done
    fi

    # Generate the migration adoc file from template
    migration_template="${0/rhdh-supported-plugins.sh/ref-community-plugins-migration.template.adoc}"
    migration_output="${0/rhdh-supported-plugins.sh/ref-community-plugins-migration.adoc}"

    if [[ -f "$migration_template" ]]; then
        # Replace placeholders in template
        sed -e "/%%MIGRATION_TABLE%%/{r $MIGRATION_TABLE_SORTED" -e 'd;}' \
            -e "/%%BUNDLED_PLUGINS%%/{r $BUNDLED_PLUGINS_FILE" -e 'd;}' \
            -e "s/%%MIGRATION_COUNT%%/$migration_count/g" \
            "$migration_template" > "$migration_output"

        echo -e "${green}Generated $migration_output with $migration_count migrated plugins${norm}"
    else
        echo -e "${red}[ERROR] Migration template not found: $migration_template${norm}"
    fi

    # Cleanup temp files
    rm -f "$MIGRATION_TABLE_FILE" "$MIGRATION_TABLE_SORTED" "$BUNDLED_PLUGINS_FILE"
}

# Call function if not skipped
if [[ $SKIP_MIGRATION -eq 0 ]]; then
    generate_migration_table
fi

# summary of changes since last time
SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)
pushd "$SCRIPT_DIR" >/dev/null || exit
    updates=$(git diff "ref*plugins*.adoc" "con-preinstalled-dynamic-plugins.adoc" | grep -E -v "\+\+|@@" | grep "+")
    if [[ $updates ]]; then
        echo "$(echo "$updates" | wc -l) Changes include:"; echo "$updates"
    fi
popd >/dev/null || exit

# see https://issues.redhat.com/browse/RHIDP-3187 - only GA plugins should be enabled by default
if [[ -f "${ENABLED_PLUGINS}.errors" ]]; then echo;sort -u "${ENABLED_PLUGINS}.errors"; fi

# cleanup
rm -f "$ENABLED_PLUGINS" "${ENABLED_PLUGINS}.errors"
rm -rf "$TEMP_DIR"
# rm -fr "${rhdhtmpdir}"

warnings=$(grep -c "WARN" "/tmp/warnings_${BRANCH}.txt" 2>/dev/null || echo "0")
if [[ $warnings -gt 0 ]]; then
    echo; echo -e "${blue}[WARN] $warnings warnings collected in /tmp/warnings_${BRANCH}.txt ! Consider upgrading upstream project to newer plugin versions !${norm}"
fi
