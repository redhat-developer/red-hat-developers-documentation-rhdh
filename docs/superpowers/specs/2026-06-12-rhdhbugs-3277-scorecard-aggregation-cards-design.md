# RHDHBUGS-3277: Scorecard Aggregation Card Fixes

**PR:** [#2346](https://github.com/redhat-developer/red-hat-developers-documentation-rhdh/pull/2346)
**Jira:** RHDHBUGS-3277
**Date:** 2026-06-12

## Context

PR #2346 addresses missing prerequisites and configuration details for Scorecard Aggregation cards. The PR has 4 open reviewer comments from @dzemanov. This spec covers the remaining fixes needed to resolve all reviewer feedback and satisfy the 5 Jira requirements.

## Jira Requirements Status

| # | Requirement | Status |
|---|---|---|
| 1 | Update prerequisites in 3 aggregation card procs | Done |
| 2 | Add "where" clause mapping `aggregationId` to `metricId` | Done, needs typo fix |
| 3 | Example discrepancy (read-only vs customizable homepage) | Assembly reordered; cross-ref notes still needed |
| 4 | Reorder sections 9.4/9.5 before 9.1-9.3 | Done |
| 5 | Show full plugin config context for mountpoints | Done for default card; cross-ref notes needed for others |

## Changes

### File 1: `proc-configure-a-default-scorecard-aggregation-card.adoc`

Three fixes in this file:

**Fix A — Typo on line 20**

Change:
```
. Add a new item to the `mountpointsarray`, `settingaggregationId` to your preferred metric ID.
```
To:
```
. Add a new item to the `mountPoints` array, setting `aggregationId` to your preferred metric ID.
```

**Fix B — Hardcoded version tag on line 25**

Replace the hardcoded version `bs_1.49.4__2.7.7` with the `<tag>` placeholder:
```yaml
- package: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/red-hat-developer-hub-backstage-plugin-scorecard:<tag>
```

Add the OCI tag snippet include after the YAML block, before the `where:` clause:
```asciidoc
+
include::{docdir}/artifacts/snip-tag-for-OCI-package-paths.adoc[]
```

This matches the established pattern used in `proc-configure-portfolio-health-on-a-customizable-home-page.adoc` and `proc-configure-portfolio-health-on-a-read-only-home-page.adoc`.

**Fix C — No changes needed for xref on line 48**

The existing xref uses the correct hardcoded context value pattern:
```asciidoc
xref:supported-scorecard-metrics-providers_evaluate-project-health-using-scorecards[]
```

### File 2: `proc-configure-an-aggregation-card-with-a-status-grouped-tracking-type.adoc`

**Fix D — Add cross-reference note for plugin config context**

After the step that says "Reference your custom aggregation ID inside the homepage card properties block under the `home.page/cards` mount point:", add a note before the YAML block pointing to the default aggregation card for full plugin configuration context:

```asciidoc
+
NOTE: Add this mount point inside the `mountPoints` array of your Scorecard plugin configuration. For a complete plugin configuration example, see xref:configure-a-default-scorecard-aggregation-card_configure-scorecard-cards-on-the-homepage[].
```

### File 3: `proc-configure-an-aggregation-card-with-an-average-tracking-type.adoc`

**Fix E — Add cross-reference note for plugin config context**

Same note as Fix D, added after the step referencing the homepage card properties block:

```asciidoc
+
NOTE: Add this mount point inside the `mountPoints` array of your Scorecard plugin configuration. For a complete plugin configuration example, see xref:configure-a-default-scorecard-aggregation-card_configure-scorecard-cards-on-the-homepage[].
```

## Design Decisions

- **Cross-reference over duplication:** The status-grouped and average procedures keep their bare mountpoint YAML snippets and add a cross-reference to the default aggregation card procedure for the full plugin config. This avoids repeating the same full YAML block across 3 procedures.
- **Xref target:** Cross-references point to the default aggregation card (not the homepage procedures) since it is the most closely related procedure and already shows the complete plugin configuration.
- **Xref pattern:** All xrefs use the hardcoded context value string (e.g., `_configure-scorecard-cards-on-the-homepage`), not the `{context}` variable.
- **Version tag pattern:** Uses `<tag>` placeholder with `snip-tag-for-OCI-package-paths.adoc` include, matching existing conventions in other scorecard procedures.

## Files Touched

| File | Fixes |
|---|---|
| `modules/.../proc-configure-a-default-scorecard-aggregation-card.adoc` | A (typo), B (version tag + OCI snippet) |
| `modules/.../proc-configure-an-aggregation-card-with-a-status-grouped-tracking-type.adoc` | D (cross-ref note) |
| `modules/.../proc-configure-an-aggregation-card-with-an-average-tracking-type.adoc` | E (cross-ref note) |
