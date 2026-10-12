# Documentation Plan

**Project**: Integration of DORA Metrics into RHDH Scorecard Plugin
**Date**: 2026-09-08
**Ticket**: [RHIDP-13987](https://redhat.atlassian.net/browse/RHIDP-13987) / [RHDHPLAN-1102](https://redhat.atlassian.net/browse/RHDHPLAN-1102)

## What is the support status of the feature(s) being used to complete the user's JTBD (Job To Be Done)?

General Availability (GA) in release 2.1.0

## Why is this content important?

Platform engineering teams and development leaders need to measure and improve their software delivery performance using industry-standard DORA (DevOps Research and Assessment) metrics. The integration of DORA metrics into the RHDH Scorecard plugin enables teams to track deployment frequency, lead time for changes, change failure rate, and time to restore service across their portfolio. Without comprehensive documentation, users cannot successfully install, configure, or interpret these metrics, preventing them from gaining actionable insights into their delivery performance and identifying improvement opportunities.

This content enables platform administrators to deploy the DORA backend module with proper database configuration, allows platform engineers to configure DORA data sources and aggregation cards, and helps development teams visualize and interpret delivery performance trends over time.

## Who is the target persona(s)?

* IT Operations Leader: Owns the platform infrastructure and needs to install and configure the DORA backend module with database requirements
* SysAdmin: Configures DORA data sources, homepage cards, and metric collection parameters
* AppDev ITDM: Consumes DORA metrics to make data-driven decisions about development process improvements and resource allocation
* Developer: Views individual component DORA metrics and trends to understand delivery performance at the team level

## What is the main JTBD? What user goal is being accomplished? What pain point is being avoided?

When I need to assess and improve my organization's software delivery performance, I want to measure DORA metrics across my portfolio with automated data collection from GitHub and Jira, so that I can identify bottlenecks in the delivery pipeline, benchmark against industry standards, and make evidence-based decisions to accelerate delivery while maintaining quality, while avoiding manual metric aggregation, fragmented tooling, and subjective performance assessments.

## How does the JTBD(s) relate to the overall real-world workflow for the user?

DORA metrics measurement fits into the broader DevOps maturity and continuous improvement workflow:

1. **Platform Setup Phase**: IT Operations Leaders and SysAdmins install the DORA backend module with database configuration and enable DORA data sources (GitHub, Jira) to begin automated metric collection.

2. **Configuration Phase**: Platform engineers configure which repositories, teams, and systems contribute to DORA metrics, set up homepage aggregation cards for visibility, and configure metric thresholds aligned with organizational goals.

3. **Monitoring Phase**: Development teams and leadership consume DORA metrics through Scorecard entity views and homepage aggregation cards to understand current delivery performance across the portfolio.

4. **Analysis Phase**: Teams analyze historical trends using time-series visualizations to identify performance patterns, seasonal variations, and the impact of process changes on delivery metrics.

5. **Improvement Phase**: Leaders use DORA insights to prioritize process improvements (e.g., deployment automation, incident response procedures, code review practices) and track the impact of these initiatives over time.

6. **Benchmarking Phase**: Organizations compare their DORA metrics against industry benchmarks to understand their maturity level (elite, high, medium, low performers) and set realistic improvement targets.

This workflow integrates with existing development practices, incident management processes, and portfolio planning activities, making DORA metrics a continuous feedback mechanism rather than a point-in-time assessment.

## What high-level steps does the user need to take to accomplish the goal?

1. **Prerequisites**: Verify Scorecard plugin is installed, ensure GitHub and/or Jira integrations are configured, confirm database access for time-series data storage
2. **Install DORA backend module**: Deploy scorecard-backend-module-dora plugin as dynamic plugin or static backend module
3. **Configure database**: Set up database schema for DORA metric storage, configure retention policies
4. **Enable DORA data sources**: Configure GitHub DORA datasource for deployment and pull request data, configure Jira DORA datasource for incident and issue data
5. **Configure metric collection**: Map repositories to components in catalog, define what constitutes a deployment, failure, or incident for your organization
6. **Add DORA metrics to Scorecard views**: Reference DORA metric IDs in Scorecard configuration to display metrics on component entity pages
7. **Configure homepage aggregation cards** (optional): Add DORA aggregation cards to homepage with trend visualizations
8. **Verify data collection**: Confirm metrics are being collected and calculated correctly
9. **Interpret and act on metrics**: Use time-series visualization to identify trends, set improvement goals based on metrics

## Is there a demo available or can one be created?

No demo URL available at this time. However, the RHDH 2.1.0 release will include working DORA metrics in the Scorecard plugin that can be demonstrated in customer environments.

## Are there special considerations for disconnected environments?

Yes. The DORA backend module requires:
- Database connectivity for time-series metric storage (PostgreSQL or similar)
- GitHub API access for GitHub DORA datasource (deployment events, pull requests, commits)
- Jira API access for Jira DORA datasource (incident tracking, issue resolution times)

For disconnected environments:
- Database must be accessible within the disconnected network
- GitHub and Jira integrations require either internal GitHub Enterprise / Jira instances or a mechanism to sync data from external instances
- Time-series data storage may grow significantly depending on portfolio size and metric retention policies

## Who can provide information and answer questions?

**Product Manager**: Dominika Zemanovicova (assignee on RHDHPLAN-1102)
**Technical SME**: Engineering team members on RHIDP-13678 (Backend), RHIDP-13983 (Frontend)
**Documentation Owner**: Gerry Forde (assignee on RHIDP-14652)
**QE Contact**: Team members on RHIDP-13984

## Release Note needed?

Yes

Draft release note:

**DORA Metrics Integration in Scorecard Plugin**

The Scorecard plugin now supports DevOps Research and Assessment (DORA) metrics, enabling platform teams to measure software delivery performance across their portfolio. Teams can track four key metrics: deployment frequency, lead time for changes, change failure rate, and time to restore service. DORA metrics are calculated from GitHub deployment events, pull requests, and Jira incident data, with time-series visualization to identify performance trends over time. Platform administrators can configure DORA aggregation cards on the homepage for portfolio-wide visibility into delivery performance.

Key capabilities:
- Automated DORA metric collection from GitHub and Jira data sources
- Time-series visualization of DORA metrics with configurable time windows (7, 30, 90 days)
- Homepage aggregation cards with trend charts for portfolio-level DORA metrics
- REST API endpoints for programmatic access to historical DORA data
- Composite metric providers enabling multi-source data aggregation

For installation and configuration instructions, see the Scorecards documentation.

## Links to existing content

- [Scorecard plugin documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/latest/html-single/configuring_plugins_in_red_hat_developer_hub/index#assembly-configuring-scorecards-in-rhdh)
- Existing module: `ref-available-scorecard-metric-providers-and-metric-ids.adoc` (will be updated with DORA metrics)
- Existing module: `proc-configure-portfolio-health-on-a-customizable-home-page.adoc` (will be updated with DORA aggregation card examples)
- Existing module: `ref-scorecard-plugin-rest-api-endpoints-and-parameters.adoc` (will be updated with TimeSeries API endpoints)
- Parent epic: [RHDHPLAN-1102](https://redhat.atlassian.net/browse/RHDHPLAN-1102)
- Backend implementation: [RHIDP-13678](https://redhat.atlassian.net/browse/RHIDP-13678)
- Frontend implementation: [RHIDP-13983](https://redhat.atlassian.net/browse/RHIDP-13983)

## New Docs

### CONCEPT: What are DORA metrics and why they matter
* **Filename**: `con-dora-metrics-in-scorecard.adoc`
* **Job Map Stage**: Observe
* **Content Journey Phase**: Discover
* **JTBD User Story**: As an AppDev ITDM, I want to understand what DORA metrics measure so that I can evaluate whether they provide actionable insights for my organization
* **Audience**: AppDev ITDM, IT Operations Leader
* **Content outline**:
  - Explanation of the four DORA metrics (deployment frequency, lead time for changes, change failure rate, time to restore service)
  - Why DORA metrics matter for software delivery performance
  - How DORA metrics in Scorecard differ from standalone DORA tools (integrated with catalog entities, automated collection)
  - What data sources feed DORA metrics (GitHub deployments/PRs, Jira incidents)
  - Performance benchmarks (elite, high, medium, low performers) for context
* **Prerequisites**: None
* **Dependencies**: Must be placed early in the documentation flow, before configuration procedures
* **Sources**: RHIDP-13987, RHDHPLAN-1102, DORA research methodology

### CONCEPT: Composite metric providers
* **Filename**: `con-composite-metric-providers.adoc`
* **Job Map Stage**: Observe
* **Content Journey Phase**: Discover
* **JTBD User Story**: As a platform engineer, I want to understand how composite metric providers work so that I can create custom metrics that aggregate data from multiple sources
* **Audience**: SysAdmin, Developer
* **Content outline**:
  - Definition of composite metric providers vs. standard single-source providers
  - How composite providers aggregate data from multiple sources (GitHub + Jira)
  - DORA metrics as the primary use case (e.g., change failure rate combines deployment data from GitHub with incident data from Jira)
  - When to use composite providers vs. standard providers
  - Architectural explanation: how the backend module orchestrates data collection from multiple sources
* **Prerequisites**: Understanding of Scorecard metric providers
* **Dependencies**: Should be read before DORA backend module installation procedure
* **Sources**: RHIDP-13977

### PROCEDURE: Install and configure DORA backend module
* **Filename**: `proc-install-configure-dora-backend-module.adoc`
* **Job Map Stage**: Configure
* **Content Journey Phase**: Evaluate
* **JTBD User Story**: As an IT Operations Leader, I want to install the DORA backend module with proper database configuration so that DORA metrics are calculated and stored reliably
* **Audience**: IT Operations Leader, SysAdmin
* **Content outline**:
  - Prerequisites: Scorecard plugin installed, database access, GitHub/Jira integrations configured
  - Installation steps for dynamic plugin deployment (OCI registry path, plugin configuration)
  - Installation steps for static backend module (package installation, backend registration)
  - Database configuration: schema setup, connection parameters in app-config.yaml
  - Configuration parameters reference: database connection string, retention policies, collection intervals
  - Verification steps: confirm backend module is loaded, check database tables are created, verify metrics collection starts
* **Prerequisites**: Scorecard plugin enabled, database available (PostgreSQL recommended), GitHub and/or Jira integrations configured
* **Dependencies**: Requires `con-composite-metric-providers.adoc` for context, feeds into data source configuration procedures
* **Sources**: RHIDP-13982, RHIDP-14848

### PROCEDURE: Configure GitHub DORA datasource
* **Filename**: `proc-configure-github-dora-datasource.adoc`
* **Job Map Stage**: Configure
* **Content Journey Phase**: Evaluate
* **JTBD User Story**: As a SysAdmin, I want to configure GitHub as a DORA data source so that deployment frequency and lead time metrics are calculated from my GitHub repositories
* **Audience**: SysAdmin
* **Content outline**:
  - Prerequisites: DORA backend module installed, GitHub integration configured with appropriate scopes
  - What GitHub data is collected: deployment events, pull requests, commits, branch protection rules
  - Configuration in app-config.yaml: GitHub datasource enablement, repository mapping
  - How to define what constitutes a "deployment" in your organization (GitHub deployment events, release tags, specific workflows)
  - How lead time for changes is calculated (first commit to merge to deployment)
  - Verification: check that GitHub events are being collected, confirm metric calculations appear
* **Prerequisites**: DORA backend module installed, GitHub integration configured
* **Dependencies**: Depends on `proc-install-configure-dora-backend-module.adoc`
* **Sources**: RHIDP-13978

### PROCEDURE: Configure Jira DORA datasource
* **Filename**: `proc-configure-jira-dora-datasource.adoc`
* **Job Map Stage**: Configure
* **Content Journey Phase**: Evaluate
* **JTBD User Story**: As a SysAdmin, I want to configure Jira as a DORA data source so that change failure rate and time to restore service metrics are calculated from incident data
* **Audience**: SysAdmin
* **Content outline**:
  - Prerequisites: DORA backend module installed, Jira integration configured
  - What Jira data is collected: incidents, bugs, issue resolution times, issue status transitions
  - Configuration in app-config.yaml: Jira datasource enablement, project mapping, issue type filters
  - How to define what constitutes a "failure" (specific Jira issue types, labels, priorities)
  - How time to restore service is calculated (incident creation to resolution)
  - Verification: check that Jira issues are being collected, confirm metric calculations
* **Prerequisites**: DORA backend module installed, Jira integration configured
* **Dependencies**: Depends on `proc-install-configure-dora-backend-module.adoc`
* **Sources**: RHIDP-13979

### CONCEPT: DORA metric trends visualization
* **Filename**: `con-dora-metric-trends-visualization.adoc`
* **Job Map Stage**: Analyze
* **Content Journey Phase**: Adopt
* **JTBD User Story**: As an AppDev ITDM, I want to visualize DORA metric trends over time so that I can identify performance improvements or degradations and correlate them with process changes
* **Audience**: AppDev ITDM, Developer
* **Content outline**:
  - What time-series visualization shows: historical DORA metric values over configurable time windows
  - Supported time windows: 7 days, 30 days, 90 days (configurable)
  - Which DORA metrics support trend visualization (all four: deployment frequency, lead time, change failure rate, time to restore service)
  - How to interpret trend charts: identifying patterns, seasonal variations, impact of process changes
  - Where trends appear: component Scorecard entity pages, homepage aggregation cards
  - Data granularity: daily, weekly aggregation options
* **Prerequisites**: DORA metrics configured and collecting data
* **Dependencies**: Logical follow-up to data source configuration procedures
* **Sources**: RHIDP-15576, RHIDP-16834

### PROCEDURE: Configure DORA aggregation cards on homepage
* **Filename**: `proc-configure-dora-aggregation-cards-homepage.adoc`
* **Job Map Stage**: Observe
* **Content Journey Phase**: Adopt
* **JTBD User Story**: As an AppDev ITDM, I want to display aggregated DORA metrics on the homepage so that I have immediate visibility into portfolio-wide delivery performance without navigating to individual components
* **Audience**: SysAdmin (configures), AppDev ITDM (consumes)
* **Content outline**:
  - Prerequisites: DORA backend module installed, DORA data sources configured, customizable homepage enabled
  - Configuration examples in app-config.yaml for DORA aggregation cards (deployment frequency, lead time, change failure rate, time to restore service)
  - How to configure trend visualization on aggregation cards (line charts showing 30-day trends)
  - Customization options: title, metric ID, aggregation method (average, sum, status-grouped)
  - Layout configuration: positioning cards on the homepage grid
  - Verification: log in to RHDH, confirm DORA aggregation cards appear on homepage, verify data is populated
* **Prerequisites**: DORA backend module configured, customizable homepage plugin enabled
* **Dependencies**: Builds on `con-dora-metric-trends-visualization.adoc`
* **Sources**: RHIDP-14402, RHIDP-16834

### REFERENCE: TimeSeries REST API for Scorecard
* **Filename**: `ref-scorecard-timeseries-api.adoc`
* **Job Map Stage**: Develop
* **Content Journey Phase**: Adopt
* **JTBD User Story**: As a Developer, I want to programmatically fetch historical DORA metrics via REST API so that I can integrate delivery performance data into custom dashboards and reporting tools
* **Audience**: Developer
* **Content outline**:
  - API endpoint path: `GET /api/scorecard/timeseries`
  - Query parameters:
    - `entity` (required): catalog entity reference (kind:namespace/name)
    - `metricId` (required): DORA metric ID (e.g., dora.deploymentFrequency)
    - `startDate` (required): ISO 8601 date for time window start
    - `endDate` (required): ISO 8601 date for time window end
    - `interval` (optional): data point granularity (daily, weekly)
  - Response format: JSON array of time-series data points with timestamp and metric value
  - Response examples for each DORA metric
  - Authentication and permissions: requires `scorecard.metric.read` permission
  - Error responses: 400 (invalid parameters), 403 (permission denied), 404 (entity not found)
  - Use cases: custom reporting, data export, integration with external BI tools
* **Prerequisites**: DORA backend module installed and collecting data
* **Dependencies**: None (standalone reference)
* **Sources**: RHIDP-13980, RHIDP-16108

### REFERENCE: Collectors metadata REST API
* **Filename**: `ref-scorecard-collectors-metadata-api.adoc`
* **Job Map Stage**: Administer
* **Content Journey Phase**: Adopt
* **JTBD User Story**: As a SysAdmin, I want to query collector health status programmatically so that I can monitor data collection reliability and troubleshoot metric gaps
* **Audience**: SysAdmin, IT Operations Leader
* **Content outline**:
  - API endpoint path: `GET /api/scorecard/collectors/metadata`
  - Response format: JSON array of active collectors with metadata fields:
    - Collector ID (datasource identifier)
    - Status (active, error, disabled)
    - Last collection timestamp
    - Entity count (number of entities monitored)
    - Error messages (if applicable)
  - Response example showing GitHub and Jira DORA collectors
  - Use cases: health monitoring, troubleshooting missing metrics, verifying collector configuration
  - Authentication and permissions: requires `scorecard.metric.read` permission (may require admin permission in future)
* **Prerequisites**: DORA backend module installed
* **Dependencies**: None (standalone reference)
* **Sources**: RHIDP-15960

## Updated Docs

### ref-available-scorecard-metric-providers-and-metric-ids.adoc
* **Update type**: Add new table entries
* **Changes required**:
  - Add DORA metrics section to the provider table with four new entries:
    1. `dora.deploymentFrequency` - Deployment Frequency - Number of deployments per day (GitHub datasource) - Type: number, Unit: deployments/day
    2. `dora.leadTimeForChanges` - Lead Time for Changes - Time from first commit to production deployment (GitHub datasource) - Type: duration, Unit: hours
    3. `dora.changeFailureRate` - Change Failure Rate - Percentage of deployments causing failures (GitHub + Jira datasources) - Type: percentage, Unit: %
    4. `dora.timeToRestoreService` - Time to Restore Service - Mean time to resolve incidents (Jira datasource) - Type: duration, Unit: hours
  - Add note explaining that DORA metrics require the DORA backend module to be installed
  - Add cross-reference to `con-dora-metrics-in-scorecard.adoc` for explanation of DORA metrics
  - Include Unit column to table header (new column) per RHIDP-15624
* **Sources**: RHIDP-13987, RHIDP-13978, RHIDP-13979, RHIDP-15624

### proc-configure-portfolio-health-on-a-customizable-home-page.adoc
* **Update type**: Add DORA aggregation card examples
* **Changes required**:
  - Add DORA aggregation card configuration examples to the YAML snippet in step 1
  - Include example for deployment frequency aggregation card with trend visualization
  - Include example for lead time aggregation card
  - Add note explaining that DORA metrics require DORA backend module installation
  - Add cross-reference to `proc-configure-dora-aggregation-cards-homepage.adoc` for detailed DORA-specific configuration
* **Sources**: RHIDP-14402, RHIDP-16834

### ref-scorecard-plugin-rest-api-endpoints-and-parameters.adoc
* **Update type**: Add new API endpoints
* **Changes required**:
  - Add two new endpoint entries to the "Supported REST API endpoints" table:
    1. `GET /timeseries` - Retrieves historical metric values over a specified time window - Status: Active
    2. `GET /collectors/metadata` - Retrieves metadata about active metric collectors - Status: Active
  - Add cross-references to `ref-scorecard-timeseries-api.adoc` and `ref-scorecard-collectors-metadata-api.adoc` for detailed documentation
  - Add note that TimeSeries API is specifically designed for DORA metrics but can be used with other metrics that support time-series storage
* **Sources**: RHIDP-13980, RHIDP-15960, RHIDP-16108

### assembly-install-and-configure-scorecards-to-view-metrics.adoc
* **Update type**: Add DORA configuration procedures
* **Changes required**:
  - Add include statement for `proc-install-configure-dora-backend-module.adoc` after existing integration procedures
  - Add include statement for `proc-configure-github-dora-datasource.adoc`
  - Add include statement for `proc-configure-jira-dora-datasource.adoc`
  - Update assembly abstract to mention DORA metrics support
* **Sources**: RHIDP-13987

### titles/observability_evaluate-project-health-using-scorecards/master.adoc
* **Update type**: Add new concepts and references to TOC
* **Changes required**:
  - Add include statement for `con-dora-metrics-in-scorecard.adoc` early in the document (after con-component-health-and-compliance-monitoring-using-scorecards.adoc)
  - Add include statement for `con-composite-metric-providers.adoc` after DORA concept
  - Add include statement for `con-dora-metric-trends-visualization.adoc` in the monitoring/observability section
  - Add include statement for `ref-scorecard-timeseries-api.adoc` in the reference section
  - Add include statement for `ref-scorecard-collectors-metadata-api.adoc` in the reference section
  - Update book abstract to mention DORA metrics
* **Sources**: RHIDP-13987

## Gap Analysis

### Coverage Gaps Identified

| Gap Area | Current State | Needed State | Impact |
|----------|--------------|--------------|--------|
| DORA metrics reference | No DORA metrics in provider table | Add 4 DORA metrics with IDs, descriptions, data sources, units | High - Users cannot identify which DORA metrics are available |
| DORA backend installation | No documentation for DORA backend module | Create installation and configuration procedure with database setup | High - Users cannot deploy DORA functionality |
| DORA data source configuration | Generic GitHub/Jira integration docs exist but no DORA-specific configuration | Create DORA-specific configuration procedures for GitHub and Jira datasources | High - Users cannot configure metric collection |
| DORA conceptual understanding | No explanation of what DORA metrics are or why they matter | Create concept module explaining DORA metrics, benchmarks, use cases | Medium - Users may not understand value proposition |
| Composite metric providers | No documentation of composite provider capability | Create concept explaining how multi-source aggregation works | Medium - Users cannot create custom composite metrics |
| Time-series visualization | No documentation of trend charts | Create concept explaining trend visualization capabilities | Medium - Users may not discover visualization features |
| Homepage DORA aggregation | Generic homepage card docs exist but no DORA examples | Add DORA-specific examples to existing procedure | Medium - Users may not know DORA metrics can be aggregated on homepage |
| TimeSeries REST API | Existing API docs do not include TimeSeries endpoints | Add TimeSeries API reference documentation | Medium - Developers cannot integrate DORA data programmatically |
| Collectors metadata API | No documentation of collector health monitoring API | Create API reference for collectors metadata endpoint | Low - Admin use case, not critical for basic usage |
| Metric units | Metric table lacks unit information | Add unit column to provider reference table | Low - Enhances usability but not blocking |

### Currency Assessment

All existing Scorecard documentation is current (no outdated DORA references to remove), but lacks DORA-specific content. The existing structure is sound and can accommodate DORA additions without major reorganization.

### Completeness Assessment

Existing Scorecard documentation provides:
- ✅ Plugin installation and RBAC configuration
- ✅ GitHub and Jira integration procedures
- ✅ Metric provider reference
- ✅ Homepage configuration
- ✅ REST API documentation structure

Missing for DORA:
- ❌ DORA backend module installation (critical gap)
- ❌ DORA-specific data source configuration (critical gap)
- ❌ DORA metrics reference entries (critical gap)
- ❌ DORA conceptual overview (important for adoption)
- ❌ Time-series visualization documentation (important for value realization)
- ❌ TimeSeries API documentation (important for integrations)

### User Journey Coverage Gaps

| Journey Phase | Current DORA Coverage | Gap |
|---------------|----------------------|-----|
| Expand | None | Need DORA overview in Scorecard concept module |
| Discover | None | Need `con-dora-metrics-in-scorecard.adoc` and `con-composite-metric-providers.adoc` |
| Learn | Partial (generic Scorecard tutorials) | Need DORA-specific quick start or tutorial (future consideration) |
| Evaluate | None | Need installation and configuration procedures (critical) |
| Adopt | None | Need trend visualization concept, API references, troubleshooting guidance |

**Highest priority**: Evaluate phase (installation/configuration) and Discover phase (conceptual understanding).

## Implementation Order and Dependencies

### Phase 1: Foundation (Critical Path)
1. **con-dora-metrics-in-scorecard.adoc** - Provides conceptual foundation, no dependencies
2. **con-composite-metric-providers.adoc** - Explains architectural approach, depends on understanding of standard providers
3. **ref-available-scorecard-metric-providers-and-metric-ids.adoc (update)** - Add DORA metrics to reference table, depends on con-dora-metrics-in-scorecard.adoc for cross-reference

### Phase 2: Installation and Configuration (Blocks Usage)
4. **proc-install-configure-dora-backend-module.adoc** - Critical for enabling DORA, depends on composite providers concept
5. **proc-configure-github-dora-datasource.adoc** - Depends on backend module installation
6. **proc-configure-jira-dora-datasource.adoc** - Depends on backend module installation
7. **assembly-install-and-configure-scorecards-to-view-metrics.adoc (update)** - Add DORA procedures to assembly

### Phase 3: Advanced Features (Enhances Value)
8. **con-dora-metric-trends-visualization.adoc** - Can be written in parallel with Phase 2
9. **proc-configure-dora-aggregation-cards-homepage.adoc** - Depends on backend configuration being documented
10. **proc-configure-portfolio-health-on-a-customizable-home-page.adoc (update)** - Add DORA examples

### Phase 4: Developer and Admin Features (Optional but Valuable)
11. **ref-scorecard-timeseries-api.adoc** - Can be written independently
12. **ref-scorecard-collectors-metadata-api.adoc** - Can be written independently
13. **ref-scorecard-plugin-rest-api-endpoints-and-parameters.adoc (update)** - Add new endpoints

### Phase 5: Integration (Finalization)
14. **titles/observability_evaluate-project-health-using-scorecards/master.adoc (update)** - Add all new modules to TOC

**Recommended authoring sequence**: Follow phases 1-5 in order. Within each phase, modules can be authored in parallel. Phase 1 and 2 are critical path and should be completed first for RHIDP-13987 to be considered minimally complete.

## Assembly Structure and Content Organization

### Proposed Assembly: "Measure software delivery performance with DORA metrics"
**Filename**: `assembly-measure-delivery-performance-with-dora-metrics.adoc`
**Parent assembly**: Include in `titles/observability_evaluate-project-health-using-scorecards/master.adoc`

**Structure**:
```
assembly-measure-delivery-performance-with-dora-metrics.adoc
├── con-dora-metrics-in-scorecard.adoc (What are DORA metrics)
├── con-composite-metric-providers.adoc (How DORA metrics aggregate data)
├── proc-install-configure-dora-backend-module.adoc (Install backend module)
├── proc-configure-github-dora-datasource.adoc (Configure GitHub data source)
├── proc-configure-jira-dora-datasource.adoc (Configure Jira data source)
├── con-dora-metric-trends-visualization.adoc (Understanding trends)
└── proc-configure-dora-aggregation-cards-homepage.adoc (Homepage visibility)
```

**Placement in master.adoc**: After `assembly-install-and-configure-scorecards-to-view-metrics.adoc` and before `assembly-scorecard-metric-thresholds.adoc`, as DORA is a specialized metric type that builds on basic Scorecard installation.

**Reading order rationale**:
1. Concept first (what/why) for context
2. Architecture concept (composite providers) for understanding
3. Installation before configuration (logical dependency)
4. Data source configuration next (GitHub, then Jira - alphabetical)
5. Advanced features last (trends, homepage cards)

**Shared prerequisites**:
- Scorecard plugin installed and enabled
- RBAC configured for Scorecard (scorecard.metric.read permission)
- GitHub and/or Jira integrations configured
- Database available for time-series storage

### Integration with Existing Assemblies

**assembly-install-and-configure-scorecards-to-view-metrics.adoc**:
- Add DORA backend installation procedure
- Add DORA data source configuration procedures
- Maintains existing structure for GitHub/Jira/OpenSSF general configuration

**assembly-configure-scorecard-cards-on-the-homepage.adoc**:
- Add DORA aggregation card procedure
- Existing generic homepage configuration remains unchanged

**assembly-monitor-collective-health-across-components.adoc**:
- May benefit from mentioning DORA aggregation as a portfolio health use case
- No structural changes required

## JTBD Hierarchy Mapping

### Category (Job Map Stage): **Observe**
Main Job: **Measure software delivery performance**

User Stories:
1. Understand what DORA metrics measure and why they matter (Discover phase)
   - Modules: `con-dora-metrics-in-scorecard.adoc`
   
2. Install and configure DORA metric collection infrastructure (Evaluate phase)
   - Modules: `con-composite-metric-providers.adoc`, `proc-install-configure-dora-backend-module.adoc`, `proc-configure-github-dora-datasource.adoc`, `proc-configure-jira-dora-datasource.adoc`
   
3. Visualize DORA metrics and trends for individual components (Adopt phase)
   - Modules: `con-dora-metric-trends-visualization.adoc`
   
4. Monitor portfolio-wide DORA metrics from the homepage (Adopt phase)
   - Modules: `proc-configure-dora-aggregation-cards-homepage.adoc`

### Category (Job Map Stage): **Develop**
Main Job: **Integrate delivery metrics into custom tools**

User Stories:
1. Fetch historical DORA metric data programmatically (Adopt phase)
   - Modules: `ref-scorecard-timeseries-api.adoc`

### Category (Job Map Stage): **Administer**
Main Job: **Monitor platform health and reliability**

User Stories:
1. Verify DORA data collection is working correctly (Adopt phase)
   - Modules: `ref-scorecard-collectors-metadata-api.adoc`

### Parent Topic: "Measure software delivery performance"
**Description**: Track deployment frequency, lead time for changes, change failure rate, and time to restore service across your portfolio to identify delivery bottlenecks and benchmark against industry standards.

**Overview**: Red Hat Developer Hub Scorecard plugin automates DORA metrics collection from GitHub deployment events, pull requests, and Jira incident data. Teams can visualize trends over time, aggregate metrics across portfolios, and access historical data via REST API.

**High-level steps**:
1. Install DORA backend module with database configuration
2. Configure GitHub and Jira as DORA data sources
3. View DORA metrics on component Scorecard pages
4. Add DORA aggregation cards to homepage for portfolio visibility
5. Analyze trends to identify improvement opportunities

## Theme Clustering

### Theme: DORA Foundation
- **Summary**: Core DORA metrics capability including installation, data source configuration, and basic metric display
- **Issues included**: RHIDP-13982 (backend module), RHIDP-13978 (GitHub datasource), RHIDP-13979 (Jira datasource), RHIDP-13977 (composite providers)
- **Overlap risk**: Low - each issue addresses distinct functionality, but must be documented cohesively
- **Recommended ownership**: Single assembly `assembly-measure-delivery-performance-with-dora-metrics.adoc`

### Theme: DORA Visualization and Trends
- **Summary**: Time-series visualization, homepage aggregation cards, and trend analysis
- **Issues included**: RHIDP-15576 (trends visualization), RHIDP-14402 (aggregation cards), RHIDP-16834 (trends on homepage)
- **Overlap risk**: Medium - trends visualization appears in both component views and homepage cards, requires careful documentation to avoid duplication
- **Recommended ownership**: Split between main DORA assembly (concept) and homepage assembly (procedure for cards)

### Theme: DORA Developer and Admin Tools
- **Summary**: Programmatic access to DORA data and operational monitoring
- **Issues included**: RHIDP-13980 (TimeSeries API), RHIDP-16108 (API enhancements), RHIDP-15960 (collectors metadata API)
- **Overlap risk**: Low - distinct API endpoints with different use cases
- **Recommended ownership**: Separate reference modules, linked from appropriate assemblies

### Theme: Metric Metadata Enhancements
- **Summary**: Improvements to metric metadata (units, descriptions)
- **Issues included**: RHIDP-15624 (metric units)
- **Overlap risk**: None - table structure enhancement that affects all metrics
- **Recommended ownership**: Update to existing `ref-available-scorecard-metric-providers-and-metric-ids.adoc`

## Relationship Classification

| Issue Pair | Relationship | Rationale |
|------------|-------------|-----------|
| RHIDP-13982 ↔ RHIDP-13978 | Sequential | Backend module must be installed before GitHub datasource can be configured |
| RHIDP-13982 ↔ RHIDP-13979 | Sequential | Backend module must be installed before Jira datasource can be configured |
| RHIDP-13978 ↔ RHIDP-13979 | Parallel/Sibling | Both are data sources for DORA, can be configured independently or together |
| RHIDP-13977 ↔ RHIDP-13982 | Complementary | Composite providers (13977) is the architectural foundation for DORA backend (13982) |
| RHIDP-15576 ↔ RHIDP-16834 | Overlapping | Trend visualization appears in both component views (15576) and homepage cards (16834) |
| RHIDP-14402 ↔ RHIDP-16834 | Sequential | Homepage aggregation cards (14402) are enhanced with trends (16834) |
| RHIDP-13980 ↔ RHIDP-16108 | Sequential | TimeSeries API (13980) is enhanced by latest-per-day fetching (16108) |
| RHIDP-13980 ↔ RHIDP-15960 | Parallel/Sibling | Both are API endpoints but serve different purposes (time-series data vs. collector metadata) |
| RHIDP-15624 ↔ All DORA metrics | Complementary | Metric units enhancement benefits DORA metrics but is not DORA-specific |

## Content Journey Phase Distribution

| Phase | Module Count | Modules |
|-------|-------------|---------|
| Expand | 0 | (General Scorecard overview covers this) |
| Discover | 3 | con-dora-metrics-in-scorecard, con-composite-metric-providers, con-dora-metric-trends-visualization |
| Learn | 0 | (Future: DORA quick start tutorial) |
| Evaluate | 4 | proc-install-configure-dora-backend-module, proc-configure-github-dora-datasource, proc-configure-jira-dora-datasource, proc-configure-dora-aggregation-cards-homepage |
| Adopt | 4 | con-dora-metric-trends-visualization (also serves Discover), proc-configure-dora-aggregation-cards-homepage (also serves Evaluate), ref-scorecard-timeseries-api, ref-scorecard-collectors-metadata-api |

**Gap analysis**: No dedicated "Learn" phase content (hands-on tutorial). Consider adding a DORA quick start tutorial in future iterations. "Expand" phase is covered by general Scorecard documentation, so no gap for DORA-specific content.

## Prioritization

| Priority | Module | Rationale | JIRA Tickets |
|----------|--------|-----------|-------------|
| **Critical** | proc-install-configure-dora-backend-module.adoc | Blocks all DORA functionality | RHIDP-13982, RHIDP-14848 |
| **Critical** | proc-configure-github-dora-datasource.adoc | Required for GitHub-based DORA metrics | RHIDP-13978 |
| **Critical** | proc-configure-jira-dora-datasource.adoc | Required for Jira-based DORA metrics | RHIDP-13979 |
| **Critical** | ref-available-scorecard-metric-providers-and-metric-ids.adoc (update) | Users need to identify DORA metric IDs for configuration | RHIDP-13987 |
| **High** | con-dora-metrics-in-scorecard.adoc | Provides value proposition and context for feature adoption | RHDHPLAN-1102 |
| **High** | con-composite-metric-providers.adoc | Explains architectural foundation for DORA | RHIDP-13977 |
| **High** | proc-configure-dora-aggregation-cards-homepage.adoc | High-value feature for leadership visibility | RHIDP-14402, RHIDP-16834 |
| **Medium** | con-dora-metric-trends-visualization.adoc | Enhances value but not blocking | RHIDP-15576 |
| **Medium** | ref-scorecard-timeseries-api.adoc | Developer use case, important for integrations | RHIDP-13980, RHIDP-16108 |
| **Medium** | proc-configure-portfolio-health-on-a-customizable-home-page.adoc (update) | Adds examples to existing procedure | RHIDP-14402, RHIDP-16834 |
| **Low** | ref-scorecard-collectors-metadata-api.adoc | Admin use case, not critical for basic usage | RHIDP-15960 |
| **Low** | ref-scorecard-plugin-rest-api-endpoints-and-parameters.adoc (update) | Minor update to existing reference | RHIDP-13980, RHIDP-15960 |

## Risks and Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Database configuration complexity may confuse users | High | Provide clear step-by-step database setup with schema examples, include troubleshooting section |
| Users may not understand what constitutes a "deployment" or "failure" in their org | High | Include decision tree or examples of common definitions (GitHub deployment events vs. release tags vs. workflow runs) |
| DORA metric values may be initially empty or incorrect | Medium | Document expected data collection latency, provide verification steps, explain how to troubleshoot missing data |
| Overlap between trend visualization in component views and homepage cards may confuse users | Medium | Use consistent terminology, cross-reference between modules, clearly distinguish entity-level vs. portfolio-level trends |
| TimeSeries API may be used incorrectly causing performance issues | Medium | Document rate limiting, recommended query patterns, pagination if applicable |
| Users may install DORA backend without understanding prerequisites | High | Create clear prerequisites checklist at start of installation procedure |

## Source Traceability

| Module | Primary Sources | Supporting Sources |
|--------|----------------|-------------------|
| con-dora-metrics-in-scorecard.adoc | RHDHPLAN-1102 | DORA research methodology (external) |
| con-composite-metric-providers.adoc | RHIDP-13977 | - |
| proc-install-configure-dora-backend-module.adoc | RHIDP-13982, RHIDP-14848 | - |
| proc-configure-github-dora-datasource.adoc | RHIDP-13978 | RHIDP-13982 |
| proc-configure-jira-dora-datasource.adoc | RHIDP-13979 | RHIDP-13982 |
| con-dora-metric-trends-visualization.adoc | RHIDP-15576 | RHIDP-16834 |
| proc-configure-dora-aggregation-cards-homepage.adoc | RHIDP-14402, RHIDP-16834 | - |
| ref-scorecard-timeseries-api.adoc | RHIDP-13980 | RHIDP-16108 |
| ref-scorecard-collectors-metadata-api.adoc | RHIDP-15960 | - |
| ref-available-scorecard-metric-providers-and-metric-ids.adoc (update) | RHIDP-13987, RHIDP-13978, RHIDP-13979 | RHIDP-15624 |

## Verification Checklist

- ✅ **No placeholder syntax**: All `[REPLACE: ...]` markers have been replaced with actual content
- ✅ **No hallucinated content**: Every recommendation is traceable to requirements analysis or JIRA tickets
- ✅ **Source traceability**: Each module links to at least one JIRA source
- ✅ **No sensitive information**: No credentials, internal URLs, or tokens in the output
- ✅ **Persona limit**: 4 personas identified (within limit, all relevant)
- ✅ **Template completeness**: All required sections populated
- ✅ **Impact consistency**: Critical priority aligns with High impact requirements from requirements.md
- ✅ **Journey coverage**: Content journey phases mapped for all modules, gaps identified
- ✅ **JIRA description**: Abbreviated sections prepared (next section)
- ✅ **Persona separation**: DORA metrics serve multiple personas (IT Ops, SysAdmin, AppDev ITDM, Developer) but each has distinct job statements - admin setup vs. consumption jobs are properly separated across modules

## Next Steps

1. Review this plan with technical SMEs on RHIDP-13678 (Backend) and RHIDP-13983 (Frontend) to validate technical accuracy
2. Confirm database requirements and configuration parameters with backend team (RHIDP-14848)
3. Gather example configurations, screenshots, and API response examples from QE (RHIDP-13984)
4. Begin authoring Phase 1 (Foundation) modules
5. Request review of concept modules before proceeding to Phase 2 (Installation)
6. Coordinate with frontend team to capture screenshots of DORA metrics UI, trend visualizations, and homepage aggregation cards

---

## JIRA Ticket Description (5 sections only - post to RHIDP-13987)

### What is the main JTBD? What user goal is being accomplished? What pain point is being avoided?

When I need to assess and improve my organization's software delivery performance, I want to measure DORA metrics across my portfolio with automated data collection from GitHub and Jira, so that I can identify bottlenecks in the delivery pipeline, benchmark against industry standards, and make evidence-based decisions to accelerate delivery while maintaining quality, while avoiding manual metric aggregation, fragmented tooling, and subjective performance assessments.

### How does the JTBD(s) relate to the overall real-world workflow for the user?

DORA metrics measurement fits into the broader DevOps maturity and continuous improvement workflow:

1. **Platform Setup Phase**: IT Operations Leaders and SysAdmins install the DORA backend module with database configuration and enable DORA data sources (GitHub, Jira) to begin automated metric collection.

2. **Configuration Phase**: Platform engineers configure which repositories, teams, and systems contribute to DORA metrics, set up homepage aggregation cards for visibility, and configure metric thresholds aligned with organizational goals.

3. **Monitoring Phase**: Development teams and leadership consume DORA metrics through Scorecard entity views and homepage aggregation cards to understand current delivery performance across the portfolio.

4. **Analysis Phase**: Teams analyze historical trends using time-series visualizations to identify performance patterns, seasonal variations, and the impact of process changes on delivery metrics.

5. **Improvement Phase**: Leaders use DORA insights to prioritize process improvements (e.g., deployment automation, incident response procedures, code review practices) and track the impact of these initiatives over time.

6. **Benchmarking Phase**: Organizations compare their DORA metrics against industry benchmarks to understand their maturity level (elite, high, medium, low performers) and set realistic improvement targets.

This workflow integrates with existing development practices, incident management processes, and portfolio planning activities, making DORA metrics a continuous feedback mechanism rather than a point-in-time assessment.

### Who can provide information and answer questions?

**Product Manager**: Dominika Zemanovicova (assignee on RHDHPLAN-1102)
**Technical SME**: Engineering team members on RHIDP-13678 (Backend), RHIDP-13983 (Frontend)
**Documentation Owner**: Gerry Forde (assignee on RHIDP-14652)
**QE Contact**: Team members on RHIDP-13984

### New Docs

* What are DORA metrics and why they matter (Concept)
    Explains the four DORA metrics (deployment frequency, lead time for changes, change failure rate, time to restore service), why they matter for software delivery performance, how DORA metrics in Scorecard differ from standalone tools, what data sources feed metrics, and performance benchmarks for context

* Composite metric providers (Concept)
    Defines composite metric providers vs. standard single-source providers, explains how composite providers aggregate data from multiple sources, uses DORA metrics as primary use case, describes when to use composite vs. standard providers

* Install and configure DORA backend module (Procedure)
    Installation steps for dynamic plugin and static backend module deployment, database configuration including schema setup and connection parameters, configuration parameters reference, verification steps to confirm backend module is loaded and collecting metrics

* Configure GitHub DORA datasource (Procedure)
    Prerequisites and GitHub integration requirements, explanation of what GitHub data is collected (deployments, PRs, commits), configuration in app-config.yaml, how to define what constitutes a deployment, how lead time is calculated, verification steps

* Configure Jira DORA datasource (Procedure)
    Prerequisites and Jira integration requirements, explanation of what Jira data is collected (incidents, bugs, resolution times), configuration in app-config.yaml with project mapping and issue filters, how to define what constitutes a failure, how time to restore service is calculated, verification steps

* DORA metric trends visualization (Concept)
    Explains what time-series visualization shows, supported time windows (7, 30, 90 days), which DORA metrics support trends (all four), how to interpret trend charts and identify patterns, where trends appear (component pages, homepage), data granularity options

* Configure DORA aggregation cards on homepage (Procedure)
    Prerequisites including DORA backend and customizable homepage, configuration examples for DORA aggregation cards with trend visualization, customization options (title, metric ID, aggregation method), layout configuration, verification steps

* TimeSeries REST API for Scorecard (Reference)
    API endpoint path and query parameters (entity, metricId, startDate, endDate, interval), response format with JSON examples for each DORA metric, authentication and permissions requirements, error responses, use cases for integration

* Collectors metadata REST API (Reference)
    API endpoint path for collector metadata, response format showing active collectors with status and health information, use cases for monitoring and troubleshooting, authentication and permissions

### Updated Docs

* ref-available-scorecard-metric-providers-and-metric-ids.adoc
    Add DORA metrics section with four new entries (deploymentFrequency, leadTimeForChanges, changeFailureRate, timeToRestoreService) including metric IDs, descriptions, data sources, types, and units; add Unit column to table header; add note about DORA backend module requirement; add cross-reference to DORA concept module

* proc-configure-portfolio-health-on-a-customizable-home-page.adoc
    Add DORA aggregation card configuration examples to YAML snippet showing deployment frequency and lead time cards with trend visualization; add note about DORA backend module requirement; add cross-reference to dedicated DORA homepage procedure

* ref-scorecard-plugin-rest-api-endpoints-and-parameters.adoc
    Add TimeSeries API endpoint (GET /timeseries) and Collectors metadata endpoint (GET /collectors/metadata) to supported endpoints table; add cross-references to detailed API reference modules; add note about TimeSeries API applicability to DORA and other time-series metrics

* assembly-install-and-configure-scorecards-to-view-metrics.adoc
    Add include statements for DORA backend installation and GitHub/Jira DORA datasource configuration procedures; update assembly abstract to mention DORA metrics support

* titles/observability_evaluate-project-health-using-scorecards/master.adoc
    Add include statements for DORA concept modules (DORA metrics, composite providers, trends visualization) and DORA API references (TimeSeries, collectors metadata); update book abstract to mention DORA metrics capability
