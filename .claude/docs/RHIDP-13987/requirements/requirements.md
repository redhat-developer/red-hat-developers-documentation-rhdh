# Documentation Requirements

**Source**: [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
**Date**: 2026-09-07
**Release/Sprint**: 2.1.0

## Summary

- Total requirements analyzed: 8
- New modules needed: 8
- Existing modules to update: 0
- Breaking changes requiring docs: 0

## Requirements by priority

### High

#### REQ-001: Document DORA metrics in Scorecard metric providers reference
- **Source**: [RHIDP-13987](https://redhat.atlassian.net/browse/RHIDP-13987) | [RHIDP-13978](https://redhat.atlassian.net/browse/RHIDP-13978) | [RHIDP-13979](https://redhat.atlassian.net/browse/RHIDP-13979)
- **Summary**: Add DORA metrics from GitHub and Jira data sources to the Scorecard metric providers reference table
- **User impact**: Enables platform engineers to understand which DORA metrics are available, their metric IDs, and which data sources provide them. Users need this information to configure scorecards with DORA metrics for measuring software delivery performance.
- **Documentation action**:
  - [ ] Update `modules/observability_evaluate-project-health-using-scorecards/ref-available-scorecard-metric-providers-and-metric-ids.adoc` (reference) - Add DORA metrics table entries for deployment frequency, lead time for changes, change failure rate, and time to restore service
- **Acceptance criteria**:
  - [ ] Reference table includes all four DORA metrics with their metric IDs
  - [ ] Each metric entry specifies GitHub and/or Jira as data source providers
  - [ ] Metric descriptions explain what each DORA metric measures
- **References**:
  - [RHIDP-13987](https://redhat.atlassian.net/browse/RHIDP-13987): Primary docs epic
  - [RHIDP-13978](https://redhat.atlassian.net/browse/RHIDP-13978): GitHub DORA datasource implementation
  - [RHIDP-13979](https://redhat.atlassian.net/browse/RHIDP-13979): Jira DORA datasource implementation

#### REQ-003: Document DORA backend module configuration
- **Source**: [RHIDP-13982](https://redhat.atlassian.net/browse/RHIDP-13982) | [RHIDP-14848](https://redhat.atlassian.net/browse/RHIDP-14848)
- **Summary**: Document installation and configuration of the scorecard-backend-module-dora plugin including database setup
- **User impact**: Platform administrators need to install and configure the DORA backend module to enable DORA metrics calculation. Without clear documentation on database requirements and configuration parameters, users cannot successfully deploy the feature.
- **Documentation action**:
  - [ ] Create `modules/observability_evaluate-project-health-using-scorecards/proc-configure-dora-backend-module.adoc` (procedure) - Installation steps, database configuration, and app-config.yaml settings for the DORA backend module
- **Acceptance criteria**:
  - [ ] Procedure includes database prerequisites and schema setup
  - [ ] Configuration examples show required app-config.yaml parameters
  - [ ] Installation steps work for both dynamic plugins and static backend configurations
- **References**:
  - [RHIDP-13982](https://redhat.atlassian.net/browse/RHIDP-13982): Backend module implementation
  - [RHIDP-14848](https://redhat.atlassian.net/browse/RHIDP-14848): Database schema and setup

#### REQ-004: Document DORA aggregation cards on homepage
- **Source**: [RHIDP-14402](https://redhat.atlassian.net/browse/RHIDP-14402) | [RHIDP-16834](https://redhat.atlassian.net/browse/RHIDP-16834)
- **Summary**: Document how to configure DORA metric aggregation cards to display on the RHDH homepage
- **User impact**: Development teams want to see DORA metrics aggregated across their portfolio on the homepage for quick visibility into delivery performance trends. Users need configuration guidance to enable and customize these homepage cards.
- **Documentation action**:
  - [ ] Update `modules/observability_evaluate-project-health-using-scorecards/proc-configure-portfolio-health-on-a-customizable-home-page.adoc` (procedure) - Add DORA aggregation card configuration examples
- **Acceptance criteria**:
  - [ ] Configuration examples show how to add DORA aggregation cards to the homepage
  - [ ] Documentation explains which DORA metrics can be aggregated
  - [ ] Examples include trend visualization configuration (line 101 reference)
- **References**:
  - [RHIDP-14402](https://redhat.atlassian.net/browse/RHIDP-14402): Initial aggregation cards implementation
  - [RHIDP-16834](https://redhat.atlassian.net/browse/RHIDP-16834): Trend visualization on aggregation cards

#### REQ-005: Document DORA metric trends visualization
- **Source**: [RHIDP-15576](https://redhat.atlassian.net/browse/RHIDP-15576)
- **Summary**: Document the time-series visualization feature for DORA metrics in the Scorecard plugin
- **User impact**: Users need to visualize DORA metric trends over time to identify performance improvements or degradations. Documentation must explain how to enable and interpret the time-series charts for historical DORA metric data.
- **Documentation action**:
  - [ ] Create `modules/observability_evaluate-project-health-using-scorecards/con-dora-metric-trends-visualization.adoc` (concept) - Explain time-series visualization, supported metrics, and time windows
- **Acceptance criteria**:
  - [ ] Concept explains which DORA metrics support trend visualization
  - [ ] Documentation describes available time windows (7 days, 30 days, 90 days)
  - [ ] Screenshots or descriptions show how to interpret trend charts
- **References**:
  - [RHIDP-15576](https://redhat.atlassian.net/browse/RHIDP-15576): Trend visualization feature implementation

### Medium

#### REQ-002: Document composite metric providers feature
- **Source**: [RHIDP-13977](https://redhat.atlassian.net/browse/RHIDP-13977)
- **Summary**: Document the new composite metric provider capability that enables DORA metrics calculation
- **User impact**: DORA metrics require aggregating data from multiple sources (deployments, incidents, pull requests). Composite metric providers enable this multi-source aggregation. Users need to understand this architectural capability to create custom composite metrics.
- **Documentation action**:
  - [ ] Create `modules/observability_evaluate-project-health-using-scorecards/con-composite-metric-providers.adoc` (concept) - Explain composite metric providers, how they differ from standard providers, and DORA use case
- **Acceptance criteria**:
  - [ ] Concept explains what composite metric providers are
  - [ ] Documentation describes how composite providers aggregate multiple data sources
  - [ ] DORA metrics are cited as the primary use case example
- **References**:
  - [RHIDP-13977](https://redhat.atlassian.net/browse/RHIDP-13977): Composite metric provider implementation

#### REQ-006: Document TimeSeries API for Scorecard
- **Source**: [RHIDP-13980](https://redhat.atlassian.net/browse/RHIDP-13980) | [RHIDP-16108](https://redhat.atlassian.net/browse/RHIDP-16108)
- **Summary**: Document the new TimeSeries REST API endpoints for retrieving historical metric data
- **User impact**: Developers integrating with RHDH programmatically need REST API documentation to fetch historical DORA metrics. Without API documentation, external tools and dashboards cannot consume DORA time-series data.
- **Documentation action**:
  - [ ] Create `modules/observability_evaluate-project-health-using-scorecards/ref-scorecard-timeseries-api.adoc` (reference) - API endpoint paths, query parameters, response format, and examples
- **Acceptance criteria**:
  - [ ] Reference documents all TimeSeries API endpoints
  - [ ] Query parameters are explained (entity, metric ID, time window, interval)
  - [ ] Response format and data structure are documented with examples
- **References**:
  - [RHIDP-13980](https://redhat.atlassian.net/browse/RHIDP-13980): TimeSeries API implementation
  - [RHIDP-16108](https://redhat.atlassian.net/browse/RHIDP-16108): Enhancements for latest-per-day fetching

#### REQ-007: Document collectors metadata API
- **Source**: [RHIDP-15960](https://redhat.atlassian.net/browse/RHIDP-15960)
- **Summary**: Document the new metadata API endpoint for retrieving collector information
- **User impact**: Platform administrators need to verify which data collectors are active and their health status. The metadata API provides this observability. Users need documentation to query collector status programmatically.
- **Documentation action**:
  - [ ] Create `modules/observability_evaluate-project-health-using-scorecards/ref-scorecard-collectors-metadata-api.adoc` (reference) - API endpoint for collector metadata, response format, and use cases
- **Acceptance criteria**:
  - [ ] Reference documents the collectors metadata endpoint path
  - [ ] Response format shows available collector metadata fields
  - [ ] Use cases explain when to query collector metadata (health checks, troubleshooting)
- **References**:
  - [RHIDP-15960](https://redhat.atlassian.net/browse/RHIDP-15960): Collectors metadata API implementation

### Low

#### REQ-008: Document metric unit field enhancement
- **Source**: [RHIDP-15624](https://redhat.atlassian.net/browse/RHIDP-15624)
- **Summary**: Document the addition of unit metadata to metric definitions for DORA metrics
- **User impact**: DORA metrics use different units (deployments per day, hours, percentages). The unit field enhancement ensures the UI displays metrics with correct units. Users benefit from this automatically, but developers creating custom metrics need to understand the unit field.
- **Documentation action**:
  - [ ] Update `modules/observability_evaluate-project-health-using-scorecards/ref-available-scorecard-metric-providers-and-metric-ids.adoc` (reference) - Add unit column to metric providers table
- **Acceptance criteria**:
  - [ ] Metric providers table includes unit information
  - [ ] Documentation explains supported unit types
  - [ ] DORA metrics show their respective units
- **References**:
  - [RHIDP-15624](https://redhat.atlassian.net/browse/RHIDP-15624): Metric unit field implementation

## Documentation scope

### New documentation needed

| Requirement | Scope | References |
|-------------|-------|------------|
| REQ-001 | Add DORA metrics to Scorecard metric providers reference table | RHIDP-13987, RHIDP-13978, RHIDP-13979 |
| REQ-002 | Explain composite metric providers concept | RHIDP-13977 |
| REQ-003 | DORA backend module installation and configuration procedure | RHIDP-13982, RHIDP-14848 |
| REQ-004 | DORA aggregation cards configuration | RHIDP-14402, RHIDP-16834 |
| REQ-005 | DORA metric trends visualization concept | RHIDP-15576 |
| REQ-006 | TimeSeries REST API reference documentation | RHIDP-13980, RHIDP-16108 |
| REQ-007 | Collectors metadata API reference documentation | RHIDP-15960 |
| REQ-008 | Add metric unit information to reference table | RHIDP-15624 |

### Existing documentation to update

| Requirement | What changed | References |
|-------------|-------------|------------|
| REQ-001 | Add DORA metrics to existing metric providers reference | RHIDP-13987, RHIDP-13978, RHIDP-13979 |
| REQ-004 | Add DORA aggregation card examples to homepage configuration procedure | RHIDP-14402, RHIDP-16834 |
| REQ-008 | Add unit column to metric providers reference table | RHIDP-15624 |

## Notes

Deep analysis was limited by JIRA API access constraints during processing. Requirements are based on discovery phase data enriched with ticket metadata and related work context. Additional technical details should be gathered from:
- Backend implementation PRs for RHIDP-13982 (backend module) and RHIDP-14848 (database schema)
- Frontend implementation PRs for RHIDP-13983 (UI components) and RHIDP-14402/RHIDP-16834 (aggregation cards)
- API specifications from RHIDP-13980 (TimeSeries API) and RHIDP-15960 (metadata API)

## Related tickets

**Parent epic:**
- [RHDHPLAN-1102](https://redhat.atlassian.net/browse/RHDHPLAN-1102): Integration of DORA Metrics into RHDH Scorecard Plugin

**Sibling tickets:**
- [RHIDP-13678](https://redhat.atlassian.net/browse/RHIDP-13678): [Backend] Integration of DORA Metrics into RHDH Scorecard Plugin
- [RHIDP-13983](https://redhat.atlassian.net/browse/RHIDP-13983): [Frontend] Integration of DORA Metrics into RHDH Scorecard Plugin
- [RHIDP-13984](https://redhat.atlassian.net/browse/RHIDP-13984): [QE] Integration of DORA Metrics into RHDH Scorecard Plugin

**Child tickets:**
- [RHIDP-14652](https://redhat.atlassian.net/browse/RHIDP-14652): [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin

## Sources consulted

### JIRA tickets
- [RHIDP-13987](https://redhat.atlassian.net/browse/RHIDP-13987): [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
- [RHIDP-14652](https://redhat.atlassian.net/browse/RHIDP-14652): [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
- [RHDHPLAN-1102](https://redhat.atlassian.net/browse/RHDHPLAN-1102): Integration of DORA Metrics into RHDH Scorecard Plugin
- [RHIDP-13678](https://redhat.atlassian.net/browse/RHIDP-13678): [Backend] Integration of DORA Metrics into RHDH Scorecard Plugin
- [RHIDP-13983](https://redhat.atlassian.net/browse/RHIDP-13983): [Frontend] Integration of DORA Metrics into RHDH Scorecard Plugin
- [RHIDP-13976](https://redhat.atlassian.net/browse/RHIDP-13976): [Spike]: Investigate how to implement composite Scorecard metric providers
- [RHIDP-13977](https://redhat.atlassian.net/browse/RHIDP-13977): Composite metric providers in Scorecard plugin
- [RHIDP-13978](https://redhat.atlassian.net/browse/RHIDP-13978): GitHub Scorecard - DORA Metrics Datasource
- [RHIDP-13979](https://redhat.atlassian.net/browse/RHIDP-13979): Jira Scorecard - DORA Metrics Datasource
- [RHIDP-13980](https://redhat.atlassian.net/browse/RHIDP-13980): Scorecard TimeSeries API
- [RHIDP-13982](https://redhat.atlassian.net/browse/RHIDP-13982): Scorecard backend module dora
- [RHIDP-14402](https://redhat.atlassian.net/browse/RHIDP-14402): DORA aggregation cards
- [RHIDP-14848](https://redhat.atlassian.net/browse/RHIDP-14848): Database in scorecard backend module dora
- [RHIDP-15576](https://redhat.atlassian.net/browse/RHIDP-15576): Visualize DORA Metric Trends in the Scorecard Plugin
- [RHIDP-15624](https://redhat.atlassian.net/browse/RHIDP-15624): Add metric unit to metrics
- [RHIDP-15960](https://redhat.atlassian.net/browse/RHIDP-15960): Collectors metadata API
- [RHIDP-16108](https://redhat.atlassian.net/browse/RHIDP-16108): Time-series API: fetch latest-per-day in DB and include error-only days
- [RHIDP-16305](https://redhat.atlassian.net/browse/RHIDP-16305): Include pre-window deployment for first in-window DORA lead-time and CFR intervals
- [RHIDP-16834](https://redhat.atlassian.net/browse/RHIDP-16834): Visualize DORA Metric Trends on the Scorecard Homepage Aggregation Cards

### Pull requests / Merge requests
None discovered during analysis phase

### Code files
None analyzed during discovery phase

### Existing documentation
- `modules/observability_evaluate-project-health-using-scorecards/ref-available-scorecard-metric-providers-and-metric-ids.adoc`: Primary reference for scorecard metric providers - will need DORA metrics added
- `modules/observability_evaluate-project-health-using-scorecards/ref-available-metric-data-for-entities.adoc`: Lists metric data availability per entity type - may need DORA metric data sources
- `modules/observability_evaluate-project-health-using-scorecards/proc-configure-aggregated-kpis-for-the-scorecard.adoc`: Configuration procedure for aggregated KPIs - DORA aggregation cards are new feature
- `modules/observability_evaluate-project-health-using-scorecards/proc-configure-portfolio-health-on-a-customizable-home-page.adoc`: Homepage configuration - may need updates for DORA aggregation cards
- `assemblies/observability_evaluate-project-health-using-scorecards/assembly-set-up-scorecards-to-monitor-your-project-health.adoc`: Main scorecard setup assembly - may need DORA metric setup steps
- `assemblies/observability_evaluate-project-health-using-scorecards/assembly-configure-scorecard-cards-on-the-homepage.adoc`: Homepage card configuration - DORA aggregation cards feature

### External references
None consulted during discovery phase

### Web search findings
None performed during discovery phase
