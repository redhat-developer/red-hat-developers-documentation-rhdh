#!/bin/bash
# cqa-00-orphaned-modules.sh - Find and optionally delete orphaned modules (CQA #0)
#
# Usage: ./cqa-00-orphaned-modules.sh [--fix] [--format checklist|json]
#
# Unlike other CQA scripts, this operates on the entire repository (not per-title).
# The --all flag is accepted but ignored (always scans everything).
# A positional <file-path> argument is also accepted but ignored.
#
# Checks:
#   - .adoc files in artifacts/, assemblies/, modules/ not referenced by any include::
#   - Image files in images/ not referenced by any .adoc file
#
# Autofix (--fix): Deletes orphaned files (git rm if tracked, rm otherwise)

source "$(dirname "${BASH_SOURCE[0]}")/cqa-lib.sh"

# Custom arg parsing: accept standard flags but don't require a target file
CQA_FIX_MODE=false
CQA_FORMAT="checklist"
for arg in "$@"; do
    case "$arg" in
        --fix)         CQA_FIX_MODE=true ;;
        --all)         ;; # accepted, ignored (always scans everything)
        --format=*)    CQA_FORMAT="${arg#--format=}" ;;
        --format)      ;; # next arg handled below
        checklist|json)
            # Could be the value after --format
            if [[ "${_prev_arg:-}" == "--format" ]]; then
                CQA_FORMAT="$arg"
            fi
            ;;
        -h|--help)
            echo "Usage: $0 [--fix] [--format checklist|json]" >&2
            exit 0
            ;;
        *)
            # Accept and ignore positional args (file paths) for interface compatibility
            ;;
    esac
    _prev_arg="$arg"
done

cqa_header "0" "Find Orphaned Modules and Images"

# ── Collect all include:: references ──
declare -A INCLUDED_BASENAMES=()

while IFS= read -r inc_line; do
    # Extract path from include::path[...]
    inc_path="${inc_line#include::}"
    inc_path="${inc_path%%\[*}"
    inc_bn=$(basename "$inc_path")

    # If basename contains {attribute}, convert to regex pattern
    if [[ "$inc_bn" == *"{"* ]]; then
        INCLUDED_BASENAMES["pattern:$inc_bn"]=1
    else
        INCLUDED_BASENAMES["$inc_bn"]=1
    fi
done < <(grep -rh "^include::" --include="*.adoc" . 2>/dev/null | sed 's/^[[:space:]]*//')

# ── Collect all image references ──
declare -A REFERENCED_IMAGES=()

while IFS= read -r img_ref; do
    REFERENCED_IMAGES["$img_ref"]=1
done < <(grep -roh 'image::[^[]*' --include="*.adoc" titles/ modules/ assemblies/ 2>/dev/null | sed 's/^image:://' | xargs -I{} basename "{}" 2>/dev/null | sort -u)

# Also check inline image: references
while IFS= read -r img_ref; do
    REFERENCED_IMAGES["$img_ref"]=1
done < <(grep -roh 'image:[^:][^[]*' --include="*.adoc" titles/ modules/ assemblies/ 2>/dev/null | sed 's/^image://' | xargs -I{} basename "{}" 2>/dev/null | sort -u)

# ── Helper: check if a basename matches any include pattern ──
_is_included() {
    local basename="$1"

    # Direct match
    [[ -n "${INCLUDED_BASENAMES[$basename]+x}" ]] && return 0

    # Pattern match (for includes with {attribute} substitution)
    for key in "${!INCLUDED_BASENAMES[@]}"; do
        if [[ "$key" == pattern:* ]]; then
            local pattern="${key#pattern:}"
            # Convert {attribute} to .* and dots to [.]
            local regex
            regex=$(echo "$pattern" | sed 's/\./[.]/g' | sed 's/{[^}]*}/.*/g')
            if [[ "$basename" =~ ^${regex}$ ]]; then
                return 0
            fi
        fi
    done

    return 1
}

# ── Check .adoc files ──
ORPHANED_COUNT=0
DELETED_COUNT=0

while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    # Skip template files
    [[ "$file" == *.template.adoc ]] && continue

    cqa_file_start "$file"

    file_bn=$(basename "$file")

    if ! _is_included "$file_bn"; then
        if [[ "$CQA_FIX_MODE" == true ]]; then
            if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
                git rm -q "$file" 2>/dev/null || rm -f "$file"
            else
                rm -f "$file"
            fi
            DELETED_COUNT=$((DELETED_COUNT + 1))
        fi
        cqa_fail_autofix "$file" "" "Orphaned .adoc file (not included anywhere)" "Deleted orphaned file"
        ORPHANED_COUNT=$((ORPHANED_COUNT + 1))
    fi
done < <(find artifacts assemblies modules -name "*.adoc" -type f 2>/dev/null | sort)

# ── Check image files ──
while IFS= read -r file; do
    [[ -f "$file" ]] || continue

    cqa_file_start "$file"

    file_bn=$(basename "$file")

    if [[ -z "${REFERENCED_IMAGES[$file_bn]+x}" ]]; then
        if [[ "$CQA_FIX_MODE" == true ]]; then
            if git ls-files --error-unmatch "$file" >/dev/null 2>&1; then
                git rm -q "$file" 2>/dev/null || rm -f "$file"
            else
                rm -f "$file"
            fi
            DELETED_COUNT=$((DELETED_COUNT + 1))
        fi
        cqa_fail_autofix "$file" "" "Orphaned image (not referenced by any .adoc file)" "Deleted orphaned image"
        ORPHANED_COUNT=$((ORPHANED_COUNT + 1))
    fi
done < <(find images/ -type f 2>/dev/null | sort)

# Clean up empty image directories after deletion
if [[ "$CQA_FIX_MODE" == true && $DELETED_COUNT -gt 0 ]]; then
    find images/ -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi

cqa_summary
exit "$(cqa_exit_code)"
