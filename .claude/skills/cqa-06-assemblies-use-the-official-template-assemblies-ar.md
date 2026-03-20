# CQA-6 - Modularization

## Assemblies use the official template.Assemblies are one user story.

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md) - Assembly definition

**Quality Level:** Required/non-negotiable


## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect assembly files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-06-assemblies-use-the-official-template-assemblies-ar.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-06-assemblies-use-the-official-template-assemblies-ar.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-06-assemblies-use-the-official-template-assemblies-ar.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA-NN]`.

**What the script does:**
- Checks assembly files have a title (= heading)
- Validates module count (≤15 includes per assembly)
- Checks for excessive nested assembly includes (≤3)
- Reports compliant assemblies and violations

**Target Results:**
- ✅ All assemblies have a title
- ✅ No assembly exceeds 15 module includes
- ✅ No assembly has more than 3 nested assembly includes

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
