#!/bin/bash
# align-title-directories.sh
#
# Aligns title, assembly, and module directory names with the :context: attribute
# derived from the :title: attribute in master.adoc.
#
# Usage:
#   ./build/scripts/align-title-directories.sh <title-dir>                        (dry-run, derive context)
#   ./build/scripts/align-title-directories.sh <title-dir> <new-context>          (dry-run, explicit context)
#   ./build/scripts/align-title-directories.sh --exec <title-dir>                 (execute, derive context)
#   ./build/scripts/align-title-directories.sh --exec <title-dir> <new-context>   (execute, explicit context)
#   ./build/scripts/align-title-directories.sh --list
#
# Examples:
#   ./build/scripts/align-title-directories.sh titles/audit-log
#   ./build/scripts/align-title-directories.sh --exec titles/about
#   ./build/scripts/align-title-directories.sh --exec titles/about about-rhdh
#   ./build/scripts/align-title-directories.sh --list
#
# The script:
# 1. Derives :context: from :title: (or uses explicit value)
# 2. Sets :context: and [id="{context}"] in master.adoc
# 3. Renames titles/<old>/ to titles/<new>/
# 4. Moves assemblies referenced by master.adoc into assemblies/<new>/
# 5. Moves modules referenced by assemblies into modules/<new>/
# 6. Updates all include paths
# 7. For single-assembly titles: inlines assembly content into master.adoc
#
# Prerequisites:
# - Run from the repository root
# - Working tree must be clean (no uncommitted changes)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Resolve local attributes defined in a master.adoc file.
# Reads :attr: value lines and substitutes them into the title string.
resolve_local_attrs() {
    local title="$1"
    local master="$2"

    # Parse local attributes from master.adoc (lines matching :attr: value)
    while IFS= read -r line; do
        local attr_name attr_value
        attr_name=$(echo "$line" | sed 's/^:\([^:]*\):.*/\1/')
        attr_value=$(echo "$line" | sed 's/^:[^:]*: *//')
        # Only substitute if the attribute is actually referenced in the title
        if [[ "$title" == *"{${attr_name}}"* ]]; then
            title="${title//\{${attr_name}\}/${attr_value}}"
        fi
    done < <(grep -E '^:[a-z][-a-z0-9]*:' "$master" 2>/dev/null | grep -v '^:_mod-docs' | grep -v '^:context:' | grep -v '^:title:' | grep -v '^:subtitle:' | grep -v '^:abstract:' | grep -v '^:imagesdir:' || true)

    echo "$title"
}

# Derive context slug from a :title: value.
# Replaces AsciiDoc attribute references with their shortest slug equivalents,
# converts to lowercase, and replaces spaces/special chars with hyphens.
# Pass master.adoc path as $2 to resolve local attributes.
derive_context() {
    local title="$1"
    local master="${2:-}"

    # First resolve local attributes from master.adoc (e.g., {platform-long})
    if [[ -n "$master" && -f "$master" ]]; then
        title=$(resolve_local_attrs "$title" "$master")
    fi

    # Replace attribute references with shortest slug equivalents.
    # Order matters: replace longer/more-specific attributes before shorter ones.
    # Compound attributes (containing other attributes) first:
    title="${title//\{ls-brand-name\}/developer-lightspeed-for-rhdh}"
    title="${title//\{ls-short\}/developer-lightspeed-for-rhdh}"
    title="${title//\{openshift-ai-connector-name\}/openshift-ai-connector-for-rhdh}"
    title="${title//\{openshift-ai-connector-name-short\}/openshift-ai-connector-for-rhdh}"

    # Product attributes:
    title="${title//\{product\}/rhdh}"
    title="${title//\{product-short\}/rhdh}"
    title="${title//\{product-very-short\}/rhdh}"
    title="${title//\{product-local\}/rhdh-local}"
    title="${title//\{product-local-very-short\}/rhdh-local}"

    # Platform attributes (use shortest form):
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

    # Convert to lowercase
    title="${title,,}"

    # Replace spaces and underscores with hyphens
    title="${title// /-}"
    title="${title//_/-}"

    # Remove parentheses and their content (e.g., "(RBAC)" or "(AKS)")
    title=$(echo "$title" | sed 's/([^)]*)//g')

    # Remove any remaining special characters except hyphens
    title=$(echo "$title" | sed 's/[^a-z0-9-]//g')

    # Collapse multiple hyphens
    title=$(echo "$title" | sed 's/-\{2,\}/-/g')

    # Remove leading/trailing hyphens
    title=$(echo "$title" | sed 's/^-//;s/-$//')

    echo "$title"
}

# Read :title: attribute from a master.adoc file
read_title() {
    local master="$1"
    grep -m1 '^:title:' "$master" 2>/dev/null | sed 's/^:title: //'
}

# List mode: show all titles with current context and derived context
if [[ "${1:-}" == "--list" ]]; then
    echo "Title directories, current :context:, and derived context:"
    echo "==========================================================="
    printf "%-55s %-45s %-45s\n" "Directory" ":context:" "Derived context"
    printf "%-55s %-45s %-45s\n" "---------" "--------" "---------------"
    for master in titles/*/master.adoc; do
        dir=$(dirname "$master" | sed 's|titles/||')
        context=$(grep -m1 '^:context:' "$master" 2>/dev/null | sed 's/^:context: //' || echo "(none)")
        title_attr=$(read_title "$master")
        if [[ -n "$title_attr" ]]; then
            derived=$(derive_context "$title_attr" "$master")
        else
            derived="(no :title:)"
        fi
        match=""
        if [[ "$dir" == "$derived" ]]; then
            match=""
        elif [[ "$context" == "$derived" ]]; then
            match=" (ctx ok, dir differs)"
        else
            match=" *"
        fi
        printf "%-55s %-45s %-45s%s\n" "$dir" "$context" "$derived" "$match"
    done
    echo ""
    echo "* = context or directory needs updating"
    exit 0
fi

DRY_RUN=true
if [[ "${1:-}" == "--exec" ]]; then
    DRY_RUN=false
    shift
fi

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 [--exec] <title-dir> [<new-context>]"
    echo "       $0 --list"
    echo ""
    echo "Dry-run is the default. Use --exec to apply changes."
    echo "If <new-context> is omitted, it is derived from the :title: attribute."
    echo ""
    echo "Examples:"
    echo "  $0 titles/audit-log                          # dry-run, derive context"
    echo "  $0 --exec titles/about                       # execute, derive context"
    echo "  $0 --exec titles/about about-rhdh            # execute, explicit context"
    exit 1
fi

TITLE_PATH="$1"

# Normalize title path
TITLE_PATH="${TITLE_PATH%/}"
if [[ "$TITLE_PATH" != titles/* ]]; then
    TITLE_PATH="titles/$TITLE_PATH"
fi

OLD_DIR=$(basename "$TITLE_PATH")
MASTER="$TITLE_PATH/master.adoc"

if [[ ! -f "$MASTER" ]]; then
    error "File not found: $MASTER"
    exit 1
fi

# Determine new context: explicit argument or derived from :title:
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

if [[ "$OLD_DIR" == "$NEW_CONTEXT" ]]; then
    info "Directory already matches context: $OLD_DIR"
    info "Only updating :context: attribute and include paths"
fi

info "Migrating: titles/$OLD_DIR → titles/$NEW_CONTEXT"

# Step 1: Find assemblies referenced by master.adoc
ASSEMBLY_INCLUDES=$(grep -oP 'include::assemblies/\K[^[]+' "$MASTER" 2>/dev/null || true)
ASSEMBLY_COUNT=$(echo "$ASSEMBLY_INCLUDES" | grep -c '\.adoc$' || true)
ASSEMBLY_COUNT=${ASSEMBLY_COUNT:-0}

# Find module directories referenced by master.adoc
MODULE_DIRS=$(grep -oP 'include::modules/\K[^/]+' "$MASTER" 2>/dev/null | sort -u || true)

info "Found $ASSEMBLY_COUNT assembly includes"
info "Module directories referenced: ${MODULE_DIRS:-none}"

if $DRY_RUN; then
    echo ""
    echo "=== DRY RUN ==="
    echo "Would rename: titles/$OLD_DIR → titles/$NEW_CONTEXT"
    if [[ $ASSEMBLY_COUNT -gt 0 ]]; then
        echo "Would move assemblies to: assemblies/$NEW_CONTEXT/"
        echo "$ASSEMBLY_INCLUDES" | while read -r asm; do
            [[ -n "$asm" ]] && echo "  assemblies/$asm"
        done
    fi
    if [[ -n "$MODULE_DIRS" ]]; then
        echo "Would move modules to: modules/$NEW_CONTEXT/"
        echo "$MODULE_DIRS" | while read -r mod; do
            [[ -n "$mod" ]] && echo "  modules/$mod/ → modules/$NEW_CONTEXT/"
        done
    fi
    exit 0
fi

# Step 2: Rename title directory
if [[ "$OLD_DIR" != "$NEW_CONTEXT" ]]; then
    info "Renaming titles/$OLD_DIR → titles/$NEW_CONTEXT"
    git mv "titles/$OLD_DIR" "titles/$NEW_CONTEXT"
    MASTER="titles/$NEW_CONTEXT/master.adoc"
fi

# Step 3: Move assemblies
if [[ $ASSEMBLY_COUNT -gt 0 ]]; then
    # Collect unique assembly files (resolve paths)
    ASSEMBLY_FILES=()
    while IFS= read -r asm; do
        [[ -z "$asm" ]] && continue
        # Handle assemblies in subdirectories (already migrated) vs loose assemblies
        if [[ -f "assemblies/$asm" ]]; then
            ASSEMBLY_FILES+=("assemblies/$asm")
        fi
    done <<< "$ASSEMBLY_INCLUDES"

    if [[ ${#ASSEMBLY_FILES[@]} -gt 0 ]]; then
        mkdir -p "assemblies/$NEW_CONTEXT"
        for asm_file in "${ASSEMBLY_FILES[@]}"; do
            asm_basename=$(basename "$asm_file")
            if [[ ! -f "assemblies/$NEW_CONTEXT/$asm_basename" ]]; then
                info "Moving $asm_file → assemblies/$NEW_CONTEXT/"
                git mv "$asm_file" "assemblies/$NEW_CONTEXT/"
            fi
        done

        # Move sub-assemblies referenced by the moved assemblies
        for asm_file in assemblies/$NEW_CONTEXT/*.adoc; do
            sub_asms=$(grep -oP 'include::assembly-\K[^[]+' "$asm_file" 2>/dev/null || true)
            while IFS= read -r sub; do
                [[ -z "$sub" ]] && continue
                sub_file="assemblies/assembly-$sub"
                if [[ -f "$sub_file" ]]; then
                    info "Moving sub-assembly $sub_file → assemblies/$NEW_CONTEXT/"
                    git mv "$sub_file" "assemblies/$NEW_CONTEXT/"
                fi
            done <<< "$sub_asms"
        done
    fi
fi

# Step 4: Move modules
if [[ -n "$MODULE_DIRS" ]]; then
    while IFS= read -r mod_dir; do
        [[ -z "$mod_dir" ]] && continue
        [[ "$mod_dir" == "$NEW_CONTEXT" ]] && continue
        if [[ -d "modules/$mod_dir" ]]; then
            if [[ -d "modules/$NEW_CONTEXT" ]]; then
                # Merge into existing directory
                info "Merging modules/$mod_dir/* → modules/$NEW_CONTEXT/"
                for f in "modules/$mod_dir"/*; do
                    [[ -e "$f" ]] && git mv "$f" "modules/$NEW_CONTEXT/"
                done
                rmdir "modules/$mod_dir" 2>/dev/null || true
            else
                info "Renaming modules/$mod_dir → modules/$NEW_CONTEXT"
                git mv "modules/$mod_dir" "modules/$NEW_CONTEXT"
            fi
        fi
    done <<< "$MODULE_DIRS"
fi

# Also move modules referenced by the assemblies (not just master.adoc)
if [[ -d "assemblies/$NEW_CONTEXT" ]]; then
    ASM_MODULE_DIRS=$(grep -ohP 'include::modules/\K[^/]+' assemblies/$NEW_CONTEXT/*.adoc 2>/dev/null | sort -u || true)
    while IFS= read -r mod_dir; do
        [[ -z "$mod_dir" ]] && continue
        [[ "$mod_dir" == "$NEW_CONTEXT" ]] && continue
        [[ "$mod_dir" == "shared" ]] && continue
        if [[ -d "modules/$mod_dir" ]]; then
            # Check if this module dir is used by other titles
            other_refs=$(grep -rl "modules/$mod_dir/" titles/*/master.adoc assemblies/*.adoc 2>/dev/null | grep -v "assemblies/$NEW_CONTEXT/" | head -1 || true)
            if [[ -n "$other_refs" ]]; then
                warn "modules/$mod_dir/ is shared with other titles, skipping move"
            else
                if [[ -d "modules/$NEW_CONTEXT" ]]; then
                    info "Merging modules/$mod_dir/* → modules/$NEW_CONTEXT/"
                    for f in "modules/$mod_dir"/*; do
                        [[ -e "$f" ]] && git mv "$f" "modules/$NEW_CONTEXT/"
                    done
                    rmdir "modules/$mod_dir" 2>/dev/null || true
                else
                    info "Renaming modules/$mod_dir → modules/$NEW_CONTEXT"
                    git mv "modules/$mod_dir" "modules/$NEW_CONTEXT"
                fi
            fi
        fi
    done <<< "$ASM_MODULE_DIRS"
fi

# Step 5: Update include paths in master.adoc
info "Updating include paths in master.adoc"

# Update assembly includes: assemblies/assembly-*.adoc → assemblies/<context>/assembly-*.adoc
sed -i "s|include::assemblies/assembly-|include::assemblies/$NEW_CONTEXT/assembly-|g" "$MASTER"

# Update module includes: modules/<old>/ → modules/<context>/
if [[ -n "$MODULE_DIRS" ]]; then
    while IFS= read -r mod_dir; do
        [[ -z "$mod_dir" ]] && continue
        [[ "$mod_dir" == "$NEW_CONTEXT" ]] && continue
        sed -i "s|include::modules/$mod_dir/|include::modules/$NEW_CONTEXT/|g" "$MASTER"
    done <<< "$MODULE_DIRS"
fi

# Step 6: Update include paths in assemblies
if [[ -d "assemblies/$NEW_CONTEXT" ]]; then
    info "Updating include paths in assemblies"
    for asm_file in assemblies/$NEW_CONTEXT/*.adoc; do
        # Update module paths: modules/<old>/ → ../modules/<context>/
        if [[ -n "${ASM_MODULE_DIRS:-}" ]]; then
            while IFS= read -r mod_dir; do
                [[ -z "$mod_dir" ]] && continue
                [[ "$mod_dir" == "$NEW_CONTEXT" ]] && continue
                sed -i "s|include::modules/$mod_dir/|include::../modules/$NEW_CONTEXT/|g" "$asm_file"
                # Handle double-slash typos
                sed -i "s|include::modules/$mod_dir//|include::../modules/$NEW_CONTEXT/|g" "$asm_file"
            done <<< "$ASM_MODULE_DIRS"
        fi

        # Update sub-assembly cross-references: assembly-*.adoc → ../assemblies/<context>/assembly-*.adoc
        sed -i "s|include::assembly-|include::../assemblies/$NEW_CONTEXT/assembly-|g" "$asm_file"
    done
fi

# Step 7: Update :context: in master.adoc
info "Setting :context: $NEW_CONTEXT in master.adoc"
sed -i "s|^:context:.*|:context: $NEW_CONTEXT|" "$MASTER"

# Ensure [id="{context}"] and = {title} are present
if ! grep -q '^\[id="{context}"\]' "$MASTER"; then
    warn "master.adoc missing [id=\"{context}\"] - please add manually"
fi

# Step 8: Verify include paths
info "Verifying include paths..."
VERIFY_ERRORS=0

# Verify master.adoc: all includes should point to shared/ or $NEW_CONTEXT/
while IFS= read -r inc; do
    if [[ "$inc" != *"/$NEW_CONTEXT/"* && "$inc" != *"/shared/"* && "$inc" != *"artifacts/"* ]]; then
        error "master.adoc: include points outside context: $inc"
        VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
    fi
done < <(grep -oP 'include::\K(assemblies|modules)/[^[]+' "$MASTER" 2>/dev/null || true)

# Verify assemblies: all includes should point to shared/ or $NEW_CONTEXT/
if [[ -d "assemblies/$NEW_CONTEXT" ]]; then
    for asm_file in assemblies/$NEW_CONTEXT/*.adoc; do
        [[ -f "$asm_file" ]] || continue
        while IFS= read -r inc; do
            if [[ "$inc" != *"/$NEW_CONTEXT/"* && "$inc" != *"/shared/"* && "$inc" != *"artifacts/"* ]]; then
                error "$(basename "$asm_file"): include points outside context: $inc"
                VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
            fi
        done < <(grep -oP 'include::\K\.\./(assemblies|modules)/[^[]+' "$asm_file" 2>/dev/null || true)
        # Also check non-relative includes (modules/ without ../)
        while IFS= read -r inc; do
            if [[ "$inc" != *"/$NEW_CONTEXT/"* && "$inc" != *"/shared/"* && "$inc" != *"artifacts/"* ]]; then
                error "$(basename "$asm_file"): include points outside context: $inc"
                VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
            fi
        done < <(grep -oP 'include::\K(modules|assemblies)/[^[]+' "$asm_file" 2>/dev/null || true)
    done
fi

if [[ $VERIFY_ERRORS -gt 0 ]]; then
    warn "$VERIFY_ERRORS include path(s) need manual fixing"
else
    info "All include paths verified"
fi

info "Done! Next steps:"
info "  1. Review changes: git diff --stat"
info "  2. Build: ./build/scripts/build-ccutil.sh"
info "  3. Commit: git add -A && git commit -m 'RHIDP-12703: Simplify file hierarchy for <title>'"
