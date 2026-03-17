# CQA #6 - Modularization

## Assemblies use the official template.Assemblies are one user story.

**Reference:** [Red Hat Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md) - Assembly definition

**Quality Level:** Required/non-negotiable


## Command

**Run assembly template and structure verification:**
```bash
./build/scripts/cqa-06-assemblies-use-the-official-template-assemblies-ar.sh [--fix] titles/<your-title>/master.adoc
```

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
