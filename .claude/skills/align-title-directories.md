# Skill: Align Title Directories

Align title, assembly, and module directory names with the `:context:` attribute derived from the `:title:` attribute.

## Context Derivation Rule

The `:context:` value is derived automatically from the `:title:` attribute in master.adoc:
1. Dereference attributes using the shortest available form (e.g., `{product}` → `rhdh`, `{ls-brand-name}` → `developer-lightspeed-for-rhdh`)
2. Convert to lowercase
3. Replace spaces with hyphens

The context value determines the subdirectory names under `titles/`, `assemblies/`, and `modules/`.

## Script

```bash
./build/scripts/align-title-directories.sh <title-dir>                        # dry-run, derive context
./build/scripts/align-title-directories.sh <title-dir> <new-context>          # dry-run, explicit context
./build/scripts/align-title-directories.sh --exec <title-dir>                 # execute, derive context
./build/scripts/align-title-directories.sh --exec <title-dir> <new-context>   # execute, explicit context
./build/scripts/align-title-directories.sh --list                             # show all titles
```

## Per-Title Checklist

For each title, follow this checklist in order:

1. **Preview changes** (dry-run is the default, context is derived from `:title:`):
   ```bash
   ./build/scripts/align-title-directories.sh titles/<old-dir>
   ```
2. **Execute the changes**:
   ```bash
   ./build/scripts/align-title-directories.sh --exec titles/<old-dir>
   ```
3. **If single assembly**: Inline assembly content (abstract and includes) into master.adoc without adding a second level heading, then delete the assembly file
4. **Verify** `[id="{context}"]` and `= {title}` are present in master.adoc
5. **Build** and fix errors:
   ```bash
   ./build/scripts/build-ccutil.sh
   ```
6. **Commit**:
   ```bash
   git add -A
   git commit -m "RHIDP-12703: Simplify file hierarchy for <title-name>

   Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
   ```

## Shared Resources

Assemblies or modules used by multiple titles go to `assemblies/shared/` or `modules/shared/` respectively. The script skips shared module directories automatically.

## Important

- Do NOT commit this skill file or memory changes
- Build using `./build/scripts/build-ccutil.sh` and fix errors before committing each title
- One commit per title
