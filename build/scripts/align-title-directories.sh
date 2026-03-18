#!/bin/bash
# align-title-directories.sh
#
# Aligns title, assembly, and module directory names using <category>_<context> naming.
#
# Usage:
#   ./build/scripts/align-title-directories.sh --list
#   ./build/scripts/align-title-directories.sh --all                               (dry-run)
#   ./build/scripts/align-title-directories.sh --all --exec                        (execute)
#   ./build/scripts/align-title-directories.sh [--exec] <title-dir> [<new-context>] (single title)
#
# Directory naming convention:
#   titles/<category>_<context>/
#   assemblies/<category>_<context>/   (owned by one title)
#   assemblies/<category>_shared/      (shared within a category)
#   assemblies/shared/                 (shared across categories)
#   modules/<category>_<context>/      (owned by one title)
#   modules/<category>_shared/         (shared within a category)
#   modules/shared/                    (shared across categories)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
phase() { echo -e "\n${BLUE}=== $* ===${NC}"; }

slugify_category() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

read_category() {
    grep -m1 '^:_mod-docs-category:' "$1" 2>/dev/null | sed 's/^:_mod-docs-category: //'
}

read_title() {
    grep -m1 '^:title:' "$1" 2>/dev/null | sed 's/^:title: //'
}

read_context() {
    grep -m1 '^:context:' "$1" 2>/dev/null | sed 's/^:context: *//' | sed 's/ *$//'
}

# Resolve local attributes defined in a master.adoc file.
resolve_local_attrs() {
    local title="$1"
    local master="$2"

    while IFS= read -r line; do
        local attr_name attr_value
        attr_name=$(echo "$line" | sed 's/^:\([^:]*\):.*/\1/')
        attr_value=$(echo "$line" | sed 's/^:[^:]*: *//')
        if [[ "$title" == *"{${attr_name}}"* ]]; then
            title="${title//\{${attr_name}\}/${attr_value}}"
        fi
    done < <(grep -E '^:[a-z][-a-z0-9]*:' "$master" 2>/dev/null | grep -v '^:_mod-docs' | grep -v '^:context:' | grep -v '^:title:' | grep -v '^:subtitle:' | grep -v '^:abstract:' | grep -v '^:imagesdir:' || true)

    echo "$title"
}

# Derive context slug from :title:
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
    title=$(echo "$title" | sed 's/([^)]*)//g')
    title=$(echo "$title" | sed 's/[^a-z0-9-]//g')
    title=$(echo "$title" | sed 's/-\{2,\}/-/g')
    title=$(echo "$title" | sed 's/^-//;s/-$//')

    echo "$title"
}

# Move all files from src dir to dest dir via git mv, then rmdir src
move_dir_contents() {
    local src="$1" dest="$2"
    for f in "$src"/*; do
        [[ -e "$f" ]] || continue
        local base
        base=$(basename "$f")
        if [[ -e "$dest/$base" ]]; then
            warn "  Skip (exists): $dest/$base"
        else
            git mv "$f" "$dest/"
        fi
    done
    rmdir "$src" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════
# --list mode
# ═══════════════════════════════════════════════════════════════════
if [[ "${1:-}" == "--list" ]]; then
    echo "Title directories with category and context:"
    echo "============================================="
    printf "%-55s %-20s %-45s %-45s\n" "Directory" "Category" ":context:" "Dest"
    printf "%-55s %-20s %-45s %-45s\n" "---------" "--------" "--------" "----"
    for master in titles/*/master.adoc; do
        dir=$(dirname "$master" | sed 's|titles/||')
        context=$(read_context "$master" || echo "(none)")
        cat=$(read_category "$master" || echo "(none)")
        catslug=$(slugify_category "${cat:-(none)}")
        dest="${catslug}_${context}"
        printf "%-55s %-20s %-45s %-45s\n" "$dir" "$cat" "$context" "$dest"
    done
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════
# --all mode: process all titles with category-based naming
# ═══════════════════════════════════════════════════════════════════
if [[ "${1:-}" == "--all" ]]; then
    EXEC=false
    [[ "${2:-}" == "--exec" ]] && EXEC=true

    # ── Phase 0: Pre-computation ──────────────────────────────────
    phase "Phase 0: Pre-computation"

    declare -A CTX_CAT       # context → category slug
    declare -A CTX_DEST      # context → <catslug>_<context>
    declare -A DIR_CTX       # title dir basename → context
    TITLE_LIST=()

    for master in titles/*/master.adoc; do
        d=$(basename "$(dirname "$master")")
        ctx=$(read_context "$master")
        cat=$(read_category "$master")
        if [[ -z "$cat" ]]; then
            error "No :_mod-docs-category: in $master — skipping"
            continue
        fi
        cs=$(slugify_category "$cat")
        CTX_CAT["$ctx"]="$cs"
        CTX_DEST["$ctx"]="${cs}_${ctx}"
        DIR_CTX["$d"]="$ctx"
        TITLE_LIST+=("$ctx")
        info "Title: $d → ${cs}_${ctx}  ($cat)"
    done

    # ── Build assembly ownership map ──
    # ASM_FILE_OWNERS: "subdir/file.adoc" or "file.adoc" → "ctx1 ctx2 ..."
    declare -A ASM_FILE_OWNERS

    for master in titles/*/master.adoc; do
        d=$(basename "$(dirname "$master")")
        ctx="${DIR_CTX[$d]}"
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

            # Same-dir relative includes: include::assembly-foo.adoc[
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

            # Cross-dir includes: include::../assemblies/<dir>/assembly-foo.adoc[
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
    # MOD_DIR_OWNERS: "dir_name" → "ctx1 ctx2 ..."
    declare -A MOD_DIR_OWNERS

    # From master.adoc
    for master in titles/*/master.adoc; do
        d=$(basename "$(dirname "$master")")
        ctx="${DIR_CTX[$d]}"
        while IFS= read -r md; do
            [[ -z "$md" || "$md" == "shared" ]] && continue
            MOD_DIR_OWNERS["$md"]="${MOD_DIR_OWNERS[$md]:-} $ctx"
        done < <(grep -v '^//' "$master" 2>/dev/null | grep -oP 'include::modules/\K[^/]+' | sort -u || true)
    done

    # From assemblies (inherit owners)
    for af in "${!ASM_FILE_OWNERS[@]}"; do
        [[ -f "assemblies/$af" ]] || continue
        owners="${ASM_FILE_OWNERS[$af]}"
        while IFS= read -r md; do
            [[ -z "$md" || "$md" == "shared" ]] && continue
            MOD_DIR_OWNERS["$md"]="${MOD_DIR_OWNERS[$md]:-} $owners"
        done < <(grep -v '^//' "assemblies/$af" 2>/dev/null | grep -oP 'include::(\.\.\/)?modules/\K[^/]+' | sort -u || true)
    done

    # Deduplicate owners
    for md in "${!MOD_DIR_OWNERS[@]}"; do
        MOD_DIR_OWNERS["$md"]=$(echo "${MOD_DIR_OWNERS[$md]}" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)
    done

    # ── Compute destinations ──
    # Given space-separated owner contexts, return destination dir name
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

        # Check if all same category
        local first_cat="${CTX_CAT[${owners[0]}]}"
        local all_same=true
        for o in "${owners[@]}"; do
            if [[ "${CTX_CAT[$o]:-}" != "$first_cat" ]]; then
                all_same=false
                break
            fi
        done

        if $all_same; then
            echo "${first_cat}_shared"
        else
            echo "shared"
        fi
    }

    # Compute assembly dir destinations
    declare -A ASM_DIR_DEST  # old dir name → new dir name
    for asm_dir in assemblies/*/; do
        [[ -d "$asm_dir" ]] || continue
        dn=$(basename "$asm_dir")
        [[ "$dn" == "shared" || "$dn" == "modules" ]] && continue

        all_owners=""
        for f in "$asm_dir"*.adoc; do
            [[ -f "$f" ]] || continue
            rel="${f#assemblies/}"
            all_owners="$all_owners ${ASM_FILE_OWNERS[$rel]:-}"
        done
        all_owners=$(echo "$all_owners" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)

        if [[ -z "$(echo "$all_owners" | tr -d ' ')" ]]; then
            warn "No owners for assemblies/$dn — keeping as-is"
            ASM_DIR_DEST["$dn"]="$dn"
            continue
        fi

        dest=$(_compute_dest $all_owners)
        ASM_DIR_DEST["$dn"]="$dest"
        [[ "$dn" != "$dest" ]] && info "  Assembly dir: $dn → $dest (owners: $all_owners)"
    done

    # Compute flat assembly file destinations
    declare -A FLAT_ASM_DEST=()  # filename → dest dir name
    FLAT_ASM_DEST[__sentinel__]=1  # bash 5.3 workaround: empty assoc array is "unbound"
    for f in assemblies/*.adoc; do
        [[ -f "$f" ]] || continue
        bn=$(basename "$f")
        owners="${ASM_FILE_OWNERS[$bn]:-}"
        owners=$(echo "$owners" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)

        if [[ -z "$(echo "$owners" | tr -d ' ')" ]]; then
            warn "No owners for flat assembly $bn — keeping as-is"
            continue
        fi

        dest=$(_compute_dest $owners)
        FLAT_ASM_DEST["$bn"]="$dest"
        info "  Flat assembly: $bn → $dest (owners: $owners)"
    done
    unset 'FLAT_ASM_DEST[__sentinel__]'

    # Compute module dir destinations
    declare -A MOD_DIR_DEST  # old dir name → new dir name
    for md in "${!MOD_DIR_OWNERS[@]}"; do
        [[ -d "modules/$md" ]] || continue
        owners="${MOD_DIR_OWNERS[$md]}"

        dest=$(_compute_dest $owners)
        MOD_DIR_DEST["$md"]="$dest"
        [[ "$md" != "$dest" ]] && info "  Module dir: $md → $dest (owners: $owners)"
    done

    # Check for untraced module dirs
    for mod_dir in modules/*/; do
        [[ -d "$mod_dir" ]] || continue
        md=$(basename "$mod_dir")
        [[ "$md" == "shared" ]] && continue
        if [[ -z "${MOD_DIR_DEST[$md]:-}" ]]; then
            warn "Module dir $md not referenced by any title — keeping as-is"
        fi
    done

    # ── Build image file ownership map ──
    # IMG_FILE_OWNERS: "subdir/file.png" → "ctx1 ctx2 ..."
    declare -A IMG_FILE_OWNERS

    # Helper: extract image references (subdir/file.png) from an adoc file
    _extract_img_refs() {
        grep -v '^//' "$1" 2>/dev/null | grep -oP 'image::?\K[^/]+/[^[\]]+' || true
    }

    # From master.adoc
    for master in titles/*/master.adoc; do
        d=$(basename "$(dirname "$master")")
        ctx="${DIR_CTX[$d]}"
        while IFS= read -r ref; do
            [[ -z "$ref" ]] && continue
            IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $ctx"
        done < <(_extract_img_refs "$master")
    done

    # From modules in subdirs (inherit owners through MOD_DIR_OWNERS)
    for mod_dir in modules/*/; do
        [[ -d "$mod_dir" ]] || continue
        md=$(basename "$mod_dir")
        [[ "$md" == "shared" ]] && continue
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

    # From shared modules — inherit owners from all titles/assemblies that include each module
    for f in modules/shared/*.adoc; do
        [[ -f "$f" ]] || continue
        bn=$(basename "$f")
        # Collect owners: titles and assemblies that include this shared module
        # Use basename for grep to handle double-slash paths (modules/shared//file.adoc)
        shared_mod_owners=""
        for master in titles/*/master.adoc; do
            if grep -q "$bn" "$master" 2>/dev/null; then
                d=$(basename "$(dirname "$master")")
                shared_mod_owners="$shared_mod_owners ${DIR_CTX[$d]}"
            fi
        done
        for af in "${!ASM_FILE_OWNERS[@]}"; do
            [[ -f "assemblies/$af" ]] || continue
            if grep -q "$bn" "assemblies/$af" 2>/dev/null; then
                shared_mod_owners="$shared_mod_owners ${ASM_FILE_OWNERS[$af]}"
            fi
        done
        [[ -z "$(echo "$shared_mod_owners" | tr -d ' ')" ]] && continue
        while IFS= read -r ref; do
            [[ -z "$ref" ]] && continue
            IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $shared_mod_owners"
        done < <(_extract_img_refs "$f")
    done

    # From assemblies in subdirs (inherit owners, skip shared)
    for af in "${!ASM_FILE_OWNERS[@]}"; do
        [[ -f "assemblies/$af" ]] || continue
        asm_dir=$(dirname "$af")
        [[ "$asm_dir" == "shared" ]] && continue
        owners="${ASM_FILE_OWNERS[$af]}"
        while IFS= read -r ref; do
            [[ -z "$ref" ]] && continue
            IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $owners"
        done < <(_extract_img_refs "assemblies/$af")
    done

    # From shared assemblies — inherit owners from all titles/assemblies that include them
    for af in "${!ASM_FILE_OWNERS[@]}"; do
        [[ -f "assemblies/$af" ]] || continue
        asm_dir=$(dirname "$af")
        [[ "$asm_dir" != "shared" ]] && continue
        owners="${ASM_FILE_OWNERS[$af]}"
        while IFS= read -r ref; do
            [[ -z "$ref" ]] && continue
            IMG_FILE_OWNERS["$ref"]="${IMG_FILE_OWNERS[$ref]:-} $owners"
        done < <(_extract_img_refs "assemblies/$af")
    done

    # Deduplicate owners
    for ref in "${!IMG_FILE_OWNERS[@]}"; do
        IMG_FILE_OWNERS["$ref"]=$(echo "${IMG_FILE_OWNERS[$ref]}" | tr ' ' '\n' | sort -u | grep -v '^$' | tr '\n' ' ' || true)
    done

    # Compute per-file destination directory
    # IMG_FILE_DEST: "old_dir/file.png" → "new_dir"
    declare -A IMG_FILE_DEST=()
    IMG_FILE_DEST[__sentinel__]=1  # bash 5.3 workaround

    for ref in "${!IMG_FILE_OWNERS[@]}"; do
        [[ -f "images/$ref" ]] || continue
        owners="${IMG_FILE_OWNERS[$ref]}"
        dest=$(_compute_dest $owners)
        old_dir=$(dirname "$ref")
        if [[ "$old_dir" != "$dest" ]]; then
            IMG_FILE_DEST["$ref"]="$dest"
            info "  Image: $ref → $dest/ (owners: $owners)"
        fi
    done
    unset 'IMG_FILE_DEST[__sentinel__]'

    # Check for unreferenced image files
    for img_file in images/*/*; do
        [[ -f "$img_file" ]] || continue
        ref="${img_file#images/}"
        if [[ -z "${IMG_FILE_OWNERS[$ref]:-}" ]]; then
            warn "Image $ref not referenced by any .adoc file — keeping as-is"
        fi
    done

    if ! $EXEC; then
        phase "DRY RUN COMPLETE"
        echo ""
        echo "Summary:"
        echo "  Titles to rename: $(for d in "${!DIR_CTX[@]}"; do ctx="${DIR_CTX[$d]}"; [[ "$d" != "${CTX_DEST[$ctx]}" ]] && echo x; done | wc -l)"
        echo "  Assembly dirs to rename: $(for d in "${!ASM_DIR_DEST[@]}"; do [[ "$d" != "${ASM_DIR_DEST[$d]}" ]] && echo x; done | wc -l)"
        echo "  Flat assemblies to move: ${#FLAT_ASM_DEST[@]}"
        echo "  Module dirs to rename: $(for d in "${!MOD_DIR_DEST[@]}"; do [[ "$d" != "${MOD_DIR_DEST[$d]}" ]] && echo x; done | wc -l)"
        echo "  Image files to move: ${#IMG_FILE_DEST[@]}"
        echo ""
        echo "Re-run with --exec to apply: $0 --all --exec"
        exit 0
    fi

    # ── Phase 1: Rename title directories ─────────────────────────
    phase "Phase 1: Rename title directories"
    # Process in sorted order for deterministic output
    for master in $(find titles -maxdepth 2 -name master.adoc | sort); do
        d=$(basename "$(dirname "$master")")
        ctx="${DIR_CTX[$d]}"
        new_dir="${CTX_DEST[$ctx]}"
        if [[ "$d" != "$new_dir" ]]; then
            info "git mv titles/$d titles/$new_dir"
            git mv "titles/$d" "titles/$new_dir"
        fi
    done

    # ── Phase 2: Move assembly directories and files ──────────────
    phase "Phase 2: Move assemblies"

    # Rename existing subdirs (sorted to handle merges predictably)
    for old_dir in $(echo "${!ASM_DIR_DEST[@]}" | tr ' ' '\n' | sort); do
        new_dir="${ASM_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        [[ ! -d "assemblies/$old_dir" ]] && continue

        if [[ -d "assemblies/$new_dir" ]]; then
            info "Merging assemblies/$old_dir → assemblies/$new_dir"
            move_dir_contents "assemblies/$old_dir" "assemblies/$new_dir"
        else
            info "git mv assemblies/$old_dir assemblies/$new_dir"
            git mv "assemblies/$old_dir" "assemblies/$new_dir"
        fi
    done

    # Move flat assembly files into subdirs
    for bn in $(echo "${!FLAT_ASM_DEST[@]}" | tr ' ' '\n' | sort); do
        dest="${FLAT_ASM_DEST[$bn]}"
        [[ ! -f "assemblies/$bn" ]] && continue
        mkdir -p "assemblies/$dest"
        info "git mv assemblies/$bn assemblies/$dest/"
        git mv "assemblies/$bn" "assemblies/$dest/"
    done

    # ── Phase 3: Move module directories ──────────────────────────
    phase "Phase 3: Move modules"

    for old_dir in $(echo "${!MOD_DIR_DEST[@]}" | tr ' ' '\n' | sort); do
        new_dir="${MOD_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        [[ ! -d "modules/$old_dir" ]] && continue

        if [[ -d "modules/$new_dir" ]]; then
            info "Merging modules/$old_dir → modules/$new_dir"
            move_dir_contents "modules/$old_dir" "modules/$new_dir"
        else
            info "git mv modules/$old_dir modules/$new_dir"
            git mv "modules/$old_dir" "modules/$new_dir"
        fi
    done

    # ── Phase 4: Move image files ───────────────────────────────────
    phase "Phase 4: Move images"

    for ref in $(echo "${!IMG_FILE_DEST[@]}" | tr ' ' '\n' | sort); do
        dest="${IMG_FILE_DEST[$ref]}"
        [[ ! -f "images/$ref" ]] && continue
        bn=$(basename "$ref")
        mkdir -p "images/$dest"
        info "git mv images/$ref images/$dest/$bn"
        git mv "images/$ref" "images/$dest/$bn"
    done

    # Clean up empty image directories
    find images/ -mindepth 1 -type d -empty -delete 2>/dev/null || true

    # ── Phase 5: Update include paths ─────────────────────────────
    phase "Phase 5: Update include and image paths"

    # Build sed script for master.adoc files
    master_sed=""

    # Assembly dir renames
    for old_dir in "${!ASM_DIR_DEST[@]}"; do
        new_dir="${ASM_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        master_sed="${master_sed}s|include::assemblies/${old_dir}/|include::assemblies/${new_dir}/|g;"
    done

    # Flat assembly file moves: assemblies/file.adoc → assemblies/<dest>/file.adoc
    for bn in "${!FLAT_ASM_DEST[@]}"; do
        dest="${FLAT_ASM_DEST[$bn]}"
        master_sed="${master_sed}s|include::assemblies/${bn}|include::assemblies/${dest}/${bn}|g;"
    done

    # Module dir renames
    for old_dir in "${!MOD_DIR_DEST[@]}"; do
        new_dir="${MOD_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        master_sed="${master_sed}s|include::modules/${old_dir}/|include::modules/${new_dir}/|g;"
    done

    # Image file moves: image::old_dir/file.png → image::new_dir/file.png (no ../ ever)
    for ref in "${!IMG_FILE_DEST[@]}"; do
        dest="${IMG_FILE_DEST[$ref]}"
        bn=$(basename "$ref")
        old_dir=$(dirname "$ref")
        master_sed="${master_sed}s|image::${old_dir}/${bn}|image::${dest}/${bn}|g;"
        master_sed="${master_sed}s|image:${old_dir}/${bn}|image:${dest}/${bn}|g;"
    done

    # Apply to all master.adoc files
    if [[ -n "$master_sed" ]]; then
        for master in titles/*/master.adoc; do
            sed -i "$master_sed" "$master"
        done
        info "Updated include paths in master.adoc files"
    fi

    # Build sed script for assembly files
    asm_sed=""

    # Module dir renames: ../modules/<old>/ → ../modules/<new>/
    # Also handle: modules/<old>/ → ../modules/<new>/ (flat assemblies that moved to subdirs)
    for old_dir in "${!MOD_DIR_DEST[@]}"; do
        new_dir="${MOD_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        asm_sed="${asm_sed}s|include::\.\.\/modules/${old_dir}/|include::../modules/${new_dir}/|g;"
        asm_sed="${asm_sed}s|include::modules/${old_dir}/|include::../modules/${new_dir}/|g;"
    done

    # Assembly cross-references: ../assemblies/<old>/ → ../assemblies/<new>/
    for old_dir in "${!ASM_DIR_DEST[@]}"; do
        new_dir="${ASM_DIR_DEST[$old_dir]}"
        [[ "$old_dir" == "$new_dir" ]] && continue
        asm_sed="${asm_sed}s|include::\.\.\/assemblies/${old_dir}/|include::../assemblies/${new_dir}/|g;"
    done

    # Image file moves in assembly files (same pattern, no ../)
    for ref in "${!IMG_FILE_DEST[@]}"; do
        dest="${IMG_FILE_DEST[$ref]}"
        bn=$(basename "$ref")
        old_dir=$(dirname "$ref")
        asm_sed="${asm_sed}s|image::${old_dir}/${bn}|image::${dest}/${bn}|g;"
        asm_sed="${asm_sed}s|image:${old_dir}/${bn}|image:${dest}/${bn}|g;"
    done

    # Apply to all assembly .adoc files in subdirs
    if [[ -n "$asm_sed" ]]; then
        for asm_file in assemblies/*/*.adoc; do
            [[ -f "$asm_file" ]] || continue
            sed -i "$asm_sed" "$asm_file"
        done
        info "Updated include paths in assembly files"
    fi

    # Update image references in module files
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
        info "Updated image paths in module files"
    fi

    # Fix flat assemblies that moved into subdirs:
    # They used include::modules/ (no ../) — now they need ../modules/
    # The asm_sed above already handles renaming, but for module dirs that
    # did NOT rename, we still need to add the ../ prefix
    for bn in "${!FLAT_ASM_DEST[@]}"; do
        dest="${FLAT_ASM_DEST[$bn]}"
        file="assemblies/$dest/$bn"
        [[ -f "$file" ]] || continue
        # Add ../ to any remaining include::modules/ that wasn't caught by renames
        sed -i 's|include::modules/|include::../modules/|g' "$file"
        # Fix any double ../ that might result
        sed -i 's|include::\.\.\/\.\.\/modules/|include::../modules/|g' "$file"
    done
    info "Fixed ../ prefix for flat assemblies moved to subdirs"

    # Also fix flat assemblies that had include::assemblies/ (same-dir sub-assembly refs)
    # These were previously flat, so they used include::assemblies/<dir>/file
    # Now in a subdir, they should use include::../assemblies/<dir>/file
    for bn in "${!FLAT_ASM_DEST[@]}"; do
        dest="${FLAT_ASM_DEST[$bn]}"
        file="assemblies/$dest/$bn"
        [[ -f "$file" ]] || continue
        # Only fix non-relative assembly includes (not include::assembly- which is same-dir)
        sed -i 's|include::assemblies/|include::../assemblies/|g' "$file"
        sed -i 's|include::\.\.\/\.\.\/assemblies/|include::../assemblies/|g' "$file"
    done

    # ── Phase 6: Verify ───────────────────────────────────────────
    phase "Phase 6: Verification"

    ERRORS=0
    # Check that all include targets exist
    for master in titles/*/master.adoc; do
        title_dir=$(dirname "$master")
        while IFS= read -r inc; do
            [[ -z "$inc" ]] && continue
            # Resolve through symlinks in title dir
            target="$title_dir/$inc"
            if [[ ! -e "$target" ]]; then
                error "$master: missing include target: $inc"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(grep -v '^//' "$master" 2>/dev/null | grep -oP 'include::\K[^[]+' || true)
    done

    for asm_file in assemblies/*/*.adoc; do
        [[ -f "$asm_file" ]] || continue
        asm_dir=$(dirname "$asm_file")
        while IFS= read -r inc; do
            [[ -z "$inc" ]] && continue
            target="$asm_dir/$inc"
            if [[ ! -e "$target" ]]; then
                error "$asm_file: missing include target: $inc"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(grep -v '^//' "$asm_file" 2>/dev/null | grep -oP 'include::\K[^[]+' || true)
    done

    # Verify image references (block image:: and inline image: macros)
    # Only match actual AsciiDoc image macros, not YAML `image:` keys in code blocks
    for adoc_file in $(find titles modules assemblies -name '*.adoc' 2>/dev/null | sort); do
        [[ -f "$adoc_file" ]] || continue
        while IFS= read -r img_ref; do
            [[ -z "$img_ref" ]] && continue
            # Skip non-image refs: YAML container images, OCI URIs, refs without subdir/
            [[ "$img_ref" == *"://"* || "$img_ref" == *" "* || "$img_ref" == *"'"* ]] && continue
            [[ "$img_ref" != *"/"* ]] && continue
            # Image references should never contain ../
            if [[ "$img_ref" == *"../"* ]]; then
                error "$adoc_file: image reference contains '../': image::$img_ref"
                ERRORS=$((ERRORS + 1))
                continue
            fi
            # Check image file exists via images/ directory
            if [[ ! -f "images/$img_ref" ]]; then
                error "$adoc_file: missing image: images/$img_ref"
                ERRORS=$((ERRORS + 1))
            fi
        done < <(grep -v '^//' "$adoc_file" 2>/dev/null | grep -oP 'image::?\K[^[\]]+' || true)
    done

    if [[ $ERRORS -gt 0 ]]; then
        warn "$ERRORS broken reference(s) found — review and fix manually"
    else
        info "All include and image targets verified"
    fi

    phase "Done"
    info "Review: git diff --stat"
    info "Build:  ./build/scripts/build-ccutil.sh"
    exit 0
fi

# ═══════════════════════════════════════════════════════════════════
# Single-title mode (legacy)
# ═══════════════════════════════════════════════════════════════════

DRY_RUN=true
if [[ "${1:-}" == "--exec" ]]; then
    DRY_RUN=false
    shift
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 [--exec] <title-dir> [<new-context>]"
    echo "       $0 --list"
    echo "       $0 --all [--exec]"
    exit 1
fi

TITLE_PATH="$1"
TITLE_PATH="${TITLE_PATH%/}"
[[ "$TITLE_PATH" != titles/* ]] && TITLE_PATH="titles/$TITLE_PATH"

OLD_DIR=$(basename "$TITLE_PATH")
MASTER="$TITLE_PATH/master.adoc"

if [[ ! -f "$MASTER" ]]; then
    error "File not found: $MASTER"
    exit 1
fi

if [[ $# -eq 2 ]]; then
    NEW_CONTEXT="$2"
    info "Using explicit context: $NEW_CONTEXT"
else
    TITLE_ATTR=$(read_title "$MASTER")
    if [[ -z "$TITLE_ATTR" ]]; then
        error "No :title: attribute found in $MASTER"
        exit 1
    fi
    NEW_CONTEXT=$(derive_context "$TITLE_ATTR" "$MASTER")
    info "Derived context from ':title: $TITLE_ATTR'"
    info "  → $NEW_CONTEXT"
fi

# Add category prefix if available
CAT=$(read_category "$MASTER")
if [[ -n "$CAT" ]]; then
    CATSLUG=$(slugify_category "$CAT")
    NEW_DIR="${CATSLUG}_${NEW_CONTEXT}"
    info "Category: $CAT → prefix: $CATSLUG"
else
    NEW_DIR="$NEW_CONTEXT"
fi

if [[ "$OLD_DIR" == "$NEW_DIR" ]]; then
    info "Directory already matches: $OLD_DIR"
fi

info "Migrating: titles/$OLD_DIR → titles/$NEW_DIR"

ASSEMBLY_INCLUDES=$(grep -v '^//' "$MASTER" 2>/dev/null | grep -oP 'include::assemblies/\K[^[]+' || true)
ASSEMBLY_COUNT=$(echo "$ASSEMBLY_INCLUDES" | grep -c '\.adoc$' || true)
ASSEMBLY_COUNT=${ASSEMBLY_COUNT:-0}
MODULE_DIRS=$(grep -v '^//' "$MASTER" 2>/dev/null | grep -oP 'include::modules/\K[^/]+' | sort -u || true)

info "Found $ASSEMBLY_COUNT assembly includes"

if $DRY_RUN; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Would rename: titles/$OLD_DIR → titles/$NEW_DIR"
    exit 0
fi

# Rename title directory
if [[ "$OLD_DIR" != "$NEW_DIR" ]]; then
    info "Renaming titles/$OLD_DIR → titles/$NEW_DIR"
    git mv "titles/$OLD_DIR" "titles/$NEW_DIR"
    MASTER="titles/$NEW_DIR/master.adoc"
fi

# Move flat assemblies
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
                info "Moving $asm_file → assemblies/$NEW_DIR/"
                git mv "$asm_file" "assemblies/$NEW_DIR/"
            fi
        done
    fi
fi

# Move modules
if [[ -n "$MODULE_DIRS" ]]; then
    while IFS= read -r mod_dir; do
        [[ -z "$mod_dir" || "$mod_dir" == "$NEW_DIR" || "$mod_dir" == "shared" ]] && continue
        if [[ -d "modules/$mod_dir" ]]; then
            if [[ -d "modules/$NEW_DIR" ]]; then
                info "Merging modules/$mod_dir/* → modules/$NEW_DIR/"
                for f in "modules/$mod_dir"/*; do
                    [[ -e "$f" ]] && git mv "$f" "modules/$NEW_DIR/"
                done
                rmdir "modules/$mod_dir" 2>/dev/null || true
            else
                info "Renaming modules/$mod_dir → modules/$NEW_DIR"
                git mv "modules/$mod_dir" "modules/$NEW_DIR"
            fi
        fi
    done <<< "$MODULE_DIRS"
fi

# Update include paths
info "Updating include paths"
sed -i "s|include::assemblies/assembly-|include::assemblies/$NEW_DIR/assembly-|g" "$MASTER"
if [[ -n "$MODULE_DIRS" ]]; then
    while IFS= read -r mod_dir; do
        [[ -z "$mod_dir" || "$mod_dir" == "$NEW_DIR" ]] && continue
        sed -i "s|include::modules/$mod_dir/|include::modules/$NEW_DIR/|g" "$MASTER"
    done <<< "$MODULE_DIRS"
fi

# Update :context:
sed -i "s|^:context:.*|:context: $NEW_CONTEXT|" "$MASTER"

info "Done! Review: git diff --stat"
