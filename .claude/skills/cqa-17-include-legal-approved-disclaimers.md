# CQA-17 - Legal and Branding

## Includes appropriate, legal-approved disclaimers for Technology Preview and Developer Preview features/content

**Reference:** https://access.redhat.com/support/offerings/devpreview

**Quality Level:** Required/non-negotiable


## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-17-include-legal-approved-disclaimers.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-17-include-legal-approved-disclaimers.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-17-include-legal-approved-disclaimers.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA-NN]`.

**What the script does:**
- Detects both raw text ("Technology Preview", "Developer Preview") and attribute usage (`{technology-preview}`, `{developer-preview}`)
- Checks that files with preview mentions include the official disclaimer snippet (`include::.*snip-.*tech.*preview` or `include::.*snip-.*dev.*preview`) or the support scope URL
- Skips snippet files (they ARE the disclaimers) and attributes.adoc

**Attributes:** Use `{developer-preview}` and `{technology-preview}` attributes (defined in `artifacts/attributes.adoc`) instead of raw text. The Vale `DeveloperHub.Attributes` check enforces this.

**Snippet placement:** Include the disclaimer snippet AFTER the `[role="_abstract"]` paragraph, not before it.

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
