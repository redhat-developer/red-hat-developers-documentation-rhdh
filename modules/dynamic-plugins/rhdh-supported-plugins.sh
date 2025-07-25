#!/bin/bash

# script to generate rhdh-supported-plugins.adoc from content in
# https://github.com/redhat-developer/rhdh/tree/main/dynamic-plugins/wrappers/*/json

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)

norm="\033[0;39m"
green="\033[1;32m"
blue="\033[1;34m"
red="\033[1;31m"
QUIET=0

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
  -b, --ref-branch    : Reference branch against which plugin versions should be incremented, like release-1.y or main
  --clean             : Force a clean GH checkout (do not reuse files on disk)
  -q                  : quieter output
  -h, --help          : Show this help

Examples:

  $0 -b release-1.7 --clean

EOF
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--clean') rm -fr /tmp/plugin-versions.txt /tmp/rhdh;;
    '-b'|'--ref-branch') BRANCH="$2"; shift 1;;        # reference branch, eg., 1.1.x
    '-q') QUIET=1;;
    '-h'|'--help') usage;;
    *) echo "Unknown parameter used: $1."; usage; exit 1;;
  esac
  shift 1
done

if [[ ! $BRANCH ]]; then usage; exit 1; fi

# fetch GH repos
# TODO use metadata from https://github.com/redhat-developer/rhdh-plugin-export-overlays/tree/release-1.7/workspaces
if [[ ! -d /tmp/rhdh ]]; then
    pushd /tmp >/dev/null || exit
        git clone "$rhdhRepo" --depth 1 -b "$BRANCH" rhdh
    popd >/dev/null || exit
fi

# thanks to https://stackoverflow.com/questions/42925485/making-a-script-that-transforms-sentences-to-title-case
# shellcheck disable=SC2048 disable=SC2086
titlecase() {
    for f in ${*} ; do \
        case $f in
            aap) echo -n "Ansible Automation Platform (AAP) ";;
            # UPPERCASE these exceptions
            acr|cd|ocm|rbac) echo -n "${f^^} ";;
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
            *) echo -n "${f^} " ;;
        esac;
    done; echo;
}

# generate a list of plugin:version mapping from the following files
# * dynamic-plugins/imports/package.json#.peerDependencies or .dependencies
# * packages/app/package.json#.dependencies
# * packages/backend/package.json#.dependencies
pluginVersFile=/tmp/plugin-versions.txt
if [[ -f /tmp/rhdh/dynamic-plugins/imports/package.json ]]; then
    jq -r '.peerDependencies' /tmp/rhdh/dynamic-plugins/imports/package.json | grep -E -v "\"\*\"|\{|\}" | grep "@" | tr -d "," > $pluginVersFile
fi
jq -r '.dependencies' /tmp/rhdh/packages/{app,backend}/package.json | grep -E -v "\"\*\"|\{|\}" | grep "@" | tr -d "," >> $pluginVersFile
cat $pluginVersFile | sort -uV > $pluginVersFile.out; mv -f $pluginVersFile.out $pluginVersFile

rm -fr /tmp/warnings.txt

# create arrays of adoc and csv content
declare -A adoc1
declare -A adoc2
declare -A adoc3
declare -A csv

# process 1 folders of json files
jsons=$(find /tmp/rhdh/dynamic-plugins/wrappers/ -maxdepth 2 -name package.json | sort -V)
c=0
tot=0
for j in $jsons; do
    (( tot++ )) || true
done

# string listing the enabled-by-default plugins to add to con-preinstalled-dynamic-plugins.template.adoc
ENABLED_PLUGINS="/tmp/ENABLED_PLUGINS.txt"; rm -f $ENABLED_PLUGINS; touch $ENABLED_PLUGINS

for j in $jsons; do
    (( c++ )) || true
    echo -e "${green}[$c/$tot] Processing $j${norm}"
    Required_Variables=""
    Required_Variables_=""

    # extract content
    Name=$(jq -r '.name' "$j")

    # backstage-plugin-catalog-backend-module-bitbucket-cloud => @backstage/plugin-catalog-backend-module-bitbucket-cloud
    Plugin="${Name}"
    if [[ $Plugin != "@"* ]]; then # don't update janus-idp/backstage-plugins plugin names
        Plugin="$(echo "${Plugin}" | sed -r -e 's/([^-]+)-(.+)/\@\1\/\2/' \
            -e 's|janus/idp-|janus-idp/|' \
            -e 's|red/hat-developer-hub-|red-hat-developer-hub/|' \
            -e 's|backstage/community-|backstage-community/|' \
            -e 's|parfuemerie/douglas-|parfuemerie-douglas/|')"
    fi

    # "dynamic-plugins/wrappers/backstage-plugin-catalog-backend-module-bitbucket-cloud" ==> ./dynamic-plugins/dist/backstage-plugin-catalog-backend-module-bitbucket-cloud-dynamic
    Path=$(jq -r '.repository.directory' "$j")
    if [[ $Path == *"/wrappers/"* ]]; then
        Path="./${Path/wrappers/dist}-dynamic"
    else
        Path="$(echo "${Plugin/@/}" | tr "/" "-")"
        Path="./dynamic-plugins/dist/${Path}-dynamic"
    fi
    # remove dupe suffixes
    Path="${Path/-dynamic-dynamic/-dynamic}"

    # echo "Path = $Path"
    # shellcheck disable=SC2016
    found_in_default_config1=$(yq -r --arg Path "${Path%-dynamic}" '.plugins[] | select(.package == $Path)' /tmp/rhdh/dynamic-plugins.default.yaml)
    # shellcheck disable=SC2016
    found_in_default_config2=$(yq -r --arg Path "${Path}"           '.plugins[] | select(.package == $Path)' /tmp/rhdh/dynamic-plugins.default.yaml)
    # echo "[DEBUG] default configs:"
    # echo "   $found_in_default_config2" | jq -r '.package'
    # echo "   $found_in_default_config1" | jq -r '.package'
    # echo "   /wrappers/ == $j"

    Path2=$(echo "$found_in_default_config2" | jq -r '.package') # with -dynamic suffix
    if [[ $Path2 ]]; then
        Path=$Path2
        # echo "[DEBUG] check path - $Name :: got $Path2"
    else
        Path=$(echo "$found_in_default_config1" | jq -r '.package') # without -dynamic suffix
        # echo "[DEBUG] check path - $Name :: got $Path"
    fi
    if [[ ! $Path ]]; then
        continue
    elif [[ $Path ]] || [[ "$j" == *"/wrappers/"* ]]; then
        # RHIDP-3203 just use the .package value from /tmp/rhdh/dynamic-plugins.default.yaml as the Path
        Role=$(jq -r '.backstage.role' "$j")
        VersionJQ=$(jq -r '.version' "$j")
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
                echo -e "${blue}[WARN] ! Using $pluginVersFile version = $Version, not $VersionJQ from $Path ${norm}" | tee -a /tmp/warnings.txt
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
        latestXYRelease="$(echo "$allVersionsPublished" | grep -v -E -- "next|alpha|-" | grep -E "^${Version%.*}" | sort -uV | tail -1)"
        # echo "[DEBUG] Latest x.y version at https://registry.npmjs.org/${Plugin/\//%2f} : $latestXYRelease"
        if [[ "$latestXYRelease" != "$Version" ]]; then
            echo -e "${blue}[WARN] Can upgrade $Version to https://www.npmjs.com/package/$Plugin/v/$latestXYRelease ${norm}" | tee -a /tmp/warnings.txt
            # echo | tee -a /tmp/warnings.txt
        fi

        # default to community unless it's a RH-authored plugin
        Support_Level="Community Support"
        keywords=$(jq -r '.keywords' "$j")
        author=$(jq -r '.author' "$j")
        if [[ $author == "Red Hat" ]]; then
            if [[ $keywords == *"support:production"* ]]; then
                Support_Level="Production"
            elif [[ $keywords == *"support:tech-preview"* ]]; then
                Support_Level="Red Hat Tech Preview"
            fi
        fi

        # compute Default from dynamic-plugins.default.yaml
        # shellcheck disable=SC2016
        disabled=$(yq -r --arg Path "${Path/-dynamic/}" '.plugins[] | select(.package == $Path) | .disabled' /tmp/rhdh/dynamic-plugins.default.yaml)
        # shellcheck disable=SC2016
        if [[ ! $disabled ]]; then disabled=$(yq -r --arg Path "${Path}" '.plugins[] | select(.package == $Path) | .disabled' /tmp/rhdh/dynamic-plugins.default.yaml); fi
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

        # compute Required_Variables from dynamic-plugins.default.yaml - look for all caps params
        # shellcheck disable=SC2016
        Required_Variables="$(yq -r --arg Path "${Path/-dynamic/}" '.plugins[] | select(.package == $Path)' /tmp/rhdh/dynamic-plugins.default.yaml | grep "\${" | sed -r -e 's/.+: "\$\{(.+)\}".*/\1/')"
        if [[ ! $Required_Variables ]]; then Required_Variables="$(yq -r --arg Path "${Path}" '.plugins[] | select(.package == $Path)' /tmp/rhdh/dynamic-plugins.default.yaml | grep "\${" | sed -r -e 's/.+: "\$\{(.+)\}".*/\1/')"; fi
        for RV in $Required_Variables; do
            this_RV="$(echo "${RV}" | tr -d "\$\{\}\"")"
            Required_Variables_="${Required_Variables_}\`$this_RV\`\n\n"
        done
        Required_Variables="${Required_Variables_}"
        Required_Variables_CSV=$(echo -e "$Required_Variables" | tr -s "\n" ";")
        # not currently used due to policy and support concern with upstream content linked from downstream doc
        # URL="https://www.npmjs.com/package/$Plugin"

        # echo -n "Converting $Name"
        Name="$(echo "${Name}" | sed -r \
            -e "s@(pagerduty)-.+@\1@g" \
            -e "s@.+(-plugin-scaffolder-backend-module|backstage-scaffolder-backend-module)-(.+)@\2@g" \
            -e "s@.+(-plugin-catalog-module|-plugin-catalog-backend-module)-(.+)@\2@g" \
            -e "s@.+(-scaffolder-backend-module|-plugin-catalog-backend-module)-(.+)@\2@g" \
            -e "s@.+(-scaffolder-backend-module|-scaffolder-backend|backstage-plugin)-(.+)@\2@g" \
            -e "s@(backstage-community-plugin-)@@g" \
            -e "s@(backstage-plugin)-(.+)@\2@g" \
            -e "s@(.+)(-backstage-plugin)@\1@g" \
            -e "s@-backend@@g" \
        )"
        Name="$(echo "${Name}" | sed -r -e "s/redhat-(.+)/\1-\(Red-Hat\)/")"
        PrettyName="$(titlecase "${Name//-/ }")"
        # echo " to $Name and $PrettyName"

        # useful console output
        if [[ $QUIET -eq 0 ]]; then
          for col in Name PrettyName Role Plugin Version Support_Level Path Required_Variables Default; do
              echo " * $col = ${!col}"
          done
        fi

        # save in an array sorted by name, then role, with frontend before backend plugins (for consistency with 1.1 markup)
        RoleSort=1; if [[ $Role != *"front"* ]]; then RoleSort=2; Role="Backend"; else Role="Frontend"; fi
        if [[ $Plugin == *"scaffolder"* ]]; then RoleSort=3; fi

        # TODO include missing data fields for Provider and Description - see https://issues.redhat.com/browse/RHIDP-3496 and https://issues.redhat.com/browse/RHIDP-3440

        # split into three tables based on support level
        if [[ ${Support_Level} == "Production" ]]; then
            adoc1["$Name-$RoleSort-$Role-$Plugin"]="|$PrettyName |\`https://npmjs.com/package/$Plugin/v/$Version[$Plugin]\` |$Version \n|\`$Path\`\n\n$Required_Variables"
        elif [[ ${Support_Level} == "Red Hat Tech Preview" ]]; then
            adoc2["$Name-$RoleSort-$Role-$Plugin"]="|$PrettyName |\`https://npmjs.com/package/$Plugin/v/$Version[$Plugin]\` |$Version \n|\`$Path\`\n\n$Required_Variables"
        else
            adoc3["$Name-$RoleSort-$Role-$Plugin"]="|$PrettyName |\`https://npmjs.com/package/$Plugin/v/$Version[$Plugin]\` |$Version \n|\`$Path\`\n\n$Required_Variables"
        fi

        # NOTE: csv is not split into separate tables at this point
        csv["$Name-$RoleSort-$Role-$Plugin"]="\"$PrettyName\",\"$Plugin\",\"$Role\",\"$Version\",\"$Support_Level\",\"$Path\",\"${Required_Variables_CSV}\",\"$Default\""
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
echo -e "\"Name\",\"Plugin\",\"Role\",\"Version\",\"Support Level\",\"Path\",\"Required Variables\",\"Default\"" > "${0/.sh/.csv}"

num_plugins=()
# append to .csv and .adocN files
rm -f "${0/.sh/.adoc1}"
sorted=(); while IFS= read -rd '' key; do sorted+=( "$key" ); done < <(printf '%s\0' "${!adoc1[@]}" | sort -z)
if [[ $sorted ]] ;then
  for key in "${sorted[@]}"; do
      (( c = c + 1 ))
      if [[ $QUIET -eq 0 ]]; then echo " * [$c] $key [ supported-plugins ] = ${csv[$key]}"; fi
      echo -e "${adoc1[$key]}" >> "${0/.sh/.ref-rh-supported-plugins}"
      # RHIDP-4196 omit techdocs plugins from the .csv
      if [[ $key != *"techdocs"* ]]; then
        echo -e "${csv[$key]}" >>  "${0/.sh/.csv}"
      else
        if [[ $QUIET -eq 0 ]]; then echo -e "${blue}   [WARN] Omit plugin $key from .csv file${norm}"; fi
      fi
  done
fi
num_plugins+=(${#adoc1[@]})

rm -f "${0/.sh/.adoc2}"
sorted=(); while IFS= read -rd '' key; do sorted+=( "$key" ); done < <(printf '%s\0' "${!adoc2[@]}" | sort -z)
# shellcheck disable=SC2128
if [[ $sorted ]] ;then
    for key in "${sorted[@]}"; do
      (( c = c + 1 ))
      if [[ $QUIET -eq 0 ]]; then echo " * [$c] $key [ tech-preview-plugins ] = ${csv[$key]}"; fi
      echo -e "${adoc2[$key]}" >> "${0/.sh/.ref-rh-tech-preview-plugins}";
      echo -e "${csv[$key]}" >>  "${0/.sh/.csv}"
    done
fi
num_plugins+=(${#adoc2[@]})

rm -f "${0/.sh/.adoc3}"
sorted=(); while IFS= read -rd '' key; do sorted+=( "$key" ); done < <(printf '%s\0' "${!adoc3[@]}" | sort -z)
# shellcheck disable=SC2128
if [[ $sorted ]] ;then
    for key in "${sorted[@]}"; do
      (( c = c + 1 ))
      if [[ $QUIET -eq 0 ]]; then echo " * [$c] $key [ community-plugins ] = ${csv[$key]}"; fi
      echo -e "${adoc3[$key]}" >> "${0/.sh/.ref-community-plugins}";
      echo -e "${csv[$key]}" >>  "${0/.sh/.csv}"
    done
fi
num_plugins+=(${#adoc3[@]})

if [[ $QUIET -eq 0 ]]; then echo; fi

# merge the content from the three .adocX files into the .template.adoc file, replacing the TABLE_CONTENT markers
count=1
index=0
for d in ref-rh-supported-plugins ref-rh-tech-preview-plugins ref-community-plugins; do
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
# rm -fr /tmp/rhdh

warnings=$(grep -c "WARN" "/tmp/warnings.txt")
if [[ $warnings -gt 0 ]]; then
    echo; echo -e "${blue}[WARN] $warnings warnings collected in /tmp/warnings.txt ! Consider upgrading upstream project to newer plugin versions !${norm}"
fi
