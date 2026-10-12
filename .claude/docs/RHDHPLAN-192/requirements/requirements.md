# Documentation Requirements

**Source**: Base RHDH frontend on the upstream new frontend system
**Date**: 2026-10-08
**Release/Sprint**: 2.1.0

## Summary

- Total requirements analyzed: 9
- New modules needed: 17
- Existing modules to update: 23
- Breaking changes requiring docs: 3

## Requirements by priority

### Critical

#### REQ-001: GA support for New Frontend System in RHDH 2.1
- **Source**: [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187) | [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192)
- **Summary**: RHDH 2.1 adopts the Backstage New Frontend System (NFS) as the exclusive frontend architecture, removing support for the legacy frontend system and Scalprum-based dynamic plugin loading. All plugins must now export extension blueprints via /alpha entry points and use the app.extensions configuration section instead of dynamicPlugins.frontend. This change enables blueprint-based dynamic routing, improved extensibility, and alignment with upstream Backstage architecture while requiring migration of custom plugins and configuration before upgrade.
- **User impact**: Users upgrading to RHDH 2.1 must migrate all custom frontend plugins to use extension blueprints and update their app-config.yaml files to use the new app.extensions configuration format. Unmigrated plugins will not load or appear in the application. Configuration sections like dynamicRoutes, mountPoints, entityTabs, and routeBindings are replaced with the extension-based model. Red Hat-provided plugins are pre-migrated and require no user action.
- **Documentation action**:
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Existing concept module covers breaking changes; verify completeness for GA status and feature flags removal
  - [ ] Update `modules/shared/proc-migrate-custom-plugins-to-the-new-frontend-system.adoc` (PROCEDURE) - Existing migration procedure; verify steps are complete for all blueprint types and troubleshooting scenarios
  - [ ] Update `modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc` (REFERENCE) - Existing configuration reference; verify all removed configuration keys and mappings are documented
  - [ ] Update `assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc` (ASSEMBLY) - Main assembly for migration guidance; verify flow covers all user scenarios and links to additional resources
  - [ ] Create `modules/shared/con-benefits-of-new-frontend-system.adoc` (CONCEPT) - New concept explaining why NFS was adopted, key benefits over legacy system, and architectural improvements
  - [ ] Create `modules/shared/ref-extension-blueprint-types.adoc` (REFERENCE) - Complete reference of available blueprint types (EntityCardBlueprint, PageBlueprint, ApiBlueprint, etc.) with parameters
  - [ ] Create `modules/shared/proc-verify-plugin-nfs-compatibility.adoc` (PROCEDURE) - Steps to check if a community or custom plugin supports NFS by inspecting /alpha exports
  - [ ] Update `modules/shared/con-dynamic-front-end-plugins-for-application-use.adoc` (CONCEPT) - Existing concept on extension blueprints; verify table is complete and examples reflect 2.1 GA capabilities
- **Acceptance criteria**:
  - [ ] Users understand that RHDH 2.1 exclusively uses the New Frontend System and the legacy system has been removed
  - [ ] Users can identify which plugins require migration by checking for /alpha exports
  - [ ] Users can successfully migrate custom plugins using extension blueprints following documented procedures
  - [ ] Users can convert dynamicPlugins.frontend configuration to app.extensions format using provided mapping reference
  - [ ] Users understand which configuration options and environment variables (APP_CONFIG_app_packageName, ENABLE_STANDARD_MODULE_FEDERATION, Scalprum fields) are removed and no longer functional
  - [ ] Users can troubleshoot missing plugin errors by checking backend logs and browser console messages
  - [ ] Users understand that Red Hat-provided plugins are pre-migrated and require no action
  - [ ] Users can verify plugin compatibility with NFS before upgrading
  - [ ] Documentation clearly distinguishes between what was Developer Preview in 1.x and what is now GA in 2.1
- **References**:
  - [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Parent outcome: Base RHDH frontend on upstream new frontend system
  - [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187): GA support for NFS in RHDH 2.1
  - [The Frontend System | Backstage](https://backstage.io/docs/frontend-system/): Official Backstage documentation for NFS architecture and concepts
  - [Migrating Plugins | Backstage](https://backstage.io/docs/frontend-system/building-plugins/migrating/): Upstream migration guide showing createFrontendPlugin, /alpha exports, and blueprint usage

#### REQ-004: RBAC fine-grained visibility control for UI elements
- **Source**: [RHDHPLAN-843](https://redhat.atlassian.net/browse/RHDHPLAN-843)
- **Summary**: Red Hat Developer Hub 2.1 introduces fine-grained RBAC visibility control that enables administrators to hide or show pages, tabs, and navigation elements based on user permissions within the New Frontend System. This feature leverages Backstage's permissions framework to conditionally render UI components, improving both user experience by presenting only relevant functionality and security by reducing the attack surface through declarative permission-based visibility rules.
- **User impact**: Administrators can now configure role-based visibility rules that automatically hide unauthorized UI elements instead of showing disabled states or permission-denied screens. Users see a cleaner interface displaying only features they have permission to access, while developers can implement permission checks using the usePermission hook or RequirePermission component.
- **Documentation action**:
  - [ ] Create `assemblies/shared/assembly-hide-pages-and-navigation-elements-using-rbac-to-maintain-a-secure-ui.adoc` (ASSEMBLY) - Primary assembly covering RBAC-based UI visibility control concepts, benefits, constraints, and configuration
  - [ ] Create `assemblies/shared/assembly-permissions-for-ui-visibility-control.adoc` (ASSEMBLY) - Reference assembly for plugin permissions, UI elements, and evaluation behavior
  - [ ] Create `modules/shared/con-permission-based-ui-visibility-for-a-cleaner-user-experience.adoc` (CONCEPT) - Explains RBAC-based UI element visibility concept
  - [ ] Create `modules/shared/con-permission-types-for-rbac-ui-visibility-control.adoc` (CONCEPT) - Describes basic permissions vs resource permissions for UI visibility
  - [ ] Create `modules/shared/con-unsupported-scenarios-and-constraints-for-rbac-ui-visibility.adoc` (CONCEPT) - Documents limitations and unsupported scenarios
  - [ ] Create `modules/shared/con-user-experience-and-security-benefits-of-rbac-ui-hiding.adoc` (CONCEPT) - Explains UX and security benefits of permission-based visibility
  - [ ] Create `modules/shared/proc-configure-rbac-visibility-rules-to-hide-unauthorized-ui-elements.adoc` (PROCEDURE) - Step-by-step procedure for configuring RBAC visibility rules with examples
  - [ ] Create `modules/shared/ref-permission-evaluation-behavior-for-ui-visibility.adoc` (REFERENCE) - Technical reference for how permissions are evaluated (with/without attributes)
  - [ ] Create `modules/shared/ref-plugin-permissions-for-ui-visibility.adoc` (REFERENCE) - Reference table of plugin permissions supporting UI visibility control
  - [ ] Create `modules/shared/ref-ui-elements-with-rbac-visibility-control.adoc` (REFERENCE) - Reference table of UI elements that support RBAC visibility control
  - [ ] Update `titles/control-access_authorization-in-rhdh/master.adoc` (ASSEMBLY) - Add includes for new RBAC UI visibility assemblies
- **Acceptance criteria**:
  - [ ] Administrators can configure RBAC policies that hide pages, tabs, and navigation elements based on user roles
  - [ ] Documentation explains the difference between basic permissions (bare permission name) and resource permissions (with attributes)
  - [ ] Users understand how permission evaluation uses the 'if' predicate to control UI element visibility
  - [ ] Procedure includes working examples of configuring visibility rules for common UI elements (catalog create button, navigation items, page tabs)
  - [ ] Reference tables list all plugins supporting UI visibility control and their permission names
  - [ ] Documentation clarifies unsupported scenarios and constraints (frontend-only checks require backend authorization)
  - [ ] Users can distinguish when to use usePermission hook vs RequirePermission component in custom plugins
  - [ ] Integration with New Frontend System is documented for RHDH 2.1
- **References**:
  - [PR #2595](https://github.com/redhat-developer/red-hat-developers-documentation-rhdh/pull/2595): Documentation structure with 10 new modules covering RBAC UI visibility
  - [Backstage Frontend Components with Authorization](https://backstage.io/docs/permissions/plugin-authors/05-frontend-authorization/): Upstream documentation on usePermission hook and RequirePermission component

### High

#### REQ-002: Enhanced UI theme customization with Material UI and CSS
- **Source**: [RHDHPLAN-249](https://redhat.atlassian.net/browse/RHDHPLAN-249)
- **Summary**: RHDH 2.1 enhances UI theme customization by supporting the New Frontend System (NFS) with improved Material UI and CSS customization capabilities. Users can now customize themes through the rhdhThemeModule configuration in the New Frontend System, providing more advanced control over color schemes, logos, typography, and visual elements through both Material UI theme providers and CSS-based Backstage UI design tokens. This enhancement aligns with the broader migration to blueprint-based dynamic routing and the extension-based frontend architecture.
- **User impact**: Platform administrators can now apply more comprehensive brand customization to align RHDH with their organization's identity. The New Frontend System provides both legacy Material UI theme customization (via UnifiedThemeProvider and dynamic plugins) and modern CSS-first customization using Backstage UI design tokens, offering flexibility for both migration scenarios and greenfield deployments.
- **Documentation action**:
  - [ ] Update `assemblies/configure_customizing-rhdh/assembly-customize-rhdh-theme-and-branding.adoc` (ASSEMBLY) - Add New Frontend System theme customization approach alongside legacy approach
  - [ ] Update `modules/shared/proc-customize-platform-appearance-to-reflect-your-brand-identity.adoc` (PROCEDURE) - Enhance with additional Material UI and CSS customization details
  - [ ] Create `modules/shared/proc-customize-theme-using-backstage-ui-design-tokens.adoc` (PROCEDURE) - New procedure for CSS-first customization using Backstage UI design tokens
  - [ ] Create `modules/shared/con-theme-customization-approaches-in-new-frontend-system.adoc` (CONCEPT) - Explain Material UI vs. CSS-first approaches and when to use each
  - [ ] Update `modules/shared/ref-customizing-rhdh-theme.adoc` (REFERENCE) - Add reference for rhdhThemeModule configuration and available design tokens
  - [ ] Update `modules/shared/proc-load-a-custom-rhdh-theme-by-using-a-dynamic-plugin.adoc` (PROCEDURE) - Clarify compatibility with New Frontend System and migration path
  - [ ] Create `modules/shared/ref-backstage-ui-design-tokens.adoc` (REFERENCE) - Reference table of available CSS design tokens (--bui-* variables)
- **Acceptance criteria**:
  - [ ] Users can enable theme customization in the New Frontend System by importing rhdhThemeModule in App.tsx
  - [ ] Users can customize themes using Material UI through UnifiedThemeProvider and dynamic plugins
  - [ ] Users can customize themes using CSS-first approach with Backstage UI design tokens (--bui-* variables)
  - [ ] Documentation explains the difference between Material UI and CSS-first customization approaches
  - [ ] Documentation provides examples of common customization patterns for both approaches
  - [ ] Migration guidance is provided for users transitioning from legacy theming to New Frontend System
  - [ ] Reference documentation lists available design tokens and their usage
- **References**:
  - [Backstage - Customize the look-and-feel of your App](https://backstage.io/docs/getting-started/app-custom-theme/): Official Backstage documentation on Material UI theme customization
  - [Backstage UI - Tokens](https://ui.backstage.io/tokens): Complete reference for Backstage UI CSS design tokens (--bui-* variables)

#### REQ-003: Plugin customization on any page
- **Source**: [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) | [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921) | [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922)
- **Summary**: RHDH 2.1 transitions from static plugin registration to dynamic plugin loading via the New Frontend System, enabling users to customize which plugins appear on any page through runtime configuration without rebuilding the application. Static plugins previously hardcoded in app-next/src/App.tsx are removed and replaced with dynamicFrontendFeaturesLoader, allowing plugins to be loaded at runtime from dynamic-plugins.yaml configuration.
- **User impact**: Users can now add, remove, or configure plugins on any page in RHDH by updating app-config.yaml without code changes or application rebuilds. Previously hardcoded plugins (home, catalog, scaffolder, search, user-settings, app-visualizer) can now be loaded dynamically, providing greater flexibility in customizing the developer portal experience.
- **Documentation action**:
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Add section explaining removal of static plugin registration and transition to dynamic loading
  - [ ] Update `modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc` (REFERENCE) - Add examples of page-level plugin customization using app.extensions configuration
  - [ ] Update `modules/shared/con-dynamic-plugins.adoc` (CONCEPT) - Clarify that dynamic plugins now work with New Frontend System for page-level customization
  - [ ] Create `modules/configure_configuring-rhdh/proc-customize-plugins-on-pages-using-app-extensions.adoc` (PROCEDURE) - Document how to enable/disable/configure plugins on specific pages using app.extensions
  - [ ] Update `assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc` (ASSEMBLY) - Include new procedure for page-level plugin customization
- **Acceptance criteria**:
  - [ ] Users can load the home plugin dynamically instead of having it statically imported
  - [ ] Users can load catalog, scaffolder, search, and user-settings plugins dynamically
  - [ ] Users can configure which plugins appear on any page using app.extensions in app-config.yaml
  - [ ] Documentation explains the migration path from static plugin imports to dynamic loading
  - [ ] Documentation provides examples of page-level plugin customization using app.extensions
- **References**:
  - [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921): Removes static home plugin import, enabling dynamic loading
  - [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922): Removes multiple static plugins (catalog, scaffolder, search, user-settings, app-visualizer) from app-next and backend

#### REQ-006: Migration from Material UI to Backstage UI
- **Source**: [RHDHPLAN-1188](https://redhat.atlassian.net/browse/RHDHPLAN-1188)
- **Summary**: Red Hat Developer Hub 2.1 migrates Backstage core plugins from Material UI components to the new Backstage UI system as part of Phase 1 of the UI modernization effort. This change aligns with the upstream Backstage project's strategic direction to replace Material Design-based components with a less opinionated, more customizable design system built on Base UI. Users will experience visual consistency improvements and enhanced theming capabilities, while plugin developers must migrate custom plugins to use @backstage/ui components instead of Material UI to maintain compatibility with RHDH 2.1 and future releases.
- **User impact**: Users with custom frontend plugins that directly use Material UI components will need to migrate those plugins to use Backstage UI components from the @backstage/ui package. The visual appearance of the platform will remain similar, but theming and customization patterns will change. Existing PatternFly and MUI theme variant options will continue to work during this transition phase, but plugin developers should begin migrating to the new Backstage UI system to ensure long-term compatibility.
- **Documentation action**:
  - [ ] Create `con-material-ui-to-backstage-ui-migration-overview.adoc` (CONCEPT) - Explain the strategic rationale for migrating from Material UI to Backstage UI, the phases of migration, and what changes in RHDH 2.1
  - [ ] Create `ref-material-ui-to-backstage-ui-component-mapping.adoc` (REFERENCE) - Provide mapping table from MUI components to Backstage UI equivalents (Grid, Typography, Box, Button, Card, etc.)
  - [ ] Create `proc-migrate-custom-plugin-from-material-ui-to-backstage-ui.adoc` (PROCEDURE) - Step-by-step guide for plugin developers to migrate MUI components to @backstage/ui
  - [ ] Create `proc-use-backstage-ui-migration-codemods.adoc` (PROCEDURE) - How to use the official Backstage codemod recipes for automated MUI to BUI migration
  - [ ] Create `ref-backstage-ui-components-reference.adoc` (REFERENCE) - Reference guide to commonly used @backstage/ui components with code examples
  - [ ] Update `modules/shared/ref-custom-component-options-for-your-rhdh-instance.adoc` (REFERENCE) - Add migration notes about how PatternFly/MUI variant options interact with Backstage UI migration
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Add section on Material UI to Backstage UI migration as part of frontend system changes
  - [ ] Update `modules/shared/proc-migrate-custom-plugins-to-the-new-frontend-system.adoc` (PROCEDURE) - Add note about Material UI component migration as part of new frontend system migration
  - [ ] Create `ref-backstage-ui-migration-troubleshooting.adoc` (REFERENCE) - Common issues and solutions when migrating from Material UI to Backstage UI
- **Acceptance criteria**:
  - [ ] Plugin developers can identify which Material UI components in their custom plugins need to be replaced with Backstage UI equivalents
  - [ ] Plugin developers can successfully run the Backstage codemod migration recipes to automatically convert MUI imports to @backstage/ui imports
  - [ ] Plugin developers understand how to manually migrate components that cannot be automatically converted by codemods
  - [ ] Users understand that Red Hat-provided plugins have been migrated and require no action
  - [ ] Users can verify that their theme customization (PatternFly/MUI variants) continues to work after the migration
  - [ ] Plugin developers can find code examples for common Backstage UI components (Button, Card, Text, Box, Grid)
  - [ ] Users understand the timeline and phases of the Material UI to Backstage UI migration
  - [ ] Plugin developers can troubleshoot common migration issues using the troubleshooting reference
- **References**:
  - [RFC: New design system for Backstage](https://github.com/backstage/backstage/issues/27726): Official Backstage RFC explaining the strategic rationale for moving from Material UI to Backstage UI
  - [MUI to BUI Migration Guide](https://github.com/backstage/community-plugins/blob/main/docs/mui-to-bui-migration.md): Comprehensive migration guide with analytics tools, codemod usage, and best practices

#### REQ-007: Red Hat plugins adoption of New Frontend System
- **Source**: [RHDHPLAN-722](https://redhat.atlassian.net/browse/RHDHPLAN-722)
- **Summary**: Red Hat Developer Hub 2.1 migrates all Red Hat-owned frontend plugins to the New Frontend System (NFS), replacing the legacy Scalprum-based system with Backstage's standard module federation and extension blueprints. This includes GA plugins such as Adoption Insights, Global Header, Homepage, Lightspeed, Orchestrator, Orchestrator Form Widgets, and Quickstart, which now export extension blueprints via /alpha modules.
- **User impact**: Users upgrading to RHDH 2.1 will benefit from Red Hat plugins automatically working with the new frontend system without requiring migration. All Red Hat-provided GA frontend plugins now use extension blueprints, providing consistent behavior with improved extensibility, performance, and alignment with upstream Backstage architecture.
- **Documentation action**:
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Clarify that all Red Hat GA frontend plugins already use NFS and list specific plugin names
  - [ ] Update `modules/extend_dynamic-plugins-reference/ref-ga-plugins.adoc` (REFERENCE) - Add NFS compatibility indicator for Red Hat frontend plugins
  - [ ] Create `modules/shared/ref-red-hat-plugins-with-new-frontend-system-support.adoc` (REFERENCE) - List all Red Hat GA frontend plugins with their /alpha exports and NFS support status
- **Acceptance criteria**:
  - [ ] Documentation clearly states that all Red Hat-owned GA frontend plugins use the New Frontend System
  - [ ] Users can identify which Red Hat plugins have /alpha exports and NFS support
  - [ ] Reference documentation lists the eight Red Hat GA frontend plugins: Adoption Insights, Analytics Module Adoption Insights, Global Header, Homepage, Lightspeed, Orchestrator, Orchestrator Form Widgets, and Quickstart
  - [ ] Documentation clarifies that users do not need to migrate Red Hat plugins, only custom and community plugins
- **References**:
  - [RHDHPLAN-722](https://redhat.atlassian.net/browse/RHDHPLAN-722): Epic for adopting NFS in Red Hat plugins, closed in 1.10.0

#### REQ-008: Bridge mechanism for legacy plugin compatibility
- **Source**: [RHDHPLAN-517](https://redhat.atlassian.net/browse/RHDHPLAN-517)
- **Summary**: Red Hat Developer Hub 2.1 introduces a bridge mechanism that enables third-party legacy frontend plugins without native New Frontend System support to operate in RHDH 2.1 through the convertLegacyPlugin utility. This temporary compatibility layer wraps old frontend plugins with extension blueprints, allowing administrators to adopt RHDH 2.1 without waiting for all third-party plugin vendors to migrate. The bridge mechanism complements the three-phase migration strategy for custom plugins and the automatic configuration conversion from dynamicPlugins.frontend to app.extensions.
- **User impact**: Administrators can upgrade to RHDH 2.1 and continue using essential third-party plugins that have not yet adopted the New Frontend System, avoiding delays in platform modernization. However, administrators must manually wrap third-party plugins using conversion utilities and understand that the bridge mechanism is a temporary solution with limitations compared to natively migrated plugins.
- **Documentation action**:
  - [ ] Create `modules/shared/con-bridge-mechanism-for-legacy-plugin-compatibility.adoc` (CONCEPT) - Explain the bridge mechanism, convertLegacyPlugin utility, when to use it, and limitations
  - [ ] Create `modules/shared/proc-wrap-third-party-legacy-plugins-using-conversion-utilities.adoc` (PROCEDURE) - Step-by-step guide for wrapping legacy third-party plugins with convertLegacyPlugin and extension converters
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Add section about third-party plugin compatibility via bridge mechanism
  - [ ] Update `modules/shared/proc-migrate-custom-plugins-to-the-new-frontend-system.adoc` (PROCEDURE) - Add cross-reference distinguishing custom plugin migration from third-party plugin wrapping
- **Acceptance criteria**:
  - [ ] Administrators can identify when the bridge mechanism is appropriate versus native migration
  - [ ] Administrators can successfully wrap a legacy third-party plugin using convertLegacyPlugin
  - [ ] Administrators understand that the bridge mechanism is a temporary solution and that native migration is preferred
  - [ ] Administrators can convert legacy page extensions using convertLegacyPageExtension
  - [ ] Administrators can convert legacy entity extensions using catalog-react conversion utilities
  - [ ] Documentation clearly distinguishes between custom plugin migration (add /alpha export) and third-party plugin wrapping (use convertLegacyPlugin)
  - [ ] Documentation explains limitations of converted plugins compared to natively migrated plugins
- **References**:
  - [Converting 3rd-party plugins from the old system](https://backstage.io/docs/next/frontend-system/building-apps/plugin-conversion/): Official Backstage documentation for convertLegacyPlugin utility and extension converters

#### REQ-009: Replacement for scalprum-based plugin APIs
- **Source**: [RHDHPLAN-463](https://redhat.atlassian.net/browse/RHDHPLAN-463)
- **Summary**: Red Hat Developer Hub 2.1 removes the old frontend system and scalprum-based plugin APIs, replacing them with the Backstage New Frontend System (NFS) that uses standard module federation. Plugin developers must migrate custom plugins to use extension blueprints with /alpha exports, and update app-config.yaml from dynamicPlugins.frontend to app.extensions configuration. The rhdh-cli 2.1.0 removes all scalprum-related commands and options, generating only NFS-compatible module federation assets.
- **User impact**: Users with custom frontend plugins that have not been migrated to the New Frontend System will find their plugins fail to load in RHDH 2.1, with errors logged about missing manifests or missing /alpha exports. All scalprum-specific configuration in app-config.yaml (dynamicPlugins.frontend section) becomes invalid and must be converted to the new app.extensions format. Environment variables ENABLE_STANDARD_MODULE_FEDERATION and DISABLE_STANDARD_MODULE_FEDERATION no longer have any effect.
- **Documentation action**:
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Add deprecation notice for scalprum APIs and explicit list of removed CLI commands and package.json fields
  - [ ] Update `modules/shared/proc-migrate-custom-plugins-to-the-new-frontend-system.adoc` (PROCEDURE) - Add troubleshooting for scalprum-to-NFS migration failures and rhdh-cli 2.1 command changes
  - [ ] Update `modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc` (REFERENCE) - Expand with complete mapping table showing all removed dynamicPlugins.frontend options
  - [ ] Update `modules/shared/proc-convert-a-custom-plugin-into-a-dynamic-plugin.adoc` (PROCEDURE) - Remove references to dist-scalprum and scalprum configuration; update to show only NFS module federation output
  - [ ] Create `modules/shared/ref-removed-scalprum-apis-and-configuration.adoc` (REFERENCE) - Comprehensive list of all removed scalprum-related APIs, CLI flags, environment variables, and configuration keys with their NFS equivalents
  - [ ] Update `titles/upgrade_upgrade-rhdh/master.adoc` (ASSEMBLY) - Add reference to frontend system migration requirements for 2.1 upgrade
- **Acceptance criteria**:
  - [ ] Documentation clearly states that scalprum-based plugin APIs are removed in RHDH 2.1
  - [ ] Users can identify whether their custom plugin requires migration by checking for /alpha export
  - [ ] Complete list of removed environment variables (APP_CONFIG_app_packageName, ENABLE_STANDARD_MODULE_FEDERATION, DISABLE_STANDARD_MODULE_FEDERATION) is documented
  - [ ] Complete list of removed package.json fields (scalprum.name, scalprum.exposedModules, dist-scalprum in files array) is documented
  - [ ] Complete list of removed rhdh-cli 2.1 options (--scalprum-config, --generate-scalprum-assets, --no-generate-scalprum-assets, --generate-module-federation-assets, --no-generate-module-federation-assets) is documented
  - [ ] Migration procedure explains how to convert scalprum configuration to extension blueprints
  - [ ] Error messages (missing manifest, missing /alpha export) are documented with resolution steps
  - [ ] Configuration migration maps all dynamicPlugins.frontend keys to app.extensions equivalents
- **References**:
  - [PR #4800](https://github.com/redhat-developer/rhdh-plugins/pull/4800): Documents actual removal of scalprum from RHDH codebase

### Medium

#### REQ-005: Feature flags support from Backstage
- **Source**: [RHDHPLAN-503](https://redhat.atlassian.net/browse/RHDHPLAN-503)
- **Summary**: Red Hat Developer Hub 2.1 introduces upstream Backstage feature flags functionality, allowing plugin developers and administrators to define toggleable feature flags within plugins or applications. Users can enable or disable experimental or beta features through the Settings interface, with preferences stored in browser local storage, providing a standard mechanism for progressive feature rollout and user-controlled feature activation.
- **User impact**: Users gain the ability to selectively enable experimental or beta features through a Settings > Feature Flags interface without requiring application reconfiguration or redeployment. Plugin developers can safely introduce new functionality behind feature flags, allowing users to opt-in to unstable or incomplete features for early testing while maintaining stability for production workflows.
- **Documentation action**:
  - [ ] Create `con-feature-flags-in-rhdh.adoc` (CONCEPT) - Explain what feature flags are, how they work in RHDH, and when to use them
  - [ ] Create `proc-enable-disable-feature-flags.adoc` (PROCEDURE) - Step-by-step guide for users to toggle feature flags via Settings page
  - [ ] Create `proc-define-feature-flags-in-plugins.adoc` (PROCEDURE) - Guide for plugin developers to register feature flags in custom plugins
  - [ ] Create `proc-define-feature-flags-in-app-config.adoc` (PROCEDURE) - Configure feature flags at application level via app-config.yaml
  - [ ] Create `ref-feature-flags-api.adoc` (REFERENCE) - Document FeatureFlagsApi methods (isActive, registerFlag, getRegisteredFlags) and FeatureFlagged component usage
  - [ ] Update `proc-customize-the-rhdh-metadata-card-on-the-settings-page.adoc` (PROCEDURE) - Add cross-reference to new feature flags functionality available in Settings
- **Acceptance criteria**:
  - [ ] Users can navigate to Settings > Feature Flags and view all registered feature flags
  - [ ] Users can toggle feature flags on/off and see changes reflected after page refresh
  - [ ] Plugin developers can register feature flags by adding them to the featureFlags array when creating a plugin
  - [ ] Developers can use the FeatureFlagged component to conditionally render UI elements based on flag state
  - [ ] Developers can programmatically check feature flag state using featureFlagsApi.isActive() method
  - [ ] Application administrators can define feature flags in app-config.yaml using the createApp() featureFlags array
  - [ ] Documentation explains that feature flag preferences are stored in browser local storage
  - [ ] Documentation includes code examples for both plugin-level and application-level feature flag registration
  - [ ] Documentation clarifies compatibility with the new frontend system in RHDH 2.1
- **References**:
  - [Feature Flags | Backstage](https://backstage.io/docs/plugins/feature-flags/): Primary upstream documentation for feature flags functionality

## Documentation scope

### New documentation needed

| Requirement | Scope | References |
|-------------|-------|------------|
| REQ-001 | con-benefits-of-new-frontend-system.adoc, ref-extension-blueprint-types.adoc, proc-verify-plugin-nfs-compatibility.adoc | RHDHPLAN-192, RHDHPLAN-1187 |
| REQ-002 | proc-customize-theme-using-backstage-ui-design-tokens.adoc, con-theme-customization-approaches-in-new-frontend-system.adoc, ref-backstage-ui-design-tokens.adoc | RHDHPLAN-249 |
| REQ-003 | proc-customize-plugins-on-pages-using-app-extensions.adoc | RHDHPLAN-552, PR #4921, PR #4922 |
| REQ-004 | 2 assemblies, 4 concepts, 1 procedure, 3 references for RBAC UI visibility | RHDHPLAN-843, PR #2595 |
| REQ-005 | 4 procedures, 1 concept, 1 reference for feature flags | RHDHPLAN-503 |
| REQ-006 | 5 new modules for MUI to BUI migration | RHDHPLAN-1188 |
| REQ-007 | ref-red-hat-plugins-with-new-frontend-system-support.adoc | RHDHPLAN-722 |
| REQ-008 | con-bridge-mechanism-for-legacy-plugin-compatibility.adoc, proc-wrap-third-party-legacy-plugins-using-conversion-utilities.adoc | RHDHPLAN-517 |
| REQ-009 | ref-removed-scalprum-apis-and-configuration.adoc | RHDHPLAN-463 |

### Existing documentation to update

| Requirement | What changed | References |
|-------------|-------------|------------|
| REQ-001 | Update 4 existing modules for NFS GA status verification | RHDHPLAN-192 |
| REQ-002 | Update 4 existing modules for NFS theme capabilities | RHDHPLAN-249 |
| REQ-003 | Update 3 existing modules for dynamic plugin loading | RHDHPLAN-552 |
| REQ-004 | Update 1 assembly for RBAC UI visibility | RHDHPLAN-843 |
| REQ-005 | Update 1 procedure for feature flags cross-reference | RHDHPLAN-503 |
| REQ-006 | Update 3 existing modules for MUI to BUI migration | RHDHPLAN-1188 |
| REQ-007 | Update 2 existing references for Red Hat plugin NFS status | RHDHPLAN-722 |
| REQ-008 | Update 2 existing modules for bridge mechanism | RHDHPLAN-517 |
| REQ-009 | Update 5 existing modules for scalprum removal | RHDHPLAN-463 |

## Breaking changes

| Change | Migration steps needed | Deprecation notice | References |
|--------|------------------------|-------------------|------------|
| REQ-001: NFS exclusive frontend | Migrate custom plugins to /alpha exports, convert app-config from dynamicPlugins.frontend to app.extensions | GA in 2.1.0, legacy system removed | RHDHPLAN-1187 |
| REQ-006: MUI to BUI migration | Migrate custom plugin components from @material-ui/* to @backstage/ui | Deprecated in 2.1.0 | RHDHPLAN-1188 |
| REQ-009: Scalprum removal | Remove all scalprum configuration and rebuild plugins with rhdh-cli 2.1.0 | Deprecated in 2.1.0 | RHDHPLAN-463 |

## Notes

This is a major architectural transformation for RHDH 2.1, marking the General Availability of the New Frontend System and complete removal of the legacy Scalprum-based architecture. The change affects all frontend plugins and requires user action before upgrade. Red Hat-provided plugins are pre-migrated. Substantial documentation already exists from Developer Preview phases, requiring verification for GA completeness rather than new authoring. JIRA API encountered PropertyHolder serialization issues for several tickets, but related tickets, pull requests, and existing documentation provided sufficient context for requirements analysis.

## Related tickets

### Parent/Ancestors
- None (RHDHPLAN-192 is the top-level outcome)

### Children
- [RHDHPLAN-249](https://redhat.atlassian.net/browse/RHDHPLAN-249): Improve Backstage UI theme and allow customers to customize it
- [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552): Be able to customize the plugins on any pages in RHDH
- [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187): GA support for the New Frontend System (NFS) in RHDH 2.1
- [RHDHPLAN-503](https://redhat.atlassian.net/browse/RHDHPLAN-503): Feature Flag feature from Backstage should be available in RHDH
- [RHDHPLAN-843](https://redhat.atlassian.net/browse/RHDHPLAN-843): RBAC Fine-Grained Visibility Control for Pages, Tabs, and Navigation Elements
- [RHDHPLAN-1188](https://redhat.atlassian.net/browse/RHDHPLAN-1188): Phase 1 - Migrate Backstage plugins from Material UI to Backstage UI
- [RHDHPLAN-463](https://redhat.atlassian.net/browse/RHDHPLAN-463): Prepare a replacement for scalprum-based plugin-targeted APIs
- [RHDHPLAN-489](https://redhat.atlassian.net/browse/RHDHPLAN-489): New Frontend System available in RHDH builds
- [RHDHPLAN-517](https://redhat.atlassian.net/browse/RHDHPLAN-517): Define a bridge mechanism to ingest old frontend plugins and config
- [RHDHPLAN-690](https://redhat.atlassian.net/browse/RHDHPLAN-690): Assess Adopting New Frontend System for different plugins
- [RHDHPLAN-722](https://redhat.atlassian.net/browse/RHDHPLAN-722): Adopt New Frontend System in all Red Hat owned and GA frontend plugins

### Linked tickets
- [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656): Make user-settings page extendable and allow plugins (and partners) to customize it
- [RHIDP-7095](https://redhat.atlassian.net/browse/RHIDP-7095): remove janus-idp/cli

## Sources consulted

### JIRA tickets
- [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Base RHDH frontend on the upstream new frontend system
- [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187): GA support for the New Frontend System (NFS) in RHDH 2.1
- [RHDHPLAN-843](https://redhat.atlassian.net/browse/RHDHPLAN-843): RBAC Fine-Grained Visibility Control
- [RHDHPLAN-249](https://redhat.atlassian.net/browse/RHDHPLAN-249): Improve Backstage UI theme customization
- [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552): Customize plugins on any pages
- [RHDHPLAN-503](https://redhat.atlassian.net/browse/RHDHPLAN-503): Feature Flag feature from Backstage
- [RHDHPLAN-1188](https://redhat.atlassian.net/browse/RHDHPLAN-1188): Phase 1 - Migrate from Material UI to Backstage UI
- [RHDHPLAN-722](https://redhat.atlassian.net/browse/RHDHPLAN-722): Adopt NFS in Red Hat plugins
- [RHDHPLAN-489](https://redhat.atlassian.net/browse/RHDHPLAN-489): NFS available in RHDH builds
- [RHDHPLAN-517](https://redhat.atlassian.net/browse/RHDHPLAN-517): Bridge mechanism for old plugins
- [RHDHPLAN-690](https://redhat.atlassian.net/browse/RHDHPLAN-690): Assess NFS adoption for plugins
- [RHDHPLAN-463](https://redhat.atlassian.net/browse/RHDHPLAN-463): Replacement for scalprum APIs

### Pull requests / Merge requests
- [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921): Remove home plugin from app-next
- [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922): Remove static plugins from app-next
- [PR #2595](https://github.com/redhat-developer/red-hat-developers-documentation-rhdh/pull/2595): RBAC UI visibility documentation
- [PR #2068](https://github.com/redhat-developer/red-hat-developers-documentation-rhdh/pull/2068): RBAC UI visibility (main branch)
- [PR #4800](https://github.com/redhat-developer/rhdh-plugins/pull/4800): Remove Scalprum export metadata

### Code files
- modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc
- modules/shared/proc-migrate-custom-plugins-to-the-new-frontend-system.adoc
- modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc
- assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc
- modules/shared/con-dynamic-front-end-plugins-for-application-use.adoc

### Existing documentation
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-front-end-plugin-wiring.adoc
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-using-mount-points.adoc
- assemblies/configure_customizing-rhdh/assembly-customize-rhdh-theme-and-branding.adoc
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-extensions-in-rhdh.adoc
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-understanding-front-end-plugin-wiring.adoc

### External references
- [The Frontend System | Backstage](https://backstage.io/docs/frontend-system/)
- [Migrating Plugins | Backstage](https://backstage.io/docs/frontend-system/building-plugins/migrating/)
- [Migrating Apps | Backstage](https://backstage.io/docs/frontend-system/building-apps/migrating/)
- [Backstage UI - Tokens](https://ui.backstage.io/tokens)
- [Feature Flags | Backstage](https://backstage.io/docs/plugins/feature-flags/)
- [RFC: New design system for Backstage](https://github.com/backstage/backstage/issues/27726)
- [MUI to BUI Migration Guide](https://github.com/backstage/community-plugins/blob/main/docs/mui-to-bui-migration.md)
- [Converting 3rd-party plugins from the old system](https://backstage.io/docs/next/frontend-system/building-apps/plugin-conversion/)
- [Backstage Permissions Overview](https://backstage.io/docs/permissions/overview/)
- [Backstage Frontend Authorization](https://backstage.io/docs/permissions/plugin-authors/05-frontend-authorization/)

### Web search findings
(Deduplicated findings from all requirements - see individual requirement references for complete list)
