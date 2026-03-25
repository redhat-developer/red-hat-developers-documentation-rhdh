#!/bin/bash
# cqa-10-titles-are-brief-complete-and-descriptive.sh
# Aligns title, ID, context, and filename per CQA rules (CQA-10)
#
# Usage: ./cqa-10-titles-are-brief-complete-and-descriptive.sh [--fix] [--all] <file-path>
#
# Autofix:
#   - Converts gerund titles to imperative (160+ rules)
#   - Updates IDs and context to match title
#   - Renames files via git mv
#   - Updates all xrefs and include statements

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"
cqa_parse_args "$0" "$@"

# shellcheck disable=SC2034
CQA_DELEGATES_TO=("DocumentId:10")

# shellcheck disable=SC2329
gerund_to_imperative() {
    local word="$1"
    local lower
    lower=$(echo "$word" | tr '[:upper:]' '[:lower:]')
    local stem="${lower%ing}"
    local result=""

    case "$lower" in
        running) result="run" ;; setting) result="set" ;; getting) result="get" ;;
        putting) result="put" ;; cutting) result="cut" ;; stopping) result="stop" ;;
        dropping) result="drop" ;; mapping) result="map" ;; planning) result="plan" ;;
        scanning) result="scan" ;; shipping) result="ship" ;; shopping) result="shop" ;;
        skipping) result="skip" ;; snapping) result="snap" ;; spinning) result="spin" ;;
        splitting) result="split" ;; stepping) result="step" ;; stripping) result="strip" ;;
        swapping) result="swap" ;; tapping) result="tap" ;; trimming) result="trim" ;;
        wrapping) result="wrap" ;; beginning) result="begin" ;;
        configuring) result="configure" ;; creating) result="create" ;;
        enabling) result="enable" ;; disabling) result="disable" ;;
        managing) result="manage" ;; upgrading) result="upgrade" ;;
        updating) result="update" ;; removing) result="remove" ;;
        deleting) result="delete" ;; editing) result="edit" ;;
        resolving) result="resolve" ;; authorizing) result="authorize" ;;
        validating) result="validate" ;; customizing) result="customize" ;;
        integrating) result="integrate" ;; migrating) result="migrate" ;;
        generating) result="generate" ;; defining) result="define" ;;
        overriding) result="override" ;; retrieving) result="retrieve" ;;
        preparing) result="prepare" ;; scaling) result="scale" ;;
        securing) result="secure" ;; authenticating) result="authenticate" ;;
        automating) result="automate" ;; bootstrapping) result="bootstrap" ;;
        restoring) result="restore" ;; replacing) result="replace" ;;
        browsing) result="browse" ;; closing) result="close" ;;
        composing) result="compose" ;; describing) result="describe" ;;
        ensuring) result="ensure" ;; using) result="use" ;;
        including) result="include" ;; invoking) result="invoke" ;;
        providing) result="provide" ;; producing) result="produce" ;;
        reducing) result="reduce" ;; releasing) result="release" ;;
        requiring) result="require" ;; subscribing) result="subscribe" ;;
        changing) result="change" ;; locating) result="locate" ;;
        navigating) result="navigate" ;; operating) result="operate" ;;
        isolating) result="isolate" ;; installing) result="install" ;;
        deploying) result="deploy" ;; building) result="build" ;;
        adding) result="add" ;; testing) result="test" ;;
        monitoring) result="monitor" ;; checking) result="check" ;;
        importing) result="import" ;; exporting) result="export" ;;
        connecting) result="connect" ;; disconnecting) result="disconnect" ;;
        adjusting) result="adjust" ;; restarting) result="restart" ;;
        starting) result="start" ;; registering) result="register" ;;
        unregistering) result="unregister" ;; assigning) result="assign" ;;
        reviewing) result="review" ;; accessing) result="access" ;;
        fetching) result="fetch" ;; searching) result="search" ;;
        finding) result="find" ;; provisioning) result="provision" ;;
        encrypting) result="encrypt" ;; mounting) result="mount" ;;
        unmounting) result="unmount" ;; attaching) result="attach" ;;
        detaching) result="detach" ;; extending) result="extend" ;;
        limiting) result="limit" ;; inspecting) result="inspect" ;;
        triggering) result="trigger" ;; troubleshooting) result="troubleshoot" ;;
        understanding) result="understand" ;; publishing) result="publish" ;;
        selecting) result="select" ;; tracking) result="track" ;;
        transforming) result="transform" ;; viewing) result="view" ;;
        verifying) result="verify" ;; modifying) result="modify" ;;
        specifying) result="specify" ;; applying) result="apply" ;;
        *)
            local last_two="${stem: -2}"
            if [[ ${#stem} -ge 3 ]] && [[ "${last_two:0:1}" == "${last_two:1:1}" ]] && \
               [[ "${last_two:0:1}" =~ [bcdfghjkmnpqrtvwxyz] ]]; then
                result="${stem%?}"
            elif [[ "$stem" =~ [v]$ ]]; then
                result="${stem}e"
            elif [[ "$stem" =~ [aeiou]z$ ]]; then
                result="${stem}e"
            elif [[ "$stem" =~ [aeiou]c$ ]]; then
                result="${stem}e"
            else
                result="$stem"
            fi
            ;;
    esac

    if [[ "$word" =~ ^[A-Z] ]]; then
        result="$(echo "${result:0:1}" | tr '[:lower:]' '[:upper:]')${result:1}"
    fi
    echo "$result"
}

# shellcheck disable=SC2329  # Helper functions invoked from _cqa10_check/_process_file
_resolve_attribute() {
    local attr_name="$1"
    local search_file="$2"
    local attr_value=""
    if [[ -f "$search_file" ]]; then
        attr_value=$(grep "^:${attr_name}:" "$search_file" 2>/dev/null | head -1 | sed "s/^:${attr_name}:[[:space:]]*//" | sed 's/[[:space:]]*$//')
    fi
    if [[ -z "$attr_value" ]] && [[ -f "artifacts/attributes.adoc" ]]; then
        attr_value=$(grep "^:${attr_name}:" "artifacts/attributes.adoc" 2>/dev/null | head -1 | sed "s/^:${attr_name}:[[:space:]]*//" | sed 's/[[:space:]]*$//')
    fi
    echo "${attr_value:-$attr_name}"
}

# shellcheck disable=SC2329
_expand_attributes() {
    local input="$1"
    local search_file="$2"
    local output="$input"
    while [[ "$output" =~ \{([^}]+)\} ]]; do
        local attr_name="${BASH_REMATCH[1]}"
        local attr_value
        attr_value=$(_resolve_attribute "$attr_name" "$search_file")
        output="${output//\{$attr_name\}/$attr_value}"
    done
    echo "$output"
}

# shellcheck disable=SC2329
_title_to_id_form() {
    local title="$1"
    echo "$title" | \
        sed 's/{product-very-short}/rhdh/g' | sed 's/{product-short}/rhdh/g' | \
        sed 's/{product}/rhdh/g' | sed 's/{product-custom-resource-type}//g' | \
        sed 's/{rhbk-brand-name}/rhbk/g' | sed 's/{rhbk}/rhbk/g' | \
        sed 's/{azure-brand-name}/microsoft-azure/g' | \
        sed 's/{ocp-brand-name}/ocp/g' | sed 's/{ocp-short}/ocp/g' | \
        sed 's/{technology-preview}/technology-preview/g' | \
        sed 's/{developer-preview}/developer-preview/g' | \
        sed 's/{[^}]*}//g'
}

# shellcheck disable=SC2329
_process_file() {
    local FILE="$1"

    local CONTENT_TYPE
    CONTENT_TYPE=$(cqa_get_content_type "$FILE")
    if [[ -z "$CONTENT_TYPE" ]]; then
        cqa_delegated "$FILE" "" "3" "No content type metadata -- run CQA-3 first"
        return 0
    fi

    local PREFIX MODULE_TYPE EXPECTED_FORM
    case "$CONTENT_TYPE" in
        PROCEDURE)  PREFIX="proc-"; MODULE_TYPE="PROCEDURE"; EXPECTED_FORM="imperative" ;;
        CONCEPT)    PREFIX="con-"; MODULE_TYPE="CONCEPT"; EXPECTED_FORM="noun phrase" ;;
        REFERENCE)  PREFIX="ref-"; MODULE_TYPE="REFERENCE"; EXPECTED_FORM="noun phrase" ;;
        ASSEMBLY)
            PREFIX="assembly-"; MODULE_TYPE="ASSEMBLY"
            if grep -q "include::.*proc-.*\.adoc" "$FILE"; then
                EXPECTED_FORM="imperative"
            else
                EXPECTED_FORM="noun phrase"
            fi
            ;;
        SNIPPET)
            # Snippets: validate no title
            local snippet_title
            snippet_title=$(grep "^= " "$FILE" | head -1 | sed 's/^= //')
            if [[ -n "$snippet_title" ]]; then
                cqa_fail_manual "$FILE" "" "Snippet has a title '= ${snippet_title}' -- snippets must not have titles"
            else
                cqa_file_pass "$FILE"
            fi
            return 0
            ;;
        *) return 0 ;;
    esac

    local WILL_CHANGE=false

    # Extract title
    local TITLE_RAW
    TITLE_RAW=$(grep "^= " "$FILE" | head -1 | sed 's/^= //')
    if [[ -z "$TITLE_RAW" ]]; then
        cqa_fail_manual "$FILE" "" "No title found (looking for '= Title')"
        return 0
    fi

    local TITLE
    TITLE=$(_expand_attributes "$TITLE_RAW" "$FILE")

    # Check title form
    local FIXED_TITLE="$TITLE" FIXED_TITLE_RAW="$TITLE_RAW" TITLE_CHANGED=false
    if [[ "$EXPECTED_FORM" == "imperative" ]]; then
        local FIRST_WORD
        FIRST_WORD=$(echo "$TITLE" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]].*//')
        if [[ "$FIRST_WORD" =~ ing$ ]] && [[ ! "$FIRST_WORD" =~ ^\{.*\}$ ]]; then
            local IMPERATIVE_WORD
            IMPERATIVE_WORD=$(gerund_to_imperative "$FIRST_WORD")
            FIXED_TITLE="${IMPERATIVE_WORD}${TITLE#"$FIRST_WORD"}"
            FIXED_TITLE_RAW="${IMPERATIVE_WORD}${TITLE_RAW#"$FIRST_WORD"}"
            TITLE_CHANGED=true; WILL_CHANGE=true; TITLE="$FIXED_TITLE"
        fi

        # Fix additional gerunds after "and"
        while [[ "$FIXED_TITLE" =~ (.*[[:space:]]and[[:space:]])([A-Za-z]+ing)([[:space:]].*)$ ]]; do
            local GERUND="${BASH_REMATCH[2]}"
            local IMPERATIVE
            IMPERATIVE=$(gerund_to_imperative "$GERUND")
            FIXED_TITLE="${BASH_REMATCH[1]}${IMPERATIVE}${BASH_REMATCH[3]}"
            FIXED_TITLE_RAW="${FIXED_TITLE_RAW//"$GERUND"/"$IMPERATIVE"}"
            TITLE_CHANGED=true; WILL_CHANGE=true
        done
        TITLE="$FIXED_TITLE"
    fi

    # Extract current ID
    local CURRENT_ID
    CURRENT_ID=$(grep "\[id=" "$FILE" | head -1 | sed 's/.*\[id="//;s/.*\[id='"'"'//' | sed 's/["'"'"'\]]*$//' | sed 's/_{context}.*//' | sed 's/_.*//')

    # Expected ID from title
    local TITLE_FOR_ID
    TITLE_FOR_ID=$(_title_to_id_form "$FIXED_TITLE_RAW")
    local EXPECTED_ID
    EXPECTED_ID=$(echo "$TITLE_FOR_ID" | \
        tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | \
        sed 's/--*/-/g' | sed 's/^-//;s/-$//' | \
        sed 's/\brhdh-rhdh\b/rhdh/g' | sed 's/\brhbk-rhbk\b/rhbk/g' | sed 's/\bocp-ocp\b/ocp/g')

    local EXPECTED_FILENAME="${PREFIX}${EXPECTED_ID}.adoc"
    local NEW_FILE
    NEW_FILE="$(dirname "$FILE")/$EXPECTED_FILENAME"

    if [[ "$CURRENT_ID" != "$EXPECTED_ID" ]] || [[ "$FILE" != "$NEW_FILE" ]]; then
        WILL_CHANGE=true
    fi

    if [[ "$WILL_CHANGE" == false ]]; then
        cqa_file_pass "$FILE"
        return 0
    fi

    cqa_file_start "$FILE"

    # Report/apply title change
    if [[ "$TITLE_CHANGED" == true ]]; then
        local OLD_TITLE
        OLD_TITLE=$(grep "^= " "$FILE" | head -1 | sed 's/^= //')
        if [[ "$CQA_FIX_MODE" == true ]]; then
            sed -i.bak "s/^= ${OLD_TITLE}/= ${FIXED_TITLE_RAW}/" "$FILE"
            rm -f "${FILE}.bak"
        fi
        cqa_fail_autofix "$FILE" "" "Title: ${OLD_TITLE} -> ${FIXED_TITLE_RAW}" "Changed title to imperative"
    fi

    # Report/apply ID change
    if [[ "$CURRENT_ID" != "$EXPECTED_ID" ]]; then
        if [[ "$CQA_FIX_MODE" == true ]]; then
            sed -i.bak "s/\[id=\"[^\"]*_{context}\"\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
            sed -i.bak "s/\[id='[^']*_{context}'\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
            sed -i.bak "s/\[id=\"${CURRENT_ID}\"\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
            sed -i.bak "s/\[id='${CURRENT_ID}'\]/[id=\"${EXPECTED_ID}_{context}\"]/" "$FILE"
            if [[ "$MODULE_TYPE" == "ASSEMBLY" ]]; then
                sed -i.bak "s/^:context: .*$/:context: ${EXPECTED_ID}/" "$FILE"
            fi
            rm -f "${FILE}.bak"

            # Update xrefs
            local xref_count=0
            while read -r xref_file; do
                sed -i.bak "s/xref:${CURRENT_ID}_/xref:${EXPECTED_ID}_/g" "$xref_file"
                rm -f "${xref_file}.bak"
                xref_count=$((xref_count + 1))
            done < <(grep -rl "xref:${CURRENT_ID}_" assemblies/ modules/ titles/ 2>/dev/null || true)
        fi
        cqa_fail_autofix "$FILE" "" "ID: ${CURRENT_ID} -> ${EXPECTED_ID}" "Updated ID and context"
    fi

    # Report/apply file rename
    if [[ "$FILE" != "$NEW_FILE" ]]; then
        local OLD_BASENAME
        OLD_BASENAME=$(basename "$FILE")
        local NEW_BASENAME
        NEW_BASENAME=$(basename "$NEW_FILE")
        if [[ "$CQA_FIX_MODE" == true ]]; then
            git mv "$FILE" "$NEW_FILE" 2>/dev/null || mv "$FILE" "$NEW_FILE"
            while read -r include_file; do
                if grep -q "include::.*${OLD_BASENAME}\[" "$include_file"; then
                    sed -i.bak "s|include::\(.*\)${OLD_BASENAME}\[|include::\1${NEW_BASENAME}[|g" "$include_file"
                    rm -f "${include_file}.bak"
                fi
            done < <(find assemblies/ modules/ titles/ -name "*.adoc" -type f 2>/dev/null)
            FILE="$NEW_FILE"
        fi
        cqa_fail_autofix "$FILE" "" "File: ${OLD_BASENAME} -> ${NEW_BASENAME}" "Renamed file and updated includes"
    fi
}

# shellcheck disable=SC2329  # Invoked indirectly via cqa_run_for_each_title
_cqa10_check() {
    local target="$1"

    cqa_header "10" "Verify titles are brief, complete, and descriptive" "$target"

    for file in "${_CQA_COLLECTED_FILES[@]}"; do
        [[ "$file" != *.adoc ]] && continue
        [[ "$(basename "$file")" == "attributes.adoc" ]] && continue
        [[ "$(basename "$file")" == "master.adoc" ]] && continue

        local content_type
        content_type=$(cqa_get_content_type "$file")
        local basename_no_ext
        basename_no_ext=$(basename "$file" .adoc)

        if [[ -n "$content_type" ]] || [[ "$basename_no_ext" =~ ^(proc|con|ref|assembly|snip)- ]]; then
            _process_file "$file"
        fi
    done
}

cqa_run_for_each_title _cqa10_check
exit "$(cqa_exit_code)"
