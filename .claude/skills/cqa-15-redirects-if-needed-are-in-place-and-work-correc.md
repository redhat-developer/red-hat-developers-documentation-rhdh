# CQA #15 - URLs and links

## Redirects (if needed) are in place and work correctly

**Quality Level:** Required/non-negotiable


## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA #NN]`.

**What the script does:**
- Checks git history for renamed files in recent 5 commits
- Checks git history for deleted files in recent 5 commits
- Reports files that may need redirects
- Informational only (does not fail on findings)

**Target Results:**
- ✅ No renamed or deleted files detected, or redirects reviewed

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
