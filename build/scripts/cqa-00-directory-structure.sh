#!/bin/bash
# shellcheck disable=SC2128,SC2178,SC2086
# SC2128/SC2178: owners variables are space-delimited strings, not arrays — intentional.
# SC2086: unquoted $owners passed to _compute_dest for word splitting — intentional.
#
# cqa-00-directory-structure.sh
#
# Aligns title, assembly, module, and image directory names using <category>_<context> naming.
# Reports misnamed directories as [AUTOFIX] findings; --fix executes git mv operations.
#
# Usage:
#   ./build/scripts/cqa-00-directory-structure.sh                  (report misnamed dirs)
#   ./build/scripts/cqa-00-directory-structure.sh --fix             (execute renames)
#   ./build/scripts/cqa-00-directory-structure.sh [--fix] <title-dir> [<new-context>]
#
# Directory naming convention:
#   titles/<category>_<context>/
#   assemblies/<category>_<context>/   (owned by one title)
#   assemblies/<category>_shared/      (shared within a category)
#   assemblies/shared/                 (shared across categories)
#   modules/<category>_<context>/      (owned by one title)
#   modules/<category>_shared/         (shared within a category)
#   modules/shared/                    (shared across categories)

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"

readonly _SHARED_DIR="shared"

# Custom arg parsing: accept standard flags plus optional positional args for single-title mode
CQA_FIX_MODE=false
# shellcheck disable=SC2034  # CQA_FORMAT used by cqa-lib output functions
CQA_FORMAT="$_CQA_FMT_CHECKLIST"
_TITLE_ARG=""
_CONTEXT_ARG=""
# shellcheck disable=SC2034
for arg in "$@"; do
    case "$arg" in
        --fix)         CQA_FIX_MODE=true ;;
        --all)         ;; # accepted, ignored (always scans everything in --all mode)
        --format=*)    CQA_FORMAT="${arg#--format=}" ;;
        --format)      ;; # next arg handled below
        -h|--help)
            echo "Usage: $0 [--fix] [--format checklist|json]" >&2
            echo "       $0 [--fix] <title-dir> [<new-context>]" >&2
            exit 0
            ;;
        *)
            if [[ "${_prev_arg:-}" == "--format" ]]; then
                CQA_FORMAT="$arg"
            elif [[ -z "$_TITLE_ARG" ]]; then
                _TITLE_ARG="$arg"
            elif [[ -z "$_CONTEXT_ARG" ]]; then
                _CONTEXT_ARG="$arg"
            fi
            ;;
    esac
    _prev_arg="$arg"
done

# ── Helpers ──

slugify_category() {
    local input="$1"
    echo "$input" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

read_category() {
    local file="$1"
    grep -m1 '^:_mod-docs-category:' "$file" 2>/dev/null | sed 's/^:_mod-docs-category: //'
}

read_title() {
    local file="$1"
    grep -m1 '^:title:' "$file" 2>/dev/null | sed 's/^:title: //'
}

read_context() {
    local file="$1"
    grep -m1 '^:context:' "$file" 2>/dev/null | sed 's/^:context: *//' | sed 's/ *$//'
}

resolve_local_attrs() {
    local title="$1"
    local master="$2"

    while IFS= read -r line; do
        local attr_name attr_value
        # shellcheck disable=SC2001
        attr_name=$(echo "$line" | sed 's/^:\([^:]*\):.*/\1/')
        # shellcheck disable=SC2001
        attr_value=$(echo "$line" | sed 's/^:[^:]*: *//')
        if [[ "$title" == *"{${attr_name}}"* ]]; then
            title="${title//\{${attr_name}\}/${attr_value}}"
        fi
    done < <(grep -E '^:[a-z][-a-z0-9]*:' "$master" 2>/dev/null | grep -v '^:_mod-docs' | grep -v '^:context:' | grep -v '^:title:' | grep -v '^:subtitle:' | grep -v '^:abstract:' | grep -v '^:imagesdir:' || true)

    echo "$title"
}

derive_context() {
    local title="$1"
    local master="${2:-}"

    if [[ -n "$master" && -f "$master" ]]; then
        title=$(resolve_local_attrs "$title" "$master")
    fi

    title="${title//\{ls-brand-name\}/developer-lightspeed-for-rhdh}"
    title="${title//\{ls-short\}/developer-lightspeed-for-rhdh}"
    title="${title//\{openshift-ai-connector-name\}/openshift-ai-connector-for-rhdh}"
    title="${title//\{openshift-ai-connector-name-short\}/openshift-ai-connector-for-rhdh}"
    title="${title//\{product\}/rhdh}"
    title="${title//\{product-short\}/rhdh}"
    title="${title//\{product-very-short\}/rhdh}"
    title="${title//\{product-local\}/rhdh-local}"
    title="${title//\{product-local-very-short\}/rhdh-local}"
    title="${title//\{ocp-brand-name\}/ocp}"
    title="${title//\{ocp-short\}/ocp}"
    title="${title//\{ocp-very-short\}/ocp}"
    title="${title//\{aks-brand-name\}/aks}"
    title="${title//\{aks-name\}/aks}"
    title="${title//\{aks-short\}/aks}"
    title="${title//\{eks-brand-name\}/eks}"
    title="${title//\{eks-name\}/eks}"
    title="${title//\{eks-short\}/eks}"
    title="${title//\{gke-brand-name\}/gke}"
    title="${title//\{gke-short\}/gke}"
    title="${title//\{gcp-brand-name\}/gcp}"
    title="${title//\{gcp-short\}/gcp}"
    title="${title//\{osd-brand-name\}/osd}"
    title="${title//\{osd-short\}/osd}"
    title="${title//\{rhacs-brand-name\}/acs}"
    title="${title//\{rhacs-short\}/acs}"
    title="${title//\{rhacs-very-short\}/acs}"
    title="${title//\{rhoai-brand-name\}/openshift-ai}"
    title="${title//\{rhoai-short\}/openshift-ai}"
    title="${title//\{backstage\}/backstage}"

    title="${title,,}"
    title="${title// /-}"
    title="${title//_/-}"
    # shellcheck disable=SC2001
    title=$(echo "$title" | sed 's/([^)]*)//g')
    # shellcheck disable=SC2001
    title=$(echo "$title" | sed 's/[^a-z0-9-]//g')
    # shellcheck disable=SC2001
    title=$(echo "$title" | sed 's/-\{2,\}/-/g')
    title=$(echo "$title" | sed 's/^-//;s/-$//')

    echo "$title"
}

move_dir_contents() {
    local src="$1" dest="$2"
    for f in "$src"/*; do
        [[ -e "$f" ]] || continue
        local base
        base=$(basename "$f")
        if [[ -e "$dest/$base" ]]; then
            echo "  Skip (exists): $dest/$base" >&2
        else
            git mv "$f" "$dest/"
        fi
    done
    rmdir "$src" 2>/dev/null || true
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# Single-title mode (when a positional arg is given)
# ═══════════════════════════════════════════════════════════════════
if [[ -n "$_TITLE_ARG" ]]; then
    TITLE_PATH="$_TITLE_ARG"
    TITLE_PATH="${TITLE_PATH%/}"
    [[ "$TITLE_PATH" != titles/* ]] && TITLE_PATH="titles/$TITLE_PATH"

    OLD_DIR=$(basename "$TITLE_PATH")
    MASTER="$TITLE_PATH/master.adoc"

    if [[ ! -f "$MASTER" ]]; then
        echo "Error: File not found: $MASTER" >&2
        exit 1
    fi

    if [[ -n "$_CONTEXT_ARG" ]]; then
        NEW_CONTEXT="$_CONTEXT_ARG"
    else
        TITLE_ATTR=$(read_title "$MASTER")
        if [[ -z "$TITLE_ATTR" ]]; then
            echo "Error: No :title: attribute found in $MASTER" >&2
            exit 1
        fi
        NEW_CONTEXT=$(derive_context "$TITLE_ATTR" "$MASTER")
    fi

    CAT=$(read_category "$MASTER")
    if [[ -n "$CAT" ]]; then
        CATSLUG=$(slugify_category "$CAT")
        NEW_DIR="${CATSLUG}_${NEW_CONTEXT}"
    else
        NEW_DIR="$NEW_CONTEXT"
    fi

    if [[ "$OLD_DIR" == "$NEW_DIR" ]]; then
        echo "Directory already matches: $OLD_DIR"
        exit 0
    fi

    if [[ "$CQA_FIX_MODE" != true ]]; then
        echo "Would rename: titles/$OLD_DIR -> titles/$NEW_DIR"
        echo "Run with --fix to execute"
        exit 0
    fi

    echo "Renaming titles/$OLD_DIR -> titles/$NEW_DIR"
    git mv "titles/$OLD_DIR" "titles/$NEW_DIR"
    MASTER="titles/$NEW_DIR/master.adoc"

    ASSEMBLY_INCLUDES=$(grep -v '^//' "$MASTER" 2>/dev/null | grep -oP 'include::assemblies/\K[^[]+' || true)
    ASSEMBLY_COUNT=$(echo "$ASSEMBLY_INCLUDES" | grep -c '\.adoc$' || true)
    ASSEMBLY_COUNT=${ASSEMBLY_COUNT:-0}
    MODULE_DIRS=$(grep -v '^//' "$MASTER" 2>/dev/null | grep -oP 'include::modules/\K[^/]+' | sort -u || true)

    if [[ $ASSEMBLY_COUNT -gt 0 ]]; then
        ASSEMBLY_FILES=()
        while IFS= read -r asm; do
            [[ -z "$asm" ]] && continue
            [[ -f "assemblies/$asm" ]] && ASSEMBLY_FILES+=("assemblies/$asm")
        done <<< "$ASSEMBLY_INCLUDES"

        if [[ ${#ASSEMBLY_FILES[@]} -gt 0 ]]; then
            mkdir -p "assemblies/$NEW_DIR"
            for asm_file in "${ASSEMBLY_FILES[@]}"; do
                asm_basename=$(basename "$asm_file")
                if [[ ! -f "assemblies/$NEW_DIR/$asm_basename" ]]; then
                    git mv "$asm_file" "assemblies/$NEW_DIR/"
                fi
            done
        fi
    fi

    if [[ -n "$MODULE_DIRS" ]]; then
        while IFS= read -r mod_dir; do
            [[ -z "$mod_dir" || "$mod_dir" == "$NEW_DIR" || "$mod_dir" == "$_SHARED_DIR" ]] && continue
            if [[ -d "modules/$mod_dir" ]]; then
                if [[ -d "modules/$NEW_DIR" ]]; then
                    for f in "modules/$mod_dir"/*; do
                        [[ -e "$f" ]] && git mv "$f" "modules/$NEW_DIR/"
                    done
                    rmdir "modules/$mod_dir" 2>/dev/null || true
                else
                    git mv "modules/$mod_dir" "modules/$NEW_DIR"
                fi
            fi
        done <<< "$MODULE_DIRS"
    fi

    sed -i "s|include::assemblies/assembly-|include::assemblies/$NEW_DIR/assembly-|g" "$MASTER"
    if [[ -n "$MODULE_DIRS" ]]; then
        while IFS= read -r mod_dir; do
            [[ -z "$mod_dir" || "$mod_dir" == "$NEW_DIR" ]] && continue
            sed -i "s|include::modules/$mod_dir/|include::modules/$NEW_DIR/|g" "$MASTER"
        done <<< "$MODULE_DIRS"
    fi

    sed -i "s|^:context:.*|:context: $NEW_CONTEXT|" "$MASTER"
    echo "Done. Review: git diff --stat"
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════
# Full repo mode (default — no positional arg)
# ═══════════════════════════════════════════════════════════════════

cqa_header "0" "Verify Directory Structure (<category>_<context> naming)"

# ── Phase 0: Pre-computation ──

declare -A CTX_CAT       # context → category slug
declare -A CTX_DEST      # context → <catslug>_<context>
declare -A DIR_CTX       # title dir basename → context
TITLE_LIST=()

for master in titles/*/master.adoc; do
    d=$(basename "$(dirname "$master")")
    ctx=$(read_context "$master")
    cat=$(read_category "$master")
    if [[ -z "$cat" ]]; then
        cqa_file_start "$master"
        cqa_fail_manual "$master" "" "Missing :_mod-docs-category: attribute"
        continue
    fi
    cs=$(slugify_category "$cat")
    CTX_CAT["$ctx"]="$cs"
    CTX_DEST["$ctx"]="${cs}_${ctx}"
    DIR_CTX["$d"]="$ctx"
    TITLE_LIST+=("$ctx")
done

# ── Build assembly ownership map ──
declare -A ASM_FILE_OWNERS

for master in titles/*/master.adoc; do
    d=$(basename "$(dirname "$master")")
    ctx="${DIR_CTX[$d]:-}"
    [[ -z "$ctx" ]] && continue
    while IFS= read -r inc; do
        [[ -z "$inc" ]] && continue
        ASM_FILE_OWNERS["$inc"]="${ASM_FILE_OWNERS[$inc]:-} $ctx"
    done < <(grep -v '^//' "$master" 2>/dev/null | grep -oP 'include::assemblies/\K[^[]+' || true)
done

# Propagate ownership to sub-assemblies (iterative)
changed=true
while $changed; do
    changed=false
    for af in "${!ASM_FILE_OWNERS[@]}"; do
        [[ -f "assemblies/$af" ]] || continue
        parent_owners="${ASM_FILE_OWNERS[$af]}"
        asm_dir=$(dirname "$af")

        while IFS= read -r sub; do
            [[ -z "$sub" ]] && continue
            if [[ "$asm_dir" != "." ]]; then
                sub_path="$asm_dir/$sub"
            else
                sub_path="$sub"
            fi
            old="${ASM_FILE_OWNERS[$sub_path]:-}"
            combined=$(echo "$old $parent_owners" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)
            if [[ "$combined" != "$old" ]]; then
                ASM_FILE_OWNERS["$sub_path"]="$combined"
                changed=true
            fi
        done < <(grep -v '^//' "assemblies/$af" 2>/dev/null | grep -oP 'include::\Kassembly-[^[]+' || true)

        while IFS= read -r sub_path; do
            [[ -z "$sub_path" ]] && continue
            old="${ASM_FILE_OWNERS[$sub_path]:-}"
            combined=$(echo "$old $parent_owners" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)
            if [[ "$combined" != "$old" ]]; then
                ASM_FILE_OWNERS["$sub_path"]="$combined"
                changed=true
            fi
        done < <(grep -v '^//' "assemblies/$af" 2>/dev/null | grep -oP 'include::\.\.\/assemblies/\K[^[]+' || true)
    done
done

# ── Build module dir ownership map ──
declare -A MOD_DIR_OWNERS

for master in titles/*/master.adoc; do
    d=$(basename "$(dirname "$master")")
    ctx="${DIR_CTX[$d]:-}"
    [[ -z "$ctx" ]] && continue
    while IFS= read -r md; do
        [[ -z "$md" || "$md" == "$_SHARED_DIR" ]] && continue
        MOD_DIR_OWNERS["$md"]="${MOD_DIR_OWNERS[$md]:-} $ctx"
    done < <(grep -v '^//' "$master" 2>/dev/null | grep -oP 'include::modules/\K[^/]+' | sort -u || true)
done

for af in "${!ASM_FILE_OWNERS[@]}"; do
    [[ -f "assemblies/$af" ]] || continue
    owners="${ASM_FILE_OWNERS[$af]}"
    while IFS= read -r md; do
        [[ -z "$md" || "$md" == "$_SHARED_DIR" ]] && continue
        MOD_DIR_OWNERS["$md"]="${MOD_DIR_OWNERS[$md]:-} $owners"
    done < <(grep -v '^//' "assemblies/$af" 2>/dev/null | grep -oP 'include::(\.\.\/)?modules/\K[^/]+' | sort -u || true)
done

for md in "${!MOD_DIR_OWNERS[@]}"; do
    MOD_DIR_OWNERS["$md"]=$(echo "${MOD_DIR_OWNERS[$md]}" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)
done

# ── Compute destinations ──
_compute_dest() {
    local owners_str="$*"
    local -a owners
    read -ra owners <<< "$owners_str"
    local n=${#owners[@]}

    if [[ $n -eq 0 ]]; then
        echo "UNKNOWN"
        return
    fi

    if [[ $n -eq 1 ]]; then
        echo "${CTX_DEST[${owners[0]}]}"
        return
    fi

    local first_cat="${CTX_CAT[${owners[0]}]}"
    local all_same=true
    for o in "${owners[@]}"; do
        if [[ "${CTX_CAT[$o]:-}" != "$first_cat" ]]; then
            all_same=false
            break
        fi
    done

    if $all_same; then
        echo "${first_cat}_${_SHARED_DIR}"
    else
        echo "$_SHARED_DIR"
    fi
}

# ── Report misnamed directories ──

# Title directories
for d in "${!DIR_CTX[@]}"; do
    ctx="${DIR_CTX[$d]}"
    expected="${CTX_DEST[$ctx]}"
    if [[ "$d" != "$expected" ]]; then
        cqa_file_start "titles/$d/master.adoc"
        cqa_fail_autofix "titles/$d" "" "Title dir should be titles/$expected" "Renamed titles/$d -> titles/$expected"
    fi
done

# Assembly directories
declare -A ASM_DIR_DEST
for asm_dir in assemblies/*/; do
    [[ -d "$asm_dir" ]] || continue
    dn=$(basename "$asm_dir")
    [[ "$dn" == "$_SHARED_DIR" || "$dn" == "modules" ]] && continue

    all_owners=""
    for f in "$asm_dir"*.adoc; do
        [[ -f "$f" ]] || continue
        rel="${f#assemblies/}"
        all_owners="$all_owners ${ASM_FILE_OWNERS[$rel]:-}"
    done
    all_owners=$(echo "$all_owners" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)

    if [[ -z "$(echo "$all_owners" | tr -d ' ')" ]]; then
        ASM_DIR_DEST["$dn"]="$dn"
        continue
    fi

    dest=$(_compute_dest $all_owners)
    ASM_DIR_DEST["$dn"]="$dest"
    if [[ "$dn" != "$dest" ]]; then
        cqa_file_start "assemblies/$dn"
        cqa_fail_autofix "assemblies/$dn" "" "Assembly dir should be assemblies/$dest" "Renamed assemblies/$dn -> assemblies/$dest"
    fi
done

# Flat assembly files
declare -A FLAT_ASM_DEST=()
FLAT_ASM_DEST[__sentinel__]=1
for f in assemblies/*.adoc; do
    [[ -f "$f" ]] || continue
    bn=$(basename "$f")
    owners="${ASM_FILE_OWNERS[$bn]:-}"
    owners=$(echo "$owners" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)

    if [[ -z "$(echo "$owners" | tr -d ' ')" ]]; then
        continue
    fi

    dest=$(_compute_dest $owners)
    FLAT_ASM_DEST["$bn"]="$dest"
    cqa_file_start "$f"
    cqa_fail_autofix "$f" "" "Flat assembly should be in assemblies/$dest/" "Moved to assemblies/$dest/"
done
unset 'FLAT_ASM_DEST[__sentinel__]'

# Module directories
declare -A MOD_DIR_DEST
for md in "${!MOD_DIR_OWNERS[@]}"; do
    [[ -d "modules/$md" ]] || continue
    owners="${MOD_DIR_OWNERS[$md]}"
    dest=$(_compute_dest $owners)
    MOD_DIR_DEST["$md"]="$dest"
    if [[ "$md" != "$dest" ]]; then
        cqa_file_start "modules/$md"
        cqa_fail_autofix "modules/$md" "" "Module dir should be modules/$dest" "Renamed modules/$md -> modules/$dest"
    fi
done

# Image file ownership and destinations
declare -A IMG_FILE_OWNERS

_extract_img_refs() {
    local file="$1"
    grep -v '^//' "$file" 2>/dev/null | grep -oP 'image::?\K[^/]+/[^[\]]+' || true
}

for master in titles/*/master.adoc; do
    d=$(basename "$(dirname "$master")")
    ctx="${DIR_CTX[$d]:-}"
    [[ -z "$ctx" ]] && continue
    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $ctx"
    done < <(_extract_img_refs "$master")
done

for mod_dir in modules/*/; do
    [[ -d "$mod_dir" ]] || continue
    md=$(basename "$mod_dir")
    [[ "$md" == "$_SHARED_DIR" ]] && continue
    owners="${MOD_DIR_OWNERS[$md]:-}"
    [[ -z "$(echo "$owners" | tr -d ' ')" ]] && continue
    for f in "$mod_dir"*.adoc; do
        [[ -f "$f" ]] || continue
        while IFS= read -r ref; do
            [[ -z "$ref" ]] && continue
            IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $owners"
        done < <(_extract_img_refs "$f")
    done
done

# Shared modules image ownership
declare -A SHARED_MOD_OWNERS
for master in titles/*/master.adoc; do
    d=$(basename "$(dirname "$master")")
    ctx="${DIR_CTX[$d]:-}"
    [[ -z "$ctx" ]] && continue
    while IFS= read -r sm; do
        [[ -z "$sm" ]] && continue
        SHARED_MOD_OWNERS["$sm"]="${SHARED_MOD_OWNERS[$sm]:-} $ctx"
    done < <(grep -v '^//' "$master" 2>/dev/null | grep -oP 'modules/shared/+\K[^[]+' || true)
done
for af in "${!ASM_FILE_OWNERS[@]}"; do
    [[ -f "assemblies/$af" ]] || continue
    owners="${ASM_FILE_OWNERS[$af]}"
    while IFS= read -r sm; do
        [[ -z "$sm" ]] && continue
        SHARED_MOD_OWNERS["$sm"]="${SHARED_MOD_OWNERS[$sm]:-} $owners"
    done < <(grep -v '^//' "assemblies/$af" 2>/dev/null | grep -oP 'modules/shared/+\K[^[]+' || true)
done

for f in modules/shared/*.adoc; do
    [[ -f "$f" ]] || continue
    bn=$(basename "$f")
    shared_mod_owners="${SHARED_MOD_OWNERS[$bn]:-}"
    [[ -z "$(echo "$shared_mod_owners" | tr -d ' ')" ]] && continue
    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $shared_mod_owners"
    done < <(_extract_img_refs "$f")
done

for af in "${!ASM_FILE_OWNERS[@]}"; do
    [[ -f "assemblies/$af" ]] || continue
    owners="${ASM_FILE_OWNERS[$af]}"
    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $owners"
    done < <(_extract_img_refs "assemblies/$af")
done

for ref in "${!IMG_FILE_OWNERS[@]}"; do
    IMG_FILE_OWNERS["$ref"]=$(echo "${IMG_FILE_OWNERS[$ref]}" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)
done

declare -A IMG_FILE_DEST=()
IMG_FILE_DEST[__sentinel__]=1

for ref in "${!IMG_FILE_OWNERS[@]}"; do
    [[ -f "images/$ref" ]] || continue
    owners="${IMG_FILE_OWNERS[$ref]}"
    dest=$(_compute_dest $owners)
    old_dir=$(dirname "$ref")
    if [[ "$old_dir" != "$dest" ]]; then
        IMG_FILE_DEST["$ref"]="$dest"
        cqa_file_start "images/$ref"
        cqa_fail_autofix "images/$ref" "" "Image should be in images/$dest/" "Moved to images/$dest/"
    fi
done
unset 'IMG_FILE_DEST[__sentinel__]'

# ── Execute renames if --fix ──
if [[ "$CQA_FIX_MODE" == true ]]; then

    # Phase 1: Rename title directories
    for master in $(find titles -maxdepth 2 -name master.adoc | sort); do
        d=$(basename "$(dirname "$master")")
        ctx="${DIR_CTX[$d]:-}"
        [[ -z "$ctx" ]] && continue
        new_dir="${CTX_DEST[$ctx]}"
        if [[ "$d" != "$new_dir" ]]; then
            git mv "titles/$d" "titles/$new_dir"
        fi
    done

    # Phase 2: Move assemblies
    for old_dir in $(echo "${!ASM_DIR_DEST[@]}" | tr ' ' '\n' | sort); do
        new_dir="${ASM_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        [[ ! -d "assemblies/$old_dir" ]] && continue

        if [[ -d "assemblies/$new_dir" ]]; then
            move_dir_contents "assemblies/$old_dir" "assemblies/$new_dir"
        else
            git mv "assemblies/$old_dir" "assemblies/$new_dir"
        fi
    done

    for bn in $(echo "${!FLAT_ASM_DEST[@]}" | tr ' ' '\n' | sort); do
        dest="${FLAT_ASM_DEST[$bn]}"
        [[ ! -f "assemblies/$bn" ]] && continue
        mkdir -p "assemblies/$dest"
        git mv "assemblies/$bn" "assemblies/$dest/"
    done

    # Phase 3: Move modules
    for old_dir in $(echo "${!MOD_DIR_DEST[@]}" | tr ' ' '\n' | sort); do
        new_dir="${MOD_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        [[ ! -d "modules/$old_dir" ]] && continue

        if [[ -d "modules/$new_dir" ]]; then
            move_dir_contents "modules/$old_dir" "modules/$new_dir"
        else
            git mv "modules/$old_dir" "modules/$new_dir"
        fi
    done

    # Phase 4: Move images
    for ref in $(echo "${!IMG_FILE_DEST[@]}" | tr ' ' '\n' | sort); do
        dest="${IMG_FILE_DEST[$ref]}"
        [[ ! -f "images/$ref" ]] && continue
        bn=$(basename "$ref")
        mkdir -p "images/$dest"
        git mv "images/$ref" "images/$dest/$bn"
    done
    find images/ -mindepth 1 -type d -empty -delete 2>/dev/null || true

    # Phase 5: Update include paths
    master_sed=""
    for old_dir in "${!ASM_DIR_DEST[@]}"; do
        new_dir="${ASM_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        master_sed="${master_sed}s|include::assemblies/${old_dir}/|include::assemblies/${new_dir}/|g;"
    done
    for bn in "${!FLAT_ASM_DEST[@]}"; do
        dest="${FLAT_ASM_DEST[$bn]}"
        master_sed="${master_sed}s|include::assemblies/${bn}|include::assemblies/${dest}/${bn}|g;"
    done
    for old_dir in "${!MOD_DIR_DEST[@]}"; do
        new_dir="${MOD_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        master_sed="${master_sed}s|include::modules/${old_dir}/|include::modules/${new_dir}/|g;"
    done
    for ref in "${!IMG_FILE_DEST[@]}"; do
        dest="${IMG_FILE_DEST[$ref]}"
        bn=$(basename "$ref")
        old_dir=$(dirname "$ref")
        master_sed="${master_sed}s|image::${old_dir}/${bn}|image::${dest}/${bn}|g;"
        master_sed="${master_sed}s|image:${old_dir}/${bn}|image:${dest}/${bn}|g;"
    done
    if [[ -n "$master_sed" ]]; then
        for master in titles/*/master.adoc; do
            sed -i "$master_sed" "$master"
        done
    fi

    asm_sed=""
    for old_dir in "${!MOD_DIR_DEST[@]}"; do
        new_dir="${MOD_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        asm_sed="${asm_sed}s|include::\.\.\/modules/${old_dir}/|include::../modules/${new_dir}/|g;"
        asm_sed="${asm_sed}s|include::modules/${old_dir}/|include::../modules/${new_dir}/|g;"
    done
    for old_dir in "${!ASM_DIR_DEST[@]}"; do
        new_dir="${ASM_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        asm_sed="${asm_sed}s|include::\.\.\/assemblies/${old_dir}/|include::../assemblies/${new_dir}/|g;"
    done
    for ref in "${!IMG_FILE_DEST[@]}"; do
        dest="${IMG_FILE_DEST[$ref]}"
        bn=$(basename "$ref")
        old_dir=$(dirname "$ref")
        asm_sed="${asm_sed}s|image::${old_dir}/${bn}|image::${dest}/${bn}|g;"
        asm_sed="${asm_sed}s|image:${old_dir}/${bn}|image:${dest}/${bn}|g;"
    done
    if [[ -n "$asm_sed" ]]; then
        for asm_file in assemblies/*/*.adoc; do
            [[ -f "$asm_file" ]] || continue
            sed -i "$asm_sed" "$asm_file"
        done
    fi

    mod_img_sed=""
    for ref in "${!IMG_FILE_DEST[@]}"; do
        dest="${IMG_FILE_DEST[$ref]}"
        bn=$(basename "$ref")
        old_dir=$(dirname "$ref")
        mod_img_sed="${mod_img_sed}s|image::${old_dir}/${bn}|image::${dest}/${bn}|g;"
        mod_img_sed="${mod_img_sed}s|image:${old_dir}/${bn}|image:${dest}/${bn}|g;"
    done
    if [[ -n "$mod_img_sed" ]]; then
        find modules/ -name '*.adoc' -exec sed -i "$mod_img_sed" {} +
    fi

    for bn in "${!FLAT_ASM_DEST[@]}"; do
        dest="${FLAT_ASM_DEST[$bn]}"
        file="assemblies/$dest/$bn"
        [[ -f "$file" ]] || continue
        sed -i 's|include::modules/|include::../modules/|g' "$file"
        sed -i 's|include::\.\.\/\.\.\/modules/|include::../modules/|g' "$file"
    done

    for bn in "${!FLAT_ASM_DEST[@]}"; do
        dest="${FLAT_ASM_DEST[$bn]}"
        file="assemblies/$dest/$bn"
        [[ -f "$file" ]] || continue
        sed -i 's|include::assemblies/|include::../assemblies/|g' "$file"
        sed -i 's|include::\.\.\/\.\.\/assemblies/|include::../assemblies/|g' "$file"
    done

    # Phase 6: Verify
    ERRORS=0
    for master in titles/*/master.adoc; do
        title_dir=$(dirname "$master")
        while IFS= read -r inc; do
            [[ -z "$inc" ]] && continue
            [[ "$inc" == *"{"*"}"* ]] && continue
            target="$title_dir/$inc"
            if [[ ! -e "$target" ]]; then
                cqa_fail_manual "$master" "" "Broken include after rename: $inc"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(grep -v '^//' "$master" 2>/dev/null | grep -oP 'include::\K[^[]+' || true)
    done

    for asm_file in assemblies/*/*.adoc; do
        [[ -f "$asm_file" ]] || continue
        asm_dir_path=$(dirname "$asm_file")
        while IFS= read -r inc; do
            [[ -z "$inc" ]] && continue
            [[ "$inc" == *"{"*"}"* ]] && continue
            target="$asm_dir_path/$inc"
            if [[ ! -e "$target" ]]; then
                cqa_fail_manual "$asm_file" "" "Broken include after rename: $inc"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(grep -v '^//' "$asm_file" 2>/dev/null | grep -oP 'include::\K[^[]+' || true)
    done

    for adoc_file in $(find titles modules assemblies -name '*.adoc' 2>/dev/null | sort); do
        [[ -f "$adoc_file" ]] || continue
        while IFS= read -r img_ref; do
            [[ -z "$img_ref" ]] && continue
            [[ "$img_ref" == *"://"* || "$img_ref" == *" "* || "$img_ref" == *"'"* ]] && continue
            [[ "$img_ref" != *"/"* ]] && continue
            if [[ "$img_ref" == *"../"* ]]; then
                cqa_fail_manual "$adoc_file" "" "Image reference contains '../': image::$img_ref"
                ERRORS=$((ERRORS + 1))
                continue
            fi
            if [[ ! -f "images/$img_ref" ]]; then
                cqa_fail_manual "$adoc_file" "" "Missing image after rename: images/$img_ref"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(grep -v '^//' "$adoc_file" 2>/dev/null | grep -oP 'image::?\K[^[\]]+' || true)
    done
fi

cqa_summary
exit "$(cqa_exit_code)"
