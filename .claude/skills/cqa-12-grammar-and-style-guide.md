# CQA-12 - Editorial

## Content is grammatically correct and follows rules of American English grammar

**References:**
- [Red Hat Supplementary Style Guide (CQA extract)](../resources/red-hat-ssg-for-cqa.md) - Grammar, style, terminology
- [Red Hat Peer Review Guide (CQA extract)](../resources/red-hat-peer-review-for-cqa.md) - Editorial quality standards

**Quality Level:** Required/non-negotiable

Content must follow American English grammar, Red Hat style standards: correct grammar/spelling/punctuation, official terminology, consistent voice, proper capitalization, parallel structure.

**IMPORTANT:** Try hard to fix ALL Vale issues — errors, warnings, AND suggestions. Do not skip warnings or suggestions unless they are clearly false positives (e.g., code blocks, attributes.adoc). Every unfixed issue degrades content quality.

## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-12-grammar-and-style-guide.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-12-grammar-and-style-guide.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-12-grammar-and-style-guide.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA-NN]`.

**What the script does:**
- Runs Vale with `.vale.ini` config on all included files
- Reports grammar, spelling, style, and terminology issues
- Requires `vale` CLI installed and `.vale.ini` config file

**Target Results:**
- ✅ Zero Vale errors
- ✅ Zero Vale warnings
- ✅ Zero Vale suggestions (fix all unless clearly false positive)

## How to Run

**IMPORTANT:** Always use the associated script to run Vale. Do NOT run `vale` directly.

```bash
./build/scripts/cqa-12-grammar-and-style-guide.sh titles/<title-name>/master.adoc
```

The script handles file discovery, filtering (e.g., excluding `attributes.adoc`), and outputs JSON.

**What it validates:**
✅ Grammar (RedHat), Spelling, Terminology, Style (Google/Microsoft), Conscious language, Capitalization
❌ DITA compatibility (use `.vale-dita-only.ini` / CQA-1 script instead)

### Step 3: Review Vale Alerts

| Severity | Action | Examples |
|----------|--------|----------|
| **error** ❌ | MUST fix | Spelling errors, prohibited terms, grammar violations |
| **warning** ⚠️ | MUST fix | Style suggestions, preferred terminology |
| **suggestion** 💡 | SHOULD fix | Alternative phrasing, minor improvements |

## Common Issues and Fixes

| Issue | Vale Rule | Incorrect | Correct |
|-------|-----------|-----------|---------|
| **Spelling** | `Vale.Spelling` | "seperately", "occured" | "separately", "occurred" |
| **Product names** | `RedHat.ProductNames` | "RHDH", "Openshift" | "Red Hat Developer Hub", "OpenShift" |
| **Conscious language** | `RedHat.ConsciousLanguage` | "whitelist", "blacklist" | "allowlist", "blocklist" |
| **Capitalization** | `RedHat.Capitalization` | "Configure OAuth Authentication For Hub" | "Configure OAuth authentication for Hub" |
| **Grammar** | `Google.Passive` | "The plugin is installed by..." | "The administrator installs the plugin" |
| **Wordiness** | `Google.WordList` | "In order to configure..." | "To configure..." |
| **Contractions** | `Microsoft.Contractions` | "don't" | "do not" |

**Parallel structure** (manual check): Ensure consistent grammar in lists/prerequisites.
- ❌ "You have cluster admin. Installing the Operator."
- ✅ "You have cluster admin. You have installed the Operator."

## Validation Workflow

1. Run the script: `./build/scripts/cqa-12-grammar-and-style-guide.sh titles/<your-title>/master.adoc`
2. Fix all errors (❌ severity)
3. Fix all warnings (⚠️ severity)
4. Fix all suggestions (💡 severity) unless clearly false positive
5. Re-run the script to verify
6. Verify zero errors, zero warnings, and zero suggestions

## Acceptable Exceptions

**`artifacts/attributes.adoc`:** Ignore all errors in this file — it defines attribute values using literal product names, which intentionally triggers `DeveloperHub.Attributes` rules. These are false positives.

**Technical terms:** Add to `.vale/styles/Vocab/RHDH/accept.txt` if legitimate (Keycloak, PostgreSQL, Kubernetes)
**Code examples:** Ignore alerts in code blocks if syntax is correct
**Quoted text:** Verify accuracy, ignore style alerts if intentional

## Assessment Checklist

- [ ] Vale styles synced (< 7 days old)
- [ ] Vale validation run with `.vale.ini`
- [ ] Spelling errors corrected
- [ ] Product names use official forms
- [ ] Conscious language violations fixed
- [ ] Capitalization follows sentence-style
- [ ] Grammar errors corrected (passive voice, wordiness, contractions)
- [ ] Parallel structure verified
- [ ] Zero Vale errors reported
- [ ] Warnings addressed

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
