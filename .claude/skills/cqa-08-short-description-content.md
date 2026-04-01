# CQA-8 - Modularization

## Short description content requirements

**Quality Level:** Required/non-negotiable

**Focus:** Content quality of short descriptions (WHAT the abstract says)

All modules and assemblies must have short descriptions that:
- Are a **complete sentence** ending with a period (`.`)
- Do **NOT** end mid-sentence with a colon (`:`), semicolon (`;`), or comma (`,`)
- Describe **WHY** the user should read (not just WHAT it contains)
- Include searchable keywords (product names, features, technologies)
- Avoid self-referential language ("This document...", "This section...")
- Make sense in standalone context (search results, link previews)
- Match the content type (Concept/Procedure/Reference/Assembly)

**Reference:** https://docs.oasis-open.org/dita/dita/v1.3/errata02/os/complete/part3-all-inclusive/langRef/base/shortdesc.html

## Verification Checklist

For each abstract, verify content quality:

- [ ] Explains WHY user should read (benefit/purpose/outcome)
- [ ] Uses action-oriented or benefit-focused language
- [ ] Includes relevant keywords for SEO/search
- [ ] Makes sense without surrounding context
- [ ] No self-referential phrases ("This...", "Here...", "The following...")
- [ ] Matches content type expectations

## Content Type Guidelines

### Concepts
- Explain WHAT the feature is and WHY it matters
- Use "Understand...", "Learn about...", or state the value directly

✅ "Understand how plugins extend Developer Hub with custom integrations."
❌ "This section explains the plugin architecture."

### Procedures
- State the OUTCOME or BENEFIT of completing the task
- Lead with action verbs when possible

✅ "Install Developer Hub on OpenShift to provide a unified developer experience."
❌ "This procedure shows how to install Developer Hub."

### References
- Describe WHAT information is available and WHY it's useful
- Use "Access...", "Review...", or state the use case

✅ "Access API endpoints to integrate Developer Hub with external systems."
❌ "This reference lists API endpoints."

### Assemblies
- Summarize the USER STORY or overall GOAL
- Focus on what the user will accomplish

✅ "Configure authentication to secure Developer Hub with your identity provider."
❌ "This assembly covers authentication configuration."

## Common Content Issues

### Issue 0: Incomplete sentence

**Detection:** Abstract ends with a colon, semicolon, or comma instead of a period

❌ "The Orchestrator plugin integrates these components:"
❌ "You can configure the following settings;"
❌ "To deploy a workflow, follow these main steps,"

✅ "The Orchestrator plugin integrates several components to automate the software development lifecycle."
✅ "Configure settings to customize the Orchestrator plugin behavior."
✅ "Deploy a workflow by following these steps to make it available in the Orchestrator plugin."

**Fix:** Rewrite as a complete, self-contained sentence ending with a period. Do not use the abstract to introduce a list or code block that follows it — the abstract must stand alone.

**Check for violations:**
```bash
# Find abstracts ending with colon, semicolon, or comma
grep -A1 '\[role="_abstract"\]' modules/ assemblies/ | grep -E '[,:;]$'
```

### Issue 1: Self-referential language

**Avoid these phrases:**
- "This document describes..."
- "This section explains..."
- "The following procedure..."
- "This guide covers..."

**Fix:** State the benefit directly

❌ "This document describes plugin configuration."
✅ "Configure plugins to extend Developer Hub functionality."

**Check for violations:**
```bash
grep -r "This section" modules/ assemblies/
grep -r "This document" modules/ assemblies/
grep -r "The following" modules/ assemblies/
```

### Issue 2: Missing WHY/benefit

**Detection:** Abstract describes WHAT without explaining WHY

❌ "Configure authentication settings for the application."
✅ "Configure authentication to enable secure single sign-on for your team."

**Fix strategy:**
1. Ask: "Why would a user read this?"
2. Add the outcome/benefit/use case
3. Connect to user's goals

### Issue 3: Missing keywords

**Detection:** Abstract lacks searchable terms (product names, features, technologies)

❌ "Set up the system to work with your corporate directory."
✅ "Configure LDAP authentication to integrate with Active Directory."

**Required keywords:**
- Product names: Red Hat Developer Hub, OpenShift
- Feature names: OAuth, LDAP, RBAC, plugins
- Technologies: Kubernetes, API, SSO

### Issue 4: Not standalone/requires context

**Detection:** Abstract doesn't make sense in search results

❌ "Follow these steps to complete the installation."
✅ "Install Red Hat Developer Hub on OpenShift for centralized developer experience."

**Test:** If you saw this in Google results, would you know what it's about?

### Issue 5: Wrong content type focus

**Concept with procedural language:**
❌ "Learn how to install and configure plugins."
✅ "Understand how plugins extend functionality through modular components."

**Procedure without outcome:**
❌ "Configure OAuth settings."
✅ "Configure OAuth to enable single sign-on through your identity provider."

## Quick Reference

**WHY vs WHAT:**
- ✅ WHY: "Secure access with OAuth integration"
- ❌ WHAT: "This explains OAuth configuration"

**Keywords:**
- ✅ "Configure LDAP authentication for Active Directory integration"
- ❌ "Set up the authentication system"

**Self-referential:**
- ✅ "Install plugins to extend Developer Hub"
- ❌ "This document describes plugin installation"

**Standalone:**
- ✅ "Troubleshoot OpenShift deployment issues for Developer Hub"
- ❌ "Follow these troubleshooting steps"

**Content type:**
- Concepts → Explain WHAT and WHY
- Procedures → State OUTCOME
- References → Describe INFORMATION
- Assemblies → Summarize GOAL

## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-08-short-description-content.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-08-short-description-content.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-08-short-description-content.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA-NN]`.

**What the script does:**
- Checks for self-referential language ("This section...", "This document...", etc.)
- Detects empty abstracts after `[role="_abstract"]`
- Reports content quality violations

**Target Results:**
- ✅ No self-referential phrases in abstracts
- ✅ No empty abstracts

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
