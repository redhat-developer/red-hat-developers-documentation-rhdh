# Bug Analysis Report: RHIDP-13987

**Generated:** 2026-08-25
**Analyst:** Claude Sonnet 4.5
**JIRA Ticket:** [RHIDP-13987](https://redhat.atlassian.net/browse/RHIDP-13987)

---

## Executive Summary

**Issue:** [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
**Type:** Epic
**Priority:** Major
**Status:** New
**Target Release:** Red Hat Developer Hub 2.1.0
**Assignee:** Gerry Forde

This epic tracks the documentation effort for integrating DORA (DevOps Research and Assessment) metrics into the Red Hat Developer Hub Scorecard plugin. The integration is part of a coordinated three-track development effort spanning backend, frontend, and documentation workstreams.

---

## Issue Classification

| Attribute | Value | Notes |
|-----------|-------|-------|
| **Issue Type** | Epic | Parent documentation tracking issue |
| **Category** | Documentation | New feature documentation |
| **Severity** | Major | Core feature addition to RHDH 2.1.0 |
| **Component** | Scorecard Plugin | Existing observability component |
| **Documentation Type** | New Feature | Requires new reference content and procedures |
| **Effort Estimate** | Medium-High | Multiple modules, integration procedures, API reference updates |

---

## Context and Background

### What are DORA Metrics?

DORA (DevOps Research and Assessment) metrics are industry-standard measurements of software delivery performance. The four key DORA metrics are:

1. **Deployment Frequency** — How often code is deployed to production
2. **Lead Time for Changes** — Time from code commit to production deployment
3. **Mean Time to Recovery (MTTR)** — Time to restore service after an incident
4. **Change Failure Rate** — Percentage of deployments causing failures in production

These metrics enable engineering teams to measure and improve their software delivery performance based on data-driven insights.

### Current State: RHDH Scorecard Plugin

The existing Scorecard plugin in RHDH provides component health and compliance monitoring through integration with multiple metric providers:

**Currently Supported Providers (as of RHDH 1.9):**
- **GitHub** — Open pull requests
- **Jira** — Open issues
- **OpenSSF** — 18 security metrics (branch protection, CI tests, code review, vulnerabilities, etc.)
- **Filecheck** — Custom file existence verification

**Current Documentation:**
- Located in `modules/observability_evaluate-project-health-using-scorecards/`
- Includes installation, configuration, threshold management, RBAC, and aggregation features
- Reference file for metric providers: `ref-available-scorecard-metric-providers-and-metric-ids.adoc`
- 66 AsciiDoc files covering scorecard functionality

**What's Missing:**
DORA metrics are NOT currently supported or documented. This feature represents a significant expansion of the Scorecard plugin's capabilities from security/compliance monitoring to software delivery performance measurement.

---

## Related Tickets Analysis

### Ticket Hierarchy

```
RHDHPLAN-1102 (Feature) - Integration of DORA Metrics into RHDH Scorecard Plugin
├── RHIDP-13678 (Epic) - [Backend] Integration of DORA Metrics into RHDH Scorecard Plugin
├── RHIDP-13983 (Epic) - [Frontend] Integration of DORA Metrics into RHDH Scorecard Plugin
└── RHIDP-13987 (Epic) - [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
    └── RHIDP-14652 (Task) - [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
```

### Parent Feature: RHDHPLAN-1102
- **Summary:** Integration of DORA Metrics into RHDH Scorecard Plugin
- **Status:** In Progress
- **Assignee:** Dominika Zemanovicova
- **Type:** Feature
- **Significance:** This is the umbrella feature tracking the entire DORA metrics integration effort

### Sibling Epics

**Backend Epic (RHIDP-13678):**
- Status: In Progress
- Responsible for DORA metrics data collection, calculation, and API endpoints
- Must be completed before documentation can be finalized with accurate API examples

**Frontend Epic (RHIDP-13983):**
- Status: In Progress
- Responsible for DORA metrics visualization and UI components
- Documentation will need screenshots and UI workflow procedures once complete

### Child Task: RHIDP-14652
- Appears to be a duplicate or sub-task of the main docs epic
- Same summary, same assignee, status "New"
- May represent a specific documentation deliverable or milestone

---

## Documentation Scope Analysis

### New Documentation Required

Based on the existing scorecard plugin documentation structure and the nature of DORA metrics, the following documentation modules will likely be needed:

#### 1. **Reference Module: DORA Metric Providers**
**Purpose:** Add DORA metrics to the existing metric providers reference table
**File:** Update `ref-available-scorecard-metric-providers-and-metric-ids.adoc`
**Content:**
- Provider name (e.g., "DORA", "GitHub DORA", or specific provider depending on implementation)
- Metric IDs for each of the 4 DORA metrics
- Metric titles and descriptions
- Data types (likely numeric or percentage)

#### 2. **Procedure Module: Enable DORA Metrics**
**Purpose:** Configuration steps to activate DORA metrics collection
**Suggested filename:** `proc-integrate-dora-metrics-using-scorecards.adoc`
**Content:**
- Prerequisites (required plugins, data sources, permissions)
- Configuration in `app-config.yaml`
- Authentication/authorization setup for data sources
- Verification steps

#### 3. **Procedure Module: Configure DORA Thresholds**
**Purpose:** Define acceptable ranges for each DORA metric
**Integration:** May extend existing threshold documentation or require new module
**Content:**
- Industry benchmarks for DORA metrics (elite/high/medium/low performers)
- Threshold expression syntax specific to DORA metrics
- Examples for each metric type

#### 4. **Concept Module: DORA Metrics in RHDH**
**Purpose:** Explain what DORA metrics are and how they're used in RHDH
**Suggested filename:** `con-dora-metrics-for-software-delivery-performance.adoc`
**Content:**
- Brief explanation of DORA metrics
- How RHDH calculates each metric
- Data sources used (Git, CI/CD systems, incident management)
- Relationship to existing scorecard metrics

#### 5. **Reference Module: DORA Data Sources**
**Purpose:** Document which systems provide data for DORA calculations
**Content:**
- Supported version control systems (GitHub, GitLab, Bitbucket, etc.)
- CI/CD integrations (Jenkins, Tekton, Argo CD, etc.)
- Incident management integrations (PagerDuty, ServiceNow, Jira incidents)
- Required webhooks or API access

#### 6. **Assembly Updates**
**Affected files:**
- `assembly-install-and-configure-scorecards-to-view-metrics.adoc`
- `assembly-set-up-scorecards-to-monitor-your-project-health.adoc`

**Changes:**
- Add includes for new DORA modules
- Update assembly abstracts to mention DORA metrics
- Ensure proper module ordering

#### 7. **Navigation Updates**
**Affected files:**
- `titles/observability_evaluate-project-health-using-scorecards/master.adoc`
- JTBD navigation maps in `titles/product_product/category-maps/administer/`

**Changes:**
- Add DORA metric procedures to relevant navigation sections
- Create new navigation categories if needed for delivery performance vs. security

### Documentation to Update

| File | Update Type | Description |
|------|-------------|-------------|
| `ref-available-scorecard-metric-providers-and-metric-ids.adoc` | Major addition | Add DORA metrics to provider table |
| `con-component-health-and-compliance-monitoring-using-scorecards.adoc` | Minor enhancement | Mention DORA metrics in abstract/overview |
| Master title files | Navigation | Include new DORA modules |
| Community plugins reference | Conditional | If DORA integration is plugin-based |

### Screenshots and Examples Required

1. **DORA metrics display** in the scorecard UI
2. **Configuration examples** in `app-config.yaml`
3. **Threshold configuration** for DORA metrics
4. **API response examples** showing DORA metric data
5. **Aggregation cards** displaying DORA KPIs across multiple components

---

## Technical Dependencies

### Blockers
- **Backend API completion** (RHIDP-13678) — Documentation requires stable API endpoints and response schemas
- **Frontend UI completion** (RHIDP-13983) — Screenshots and UI procedures depend on finalized interface
- **Data source integrations** — Need to know which systems are supported for DORA calculations

### Information Required from Development

To complete accurate documentation, the following technical details are needed:

1. **Metric Provider Name** — What identifier is used in configuration? (e.g., `dora`, `github.dora`, etc.)
2. **Exact Metric IDs** — What are the configuration keys for each metric?
   - Deployment Frequency: `dora.deploymentFrequency`?
   - Lead Time: `dora.leadTime`?
   - MTTR: `dora.mttr`?
   - Change Failure Rate: `dora.changeFailureRate`?
3. **Data Sources** — Which systems are queried? (Git webhooks, CI/CD APIs, incident systems)
4. **Calculation Method** — How are metrics computed? (important for user understanding)
5. **Configuration Schema** — Exact YAML structure for enabling DORA metrics
6. **API Endpoints** — REST endpoints for retrieving DORA metrics
7. **RBAC Permissions** — What permissions control access to DORA metrics?
8. **Threshold Syntax** — Any DORA-specific threshold operators or functions?

### External Dependencies

- **Upstream Backstage Plugin** — If this is based on an upstream Backstage plugin for DORA metrics
- **Third-party Libraries** — Any external DORA calculation engines or libraries used
- **Data Provider Availability** — Whether users need specific SaaS subscriptions or on-prem tools

---

## Risk Assessment

### Documentation Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Backend API changes during doc writing | High | Establish API freeze date before doc work begins |
| Screenshots become outdated | Medium | Take screenshots late in process, use generic examples where possible |
| Incomplete technical specifications | High | Request detailed implementation design doc from backend team |
| DORA metrics calculated incorrectly in examples | Medium | Have SME review all calculation examples and thresholds |
| Missing data source integrations | Medium | Document only confirmed integrations, note others as "planned" |

### Schedule Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Backend/frontend delays | High | Begin with concept modules that don't depend on implementation details |
| Late discovery of breaking changes | High | Establish regular sync meetings with backend/frontend teams |
| Insufficient review time before 2.1.0 release | Medium | Start documentation in parallel with development, not after |

---

## Recommended Approach

### Phase 1: Discovery and Planning (Week 1)
1. **Review backend design documents** for DORA metrics implementation
2. **Interview backend developer** (sibling epic RHIDP-13678 owner) to understand data model
3. **Interview frontend developer** (sibling epic RHIDP-13983 owner) to understand UI design
4. **Create documentation plan** with detailed module breakdown
5. **Establish review cadence** with technical stakeholders

### Phase 2: Draft Creation (Weeks 2-3)
1. **Write concept module** explaining DORA metrics (can be done early)
2. **Draft reference table updates** for metric providers (pending metric IDs from backend)
3. **Create configuration procedure** (requires stable config schema from backend)
4. **Write threshold configuration procedure** (requires threshold syntax documentation)
5. **Document API endpoints** (requires backend API to be finalized)

### Phase 3: Technical Review (Week 4)
1. **Backend SME review** of all technical accuracy
2. **Frontend SME review** of UI procedures and screenshots
3. **QE review** of configuration examples and troubleshooting
4. **Style guide compliance** using docs-reviewer agent

### Phase 4: Integration and Testing (Week 5)
1. **Test all configuration examples** in a live RHDH instance
2. **Validate API examples** against actual endpoints
3. **Take final screenshots** from production-like environment
4. **Update navigation** and assemblies
5. **Final peer review** and CQA compliance check

---

## Open Questions

1. **Metric Calculation Source**: Does DORA data come from existing integrations (GitHub, Jira, Tekton) or require new data source connections?
2. **Historical Data**: How far back does RHDH calculate DORA metrics? Is there a retention policy?
3. **Real-time vs. Batch**: Are DORA metrics calculated in real-time or on a schedule?
4. **Multi-repository Aggregation**: Can DORA metrics span multiple repositories for a single component?
5. **Custom Calculations**: Can users define custom formulas for DORA metrics or are they fixed?
6. **Alerting**: Do DORA metrics support threshold-based alerting like other scorecard metrics?
7. **Export/Reporting**: Can DORA metrics be exported for external reporting tools?
8. **Backwards Compatibility**: Will existing scorecard configurations continue to work after DORA integration?

---

## Success Criteria

Documentation for RHIDP-13987 will be considered complete when:

✅ **Content Completeness**
- [ ] All 4 DORA metrics are documented with accurate descriptions
- [ ] Configuration procedures are tested and verified
- [ ] All required prerequisites are identified and documented
- [ ] API reference is complete and accurate
- [ ] At least 2 end-to-end examples are provided

✅ **Technical Accuracy**
- [ ] Backend SME has reviewed and approved all technical content
- [ ] All code examples have been tested in a live RHDH environment
- [ ] API endpoints and response schemas match actual implementation
- [ ] Screenshots reflect final UI (no placeholder images)

✅ **Style and Quality**
- [ ] Vale linting passes with zero errors
- [ ] CQA 2.1 assessment score ≥ 85%
- [ ] Modular docs structure follows Red Hat standards
- [ ] All internal xrefs and includes resolve correctly

✅ **Usability**
- [ ] A first-time user can enable DORA metrics following the docs alone
- [ ] Troubleshooting section addresses common configuration issues
- [ ] Threshold examples include industry benchmarks (elite/high/medium/low performers)

✅ **Integration**
- [ ] DORA content is properly integrated into existing scorecard documentation
- [ ] Navigation maps are updated
- [ ] Related assemblies include new modules
- [ ] No broken links or missing includes

---

## Estimated Effort

| Activity | Estimated Hours | Dependencies |
|----------|----------------|--------------|
| Discovery and planning | 8h | Backend/frontend teams available |
| Concept module writing | 4h | DORA metrics understanding |
| Reference table updates | 2h | Final metric IDs from backend |
| Configuration procedures | 6h | Stable config schema |
| Threshold configuration | 4h | Threshold syntax documentation |
| API reference | 4h | Backend API finalized |
| Screenshots | 3h | Frontend UI complete |
| Testing and validation | 6h | RHDH test environment access |
| Review cycles | 8h | SME availability |
| Navigation/assembly updates | 2h | All modules complete |
| **Total** | **47h** (~6 days) | |

**Note:** Estimate assumes stable backend/frontend implementations. Delays or scope changes will extend timeline.

---

## Attachments and References

### JIRA Tickets
- [RHIDP-13987](https://redhat.atlassian.net/browse/RHIDP-13987) — This docs epic
- [RHDHPLAN-1102](https://redhat.atlassian.net/browse/RHDHPLAN-1102) — Parent feature
- [RHIDP-13678](https://redhat.atlassian.net/browse/RHIDP-13678) — Backend epic
- [RHIDP-13983](https://redhat.atlassian.net/browse/RHIDP-13983) — Frontend epic
- [RHIDP-14652](https://redhat.atlassian.net/browse/RHIDP-14652) — Child task

### Existing Documentation
- Scorecard documentation root: `modules/observability_evaluate-project-health-using-scorecards/`
- Metric providers reference: `ref-available-scorecard-metric-providers-and-metric-ids.adoc`
- Main title: `titles/observability_evaluate-project-health-using-scorecards/master.adoc`

### External Resources
- [DORA Metrics Official Documentation](https://dora.dev/)
- [Google Cloud's DORA Metrics Guide](https://cloud.google.com/blog/products/devops-sre/using-the-four-keys-to-measure-your-devops-performance)
- [Backstage Scorecard Plugin](https://backstage.io/docs/features/software-catalog/scorecards) (potential upstream)

---

## Next Steps

### Immediate Actions (This Week)
1. **Connect with parent feature owner** (Dominika Zemanovicova) to align on overall timeline
2. **Review backend epic** (RHIDP-13678) for implementation details and API design
3. **Review frontend epic** (RHIDP-13983) for UI mockups and component designs
4. **Request technical design documents** from backend and frontend teams

### Short-term (Next 2 Weeks)
1. **Create detailed documentation plan** with module list and assignments
2. **Begin concept module** for DORA metrics (low dependency, high value)
3. **Draft configuration examples** based on early backend feedback
4. **Set up review schedule** with SMEs

### Before Documentation Freeze
1. **Verify all metrics are implemented** and API is stable
2. **Test all configuration examples** in RHDH 2.1.0 beta
3. **Complete technical review** with backend/frontend teams
4. **Run full CQA assessment** and remediate issues
5. **Obtain final screenshots** from production-ready UI

---

**Report Status:** Draft
**Last Updated:** 2026-08-25
**Next Review:** TBD (pending backend/frontend design docs)
