# RHDHBUGS-3277 Scorecard Aggregation Card Fixes — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address all 4 open reviewer comments on PR #2346 and complete the remaining Jira requirements for Scorecard Aggregation card documentation.

**Architecture:** Targeted edits to 3 existing AsciiDoc procedure modules. No new files, no structural changes. The default aggregation card gets a typo fix and version tag correction; the status-grouped and average procedures each get a cross-reference note.

**Tech Stack:** AsciiDoc (modular docs), CQA linting

---

### Task 1: Fix typo and version tag in default aggregation card

**Files:**
- Modify: `modules/observability_evaluate-project-health-using-scorecards/proc-configure-a-default-scorecard-aggregation-card.adoc:20-48`

- [ ] **Step 1: Fix typo on line 20**

Change the malformed step text. Replace:

```asciidoc
. Add a new item to the `mountpointsarray`, `settingaggregationId` to your preferred metric ID.
```

With:

```asciidoc
. Add a new item to the `mountPoints` array, setting `aggregationId` to your preferred metric ID.
```

- [ ] **Step 2: Replace hardcoded version tag on line 25**

Replace the hardcoded `bs_1.49.4__2.7.7` with the `<tag>` placeholder. Change:

```yaml
  - package: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/red-hat-developer-hub-backstage-plugin-scorecard:bs_1.49.4__2.7.7
```

To:

```yaml
  - package: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/red-hat-developer-hub-backstage-plugin-scorecard:<tag>
```

- [ ] **Step 3: Add OCI snippet include and merge where clause**

The OCI snippet (`artifacts/snip-tag-for-OCI-package-paths.adoc`) provides its own `where:` heading with the `<tag>` definition. The existing file has a separate `where:` heading with the `aggregationId` definition. Merge them so both definitions appear under one `where:` block.

Replace lines 44-48 (from the YAML closing `----` through the `where:` block):

```asciidoc
----
+
where:

`aggregationId`:: The aggregation identifier used in the mount point configuration. For default aggregations, this value must match the `metricId` from your installed Scorecard module. For more information, see xref:supported-scorecard-metrics-providers_evaluate-project-health-using-scorecards[].
```

With:

```asciidoc
----
+
include::{docdir}/artifacts/snip-tag-for-OCI-package-paths.adoc[]
+
`aggregationId`:: The aggregation identifier used in the mount point configuration. For default aggregations, this value must match the `metricId` from your installed Scorecard module. For more information, see xref:supported-scorecard-metrics-providers_evaluate-project-health-using-scorecards[].
```

The snippet provides the `where:` heading and `<tag>` definition. The `aggregationId` definition follows as a continuation under the same heading.

- [ ] **Step 4: Verify the file looks correct**

The full file should now read (lines 16-51 region):

```asciidoc
.Procedure
. Open your dynamic plugin configuration file.

. Navigate to your scorecard card block under the `home.page/cards` mount point.

. Add a new item to the `mountPoints` array, setting `aggregationId` to your preferred metric ID.
+
[source,yaml]
----
plugins:
  - package: oci://ghcr.io/redhat-developer/rhdh-plugin-export-overlays/red-hat-developer-hub-backstage-plugin-scorecard:<tag>
    disabled: false
    pluginConfig:
      dynamicPlugins:
        frontend:
          red-hat-developer-hub.backstage-plugin-scorecard:
            mountPoints:
              - mountPoint: home.page/cards
                importName: ScorecardHomepageCard
                config:
                  props:
                    aggregationId: "github.open_prs"
                  layouts:
                    xl: { w: 3, h: 6, x: 3 }
                    lg: { w: 4, h: 6, x: 4 }
                    md: { w: 6, h: 6, x: 6 }
                    sm: { w: 12, h: 6 }
                    xs: { w: 12, h: 6 }
                    xxs: { w: 12, h: 6 }
----
+
include::{docdir}/artifacts/snip-tag-for-OCI-package-paths.adoc[]
+
`aggregationId`:: The aggregation identifier used in the mount point configuration. For default aggregations, this value must match the `metricId` from your installed Scorecard module. For more information, see xref:supported-scorecard-metrics-providers_evaluate-project-health-using-scorecards[].

. Save the modified configuration file and restart your {product} instance.
```

- [ ] **Step 5: Commit**

```bash
git add modules/observability_evaluate-project-health-using-scorecards/proc-configure-a-default-scorecard-aggregation-card.adoc
git commit -m "fix: typo, version tag, and OCI snippet in default aggregation card"
```

---

### Task 2: Add cross-reference note to status-grouped procedure

**Files:**
- Modify: `modules/observability_evaluate-project-health-using-scorecards/proc-configure-an-aggregation-card-with-a-status-grouped-tracking-type.adoc:30-31`

- [ ] **Step 1: Add NOTE block after mountpoint step**

Insert a NOTE between the step text on line 30 and the YAML continuation on line 31. Replace:

```asciidoc
. Reference your custom aggregation ID inside the homepage card properties block under the `home.page/cards` mount point:
+
[source,yaml]
```

With:

```asciidoc
. Reference your custom aggregation ID inside the homepage card properties block under the `home.page/cards` mount point:
+
NOTE: Add this mount point inside the `mountPoints` array of your Scorecard plugin configuration. For a complete plugin configuration example, see xref:configure-a-default-scorecard-aggregation-card_configure-scorecard-cards-on-the-homepage[].
+
[source,yaml]
```

- [ ] **Step 2: Commit**

```bash
git add modules/observability_evaluate-project-health-using-scorecards/proc-configure-an-aggregation-card-with-a-status-grouped-tracking-type.adoc
git commit -m "fix: add plugin config cross-reference to status-grouped procedure"
```

---

### Task 3: Add cross-reference note to average tracking type procedure

**Files:**
- Modify: `modules/observability_evaluate-project-health-using-scorecards/proc-configure-an-aggregation-card-with-an-average-tracking-type.adoc:63-64`

- [ ] **Step 1: Add NOTE block after mountpoint step**

Insert a NOTE between the step text on line 63 and the YAML continuation on line 64. Replace:

```asciidoc
. Reference your average tracking aggregation ID inside the homepage card properties block under the `home.page/cards` mount point:
+
[source,yaml]
```

With:

```asciidoc
. Reference your average tracking aggregation ID inside the homepage card properties block under the `home.page/cards` mount point:
+
NOTE: Add this mount point inside the `mountPoints` array of your Scorecard plugin configuration. For a complete plugin configuration example, see xref:configure-a-default-scorecard-aggregation-card_configure-scorecard-cards-on-the-homepage[].
+
[source,yaml]
```

- [ ] **Step 2: Commit**

```bash
git add modules/observability_evaluate-project-health-using-scorecards/proc-configure-an-aggregation-card-with-an-average-tracking-type.adoc
git commit -m "fix: add plugin config cross-reference to average tracking procedure"
```

---

### Task 4: Run CQA checks and verify build

**Files:**
- All 3 modified files via their parent title

- [ ] **Step 1: Identify the title that includes these modules**

```bash
grep -rl "proc-configure-a-default-scorecard-aggregation-card" titles/
```

- [ ] **Step 2: Run CQA checks on the title**

```bash
node build/scripts/cqa/index.js titles/<title>/master.adoc
```

Expected: No new `[MANUAL]` issues introduced by our changes. Any `[AUTOFIX]` issues should be auto-fixed.

- [ ] **Step 3: Auto-fix any CQA issues**

```bash
node build/scripts/cqa/index.js --fix titles/<title>/master.adoc
```

- [ ] **Step 4: Commit any CQA fixes if needed**

```bash
git add modules/observability_evaluate-project-health-using-scorecards/
git commit -m "fix: apply CQA auto-fixes"
```
