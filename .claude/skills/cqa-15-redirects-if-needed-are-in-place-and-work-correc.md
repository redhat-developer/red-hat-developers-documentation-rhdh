# CQA #15 - URLs and links

## Redirects (if needed) are in place and work correctly

**Quality Level:** Required/non-negotiable


## Command

**Run redirects check:**
```bash
./build/scripts/cqa-15-redirects-if-needed-are-in-place-and-work-correc.sh [--fix] titles/<your-title>/master.adoc
```

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
