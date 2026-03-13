# CQA #12 - Editorial

## Content is grammatically correct and follows rules of American English grammar

**References:**
- [Red Hat Supplementary Style Guide](../resources/red-hat-ssg.md) - Grammar, style, terminology
- [Red Hat Peer Review Guide](../resources/red-hat-peer-review.md) - Editorial quality standards

**Quality Level:** Required/non-negotiable

Content must follow American English grammar, Red Hat style standards: correct grammar/spelling/punctuation, official terminology, consistent voice, proper capitalization, parallel structure.

## Commands

### Step 1: Ensure Vale Styles Current (< 7 Days)

```bash
LAST_SYNC=$(cat .claude/.vale-sync-timestamp 2>/dev/null || echo 0)
DAYS_OLD=$(( ($(date +%s) - $LAST_SYNC) / 86400 ))
[ $DAYS_OLD -ge 7 ] && vale sync && echo $(date +%s) > .claude/.vale-sync-timestamp
```

### Step 2: Run Vale Grammar and Style Validation

**Validate title master.adoc and ALL included files:**

```bash
# For a specific title (recommended approach)
vale --config .vale.ini \
  $(./build/scripts/list-all-included-files-starting-from titles/<title-name>/master.adoc)
```

**Example for install-rhdh-osd-gcp:**
```bash
vale --config .vale.ini \
  $(./build/scripts/list-all-included-files-starting-from titles/install-rhdh-osd-gcp/master.adoc)
```

**See also:** [get-title-files.md](get-title-files.md) for detailed explanation of the file list extraction script.

**What .vale.ini validates:**
✅ Grammar (RedHat), Spelling, Terminology, Style (Google/Microsoft), Conscious language, Capitalization
❌ DITA compatibility (use .vale-dita-only.ini for CQA #1)

**IMPORTANT:** Do NOT run `vale titles/<title>/` on the entire directory - this validates files NOT part of the title and produces misleading results. Always specify master.adoc and its includes.

### Step 3: Review Vale Alerts

| Severity | Action | Examples |
|----------|--------|----------|
| **error** ❌ | MUST fix | Spelling errors, prohibited terms, grammar violations |
| **warning** ⚠️ | SHOULD fix | Style suggestions, preferred terminology |
| **suggestion** 💡 | OPTIONAL | Alternative phrasing, minor improvements |

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

1. Sync Vale styles (if > 7 days): `vale sync && echo $(date +%s) > .claude/.vale-sync-timestamp`
2. Run validation: `vale --config .vale.ini titles/<your-title>/`
3. Fix all errors (❌ severity)
4. Fix warnings (⚠️ severity)
5. Re-run Vale to verify: `vale --config .vale.ini titles/<your-title>/`
6. Verify zero errors and minimal warnings

## Acceptable Exceptions

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
