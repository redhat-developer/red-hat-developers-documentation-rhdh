# CQA #10 - Modularization

## Titles are brief, complete, and descriptive

**Quality Level:** Required/non-negotiable

All module and assembly titles must be:
- **Brief:** 3-11 words (optimal for searchability)
- **Complete:** Fully describe the content without context
- **Descriptive:** Use specific, meaningful language
- **Capitalization:** Sentence-style (not headline-style)
- **Content-appropriate:** Match module type conventions

**References:**
- [Red Hat Supplementary Style Guide](../resources/red-hat-ssg.md) - Title capitalization and length
- [Red Hat Peer Review Guide](../resources/red-hat-peer-review.md) - Style checklist and title standards
- [Modular Documentation Reference Guide](../resources/red-hat-modular-docs.md) - Title forms by type

## Verification

**Check titles:**
```bash
# Extract all module/assembly titles
grep -h "^= " titles/<your-title>/master.adoc assemblies/*.adoc modules/*/*.adoc | sort

# Count words in titles
grep -h "^= " assemblies/*.adoc modules/*/*.adoc | while read line; do
  title="${line#= }"
  words=$(echo "$title" | wc -w)
  echo "$words words: $title"
done | sort -n
```

**Checklist:**
- [ ] All titles use sentence-style capitalization
- [ ] Titles are 3-11 words (optimal length)
- [ ] Procedure titles use imperative form
- [ ] Concept titles use noun phrases
- [ ] Reference titles use noun phrases
- [ ] No vague words ("Overview", "Introduction", "General")

## Title Guidelines by Content Type

| Type | Form | Correct | Incorrect |
|------|------|---------|-----------|
| **Procedure** | Imperative (verb-first) | "Install Developer Hub on OpenShift" | "Installing Developer Hub" (gerund) |
| **Concept** | Noun phrase | "Plugin architecture" | "Understanding plugins" (verb) |
| **Reference** | Noun phrase | "Configuration file reference" | "List of configuration options" |
| **Assembly** | Imperative or noun phrase | "Installing Developer Hub" (task-based)<br>"Developer Hub architecture" (concept) | "How to install Developer Hub" |

## Capitalization and Length Rules

**Sentence-style capitalization:**
- Capitalize: First word + proper nouns only
- ✅ "Configure OAuth authentication for Developer Hub"
- ❌ "Configure OAuth Authentication For Developer Hub" (headline-style)

**Word count: 3-11 words (optimal: 5-8)**
- Too short (< 3): "OAuth configuration" → "Configure OAuth authentication providers"
- Too long (> 11): "Installing and configuring Red Hat Developer Hub on OpenShift Container Platform using Operator" (13 words) → "Install Developer Hub on OpenShift with Operator" (8 words)

## Common Violations and Fixes

| Violation | Incorrect | Correct | Fix |
|-----------|-----------|---------|-----|
| **Gerund in procedures** | "Installing the Helm chart" | "Install the Helm chart" | Remove "-ing", use imperative |
| **Headline-style caps** | "Configure OAuth Authentication For Hub" | "Configure OAuth authentication for Hub" | Sentence-style only |
| **Vague titles** | "Overview", "Introduction" | "Developer Hub architecture overview" | Add specific context |
| **Self-referential** | "About authentication", "How to install" | "Authentication options", "Install Developer Hub" | Remove "About", "How to" |
| **Too long** | "Installing and configuring RHDH on OCP using Operator" (9 words) | "Install Developer Hub with Operator" (5 words) | Remove redundant words |

## Quick Reference

**Capitalization:**
- ✅ Sentence-style: "Configure OAuth authentication for Developer Hub"
- ❌ Headline-style: "Configure OAuth Authentication For Developer Hub"

**Procedure titles:**
- ✅ Imperative: "Install the plugin"
- ❌ Gerund: "Installing the plugin"
- ❌ Infinitive: "To install the plugin"

**Concept titles:**
- ✅ Noun phrase: "Plugin architecture"
- ❌ Verb phrase: "Understanding plugins"

**Word count:**
- Target: 3-11 words
- Ideal: 5-8 words

**Content-specific:**
- Use exact product names (Red Hat Developer Hub, not RHDH)
- Include key technologies (OpenShift, Kubernetes, Helm)
- Avoid marketing language ("amazing", "powerful")

## Script Integration

The title/ID/filename alignment script helps enforce title correctness:

```bash
./build/scripts/cqa-10-fix-title-id-filename.sh titles/<your-title>/master.adoc
```

This script:
- Converts gerunds to imperatives in procedure titles
- Aligns IDs with titles
- Renames files to match titles
- Updates xrefs automatically

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
