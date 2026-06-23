# Red Hat Developer Hub Documentation

Documentation for Red Hat Developer Hub (RHDH) following JTBD methodology and CQA 2.1 standards.

## Project Overview

**Product**: Red Hat Developer Hub
**Upstream**: Backstage
**Documentation type**: Red Hat modular documentation (AsciiDoc)
**JTBD Implementation Status**: Phase 0 - Ready for implementation

## JTBD Standards and Workflow

### JTBD Content Structure

All content must follow the JTBD (Jobs to be Done) framework with the following category structure:

```
1. Discover    → Architecture, capabilities, platform understanding
2. Get Started → Quick start, first use, initial setup
3. Install     → Deployment procedures across platforms  
4. Configure   → Configuration, customization, integration
5. Develop     → Building, extending, creating content
6. Extend      → Plugins, customizations, advanced features
7. Control Access → Authentication, authorization, security
8. Integrate   → External system connections, Git providers
9. Observability → Monitoring, logging, insights, diagnostics
10. Upgrade    → Version migration, updates
```

### Content Creation Requirements

**Job Statements Format**: "When [situation], I want to [motivation], so I can [expected outcome]."

**Title Requirements**:
- Imperative voice, 3-11 words, sentence case
- Lead with direct action verbs: "Add", "Create", "Configure", "Set", "Define", "Apply", "Run"
- No indirect constructions like "Goal: action" or informal verbs like "Put", "Place"

**Abstracts (WHAT + WHY)**:
- 50-300 characters, max 50 words  
- Must explain WHAT the content covers and WHY it matters
- No "You can", "This section describes", "Learn how to"
- No title restatement
- Preserve specific names and technical details

### Content Types and Prefixes

| Content Type | Prefix | Purpose |
|--------------|--------|---------|
| Concept | `con_` | Conceptual information, understanding |
| Procedure | `proc_` | Step-by-step instructions |
| Reference | `ref_` | Lookup information, specifications |
| Snippet | `snip_` | Reusable content fragments |
| Assembly | No prefix | Collections of modules |

## CQA 2.1 Compliance

When editing `.adoc` files, ALWAYS run the relevant CQA checks to validate and fix changes before considering the task done:

```bash
# Report issues for a title
node build/scripts/cqa/index.js titles/<title>/master.adoc

# Auto-fix issues
node build/scripts/cqa/index.js --fix titles/<title>/master.adoc

# Run a single check
node build/scripts/cqa/index.js --check NN titles/<title>/master.adoc
```

Output markers: `[AUTOFIX]` (auto-fixable), `[FIXED]` (applied), `[MANUAL]` (needs human), `[-> CQA-NN AUTOFIX]` / `[-> CQA-NN MANUAL]` (delegated).

The `project-cqa` plugin (`.claude/plugins/project-cqa/`) provides skills for the full CQA workflow and individual checks. The CQA spec is at `.claude/plugins/project-cqa/resources/cqa-spec.md`.

### Procedure Review Rules (Complete Checklist)

When reviewing `proc_*.adoc` files, apply ALL rules below with ZERO content loss:

1. **One action per step**: Each numbered step = one user action. Split multi-action steps.
2. **Direct imperative verbs**: Lead steps with action verbs (Add, Create, Define, Set, Configure, Apply, Run). No indirect "Goal: action" constructions. No informal verbs (Put, Place).
3. **Optional steps**: Use `Optional:` (capitalized, colon). Not "(Optional)", "(OPTIONAL)", "Optionally,".
4. **Abstract (WHAT + WHY)**: 50-300 chars, max 50 words. No "You can", "This section describes", "Learn how to". No title restatement. Must explain WHAT and WHY.
5. **Prerequisites**: Must exist. Use "You have...", "You are...", "You know..." pattern. No imperatives. No bare nouns. Use product attributes (`{product}`, `{ocp-short}`).
6. **Verification**: Must exist after .Procedure. Meaningful verification steps. Not inside procedure as last step.
7. **Admonitions**: Do NOT add new ones. Preserve existing admonition TYPES (NOTE stays NOTE, WARNING stays WARNING). Move misplaced content to proper location WITH zero content loss.
8. **ZERO content loss**: Every word, qualifier, link, admonition type, and sentence matters. Never drop, rephrase, or summarize content.
9. **ZERO meaning change**: Preserve conditional framing, user agency, severity levels, and contextual nuance.
10. **No mixed content types**: Pure PROCEDURE. If conceptual content exists, flag it but don't restructure unless safe.
11. **Definition lists and `where:` pattern**: After source blocks with placeholders, use `where:` lead-in + definition list entries.
12. **Source blocks**: `[source,LANG]` format. Placeholders use `__<placeholder>__` with `subs="+quotes"`. No bare `<placeholder>`.
13. **Product attributes**: No hardcoded "Developer Hub", "OpenShift". Use `{product-short}`, `{ocp-short}`, `{ocp-brand-name}`, etc.
14. **No `==` subsections**: DITA forbids subsections in procedures.
15. **Scannability**: Average ≤22 words/sentence. Flag >30 words.
16. **Example formatting**: `For example:` as plain text, NOT `.Example:` block title.
17. **Title**: Imperative, 3-11 words, sentence case.
18. **Role annotations**: `[role="_additional-resources"]` required before `.Additional resources`. NOT before `.Prerequisites`, `.Procedure`, `.Verification`.
19. **ID format**: Must match `[id="prefix_name_{context}"]`. Known inconsistencies exist — always verify actual ID in file before writing xrefs.
20. **Cross-references**: Use `xref:` with `_{context}` for within-guide. Use `link:` with hardcoded target context for cross-guide.

## Content Workflow and Standards

### JTBD Implementation Workflow

1. **Content Planning**: Map existing content to JTBD categories and user jobs
2. **Gap Analysis**: Identify missing content for high-priority jobs  
3. **Content Creation**: Write/update content following JTBD principles
4. **CQA Review**: Run all 19 CQA checks before submission
5. **Technical Review**: Verify accuracy and completeness
6. **Publication**: Deploy to production environment

### American English Standards

- American spelling: "behavior", "customize", "analyze", "organization", "center"
- Article usage: "a {product}" (consonant sound), "an {ocp-brand-name}" (vowel sound)

### Conscious Language Requirements

**Do NOT use**: `blacklist`, `whitelist`, `slave`, `sanity check`, `segregate`, `evangelist`, `man hour`

**Use with caution**: `master` (only without `slave`), `abort` (only if product terminology), `disabled` (only for UI elements), `dummy` (replace with `placeholder`)

### Product Attributes (Key Variables)

| Attribute | Value | Usage |
|-----------|-------|--------|
| `{product}` | Red Hat Developer Hub | Full product name |
| `{product-short}` | Developer Hub | Short product name |
| `{product-very-short}` | RHDH | Abbreviation |
| `{ocp-brand-name}` | Red Hat OpenShift Container Platform | Full OpenShift name |
| `{ocp-short}` | OpenShift Container Platform | Short OpenShift name |
| `{backstage}` | Backstage | Upstream project name |
| `{kubernetes-version}` | 1.31 | Supported Kubernetes version |

## Repository Structure

- `titles/` - Top-level documentation guides (master.adoc files)
- `assemblies/` - Assembly files that combine modules
- `modules/` - Individual module files (con-, proc-, ref-, snip- prefixes)
- `artifacts/` - Reusable snippets and fragments (attributes.adoc)
- `build/scripts/` - Automation scripts for CQA and validation
- `.claude/` - Claude Code configuration and documentation

**Title Naming Convention**: `{category}_{guide-name}` (e.g., `discover_about-rhdh`, `install_installing-rhdh-on-ocp`)

## Pull Requests

When creating PRs, follow `.github/pull_request_template.md`:

- **Title format:** `[RHIDP#<jira-id>]: <short description>` (no `GH#` or `BZ#` prefix needed unless applicable)
- **Body:** Must include the `IMPORTANT: Do Not Merge` banner, `Version(s):`, `Issue:` (Jira link), and `Preview:` (preview URL or N/A)
- **Target branch:** Open PRs against `main` and cherrypick to released branches as needed
- **Never use `#N` in PR title or body** — GitHub auto-links it to issues/PRs. Use dash notation (e.g., `CQA-05`) instead.

## GitHub Workflows (`.github/workflows/`)

| Workflow | Trigger | Purpose |
|---|---|---|
| `build-asciidoc.yml` | Push to main/release | Builds AsciiDoc docs and deploys to GitHub Pages (deploy includes cleanup of merged/closed PRs and deleted branches). |
| `pr.yml` | PR | Builds HTML preview, runs CQA checks, deploys to `gh-pages`, posts preview URL and CQA checklist as PR comments. Build scripts sourced from base branch. |
| `style-guide.yml` | PR | Runs Vale linter on `assemblies/` for style guide compliance. |
| `shellcheck.yml` | PR (`*.sh`) | Runs shellcheck on changed shell scripts via reviewdog. |
| `generate-supported-plugins-pr.yml` | Weekly schedule (Monday 04:00 UTC) and manual dispatch | Updates Dynamic Plugins tables for configured branches and creates a PR. |

**Security:** `pr` and `shellcheck` use `pull_request_target` with an authorization gate — fork PRs from non-team members require manual approval via the `external` environment.

## Required Jira Ticket Creation

**CRITICAL**: Always create a Jira ticket before starting any documentation task if none is provided.

- **For RHDH content**: Create tickets in project `RHIDP` 
- **Format**: `[RHIDP-XXXX] <task description>`
- **Example**: `[RHIDP-1234] Update installation guide for RHDH 1.10`

This ensures proper tracking and project management compliance.

## Skills and Agent Usage

Use the `jtbd-map` skill when:
- Mapping content for a JTBD job
- Populating navigation files  
- Connecting existing modules to the JTBD structure

Use the CQA skills for:
- Running full CQA workflow: `cqa-main-workflow`
- Individual checks: `cqa-NN-*` skills for each check
- The CQA spec is the single source of truth at `.claude/plugins/project-cqa/resources/cqa-spec.md`

## Pull Requests

When creating PRs, follow `.github/pull_request_template.md`:

- **Title format:** `[RHIDP#<jira-id>]: <short description>` (no `GH#` or `BZ#` prefix needed unless applicable)
- **Body:** Must include the `IMPORTANT: Do Not Merge` banner, `Version(s):`, `Issue:` (Jira link), and `Preview:` (preview URL or N/A)
- **Target branch:** Open PRs against `main` and cherrypick to released branches as needed
- **Never use `#N` in PR title or body** — GitHub auto-links it to issues/PRs. Use dash notation (e.g., `CQA-05`) instead.

## GitHub Workflows (`.github/workflows/`)

| Workflow | Trigger | Purpose |
|---|---|---|
| `build-asciidoc.yml` | Push to main/release | Builds AsciiDoc docs and deploys to GitHub Pages (deploy includes cleanup of merged/closed PRs and deleted branches). |
| `pr.yml` | PR | Builds HTML preview, runs CQA checks, deploys to `gh-pages`, posts preview URL and CQA checklist as PR comments. Build scripts sourced from base branch. |
| `style-guide.yml` | PR | Runs Vale linter on `assemblies/` for style guide compliance. |
| `shellcheck.yml` | PR (`*.sh`) | Runs shellcheck on changed shell scripts via reviewdog. |
| `generate-supported-plugins-pr.yml` | Weekly schedule (Monday 04:00 UTC) and manual dispatch | Updates Dynamic Plugins tables for configured branches and creates a PR. |

**Security:** `pr` and `shellcheck` use `pull_request_target` with an authorization gate — fork PRs from non-team members require manual approval via the `external` environment.
