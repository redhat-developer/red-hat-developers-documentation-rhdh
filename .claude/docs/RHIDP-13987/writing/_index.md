# Documentation Modules: RHIDP-13987

**Ticket:** RHIDP-13987
**Generated:** 2026-09-08
**Placement mode:** UPDATE-IN-PLACE
**Build framework:** Red Hat ccutil documentation (modular AsciiDoc)
**Content root:** /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2

## Files Written and Modified

| Path | Type | Description |
|------|------|-------------|
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/con-dora-metrics-in-scorecard.adoc | CONCEPT (NEW) | Explains what DORA metrics are, why they matter, and how they integrate with Scorecard |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/con-composite-metric-providers.adoc | CONCEPT (NEW) | Explains how composite metric providers work and when to use them |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/proc-install-configure-dora-backend-module.adoc | PROCEDURE (NEW) | Installation and configuration of DORA backend module with database setup |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/proc-configure-github-dora-datasource.adoc | PROCEDURE (NEW) | Configuration of GitHub as DORA datasource for deployment and PR metrics |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/proc-configure-jira-dora-datasource.adoc | PROCEDURE (NEW) | Configuration of Jira as DORA datasource for incident and resolution metrics |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/con-dora-metric-trends-visualization.adoc | CONCEPT (NEW) | Explains time-series visualization of DORA metrics and interpretation |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/proc-configure-dora-aggregation-cards-homepage.adoc | PROCEDURE (NEW) | Configuration of DORA aggregation cards on the homepage with trend visualization |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/ref-scorecard-timeseries-api.adoc | REFERENCE (NEW) | TimeSeries REST API endpoint documentation for retrieving historical DORA metrics |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/ref-scorecard-collectors-metadata-api.adoc | REFERENCE (NEW) | Collectors metadata REST API endpoint for monitoring data collection health |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/ref-available-scorecard-metric-providers-and-metric-ids.adoc | REFERENCE (UPDATED) | Added DORA metrics entries, added Unit column, added DORA prerequisite note |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/observability_evaluate-project-health-using-scorecards/proc-configure-portfolio-health-on-a-customizable-home-page.adoc | PROCEDURE (UPDATED) | Added DORA aggregation card examples with trend visualization |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/assemblies/observability_evaluate-project-health-using-scorecards/assembly-install-and-configure-scorecards-to-view-metrics.adoc | ASSEMBLY (UPDATED) | Added includes for DORA backend installation and datasource configuration procedures |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/titles/observability_evaluate-project-health-using-scorecards/master.adoc | TITLE (UPDATED) | Added DORA concept modules, trends visualization, and API references to TOC; updated abstract |

## Summary

- **New modules created:** 9 (2 concepts, 3 procedures, 2 references, 2 API references)
- **Existing modules updated:** 4 (1 reference table, 1 procedure, 1 assembly, 1 title)
- **Total files modified:** 13

## Module Dependencies

The DORA modules follow this logical dependency order:

1. **Foundation concepts** (no dependencies):
   - con-dora-metrics-in-scorecard.adoc
   - con-composite-metric-providers.adoc

2. **Installation and configuration** (depends on concepts):
   - proc-install-configure-dora-backend-module.adoc
   - proc-configure-github-dora-datasource.adoc (depends on backend installation)
   - proc-configure-jira-dora-datasource.adoc (depends on backend installation)

3. **Advanced features** (depends on configuration):
   - con-dora-metric-trends-visualization.adoc
   - proc-configure-dora-aggregation-cards-homepage.adoc

4. **API references** (standalone):
   - ref-scorecard-timeseries-api.adoc
   - ref-scorecard-collectors-metadata-api.adoc

## Next Steps for Review

1. Run CQA checks on the title master file:
   ```bash
   node build/scripts/cqa/index.js titles/observability_evaluate-project-health-using-scorecards/master.adoc
   ```

2. Run Vale linting on new modules:
   ```bash
   vale modules/observability_evaluate-project-health-using-scorecards/con-dora-metrics-in-scorecard.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/con-composite-metric-providers.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/proc-install-configure-dora-backend-module.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/proc-configure-github-dora-datasource.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/proc-configure-jira-dora-datasource.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/con-dora-metric-trends-visualization.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/proc-configure-dora-aggregation-cards-homepage.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/ref-scorecard-timeseries-api.adoc
   vale modules/observability_evaluate-project-health-using-scorecards/ref-scorecard-collectors-metadata-api.adoc
   ```

3. Build HTML preview locally to verify rendering and navigation.

4. Request technical review from engineering team members on RHIDP-13678 and RHIDP-13983.

5. Request screenshots from QE team (RHIDP-13984) for:
   - DORA metrics on component Scorecard tab
   - DORA trend visualizations
   - DORA homepage aggregation cards
