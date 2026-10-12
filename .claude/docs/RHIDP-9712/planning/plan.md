# Documentation Plan

**Project**: Be able to customize the plugins on any pages in RHDH
**Date**: 2026-10-09
**Ticket**: [RHIDP-9712](https://redhat.atlassian.net/browse/RHIDP-9712)

## What is the support status of the feature(s) being used to complete the user's JTBD (Job To Be Done)?

General Availability - RHDH 2.1.0

## Why is this content important?

RHDH 2.1 introduces the ability to customize all pages through the New Frontend System (NFS), enabling users to fully control catalog entity pages, user settings pages, and other interface elements without code changes. This capability eliminates the previous requirement for application rebuilds when customizing the UI and provides a unified configuration mechanism through app.extensions. Organizations can now tailor RHDH to their specific workflows, add custom functionality through dynamic plugins, and maintain these customizations across upgrades using declarative YAML configuration.

## Who is the target persona(s)?

* Developer: Creates custom plugins and UI extensions to add functionality to RHDH for their organization
* SysAdmin: Configures and customizes RHDH interface to meet organizational requirements, enables/disables features
* IT Operations Leader: Owns infrastructure decisions and ensures the platform is correctly configured for development teams

## What is the main JTBD? What user goal is being accomplished? What pain point is being avoided?

When I need to adapt RHDH's user interface to match my organization's workflows and requirements, I want to customize which plugins, tabs, and features appear on each page through configuration, so that I can provide a tailored experience for my teams without rebuilding the application or maintaining code forks while avoiding the complexity and upgrade friction of custom builds.

## How does the JTBD(s) relate to the overall real-world workflow for the user?

Platform customization fits into the broader administrator workflow of deploying and maintaining RHDH for their organization:

1. **Initial deployment**: Admin installs RHDH with default configuration
2. **Assess organizational needs**: Admin identifies which features teams need and which should be hidden
3. **Customize the interface**: Admin configures app.extensions to enable, disable, reorder, or customize pages, tabs, and cards
4. **Add custom functionality**: Developers create custom plugins using extension blueprints; admin configures them through app.extensions
5. **Refine based on feedback**: Teams use customized RHDH; admin iteratively adjusts configuration based on user feedback
6. **Upgrade and maintain**: Admin upgrades RHDH while maintaining customizations through configuration migration

The customization job is continuous throughout the platform lifecycle, with configuration serving as the stable contract across versions.

## What high-level steps does the user need to take to accomplish the goal?

1. **Prerequisites**: Verify RHDH 2.1+ is installed with New Frontend System enabled
2. **Identify customization needs**: Determine which pages, tabs, or cards to modify (entity pages, user settings, navigation)
3. **Understand extension system**: Learn about extension blueprints (EntityCardBlueprint, EntityContentBlueprint, PageBlueprint) and how plugins expose them
4. **Configure app.extensions**: Edit app-config.yaml to enable, disable, reorder, or customize extensions
5. **For custom functionality**: Develop custom plugins with /alpha exports using extension blueprints
6. **Verify changes**: Restart RHDH and confirm customizations appear as expected
7. **Migrate from old system** (if upgrading from RHDH 2.0): Convert dynamicPlugins.frontend configuration to app.extensions format

## Is there a demo available or can one be created?

No - A demo could be created showing entity page customization, disabling default tabs, and adding custom tabs through app.extensions configuration.

## Are there special considerations for disconnected environments?

No - Page customization through app.extensions is configuration-only and does not require external network access. Custom plugins must be available in the dynamic-plugins-root directory or served from an accessible plugin registry.

## Who can provide information and answer questions?

* **PM**: Stan Lewis (parent RHDHPLAN-552 assignee)
* **Technical SME**: Gerry Forde (RHIDP-9712 assignee)
* **Parent Outcome Lead**: Stan Lewis (RHDHPLAN-192 assignee)

## Release Note needed?

Yes

Draft release note: Red Hat Developer Hub 2.1 enables full customization of catalog entity pages, user settings pages, and all other interface elements through the New Frontend System. Administrators can now configure which tabs and cards appear on entity pages, add custom settings options, and control page layout using declarative app.extensions configuration without rebuilding the application. All core plugins including catalog, scaffolder, search, and user settings are now loaded as dynamic plugins, providing consistent configuration across all features. Users migrating from RHDH 2.0 should update their dynamicPlugins.frontend configuration to the new app.extensions format.

## Links to existing content

* [RHDH configuration migration guide](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/migrating-config-to-new-frontend-system.md)
* [RHDH plugin migration guide](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/migrating-plugins-to-new-frontend-system.md)
* [Upstream Backstage plugin migration guide](https://backstage.io/docs/frontend-system/building-plugins/migrating/)
* [Upstream Backstage catalog customization guide](https://backstage.io/docs/features/software-catalog/catalog-customization/)
* [Common Extension Blueprints](https://backstage.io/docs/frontend-system/building-plugins/common-extension-blueprints/)
* modules/shared/ref-customizing-and-extending-entity-tabs.adoc
* modules/shared/ref-customizing-entity-page.adoc
* modules/shared/proc-configure-entity-tab-titles.adoc
* modules/shared/con-dynamic-front-end-plugins-for-application-use.adoc
* modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc
* modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc

## Gap Analysis

### Documentation Impact Assessment

| Requirement | Impact Grade | Rationale |
|-------------|--------------|-----------|
| REQ-001: Static plugins removed | **High** | Breaking change affecting custom builds - requires migration documentation |
| REQ-002: Home plugin dynamic | **High** | Breaking change - home page no longer included by default |
| REQ-003: Entity tabs/cards customizable | **High** | Major new capability enabling full entity page customization |
| REQ-004: NFS plugins as dynamic | **Medium** | Enhancement to existing dynamic plugins - requires reference updates |
| REQ-005: User settings extensibility | **Medium** | New capability for extending settings page |
| REQ-006: Entity validation extensibility | **Medium** | New capability for plugin-contributed validation messages |

### Coverage Gaps

**Critical gaps** (blocks users from core functionality):
- No documentation explaining static plugin removal and migration path for custom builds (REQ-001)
- Entity page customization docs reference old dynamicPlugins.frontend.entityTabs format (REQ-003)
- Missing procedures for disabling/reordering entity tabs and cards in NFS (REQ-003)

**High priority gaps** (important features lacking documentation):
- User settings page extensibility not documented (REQ-005)
- Entity validation message extensibility not documented (REQ-006)
- Core plugins converted to dynamic plugins not listed in preinstalled plugins reference (REQ-004)

**Medium priority gaps** (improvements to existing documentation):
- Dynamic plugins concept needs examples specific to entity page customization (REQ-003)
- NFS changes concept missing details on static plugin removal (REQ-001, REQ-002)
- App config reference needs enhanced entity page configuration examples (REQ-003)

### Currency Issues

| Existing Module | Update Needed | Reason |
|-----------------|---------------|--------|
| ref-customizing-and-extending-entity-tabs.adoc | **Critical** | Uses deprecated dynamicPlugins.frontend.entityTabs format instead of app.extensions |
| ref-customizing-entity-page.adoc | **Critical** | References old mountPoints configuration instead of app.extensions |
| proc-configure-entity-tab-titles.adoc | **High** | Procedure uses old configuration path |
| con-new-frontend-system-changes-in-rhdh-2-1.adoc | **High** | Missing information about static plugin removal and core plugins as dynamic |
| con-dynamic-front-end-plugins-for-application-use.adoc | **Medium** | Lacks specific entity page customization examples |

### Content Journey Phase Distribution

| Phase | Existing Coverage | Gaps Identified |
|-------|------------------|-----------------|
| **Expand** | Weak | Missing: High-level concept explaining page customization capabilities and benefits |
| **Discover** | Moderate | Present: NFS changes concept exists but incomplete; Missing: Architecture overview of extension system |
| **Learn** | Strong | Present: Migration procedures exist but need updates for NFS changes |
| **Evaluate** | Moderate | Present: Configuration reference exists but uses old format; needs updates and examples |
| **Adopt** | Weak | Missing: Troubleshooting for extension loading issues, validation procedures |

The distribution shows strong Learn content but weak Expand and Adopt coverage, suggesting users can follow procedures but may struggle to discover capabilities and troubleshoot issues.

### Relationship Classification

**Between requirements in RHDHPLAN-552**:

| Pair | Relationship | Risk Level | Notes |
|------|--------------|-----------|-------|
| REQ-001 ↔ REQ-002 | Complementary | Low | Static plugin removal (REQ-001) includes home plugin specifically covered in REQ-002 |
| REQ-001 ↔ REQ-004 | Sequential | Medium | Static plugins removed (REQ-001) must have dynamic equivalents documented (REQ-004) |
| REQ-003 ↔ REQ-006 | Complementary | Low | Entity validation (REQ-006) uses same extension mechanism as entity page customization (REQ-003) |
| REQ-003 ↔ REQ-005 | Parallel | Low | Both extend different pages (entity vs settings) using same extension blueprint pattern |

**With parent RHDHPLAN-192** (Base RHDH frontend on NFS):
- REQ-001, REQ-002, REQ-003 are implementations of the broader NFS migration
- All requirements share common migration documentation needs

### Theme Clustering

**Theme 1: Breaking Changes and Migration**
- **Title**: Static Plugin Removal and Migration to Dynamic Plugins
- **Summary**: RHDH 2.1 removes static plugins from app-next and backend packages, requiring custom build users to migrate to dynamic plugin loading
- **Issues included**: RHDHPLAN-552, RHIDP-14180, RHIDP-14179, PR #4921, PR #4922
- **Overlap risk**: High - multiple sources describe same breaking change
- **Recommended ownership**: Migrate category assembly (assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc)

**Theme 2: Entity Page Customization**
- **Title**: Full Entity Page Customization Through Extension Blueprints
- **Summary**: All entity tabs and cards are customizable through app.extensions configuration using EntityCardBlueprint and EntityContentBlueprint
- **Issues included**: RHIDP-5796, RHDHPLAN-552
- **Overlap risk**: Medium - overlaps with existing entity customization docs that need updating
- **Recommended ownership**: Configure category (customize RHDH navigation assembly)

**Theme 3: Extensibility Points for Custom Plugins**
- **Title**: New Extensibility Points for User Settings and Entity Validation
- **Summary**: User settings page and entity overview tab now support plugin-contributed extensions
- **Issues included**: RHDHPLAN-656, RHDHPLAN-850
- **Overlap risk**: Low - new capabilities with minimal existing docs
- **Recommended ownership**: Extend category (dynamic plugins assembly)

## JTBD Hierarchy and Module Planning

### Category: Configure
**Main Job**: Customize interface layout and navigation to match organizational workflows

This main job covers the administrator's need to tailor RHDH's user interface without code changes. It maps to the Configure category because it involves configuring the existing RHDH installation rather than extending it with new code.

#### User Story 1: Control which tabs and cards appear on catalog entity pages

**Situation**: Admin needs to simplify entity pages by hiding unused tabs or reordering important tabs
**Motivation**: Reduce clutter and highlight relevant information for their teams
**Outcome**: Entity pages show only necessary tabs in the desired order

**Content Journey Phase**: Evaluate → Adopt

**Modules**:

1. **proc-disable-entity-tabs-and-cards.adoc** (PROCEDURE)
   - Title: Remove unused tabs and cards from entity pages
   - Audience: SysAdmin
   - Content points:
     * Prerequisite: RHDH 2.1+ with NFS enabled
     * Identify entity page extension IDs using browser dev tools or documentation
     * Set extension to false in app.extensions to disable it
     * Examples: Disable CI tab, disable monitoring card
     * Verification: Confirm tab/card no longer appears on entity pages
   - Prerequisites: Understanding of app.extensions configuration
   - Content journey phase: Adopt
   - Sources: RHIDP-5796, Backstage catalog customization docs

2. **proc-reorder-entity-tabs.adoc** (PROCEDURE)
   - Title: Change the order of tabs on entity pages
   - Audience: SysAdmin
   - Content points:
     * Prerequisite: RHDH 2.1+ with NFS enabled
     * List extensions in app.extensions in desired order
     * Extensions appear in the order listed in configuration
     * Example: Move Dependencies tab before Docs tab
     * Handle tab groups and nested navigation
     * Verification: Confirm tab order matches configuration
   - Prerequisites: Understanding of app.extensions configuration
   - Content journey phase: Adopt
   - Sources: RHIDP-5796, Backstage app config docs

#### User Story 2: Migrate entity page customization from old to new frontend system

**Situation**: User is upgrading from RHDH 2.0 and has existing entityTabs or mountPoints configuration
**Motivation**: Ensure existing customizations continue working after upgrade
**Outcome**: Entity page customizations migrated to app.extensions format and functioning correctly

**Content Journey Phase**: Evaluate

**Modules**:

3. **UPDATE: modules/shared/ref-customizing-and-extending-entity-tabs.adoc** (REFERENCE)
   - Changes needed:
     * Replace dynamicPlugins.frontend.entityTabs examples with app.extensions examples
     * Update configuration path from dynamicPlugins.frontend.<plugin>.entityTabs to app.extensions with entity-content: entries
     * Add migration note explaining old format removed in RHDH 2.1
     * Preserve table of default entity routes and mount points (still accurate)
     * Add examples showing filter syntax (filter: kind:Component)
     * Add examples showing group and icon configuration for EntityContentBlueprint
   - Content journey phase: Evaluate → Adopt
   - Sources: RHIDP-5796, ref-app-config-changes-for-the-new-frontend-system.adoc

4. **UPDATE: modules/shared/ref-customizing-entity-page.adoc** (REFERENCE)
   - Changes needed:
     * Replace mountPoints configuration examples with app.extensions entity-card: examples
     * Update filter syntax from config.if.isKind to config.filter: kind:Component
     * Document that layout grid positioning is no longer available in app.extensions (determined by card type or component)
     * Explain entity-card vs entity-content extension types
     * Add examples for both info cards (sidebar) and content cards (main area)
   - Content journey phase: Evaluate → Adopt
   - Sources: RHIDP-5796, EntityCardBlueprint API docs

5. **UPDATE: modules/shared/proc-configure-entity-tab-titles.adoc** (PROCEDURE)
   - Changes needed:
     * Update procedure to use app.extensions configuration instead of dynamicPlugins.frontend
     * Update examples to use entity-content:plugin-id/extension-name format
     * Clarify that title configuration is set in config.title under the extension
     * Add prerequisite about RHDH 2.1 with NFS
   - Content journey phase: Adopt
   - Sources: RHIDP-5796

6. **UPDATE: modules/shared/con-dynamic-front-end-plugins-for-application-use.adoc** (CONCEPT)
   - Changes needed:
     * Add section with specific entity page customization examples
     * Show EntityCardBlueprint usage with filter configuration
     * Show EntityContentBlueprint usage with group and icon parameters
     * Explain how auto-discovery works for entity extensions
     * Cross-reference to entity page customization procedures
   - Content journey phase: Discover → Evaluate
   - Sources: RHIDP-5796, Common Extension Blueprints docs

7. **UPDATE: modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc** (REFERENCE)
   - Changes needed:
     * Enhance entity page configuration section with more detailed examples
     * Add example showing multiple entity-card configurations with different filters
     * Add example showing entity-content with group, icon, and filter
     * Document showNavItemIcons configuration for tab icons
     * Add troubleshooting note about extension ID format (pluginId/extensionName)
   - Content journey phase: Evaluate
   - Sources: RHIDP-5796, Backstage configuring extensions docs

### Category: Migrate
**Main Job**: Transition from static plugins to dynamic plugins without losing functionality

This main job covers the breaking change introduced in RHDH 2.1 where static plugins are removed, requiring users with custom builds to migrate to dynamic plugin loading.

#### User Story 1: Understand impact of static plugin removal on custom builds

**Situation**: User has a custom RHDH build or fork with modified app-next/App.tsx or backend/src/index.ts
**Motivation**: Determine whether upgrade to RHDH 2.1 will affect their installation
**Outcome**: Clear understanding of what changed, why, and whether migration is needed

**Content Journey Phase**: Discover → Evaluate

**Personas**: This requirement serves two distinct personas with different jobs:
- **SysAdmin job**: "Assess upgrade impact on my custom RHDH deployment"
- **Developer job**: "Migrate my custom build to use dynamic plugins"

These are separate jobs because the SysAdmin needs to understand impact and plan the upgrade, while the Developer implements the technical migration.

**Modules**:

8. **con-static-plugins-removed-in-rhdh-2-1.adoc** (CONCEPT)
   - Title: Static plugin removal and dynamic plugin migration in RHDH 2.1
   - Audience: SysAdmin, Developer
   - Content points:
     * What changed: All static frontend and backend plugins removed from app-next and backend packages
     * Why: Migration to New Frontend System requires all plugins to load dynamically through blueprints
     * Relationship to NFS migration: Static removal is prerequisite for NFS GA support
     * Who is affected: Only custom builds and forks; standard installations unaffected
     * What plugins were removed: List of 14 frontend + 10 backend plugins
     * How they're loaded now: Dynamic plugins through app.extensions and backend plugin configuration
     * Impact assessment: Check if you have modified App.tsx or index.ts files
   - Prerequisites: Basic understanding of RHDH architecture
   - Content journey phase: Discover → Evaluate
   - Sources: RHDHPLAN-552, RHIDP-14180, PR #4921, PR #4922

9. **ref-plugins-removed-from-static-builds.adoc** (REFERENCE)
   - Title: Plugins removed from static builds in RHDH 2.1
   - Audience: Developer, SysAdmin
   - Content points:
     * Table of removed frontend plugins with dynamic equivalents
     * Columns: Static package name, Dynamic plugin package, Configuration location
     * Frontend plugins: home, catalog, scaffolder, search, user-settings, app-visualizer, catalog-graph, catalog-import, catalog-unprocessed-entities
     * Table of removed backend plugins with dynamic equivalents
     * Backend plugins: catalog-backend, scaffolder-backend, search-backend, user-settings-backend, and modules
     * Notes on auto-enabled vs requires explicit configuration
   - Prerequisites: None
   - Content journey phase: Evaluate
   - Sources: PR #4921, PR #4922, app-next/package.json, backend/package.json

#### User Story 2: Migrate custom build from static to dynamic plugin loading

**Situation**: User has custom build with static plugin imports that will break on upgrade
**Motivation**: Continue using customized RHDH build after upgrading to 2.1
**Outcome**: Custom build migrated to load all plugins dynamically, verified to work

**Content Journey Phase**: Evaluate → Adopt

**Modules**:

10. **proc-migrate-from-static-to-dynamic-plugin-loading.adoc** (PROCEDURE)
    - Title: Migrate custom builds to load plugins dynamically
    - Audience: Developer
    - Content points:
      * Prerequisites: Custom build with modified App.tsx or index.ts, RHDH 2.1 installation
      * Step 1: Identify static plugin imports in App.tsx and index.ts (search for @backstage/plugin-*)
      * Step 2: Remove static plugin imports from both files
      * Step 3: Remove plugin registration calls (features array in App.tsx, backend.add() in index.ts)
      * Step 4: Configure dynamic-plugins.yaml or app-config.yaml to enable removed plugins
      * Step 5: For core plugins (catalog, scaffolder, search): Add to dynamic-plugins.yaml if not auto-enabled
      * Step 6: For custom home page: Configure dynamic home page in app.extensions
      * Verification: Start RHDH, check backend logs for plugin loading, verify UI shows all expected features
      * Troubleshooting: Check for "Could not find manifest" errors, verify plugin packages installed
    - Prerequisites: Understanding of dynamic plugins and app.extensions
    - Content journey phase: Evaluate → Adopt
    - Sources: RHDHPLAN-552, PR #4921, PR #4922, RHDH migration guide

11. **snip-breaking-change-static-plugins-removed.adoc** (SNIPPET)
    - Title: Breaking change - Static plugins removed
    - Audience: SysAdmin, Developer
    - Content points:
      * WARNING admonition for release notes and upgrade guides
      * Text: "RHDH 2.1 removes all static plugins from app-next and backend packages. If you have a custom build with modified App.tsx or backend/src/index.ts files, you must migrate to dynamic plugin loading before upgrading."
      * Link to migration procedure
      * Link to list of removed plugins
    - Prerequisites: None
    - Content journey phase: Discover
    - Sources: RHIDP-14180

#### User Story 3: Configure dynamic home page after static removal

**Situation**: User upgrades to RHDH 2.1 and home page is missing or wants to customize it
**Motivation**: Restore or customize home page functionality after upgrade
**Outcome**: Home page configured and displaying desired content

**Content Journey Phase**: Evaluate → Adopt

**Modules**:

12. **UPDATE: modules/shared/proc-migrate-the-homepage-to-function-as-a-dynamic-plugin-loaded-through-blueprints.adoc** (PROCEDURE)
    - Changes needed:
      * Add note at top: Home plugin no longer included by default in RHDH 2.1, must be explicitly configured
      * Add prerequisite: RHDH 2.1+ required
      * Clarify choice between upstream @backstage/plugin-home/alpha and @red-hat-developer-hub/backstage-plugin-dynamic-home-page
      * Update configuration examples to emphasize this is now required, not optional
      * Add troubleshooting: If home page missing after upgrade, verify dynamic home page configuration exists
    - Content journey phase: Evaluate → Adopt
    - Sources: RHDHPLAN-552, PR #4921

13. **UPDATE: modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc** (CONCEPT)
    - Changes needed:
      * Add section on static plugin removal under "The following changes affect your upgrade"
      * Explain home plugin removal and requirement to configure dynamic home page
      * Explain catalog, scaffolder, search, user-settings removal from static builds
      * Add note that core plugins are now loaded dynamically via blueprints
      * Cross-reference to con-static-plugins-removed-in-rhdh-2-1.adoc and migration procedure
    - Content journey phase: Discover → Evaluate
    - Sources: RHDHPLAN-552, RHIDP-14180, PR #4921, PR #4922

14. **UPDATE: modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc** (REFERENCE)
    - Changes needed:
      * Add section documenting home plugin removal
      * Show configuration for dynamic home page as now-required instead of optional
      * Note that home plugin was auto-included in RHDH 2.0, requires explicit config in 2.1
    - Content journey phase: Evaluate
    - Sources: RHDHPLAN-552, PR #4921

15. **UPDATE: assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc** (ASSEMBLY)
    - Changes needed:
      * Include new proc-migrate-from-static-to-dynamic-plugin-loading.adoc module
      * Verify proc-migrate-the-homepage-to-function-as-a-dynamic-plugin-loaded-through-blueprints.adoc is properly integrated
      * Ensure reading order: concept → migration procedures → configuration reference
      * Add con-static-plugins-removed-in-rhdh-2-1.adoc as prerequisite understanding
    - Content journey phase: Evaluate → Adopt
    - Sources: RHDHPLAN-552, RHDHPLAN-192

### Category: Extend
**Main Job**: Add custom functionality to RHDH through dynamic plugins

This main job covers plugin developers creating extensions and administrators configuring them. Note: While some requirements serve both Developer and SysAdmin personas, their jobs differ: Developers create plugins, SysAdmins configure them.

#### User Story 1: Make core platform plugins available through dynamic loading

**Situation**: Admin configures RHDH and needs to understand which core plugins are available
**Motivation**: Ensure required functionality is enabled and discoverable
**Outcome**: Core plugins are documented, their availability is understood, and configuration requirements are clear

**Content Journey Phase**: Discover → Evaluate

**Modules**:

16. **ref-core-plugins-as-dynamic-plugins.adoc** (REFERENCE)
    - Title: Core plugins loaded as dynamic plugins in RHDH 2.1
    - Audience: SysAdmin
    - Content points:
      * List of core plugins now loaded dynamically: catalog, scaffolder, search, user-settings, app-visualizer, home
      * Configuration requirements: Some auto-enabled (catalog, scaffolder, search), some require explicit config (home)
      * Table: Plugin name, Package name, Auto-enabled?, Configuration location (app.extensions vs dynamic-plugins.yaml)
      * Relationship to NFS: Core plugins use extension blueprints for UI contributions
      * How to verify a core plugin is loaded: Check backend logs, UI presence
      * Cross-reference to preinstalled plugins list
    - Prerequisites: Understanding of dynamic plugins
    - Content journey phase: Discover → Evaluate
    - Sources: RHIDP-14179, RHDHPLAN-552, PR #4921, PR #4922

17. **UPDATE: modules/extend_dynamic-plugins-reference/con-preinstalled-dynamic-plugins.adoc** (REFERENCE)
    - Changes needed:
      * Add newly converted core plugins to preinstalled plugins list
      * For each: catalog, scaffolder, search, user-settings, home, app-visualizer
      * Mark as auto-enabled or requires configuration
      * Note NFS compatibility (all have /alpha exports)
    - Content journey phase: Discover
    - Sources: RHIDP-14179

18. **UPDATE: modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc** (CONCEPT)
    - Changes needed:
      * Add clarification that core plugins are now dynamic plugins loaded via blueprints
      * Explain auto-discovery mechanism for core plugins
      * Cross-reference to ref-core-plugins-as-dynamic-plugins.adoc
    - Content journey phase: Discover → Evaluate
    - Sources: RHDHPLAN-552, RHIDP-14179

19. **UPDATE: modules/extend_dynamic-plugins-reference/ref-ga-plugins.adoc** (REFERENCE)
    - Changes needed:
      * Verify GA plugins list includes NFS-compatible dynamic versions of core plugins
      * Ensure catalog, scaffolder, search, user-settings, home are listed with correct package names
      * Mark as NFS-compatible (have /alpha exports)
    - Content journey phase: Discover
    - Sources: RHIDP-14179

#### User Story 2: Extend user settings page with custom configuration tabs

**Situation**: Plugin developer or admin wants to add custom settings tab for their plugin or organizational config
**Motivation**: Provide users with a centralized location for plugin-specific or org-specific settings
**Outcome**: Custom settings tab appears in user settings page, users can configure settings

**Content Journey Phase**: Learn → Adopt

**Personas**: This serves two distinct personas:
- **Developer job**: "Create a custom settings tab for my plugin"
- **SysAdmin job**: "Configure which settings tabs are available to users"

**Modules**:

20. **con-user-settings-page-extensibility-in-new-frontend-system.adoc** (CONCEPT)
    - Title: Extend user settings with custom configuration options
    - Audience: Developer, SysAdmin
    - Content points:
      * What: User settings page supports plugin-contributed tabs and settings
      * Why: Centralize all user-facing configuration in one location
      * How it works: Extensions use blueprints to contribute tabs, admin controls via app.extensions
      * Default tabs: General, Authentication Providers, Feature Flags
      * Extension types: Settings tabs, settings cards within tabs
      * Relationship to NFS: User settings page rebuilt with extension points in NFS
      * Auto-discovery: Settings extensions from installed plugins load automatically
    - Prerequisites: Understanding of extension blueprints
    - Content journey phase: Discover → Learn
    - Sources: RHDHPLAN-656, Backstage user-settings plugin docs

21. **proc-add-custom-settings-tab-using-extension-blueprint.adoc** (PROCEDURE)
    - Title: Add a custom tab to the user settings page
    - Audience: Developer
    - Content points:
      * Prerequisites: Plugin with /alpha export, knowledge of extension blueprints
      * Step 1: Import required blueprints (likely SettingsTabBlueprint or custom blueprint)
      * Step 2: Define settings tab extension with loader pointing to component
      * Step 3: Add extension to plugin's extensions array in /alpha export
      * Step 4: Export plugin as dynamic plugin
      * Step 5: Install plugin in RHDH
      * Verification: Navigate to user settings, verify custom tab appears
      * Configuration: Use app.extensions to disable or reorder settings tabs
      * Example: Custom notification preferences tab, custom theme settings tab
    - Prerequisites: Plugin development environment, understanding of React components
    - Content journey phase: Learn → Adopt
    - Sources: RHDHPLAN-656, Backstage plugin-user-settings README

22. **ref-user-settings-extension-configuration-options.adoc** (REFERENCE)
    - Title: User settings extension configuration parameters
    - Audience: Developer, SysAdmin
    - Content points:
      * Configuration schema for user settings extensions in app.extensions
      * Extension ID format: settings-tab:plugin-id/tab-name
      * Configuration parameters: title, path, icon, priority
      * Filter options: Control tab visibility based on user properties
      * Ordering: Control tab order through app.extensions list order
      * Disabling: Set extension to false to hide default or custom tabs
      * Examples: Reorder tabs, disable Feature Flags tab, add custom tab
    - Prerequisites: Understanding of app.extensions configuration
    - Content journey phase: Evaluate → Adopt
    - Sources: RHDHPLAN-656, Backstage configuring extensions docs

23. **UPDATE: modules/shared/proc-customize-the-rhdh-metadata-card-on-the-settings-page.adoc** (PROCEDURE)
    - Changes needed:
      * Add note referencing NFS extensibility
      * Cross-reference to con-user-settings-page-extensibility-in-new-frontend-system.adoc
      * Link to new proc-add-custom-settings-tab-using-extension-blueprint.adoc for broader customization
      * Clarify this procedure is for the specific RHDH metadata card, not general settings extensibility
    - Content journey phase: Adopt
    - Sources: RHDHPLAN-656

24. **UPDATE: modules/shared/ref-adding-custom-authentication-provider-settings.adoc** (REFERENCE)
    - Changes needed:
      * Update to show authentication provider settings work with NFS app.extensions configuration
      * Update configuration path from dynamicPlugins.frontend to app.extensions if applicable
      * Add note that authentication providers tab is a default settings extension
      * Cross-reference to user settings extensibility documentation
    - Content journey phase: Evaluate → Adopt
    - Sources: RHDHPLAN-656

#### User Story 3: Display plugin-contributed validation messages on entity pages

**Situation**: Plugin developer wants to provide validation feedback about entity configuration or compliance
**Motivation**: Give users immediate visibility into entity health, configuration issues, or compliance status
**Outcome**: Validation messages from multiple plugins appear in entity overview tab with appropriate severity indicators

**Content Journey Phase**: Learn → Adopt

**Personas**: This serves two distinct personas:
- **Developer job**: "Contribute validation messages from my plugin"
- **SysAdmin job**: "Configure which validation messages are displayed"

**Modules**:

25. **con-entity-validation-extensibility.adoc** (CONCEPT)
    - Title: Display validation feedback on catalog entities
    - Audience: Developer, SysAdmin
    - Content points:
      * What: Entity overview tab supports plugin-contributed validation messages
      * Why: Provide immediate feedback about entity health, config issues, compliance
      * How it works: Plugins contribute validation message extensions, multiple plugins can contribute simultaneously
      * Validation message types: Error, warning, info
      * Visual indicators: Color coding, icons based on severity
      * Relationship to entity processors: Frontend validation display vs backend validation processing
      * Auto-discovery: Validation extensions from installed plugins load automatically
    - Prerequisites: Understanding of entity model and extension blueprints
    - Content journey phase: Discover → Learn
    - Sources: RHDHPLAN-850, Backstage entity processors docs

26. **proc-contribute-validation-messages-from-plugins.adoc** (PROCEDURE)
    - Title: Add validation messages to entity overview from your plugin
    - Audience: Developer
    - Content points:
      * Prerequisites: Plugin with /alpha export, understanding of entity model
      * Step 1: Import validation message blueprint (likely custom or EntityCardBlueprint variant)
      * Step 2: Define validation logic that checks entity properties
      * Step 3: Return validation messages with severity (error/warning/info) and text
      * Step 4: Create validation extension with loader and entity filter
      * Step 5: Add extension to plugin's extensions array
      * Step 6: Export plugin as dynamic plugin
      * Verification: View entity overview tab, verify validation messages appear
      * Example: Metadata completeness check, annotation validation, compliance check
    - Prerequisites: Plugin development environment, entity model knowledge
    - Content journey phase: Learn → Adopt
    - Sources: RHDHPLAN-850, Backstage entity validation plugin, Processing entities article

27. **ref-entity-validation-extension-api.adoc** (REFERENCE)
    - Title: Entity validation extension API and configuration
    - Audience: Developer, SysAdmin
    - Content points:
      * Extension type and ID format for validation messages
      * Configuration schema in app.extensions
      * Message severity levels: error, warning, info
      * Visual rendering: How severity maps to UI presentation
      * Filter configuration: Control when validation runs (entity kind, namespace)
      * Disabling validation extensions: Set to false in app.extensions
      * Message structure: Required and optional fields
      * Performance: Best practices for validation logic (async, caching)
    - Prerequisites: Understanding of extension blueprints and entity model
    - Content journey phase: Evaluate → Adopt
    - Sources: RHDHPLAN-850, EntityCardBlueprint API reference

28. **UPDATE: modules/shared/ref-customizing-and-extending-entity-tabs.adoc** (REFERENCE)
    - Changes needed:
      * Add information about validation message mount points for entity.page.overview tab
      * Explain that validation messages are a specific type of entity card extension
      * Show extension ID format for validation message extensions
      * Cross-reference to entity validation extensibility documentation
    - Content journey phase: Evaluate → Adopt
    - Sources: RHDHPLAN-850

29. **UPDATE: modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc** (CONCEPT)
    - Changes needed:
      * Add extensible validation messages as a new frontend system capability in RHDH 2.1
      * Brief description of entity validation extensibility
      * Cross-reference to con-entity-validation-extensibility.adoc
    - Content journey phase: Discover → Evaluate
    - Sources: RHDHPLAN-850

## Content Journey Phase Summary

| Phase | Module Count | Examples |
|-------|--------------|----------|
| **Expand** | 0 | None - Gap identified |
| **Discover** | 6 | con-static-plugins-removed, con-user-settings-extensibility, con-entity-validation-extensibility |
| **Learn** | 3 | proc-add-custom-settings-tab, proc-contribute-validation-messages, concept updates |
| **Evaluate** | 10 | ref-plugins-removed, ref-core-plugins, ref-user-settings-config, reference updates |
| **Adopt** | 10 | proc-disable-entity-tabs, proc-reorder-entity-tabs, proc-migrate-static-to-dynamic, procedure updates |

**Gap identified**: No Expand-phase content to introduce page customization capabilities at a high level. Consider creating a landing page or overview module.

## Module Dependencies and Implementation Order

### Phase 1: Foundation (Breaking Changes Understanding)
**Goal**: Users understand what changed and impact on their installations
**Priority**: Critical

1. con-static-plugins-removed-in-rhdh-2-1.adoc (NEW)
2. ref-plugins-removed-from-static-builds.adoc (NEW)
3. snip-breaking-change-static-plugins-removed.adoc (NEW)
4. UPDATE: con-new-frontend-system-changes-in-rhdh-2-1.adoc
   - Add static plugin removal, home plugin removal, core plugins as dynamic
   - Add validation extensibility and user settings extensibility

**Dependencies**: None - these are foundational concepts

### Phase 2: Core Migration Procedures
**Goal**: Users with custom builds can migrate to RHDH 2.1
**Priority**: Critical

5. proc-migrate-from-static-to-dynamic-plugin-loading.adoc (NEW)
   - Depends on: con-static-plugins-removed, ref-plugins-removed
6. UPDATE: proc-migrate-the-homepage-to-function-as-a-dynamic-plugin-loaded-through-blueprints.adoc
   - Depends on: con-static-plugins-removed
7. UPDATE: assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc
   - Depends on: All Phase 1 and Phase 2 modules

**Dependencies**: Phase 1 complete

### Phase 3: Entity Page Customization References
**Goal**: Update existing entity page docs to use new configuration format
**Priority**: High

8. UPDATE: ref-customizing-and-extending-entity-tabs.adoc
9. UPDATE: ref-customizing-entity-page.adoc
10. UPDATE: proc-configure-entity-tab-titles.adoc
11. UPDATE: ref-app-config-changes-for-the-new-frontend-system.adoc
    - Enhanced entity page examples, home plugin removal note

**Dependencies**: Phase 1 (con-new-frontend-system-changes updated)

### Phase 4: Entity Page Customization Procedures
**Goal**: Users can disable, reorder, and customize entity pages
**Priority**: High

12. proc-disable-entity-tabs-and-cards.adoc (NEW)
    - Depends on: ref-customizing-and-extending-entity-tabs updated
13. proc-reorder-entity-tabs.adoc (NEW)
    - Depends on: ref-customizing-and-extending-entity-tabs updated
14. UPDATE: con-dynamic-front-end-plugins-for-application-use.adoc
    - Add entity page examples
    - Depends on: Phase 3 reference updates

**Dependencies**: Phase 3 complete

### Phase 5: Core Plugins as Dynamic Plugins
**Goal**: Document core plugins availability and configuration
**Priority**: Medium

15. ref-core-plugins-as-dynamic-plugins.adoc (NEW)
16. UPDATE: con-preinstalled-dynamic-plugins.adoc
17. UPDATE: ref-ga-plugins.adoc

**Dependencies**: Phase 1 (con-static-plugins-removed)

### Phase 6: User Settings Extensibility
**Goal**: Plugin developers can extend user settings page
**Priority**: Medium

18. con-user-settings-page-extensibility-in-new-frontend-system.adoc (NEW)
    - No dependencies beyond Phase 1
19. proc-add-custom-settings-tab-using-extension-blueprint.adoc (NEW)
    - Depends on: con-user-settings-extensibility
20. ref-user-settings-extension-configuration-options.adoc (NEW)
    - Depends on: con-user-settings-extensibility
21. UPDATE: proc-customize-the-rhdh-metadata-card-on-the-settings-page.adoc
    - Depends on: con-user-settings-extensibility
22. UPDATE: ref-adding-custom-authentication-provider-settings.adoc
    - Depends on: con-user-settings-extensibility

**Dependencies**: Phase 1 complete (can run parallel to Phases 3-5)

### Phase 7: Entity Validation Extensibility
**Goal**: Plugin developers can contribute validation messages
**Priority**: Medium

23. con-entity-validation-extensibility.adoc (NEW)
    - Depends on: Phase 3 (ref-customizing-and-extending-entity-tabs updated)
24. proc-contribute-validation-messages-from-plugins.adoc (NEW)
    - Depends on: con-entity-validation-extensibility
25. ref-entity-validation-extension-api.adoc (NEW)
    - Depends on: con-entity-validation-extensibility

**Dependencies**: Phase 3 complete (entity tabs reference updated)

### Critical Path

```
Phase 1 (Foundation) →
    ├─→ Phase 2 (Migration) → Phase 3 (Entity Refs) → Phase 4 (Entity Procedures)
    ├─→ Phase 5 (Core Plugins)
    ├─→ Phase 6 (User Settings)
    └─→ Phase 3 → Phase 7 (Validation)
```

**Minimum viable documentation for RHDH 2.1 launch**: Phases 1-4 (breaking changes, migration, entity customization)

**Full feature coverage**: All phases (includes extensibility for plugin developers)

## Assembly Structure

### Assembly 1: Migrate to the New Frontend System (EXISTING - UPDATE)
**File**: assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc
**Category**: Migrate
**Main Job**: Transition from static plugins to dynamic plugins without losing functionality

**Modules** (in reading order):
1. con-new-frontend-system-changes-in-rhdh-2-1.adoc (UPDATED) - Breaking changes overview
2. con-static-plugins-removed-in-rhdh-2-1.adoc (NEW) - Static plugin removal concept
3. ref-plugins-removed-from-static-builds.adoc (NEW) - List of removed plugins
4. proc-migrate-from-static-to-dynamic-plugin-loading.adoc (NEW) - Custom build migration
5. proc-migrate-the-homepage-to-function-as-a-dynamic-plugin-loaded-through-blueprints.adoc (UPDATED) - Home page config
6. proc-migrate-custom-plugins-to-the-new-frontend-system.adoc (EXISTING) - Custom plugin migration
7. ref-app-config-changes-for-the-new-frontend-system.adoc (UPDATED) - Configuration reference

**Prerequisites**: Understanding of RHDH architecture, custom builds

### Assembly 2: Customize RHDH Navigation (EXISTING - EXTEND)
**File**: assemblies/configure_customizing-rhdh/assembly-customize-rhdh-navigation.adoc
**Category**: Configure
**Main Job**: Customize interface layout and navigation to match organizational workflows

**Modules** (in reading order):
1. con-dynamic-front-end-plugins-for-application-use.adoc (UPDATED) - Extension blueprints concept with entity examples
2. ref-customizing-and-extending-entity-tabs.adoc (UPDATED) - Entity tabs configuration reference
3. ref-customizing-entity-page.adoc (UPDATED) - Entity cards configuration reference
4. proc-disable-entity-tabs-and-cards.adoc (NEW) - Disable unused tabs/cards
5. proc-reorder-entity-tabs.adoc (NEW) - Reorder entity tabs
6. proc-configure-entity-tab-titles.adoc (UPDATED) - Customize tab titles

**Prerequisites**: RHDH 2.1+ installed with NFS enabled

### Assembly 3: Install and Configure Dynamic Plugins (EXISTING - EXTEND)
**File**: assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-install-dynamic-plugins-in-rhdh.adoc
**Category**: Extend
**Main Job**: Add custom functionality to RHDH through dynamic plugins

**Add to this assembly**:
1. ref-core-plugins-as-dynamic-plugins.adoc (NEW) - Core plugins as dynamic
2. UPDATE: con-preinstalled-dynamic-plugins.adoc - Add core plugins
3. UPDATE: ref-ga-plugins.adoc - Verify core plugins listed

**Prerequisites**: RHDH installation, understanding of dynamic plugins

### Assembly 4: Extend User Settings Page (NEW)
**File**: assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-extend-user-settings-page.adoc
**Category**: Extend
**Main Job**: Add custom functionality to RHDH through dynamic plugins
**User Story**: Extend user settings page with custom configuration tabs

**Modules** (in reading order):
1. con-user-settings-page-extensibility-in-new-frontend-system.adoc (NEW) - Concept
2. proc-add-custom-settings-tab-using-extension-blueprint.adoc (NEW) - Create custom tab
3. ref-user-settings-extension-configuration-options.adoc (NEW) - Configuration reference
4. proc-customize-the-rhdh-metadata-card-on-the-settings-page.adoc (UPDATED) - Specific customization
5. ref-adding-custom-authentication-provider-settings.adoc (UPDATED) - Auth provider settings

**Prerequisites**: Plugin development environment, understanding of extension blueprints

### Assembly 5: Extend Entity Validation (NEW)
**File**: assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-extend-entity-validation.adoc
**Category**: Extend
**Main Job**: Add custom functionality to RHDH through dynamic plugins
**User Story**: Display plugin-contributed validation messages on entity pages

**Modules** (in reading order):
1. con-entity-validation-extensibility.adoc (NEW) - Concept
2. proc-contribute-validation-messages-from-plugins.adoc (NEW) - Contribute messages
3. ref-entity-validation-extension-api.adoc (NEW) - API reference

**Prerequisites**: Plugin development environment, entity model knowledge

## New Docs

* con-static-plugins-removed-in-rhdh-2-1.adoc (CONCEPT)
    Explains the removal of static plugins from app-next and backend packages in RHDH 2.1 as part of the New Frontend System migration. Covers what changed, why it happened, the relationship to NFS, who is affected (custom builds only), and how plugins are now loaded dynamically through extension blueprints.

* ref-plugins-removed-from-static-builds.adoc (REFERENCE)
    Complete list of all 24 plugins removed from static builds (14 frontend + 10 backend), including their package names, dynamic plugin equivalents, and configuration requirements. Organized in tables mapping static package names to dynamic plugin packages and configuration locations.

* proc-migrate-from-static-to-dynamic-plugin-loading.adoc (PROCEDURE)
    Step-by-step migration procedure for users with custom RHDH builds. Guides users through identifying static plugin imports in App.tsx and index.ts, removing them, configuring dynamic-plugins.yaml and app-config.yaml to enable the plugins dynamically, and verifying the migration succeeded. Includes troubleshooting for common migration issues.

* snip-breaking-change-static-plugins-removed.adoc (SNIPPET)
    Warning admonition for inclusion in release notes and upgrade guides explaining that RHDH 2.1 removes static plugins and custom builds must migrate to dynamic loading. Links to migration documentation.

* proc-disable-entity-tabs-and-cards.adoc (PROCEDURE)
    Procedure showing how to hide unwanted tabs and cards from catalog entity pages using app.extensions configuration. Covers identifying extension IDs, setting extensions to false, examples for disabling common tabs (CI, monitoring), and verification steps.

* proc-reorder-entity-tabs.adoc (PROCEDURE)
    Procedure showing how to control the display order of tabs on entity pages by listing extensions in the desired order in app.extensions configuration. Covers list ordering, handling tab groups, example configurations, and verification.

* ref-core-plugins-as-dynamic-plugins.adoc (REFERENCE)
    Documents which core RHDH plugins (catalog, scaffolder, search, user-settings, app-visualizer, home) are now loaded as dynamic plugins in RHDH 2.1. Table format showing plugin name, package name, auto-enabled status, and configuration location. Explains relationship to NFS and how to verify plugins are loaded.

* con-user-settings-page-extensibility-in-new-frontend-system.adoc (CONCEPT)
    Explains how the user settings page supports plugin-contributed extensions in the New Frontend System. Covers what extensibility is, why it matters, how it works with extension blueprints, default tabs, extension types, auto-discovery, and relationship to NFS.

* proc-add-custom-settings-tab-using-extension-blueprint.adoc (PROCEDURE)
    Step-by-step guide for plugin developers to add custom tabs to the user settings page using extension blueprints. Covers importing blueprints, defining settings tab extensions, adding to plugin exports, installation, verification, and configuration through app.extensions. Includes examples for notification preferences and theme settings tabs.

* ref-user-settings-extension-configuration-options.adoc (REFERENCE)
    Configuration schema and parameters for user settings page extensions in app.extensions. Covers extension ID format, configuration parameters (title, path, icon, priority), filter options, ordering, disabling extensions, and examples for reordering and customization.

* con-entity-validation-extensibility.adoc (CONCEPT)
    Explains how plugins can contribute validation messages to the entity overview tab. Covers what validation extensibility is, why it matters for entity health feedback, how it works with multiple plugins contributing simultaneously, message severity levels, visual indicators, relationship to backend entity processors, and auto-discovery.

* proc-contribute-validation-messages-from-plugins.adoc (PROCEDURE)
    Step-by-step guide for plugin developers to add validation message extensions. Covers importing validation blueprints, defining validation logic, creating validation extensions with entity filters, adding to plugin exports, and verification. Examples include metadata completeness checks, annotation validation, and compliance checks.

* ref-entity-validation-extension-api.adoc (REFERENCE)
    API reference for entity validation extensions including extension type, ID format, configuration schema in app.extensions, message severity levels, visual rendering, filter configuration, disabling extensions, message structure, and performance best practices for validation logic.

## Updated Docs

* modules/shared/ref-customizing-and-extending-entity-tabs.adoc
    Replace dynamicPlugins.frontend.entityTabs configuration examples with app.extensions entity-content: format. Update configuration paths, add filter syntax examples (filter: kind:Component), add group and icon configuration examples for EntityContentBlueprint, add migration note that old format removed in RHDH 2.1, preserve table of default routes. Add validation message mount points information.

* modules/shared/ref-customizing-entity-page.adoc
    Replace mountPoints configuration examples with app.extensions entity-card: format. Update filter syntax from config.if.isKind to config.filter. Document that layout grid positioning no longer available in app.extensions. Explain entity-card vs entity-content extension types. Add examples for info cards (sidebar) and content cards (main area).

* modules/shared/proc-configure-entity-tab-titles.adoc
    Update procedure to use app.extensions configuration instead of dynamicPlugins.frontend path. Update examples to entity-content:plugin-id/extension-name format. Clarify title configuration set in config.title. Add prerequisite about RHDH 2.1 with NFS.

* modules/shared/con-dynamic-front-end-plugins-for-application-use.adoc
    Add section with entity page customization examples showing EntityCardBlueprint with filter configuration and EntityContentBlueprint with group and icon parameters. Explain auto-discovery for entity extensions. Cross-reference to entity page customization procedures.

* modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc
    Enhance entity page configuration section with detailed examples showing multiple entity-card configurations with different filters, entity-content with group/icon/filter, showNavItemIcons configuration for tab icons, troubleshooting notes about extension ID format. Add section on home plugin removal and required dynamic home page configuration.

* modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc
    Add section on static plugin removal explaining which plugins removed (home, catalog, scaffolder, search, user-settings, app-visualizer), why they were removed, requirement to configure dynamic home page, note that core plugins loaded dynamically via blueprints. Add extensible validation messages and user settings extensibility as new NFS capabilities. Cross-reference to migration documentation.

* modules/shared/proc-migrate-the-homepage-to-function-as-a-dynamic-plugin-loaded-through-blueprints.adoc
    Add note that home plugin no longer included by default in RHDH 2.1 and must be explicitly configured. Add RHDH 2.1+ prerequisite. Clarify choice between upstream @backstage/plugin-home/alpha and @red-hat-developer-hub/backstage-plugin-dynamic-home-page. Update configuration examples to emphasize required configuration. Add troubleshooting for missing home page after upgrade.

* assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc
    Include new proc-migrate-from-static-to-dynamic-plugin-loading.adoc module. Verify home page migration procedure properly integrated. Ensure reading order: concept → migration procedures → configuration reference. Add con-static-plugins-removed-in-rhdh-2-1.adoc as prerequisite.

* modules/extend_dynamic-plugins-reference/con-preinstalled-dynamic-plugins.adoc
    Add newly converted core plugins (catalog, scaffolder, search, user-settings, home, app-visualizer) to preinstalled plugins list. Mark as auto-enabled or requires configuration. Note NFS compatibility (all have /alpha exports).

* modules/extend_dynamic-plugins-reference/ref-ga-plugins.adoc
    Verify GA plugins list includes NFS-compatible dynamic versions of core plugins with correct package names marked as NFS-compatible.

* modules/shared/proc-customize-the-rhdh-metadata-card-on-the-settings-page.adoc
    Add note referencing NFS extensibility. Cross-reference to con-user-settings-page-extensibility-in-new-frontend-system.adoc and proc-add-custom-settings-tab-using-extension-blueprint.adoc. Clarify this procedure is specific to RHDH metadata card, not general settings extensibility.

* modules/shared/ref-adding-custom-authentication-provider-settings.adoc
    Update to show authentication provider settings work with NFS app.extensions configuration. Update configuration path if applicable. Add note that authentication providers tab is a default settings extension. Cross-reference to user settings extensibility documentation.

## Verification Checklist

Self-review verification completed:

- [x] **No placeholder syntax**: All `[REPLACE]`, `[TODO]`, `[TBD]` markers removed and replaced with actual content
- [x] **No hallucinated content**: Every recommendation traceable to requirements sources (RHDHPLAN-552, RHIDP-5796, RHIDP-14179, RHIDP-14180, RHDHPLAN-656, RHDHPLAN-850, PR #4921, PR #4922)
- [x] **Source traceability**: Each module recommendation links to at least one source from requirements analysis
- [x] **No sensitive information**: No hostnames, passwords, IPs, internal URLs, or tokens included
- [x] **Persona limit**: Maximum 3 user personas identified (Developer, SysAdmin, IT Operations Leader)
- [x] **Template completeness**: All required output sections present and populated
- [x] **Impact consistency**: Doc impact grades (High for breaking changes and entity customization, Medium for extensibility features) align with prioritization
- [x] **Journey coverage**: Content journey phases mapped for all modules - identified gap in Expand phase
- [x] **JIRA description**: N/A - Full plan format only, JIRA description will be extracted from specific sections
- [x] **Persona separation**: Multi-persona capabilities (user settings extensibility, entity validation) have separate job statements for Developer (create) vs SysAdmin (configure) jobs

## Notes

**Implementation Priority**: Phases 1-4 are critical path for RHDH 2.1 launch to document breaking changes and migration. Phases 5-7 are medium priority for full feature coverage.

**Content Journey Gap**: No Expand-phase content identified. Consider creating a high-level overview module or landing page introducing RHDH page customization capabilities for discovery.

**Relationship to Parent Epic**: This plan addresses RHDHPLAN-552 which is part of the broader RHDHPLAN-192 outcome (Base RHDH frontend on upstream new frontend system). All requirements share the common theme of NFS migration and configuration-based customization.

**Coordination Needed**: Static plugin removal (REQ-001) affects both RHDHPLAN-552 scope and potentially other feature areas. Ensure breaking change communication is consistent across all RHDH 2.1 documentation.
