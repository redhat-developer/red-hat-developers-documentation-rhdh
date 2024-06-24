#!/bin/bash

# script to generate rhdh-supported-plugins.adoc from content in 
# https://github.com/janus-idp/backstage-plugins/tree/main/plugins/ */package.json
# https://github.com/janus-idp/backstage-showcase/tree/main/dynamic-plugins/wrappers/ */json

# TODO generate rhdh-supported-plugins.json for consumption by other tools?

usage() {
  cat <<EOF
Generate updated table of dynamic plugins from content in janus-idp/backstage-plugins and backstage-showcase repos, 
for the specified branch

Requires:
* jq 1.6+

Usage:

$0 -b stable-ref-branch

Options:
  -b, --ref-branch    : Reference branch against which plugin versions should be incremented, like 1.1.x or main
  --clean             : Force a clean GH checkout (do not reuse files on disk)
  -h, --help          : Show this help

Examples:
  $0 -b 1.1.x

EOF
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    '--clean') rm -fr /tmp/backstage-plugins /tmp/backstage-showcase;;
    '-b'|'--ref-branch') BRANCH="$2"; shift 1;;        # reference branch, eg., 1.1.x 
    '-h'|'--help') usage;;
    *) echo "Unknown parameter used: $1."; usage; exit 1;;
  esac
  shift 1
done

if [[ ! $BRANCH ]]; then usage; exit 1; fi

# fetch GH repos
# TODO switch this to backstage/community-plugins
if [[ ! -d /tmp/backstage-plugins ]]; then
    pushd /tmp >/dev/null || exit
        git clone https://github.com/janus-idp/backstage-plugins --depth 1 -b "$BRANCH"
    popd >/dev/null || exit
fi

# TODO switch this to redhat-developer/rhdh
if [[ ! -d /tmp/backstage-showcase ]]; then
    pushd /tmp >/dev/null || exit
        git clone https://github.com/janus-idp/backstage-showcase --depth 1 -b "$BRANCH"
    popd >/dev/null || exit
fi

# thanks to https://stackoverflow.com/questions/42925485/making-a-script-that-transforms-sentences-to-title-case
# shellcheck disable=SC2048 disable=SC2086
titlecase() { 
    for f in ${*} ; do \
        case $f in 
            # UPPERCASE these exceptions
            aap|acr|cd|ocm|rbac) echo -n "${f^^} ";;
            # MixedCase exceptions
            argocd) echo -n "Argo CD ";;
            github) echo -n "GitHub ";;
            gitlab) echo -n "GitLab ";;
            jfrog) echo -n "JFrog ";;
            pagerduty) echo -n "PagerDuty ";;
            servicenow) echo -n "ServiceNow ";;
            sonarqube) echo -n "SonarQube ";;
            techdocs) echo -n "TechDocs ";;
            # Uppercase the first letter
            *) echo -n "${f^} " ;;
        esac;
    done; echo;
}

# process 2 folders of json files
declare -A adoc
jsons=$(find /tmp/backstage-showcase/dynamic-plugins/wrappers/ /tmp/backstage-plugins/plugins/ -maxdepth 2 -name package.json | sort -V)
c=0
tot=0
for j in $jsons; do 
    (( tot++ )) || true
done
for j in $jsons; do 
    (( c++ )) || true
    echo "[$c/$tot] Processing $j ..."
    Required_Variables=""
    Required_Variables_=""

    # extract content
    Name=$(jq -r '.name' "$j")
    Version=$(jq -r '.version' "$j")
    Role=$(jq -r '.backstage.role' "$j")

    # backstage-plugin-catalog-backend-module-bitbucket-cloud => @backstage/plugin-catalog-backend-module-bitbucket-cloud
    Plugin="${Name}"
    if [[ $Plugin != "@"* ]]; then # don't update janus-idp/backstage-plugins plugin names
        Plugin="$(echo "${Plugin}" | sed -r -e 's/([^-]+)-(.+)/\@\1\/\2/')"
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
    found_in_default_config1=$(yq -r --arg Path "${Path/-dynamic/}" '.plugins[] | select(.package == $Path)' /tmp/backstage-showcase/dynamic-plugins.default.yaml)
    # shellcheck disable=SC2016
    found_in_default_config2=$(yq -r --arg Path "${Path}" '.plugins[] | select(.package == $Path)' /tmp/backstage-showcase/dynamic-plugins.default.yaml)
    if [[ $found_in_default_config1 ]] || [[ $found_in_default_config2 ]] || [[ "$j" == *"/wrappers/"* ]]; then

        # default to community unless it's a RH-authored plugin
        Support_Level="Community Support"
        keywords=$(jq -r '.keywords' "$j")
        author=$(jq -r '.author' "$j")
        if [[ $author == "Red Hat" ]]; then 
            if [[ $keywords == *"support:production"* ]]; then
                Support_Level="Production"
            elif [[ $keywords == *"support:tech-preview"* ]]; then
                # mark Tech Preview wrappers as Community Supported
                if [[ "$j" != *"/wrappers/"* ]]; then 
                    Support_Level="Red Hat Tech Preview"
                fi
            fi
        fi

        # compute Default from dynamic-plugins.default.yaml
        # shellcheck disable=SC2016
        disabled=$(yq -r --arg Path "${Path/-dynamic/}" '.plugins[] | select(.package == $Path) | .disabled' /tmp/backstage-showcase/dynamic-plugins.default.yaml)
        # shellcheck disable=SC2016
        if [[ ! $disabled ]]; then disabled=$(yq -r --arg Path "${Path}" '.plugins[] | select(.package == $Path) | .disabled' /tmp/backstage-showcase/dynamic-plugins.default.yaml); fi
        # echo "Using Path = $Path got disabled = $disabled"
        # null or false == enabled by default
        Default="Enabled"; if [[ $disabled == "true" ]]; then Default="Disabled"; fi

        # compute Required_Variables from dynamic-plugins.default.yaml - look for all caps params
        # shellcheck disable=SC2016
        Required_Variables="$(yq -r --arg Path "${Path/-dynamic/}" '.plugins[] | select(.package == $Path)' /tmp/backstage-showcase/dynamic-plugins.default.yaml | grep "\${" | sed -r -e 's/.+: "\$\{(.+)\}".*/\1/')"
        if [[ ! $Required_Variables ]]; then Required_Variables="$(yq -r --arg Path "${Path}" '.plugins[] | select(.package == $Path)' /tmp/backstage-showcase/dynamic-plugins.default.yaml | grep "\${" | sed -r -e 's/.+: "\$\{(.+)\}".*/\1/')"; fi
        for RV in $Required_Variables; do 
            Required_Variables_="${Required_Variables_}\`$RV\`\n\n"
        done
        Required_Variables="${Required_Variables_}"
        # not currently used due to policy and support concern with upstream content linked from downstream doc
        # URL="https://www.npmjs.com/package/$Plugin" 

        # echo -n "Converting $Name"
        Name="$(echo "${Name}" | sed -r \
            -e "s@.+(-plugin-scaffolder-backend-module|backstage-scaffolder-backend-module)-(.+)@\2@g" \
            -e "s@.+(-plugin-catalog-module|-plugin-catalog-backend-module)-(.+)@\2@g" \
            -e "s@.+(-scaffolder-backend-module|-plugin-catalog-backend-module)-(.+)@\2@g" \
            -e "s@.+(-scaffolder-backend-module|-scaffolder-backend|backstage-plugin)-(.+)@\2@g" \
            -e "s@(backstage-plugin)-(.+)@\2@g" \
            -e "s@(.+)(-backstage-plugin)@\1@g" \
            -e "s@-backend@@g" \
        )"
        # echo " to $Name"
        PrettyName="$(titlecase "${Name//-/ }")"


        # useful console output
        for col in Name PrettyName Role Plugin Version Support_Level Path Required_Variables Default; do
            echo "Got $col = ${!col}"
        done

        # TODO could split out the front, back, and scaffolders into separate tables. Or split by support levels.

        # save in an array sorted by name, then role, with frontend before backend plugins (for consistency with 1.1 markup)
        RoleSort=1; if [[ $Role != *"front"* ]]; then RoleSort=2; Role="Backend"; else Role="Frontend"; fi
        if [[ $Plugin == *"scaffolder"* ]]; then RoleSort=3; fi

        # shellcheck disable=SC1087
        adoc["$Name-$RoleSort-$Role-$Plugin"]="|$PrettyName |$Plugin |$Role |$Version |$Support_Level\n|$Path\na|\n$Required_Variables|$Default\n"
    else
        (( tot-- )) || true
        echo "        Skip: not in backstage-showcase/dynamic-plugins.default.yaml !"
    fi
    echo
done

# markup content 2 ways, write to file
adocHeader=$(cat <<EOF
[id="rhdh-supported-plugins"]
= Preinstalled dynamic plugin descriptions and details

// This page is generated! Do not edit the .adoc file, but instead run rhdh-supported-plugins.sh to regen this page from the latest plugin metadata.
// cd /path/to/rhdh-documentation; ./modules/dynamic-plugins/rhdh-supported-plugins.sh; ./build/scripts/build.sh; google-chrome titles-generated/main/plugin-rhdh/index.html

[IMPORTANT]
====
Technology Preview features are not supported with Red Hat production service level agreements (SLAs), might not be functionally complete, and Red Hat does not recommend using them for production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.

For more information on Red Hat Technology Preview features, see https://access.redhat.com/support/offerings/techpreview/[Technology Preview Features Scope].

Additional detail on how Red Hat provides support for bundled community dynamic plugins is available on the https://access.redhat.com/policy/developerhub-support-policy[Red Hat Developer Support Policy] page.
====

There are $tot plugins available in {product}. See the following table for more information:

[dynamic-plugins-matrix]
.Dynamic plugins support matrix

[%header,cols=8*]
|===
|*Name* |*Plugin* |*Role* |*Version* |*Support Level*
|*Path* |*Required Variables* |*Default*
EOF
)

adocFooter=$(cat <<EOF
[NOTE]
====
* To configure Keycloak, see xref:rhdh-keycloak_{context}[Installation and configuration of Keycloak].

* To configure Techdocs, see http://backstage.io/docs/features/techdocs/configuration[reference documentation]. After experimenting with basic setup, use CI/CD to generate docs and an external cloud storage when deploying TechDocs for production use-case.
See also this https://backstage.io/docs/features/techdocs/how-to-guides#how-to-migrate-from-techdocs-basic-to-recommended-deployment-approach[recommended deployment approach].
====
EOF
)

# echo sorted by array keys - see above for how that's set up
sorted=()
while IFS= read -rd '' key; do
    sorted+=( "$key" )
done < <(printf '%s\0' "${!adoc[@]}" | sort -z)
# set up page header and open the table
echo -e "$adocHeader" > "${0/.sh/.adoc}"
for key in "${sorted[@]}"; do
    echo -e "${adoc[$key]}" >> "${0/.sh/.adoc}" 
done
# close the table
echo -e "|===" >> "${0/.sh/.adoc}" 

echo -e "$adocFooter" >> "${0/.sh/.adoc}" 

# cleanup
# rm -fr /tmp/backstage-plugins /tmp/backstage-showcase
