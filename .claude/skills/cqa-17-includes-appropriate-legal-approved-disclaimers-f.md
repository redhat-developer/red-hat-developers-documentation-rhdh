# CQA #17 - Legal and Branding

## Includes appropriate, legal-approved disclaimers for Technology Preview and Developer Preview features/content

**Reference:** https://access.redhat.com/support/offerings/devpreview

**Quality Level:** Required/non-negotiable


## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA #NN]`.

**What the script does:**
- Checks files mentioning "Technology Preview" include the official disclaimer snippet
- Checks files mentioning "Developer Preview" include the official disclaimer snippet
- Looks for `include::.*snip-.*tech.*preview` or `{technology-preview}` attribute references
- Skips snippet files (they ARE the disclaimers) and attributes.adoc

**Target Results:**
- ✅ All preview feature mentions have appropriate disclaimers

## Notes

You can use snippets for these disclaimers in assembly files. They will resolve appropriately during migration.


## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
