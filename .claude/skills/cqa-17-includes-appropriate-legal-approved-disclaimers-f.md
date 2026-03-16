# CQA #17 - Legal and Branding

## Includes appropriate, legal-approved disclaimers for Technology Preview and Developer Preview features/content

**Reference:** https://access.redhat.com/support/offerings/devpreview

**Quality Level:** Required/non-negotiable


## Command

**Run legal disclaimers verification:**
```bash
./build/scripts/cqa-17-includes-appropriate-legal-approved-disclaimers-f.sh [--fix] titles/<your-title>/master.adoc
```

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
