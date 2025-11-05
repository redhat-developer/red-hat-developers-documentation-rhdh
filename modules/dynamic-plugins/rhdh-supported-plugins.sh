#!/bin/bash

# Set consistent locale for sorting across different systems
export LC_ALL=C

# script to generate rhdh-supported-plugins.adoc from content in
# https://github.com/redhat-developer/rhdh/tree/main/catalog-entities/marketplace/packages/

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

norm="\033[0;39m"
green="\033[1;32m"
blue="\033[1;34m"
red="\033[1;31m"
QUIET=0
DO_CLEAN=0

BRANCH=main

rhdhRepo="https://github.com/redhat-developer/rhdh"
usage() {
  cat <<EOF

Generate an updated table of dynamic plugins from content in the following two repos, for the specified branch:
* $rhdhRepo

Requires:
* jq 1.6+
* yq from https://pypi.org/project/yq/ - not the mikefarah version

Usage:

$0 -b stable-ref-branch

Options:
  -b, --ref-branch    : Branch against which plugin versions should be incremented, like release-1.y; default: main
  --clean             : Force a clean GH checkout (do not reuse files on disk)
  -q                  : quieter output
  -h, --help          : Show this help

Examples:

  $0 -b release-1.8 --clean

EOF
}

tmpdir="/tmp/rhdh_$BRANCH"

if [[ "$#" -lt 1 ]]; then usage; exit 1; fi

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--clean') DO_CLEAN=1;;
    '-b'|'--ref-branch') BRANCH="$2" tmpdir="/tmp/rhdh_$BRANCH"; shift 1;;        # reference branch, eg., 1.1.x
    '-q') QUIET=1;;
    '-h'|'--help') usage;;
    *) echo "Unknown parameter used: $1."; usage; exit 1;;
  esac
  shift 1
done

if [[ ! $BRANCH ]]; then usage; exit 1; fi

if [[ $DO_CLEAN -eq 1 ]]; then
    rm -fr /tmp/plugin-versions_"${BRANCH}".txt "${tmpdir}"
fi

# fetch GH repos
# TODO use metadata from https://github.com/redhat-developer/rhdh-plugin-export-overlays/tree/release-1.7/workspaces
if [[ ! -d "$tmpdir" ]]; then
    pushd /tmp >/dev/null || exit
        git clone "$rhdhRepo" --depth 1 -b "$BRANCH" "rhdh_$BRANCH"
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

# generate a list of plugin:version mapping from the following files
# * dynamic-plugins/imports/package.json#.peerDependencies or .dependencies
# * packages/app/package.json#.dependencies
# * packages/backend/package.json#.dependencies
pluginVersFile=/tmp/plugin-versions_"${BRANCH}".txt
if [[ -f "${tmpdir}"/dynamic-plugins/imports/package.json ]]; then
    jq -r '.peerDependencies' "${tmpdir}"/dynamic-plugins/imports/package.json | grep -E -v "\"\*\"|\{|\}" | grep "@" | tr -d "," > "$pluginVersFile"
fi
jq -r '.dependencies' "${tmpdir}"/packages/{app,backend}/package.json | grep -E -v "\"\*\"|\{|\}" | grep "@" | tr -d "," >> "$pluginVersFile"
# Use LC_ALL=C for consistent sorting across different locales
cat "$pluginVersFile" | sort -u > "$pluginVersFile".out; mv -f "$pluginVersFile".out "$pluginVersFile"

rm -fr /tmp/warnings_"${BRANCH}".txt

# create temporary files instead of associative arrays
TEMP_DIR="/tmp/rhdh-processing_${BRANCH}"
mkdir -p "$TEMP_DIR"
rm -f "$TEMP_DIR"/*.tmp

# process YAML files from catalog-entities/marketplace/packages/
yamls=$(find "${tmpdir}"/catalog-entities/marketplace/packages/ -maxdepth 1 -name "*.yaml" | sort)
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
    Required_Variables_=""

    # extract content from YAML
    Name=$(yq -r '.metadata.name' "$y")
    Plugin_Title=$(yq -r '.metadata.title' "$y")
    
    # Use .spec.packageName, or if not set use .metadata.name
    Plugin=$(yq -r '.spec.packageName // .metadata.name' "$y")
    
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

    # Filter 1: Only dynamic plugin artifacts under dist root (frontend or backend) or @redhat NRRC registry
    # Accept both patterns:
    #  - Frontend: ./dynamic-plugins/dist/<name>
    #  - Backend:  ./dynamic-plugins/dist/<name>-dynamic
    #  - NRRC registry: @redhat/<package>@version
    #  this change was made since FE plugins were not being included in the .csv file
    [[ $Path == ./dynamic-plugins/dist/* ]] || [[ $Path == "@redhat"* ]] || continue
    
    # Filter 2: Exclude oci:// paths
    [[ $Path == "oci://"* ]] && continue
    
    # Filter 3: Handle @redhat packages - exclude unless they have dynamicArtifact from NRRC registry
    if [[ $Plugin == "@redhat"* ]] && [[ $(yq -r '.spec.dynamicArtifact // ""' "$y") != "@redhat"* ]]; then
        continue
    else
        # shellcheck disable=SC2016
        found_in_default_config1=$(yq -r --arg Path "${Path%-dynamic}" '.plugins[] | select(.package == $Path)' "${tmpdir}"/dynamic-plugins.default.yaml)
        # shellcheck disable=SC2016
        found_in_default_config2=$(yq -r --arg Path "${Path}"           '.plugins[] | select(.package == $Path)' "${tmpdir}"/dynamic-plugins.default.yaml)

        Path2=$(echo "$found_in_default_config2" | jq -r '.package') # with -dynamic suffix
        if [[ $Path2 ]]; then
            Path=$Path2
        else
            Path=$(echo "$found_in_default_config1" | jq -r '.package') # without -dynamic suffix
        fi
    fi
    
    # For marketplace YAML files, skip the default config check for inclusion
    if [[ "$y" == *"catalog-entities/marketplace/packages/"* ]]; then
        # Process marketplace packages regardless of default config
        if [[ $QUIET -eq 0 ]]; then echo "Processing marketplace package: $Name"; fi
    elif [[ ! $Path ]]; then
        continue
    fi
    
    if [[ $Path ]] || [[ "$y" == *"catalog-entities/marketplace/packages/"* ]]; then
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
            if [[ $support == "production"* ]]; then
                Support_Level="Production"
            elif [[ $support == "tech-preview"* ]]; then
                Support_Level="Red Hat Tech Preview"
            fi
        fi

        # compute Default from dynamic-plugins.default.yaml
        # shellcheck disable=SC2016
        disabled=$(yq -r --arg Path "${Path/-dynamic/}" '.plugins[] | select(.package == $Path) | .disabled' "${tmpdir}"/dynamic-plugins.default.yaml)
        # shellcheck disable=SC2016
        if [[ ! $disabled ]]; then disabled=$(yq -r --arg Path "${Path}" '.plugins[] | select(.package == $Path) | .disabled' "${tmpdir}"/dynamic-plugins.default.yaml); fi
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
              echo " * $col = ${!col}"
          done
        fi

        # save in an array sorted by name, then role, with frontend before backend plugins (for consistency with 1.1 markup)
        RoleSort=1; if [[ $Role != *"front"* ]]; then RoleSort=2; Role="Backend"; else Role="Frontend"; fi
        if [[ $Plugin == *"scaffolder"* ]]; then RoleSort=3; fi

        # TODO include missing data fields for Provider and Description - see https://issues.redhat.com/browse/RHIDP-3496 and https://issues.redhat.com/browse/RHIDP-3440

        # Use temporary files to allow sorting later
        key="$Name-$RoleSort-$Role-$Plugin"
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
if [[ $QUIET -eq 0 ]]; then
  echo "Creating .csv ..."
fi

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
        if [[ $QUIET -eq 0 ]]; then echo " * [$count] $key [ ${out_file##*/} ]"; fi
        echo -e "$content" >> "$out_file"
    done
    count=$(wc -l < "$temp_file")
fi
num_plugins+=($count)

# 2) Tech Preview
temp_file="$TEMP_DIR/adoc.tech-preview.tmp"
out_file="${0/.sh/.ref-rh-tech-preview-plugins}"
rm -f "$out_file"
count=0
if [[ -f "$temp_file" ]]; then
    sort "$temp_file" | while IFS='|' read -r key content; do
        (( count = count + 1 ))
        if [[ $QUIET -eq 0 ]]; then echo " * [$count] $key [ ${out_file##*/} ]"; fi
        echo -e "$content" >> "$out_file"
    done
    count=$(wc -l < "$temp_file")
fi
num_plugins+=($count)

# 3) Community
temp_file="$TEMP_DIR/adoc.community.tmp"
out_file="${0/.sh/.ref-community-plugins}"
rm -f "$out_file"
count=0
if [[ -f "$temp_file" ]]; then
    sort "$temp_file" | while IFS='|' read -r key content; do
        (( count = count + 1 ))
        if [[ $QUIET -eq 0 ]]; then echo " * [$count] $key [ ${out_file##*/} ]"; fi
        echo -e "$content" >> "$out_file"
    done
    count=$(wc -l < "$temp_file")
fi
num_plugins+=($count)

# 3) Deprecated
temp_file="$TEMP_DIR/adoc.deprecated.tmp"
out_file="${0/.sh/.ref-deprecated-plugins}"
rm -f "$out_file"
count=0
if [[ -f "$temp_file" ]]; then
    sort "$temp_file" | while IFS='|' read -r key content; do
        (( count = count + 1 ))
        if [[ $QUIET -eq 0 ]]; then echo " * [$count] $key [ ${out_file##*/} ]"; fi
        echo -e "$content" >> "$out_file"
    done
    count=$(wc -l < "$temp_file")
fi
num_plugins+=($count)

# Process CSV: sort by SupportSort (1,2,3,4) then PrettyName, and omit techdocs
if [[ -f "$TEMP_DIR/csv.tmp" ]]; then
    sort -t '|' -k1,1 -k2,2 "$TEMP_DIR/csv.tmp" | while IFS='|' read -r key content; do
        # RHIDP-4196 omit techdocs plugins from the .csv
        if [[ $key != *"techdocs"* ]]; then
            echo -e "$content" >> "${0/.sh/.csv}"
        else
            if [[ $QUIET -eq 0 ]]; then echo -e "${blue}   [WARN] Omit plugin $key from .csv file${norm}"; fi
        fi
    done
fi

if [[ $QUIET -eq 0 ]]; then echo; fi

# merge the content from the 4 .adocX files into the .template.adoc file, replacing the TABLE_CONTENT markers
count=1
index=0
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
      echo "" > "${0/rhdh-supported-plugins.sh/${d}.adoc}"
    fi
    (( count = count + 1 ))
done

# inject ENABLED_PLUGINS into con-preinstalled-dynamic-plugins.template.adoc
sed -e "/%%ENABLED_PLUGINS%%/{r $ENABLED_PLUGINS" -e 'd;}' \
    "${0/rhdh-supported-plugins.sh/con-preinstalled-dynamic-plugins.template.adoc}" > "${0/rhdh-supported-plugins.sh/con-preinstalled-dynamic-plugins.adoc}"

# summary of changes since last time
SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)
pushd "$SCRIPT_DIR" >/dev/null || exit
    updates=$(git diff "ref*plugins.adoc"| grep -E -v "\+\+|@@" | grep "+")
    if [[ $updates ]]; then
        echo "$(echo "$updates" | wc -l) Changes include:"; echo "$updates"
    fi
popd >/dev/null || exit

# see https://issues.redhat.com/browse/RHIDP-3187 - only GA plugins should be enabled by default
if [[ -f "${ENABLED_PLUGINS}.errors" ]]; then echo;cat "${ENABLED_PLUGINS}.errors"; fi

# cleanup
rm -f "$ENABLED_PLUGINS" "${ENABLED_PLUGINS}.errors"
rm -rf "$TEMP_DIR"
# rm -fr "${tmpdir}"

warnings=$(grep -c "WARN" "/tmp/warnings_${BRANCH}.txt" 2>/dev/null || echo "0")
if [[ $warnings -gt 0 ]]; then
    echo; echo -e "${blue}[WARN] $warnings warnings collected in /tmp/warnings_${BRANCH}.txt ! Consider upgrading upstream project to newer plugin versions !${norm}"
fi
