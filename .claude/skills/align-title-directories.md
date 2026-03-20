# Skill: Align Title Directories

Align title, assembly, module, and image directory names to the `<category>_<context>` flat naming convention.

## Directory Naming Convention

All directories follow `<category>_<context>` naming:

```
titles/<category>_<context>/master.adoc
assemblies/<category>_<context>/         # owned by one title
assemblies/shared/                       # shared across categories
modules/<category>_<context>/            # owned by one title
modules/shared/                          # shared across categories
images/<category>_<context>/             # owned by one title
images/shared/                           # shared across categories
```

- `<category>` comes from `:_mod-docs-category:` in master.adoc (slugified: lowercase, spaces to hyphens)
- `<context>` is derived from `:title:` by resolving attributes and slugifying

## Context Derivation Rule

The `:context:` value is derived automatically from the `:title:` attribute in master.adoc:
1. Resolve local attributes defined in the same file
2. Dereference product attributes using the shortest form (e.g., `{product}` -> `rhdh`)
3. Convert to lowercase, replace spaces with hyphens

## Script Usage

```bash
./build/scripts/align-title-directories.sh --list                              # show all titles
./build/scripts/align-title-directories.sh --all                               # dry-run all titles
./build/scripts/align-title-directories.sh --all --exec                        # execute all titles
./build/scripts/align-title-directories.sh <title-dir>                         # dry-run single title
./build/scripts/align-title-directories.sh --exec <title-dir>                  # execute single title
./build/scripts/align-title-directories.sh --exec <title-dir> <new-context>    # explicit context
```

## Script Phases

The script runs 7 phases in order:

0. **Pre-computation** - Read all titles, extract category/context, build ownership maps
1. **Rename titles** - `git mv titles/<old>/ titles/<cat>_<ctx>/`
2. **Move assemblies** - Move to `assemblies/<cat>_<ctx>/` or keep in `assemblies/shared/`
3. **Move modules** - Move to `modules/<cat>_<ctx>/` or keep in `modules/shared/`
4. **Move images** - Move individual image files based on file-level ownership tracing
5. **Update paths** - Fix all `include::` and `image::` / `image:` references in .adoc files
6. **Verification** - Check all include/image paths resolve correctly

## Image Handling

Images use `:imagesdir:` so references never contain `../`. The script:
- Traces ownership at the **individual file level** (not directory level)
- Follows the chain: image -> module -> assembly -> title
- Images used by one title go to `images/<cat>_<ctx>/`
- Images used by multiple titles go to `images/shared/`
- Updates both block `image::` and inline `image:` references

## Shared Resources

Resources used by multiple titles stay in `*/shared/`. The script determines this automatically by tracing include chains from each title's master.adoc.

## Companion Scripts

- `./build/scripts/cqa-00-orphaned-modules.sh` - Find orphaned .adoc files and images
- `./build/scripts/cqa-00-orphaned-modules.sh --fix` - Delete orphaned files

## Per-Title Checklist

For each title, follow this checklist in order:

1. **Preview changes** (dry-run):
   ```bash
   ./build/scripts/align-title-directories.sh titles/<old-dir>
   ```
2. **Execute**:
   ```bash
   ./build/scripts/align-title-directories.sh --exec titles/<old-dir>
   ```
3. **If single assembly**: Inline assembly content into master.adoc without adding a second level heading, then delete the assembly file
4. **Verify** `[id="{context}"]` and `= {title}` are present in master.adoc
5. **Build** and fix errors:
   ```bash
   ./build/scripts/build-ccutil.sh
   ```
6. **Commit**:
   ```bash
   git add -A
   git commit -m "RHIDP-12703: Simplify file hierarchy for <title-name>"
   ```

## Known Edge Cases

- **AsciiDoc attributes in paths** (`{platform-id}`, `{docdir}`): Verification skips these since they resolve at build time
- **YAML `image:` in code blocks**: Not AsciiDoc macros; verification filters refs containing `://`, spaces, or quotes
- **Bash 5.3 `set -u`**: Empty associative arrays are "unbound"; script uses sentinel keys as workaround
- **Double-slash in include paths**: `modules/shared//file.adoc` can cause grep mismatches; script handles basename matching

## Important

- Do NOT commit this skill file or memory changes
- Build using `./build/scripts/build-ccutil.sh` and fix errors before committing
- The `--all` mode is idempotent: running it again on an already-aligned repo produces no changes
