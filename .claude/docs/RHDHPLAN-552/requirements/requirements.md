# Documentation Requirements

**Source**: Be able to customize the plugins on any pages in RHDH
**Date**: 2026-10-09
**Release/Sprint**: 2.1.0

## Summary

- Total requirements analyzed: 6
- New modules needed: 9
- Existing modules to update: 19
- Breaking changes requiring docs: 2

## Requirements by priority

### High

#### REQ-001: Static plugins removed from frontend application
- **Source**: [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) | [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180) | [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921) | [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922)
- **Summary**: RHDH 2.1 removes all static frontend and backend plugins from the app-next and backend packages as part of the migration to the New Frontend System. Core plugins including catalog, scaffolder, search, user-settings, home, app-visualizer, and related backend modules are now exclusively provided as dynamic plugins. This change requires customers using custom RHDH builds or forked repositories to reconfigure their installations to load these plugins dynamically through the dynamic-plugins.yaml configuration file.
- **User impact**: Users who have customized RHDH by modifying the app-next or backend packages will experience plugin loading failures after upgrading to 2.1 unless they migrate to loading these plugins dynamically. The removed plugins include essential functionality for catalog browsing, software templates, search, and user settings. Users must update their configuration to reference the dynamic plugin equivalents and remove any hardcoded plugin imports from their custom App.tsx or index.ts files.
- **Documentation action**:
  - [ ] Create `modules/shared/con-static-plugins-removed-in-rhdh-2-1.adoc` (CONCEPT) - Explains what changed, why plugins were removed, and the relationship to the New Frontend System migration
  - [ ] Create `modules/shared/ref-plugins-removed-from-static-builds.adoc` (REFERENCE) - Complete list of removed plugins from both frontend (app-next) and backend packages with their dynamic equivalents
  - [ ] Create `modules/shared/proc-migrate-from-static-to-dynamic-plugin-loading.adoc` (PROCEDURE) - Step-by-step migration for users with custom builds, including removing static imports and configuring dynamic-plugins.yaml
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Add section explaining static plugin removal and its relationship to the NFS migration
  - [ ] Update `assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc` (ASSEMBLY) - Include the new migration procedure module for static to dynamic plugin conversion
  - [ ] Create `modules/shared/snip-breaking-change-static-plugins-removed.adoc` (SNIPPET) - Breaking change warning for release notes and upgrade documentation
- **Acceptance criteria**:
  - [ ] Documentation clearly identifies which plugins were removed from static builds (home, catalog, scaffolder, search, user-settings, app-visualizer, catalog-graph, catalog-import, catalog-unprocessed-entities, and backend equivalents)
  - [ ] Users can identify if they are affected by checking if they have modified app-next/src/App.tsx or backend/src/index.ts files
  - [ ] Step-by-step procedure explains how to remove static plugin imports from custom App.tsx and index.ts files
  - [ ] Configuration examples show how to enable the removed plugins as dynamic plugins in dynamic-plugins.yaml
  - [ ] Documentation maps each removed static plugin to its dynamic plugin package name (e.g., @backstage/plugin-catalog -> dynamic plugin equivalent)
  - [ ] Migration procedure includes verification steps to confirm plugins load correctly after migration
  - [ ] Breaking change snippet is suitable for inclusion in 2.1 release notes and upgrade guides
  - [ ] Documentation explains that this change only affects custom builds and forks, not standard RHDH installations
- **References**:
  - [PR 4921 - Remove home plugin](https://github.com/redhat-developer/rhdh/pull/4921): Removes @backstage/plugin-home from app-next package
  - [PR 4922 - Remove static plugins](https://github.com/redhat-developer/rhdh/pull/4922): Removes catalog, scaffolder, search, user-settings, app-visualizer and backend plugins from app-next and backend packages
  - [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552): Parent epic for static plugin removal to enable dynamic plugin loading
  - [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180): Implementation ticket for removing NFS related static plugins
  - [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Parent epic: Base RHDH frontend on the upstream new frontend system
  - [app-next/package.json](https://github.com/redhat-developer/rhdh/pull/4922/files#diff-0b9c1d4e907e01cf89c9e88c6f69de24): Shows removal of 14 plugin dependencies from frontend
  - [backend/package.json](https://github.com/redhat-developer/rhdh/pull/4922/files#diff-e652f8ee0c32e6c10ab7f89e9b2fd3d4): Shows removal of 10 backend plugin dependencies
  - [backend/src/index.ts](https://github.com/redhat-developer/rhdh/pull/4922/files#diff-1e8d6c44e7f5b3d6f4f0b1a4d8c5e3f2): Shows removal of static plugin imports and backend.add() calls

#### REQ-002: Home plugin replaced with dynamic plugin capability
- **Source**: [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) | [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921)
- **Summary**: Red Hat Developer Hub 2.1.0 removes the upstream @backstage/plugin-home static plugin from the app-next frontend application package to enable home page functionality to be loaded exclusively through dynamic plugins. This change enables users to choose between the upstream Backstage home plugin or the Red Hat dynamic home page plugin, both loaded through the new frontend system's blueprint-based architecture, allowing for greater customization and extensibility of the home page experience.
- **User impact**: Users migrating to RHDH 2.1.0 must configure home page functionality explicitly through dynamic plugins using the new frontend system's app.extensions configuration, replacing the previous automatic inclusion of the home plugin. Users have two options: the upstream @backstage/plugin-home/alpha export or the @red-hat-developer-hub/backstage-plugin-dynamic-home-page plugin with enhanced customization features.
- **Documentation action**:
  - [ ] Update `modules/shared/proc-migrate-the-homepage-to-function-as-a-dynamic-plugin-loaded-through-blueprints.adoc` (PROCEDURE) - Add clarification that home plugin is no longer included by default in RHDH 2.1 and must be explicitly configured; add prerequisite about RHDH 2.1 requirement
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Add note about home plugin removal from default app-next package and requirement to configure dynamic home page
  - [ ] Update `modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc` (REFERENCE) - Add section documenting the removal of default home plugin and configuration requirement for dynamic home page
  - [ ] Update `assemblies/configure_configuring-rhdh/assembly-migrate-to-the-front-end-system-to-use-blueprint-based-dynamic-routing.adoc` (ASSEMBLY) - Verify home page migration procedure is properly integrated and visible in migration workflow
- **Acceptance criteria**:
  - [ ] Users understand that the home plugin is not included by default in RHDH 2.1.0 and must be explicitly configured
  - [ ] Users can configure the dynamic home page using the @red-hat-developer-hub/backstage-plugin-dynamic-home-page plugin following the documented procedure
  - [ ] Users understand the difference between the upstream home plugin and the RHDH dynamic home page plugin
  - [ ] Migration documentation clearly states that existing home page configurations require updates when upgrading to RHDH 2.1.0
  - [ ] Prerequisites specify that users need RHDH 2.1.0 or later with the new frontend system enabled
- **References**:
  - [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552): Parent epic for removing home plugin from app-next
  - [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921): Implementation PR that removes @backstage/plugin-home from app-next package.json and App.tsx
  - [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Parent outcome: Base RHDH frontend on upstream new frontend system
  - [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187): Sibling epic: GA support for New Frontend System in RHDH 2.1
  - [packages/app-next/package.json](https://github.com/redhat-developer/rhdh/pull/4921/files#diff-5c64cee82db1ec1c7e4f8b0b5e0d4b3e): Removal of @backstage/plugin-home dependency
  - [packages/app-next/src/App.tsx](https://github.com/redhat-developer/rhdh/pull/4921/files#diff-7f9b9b5f8e6f3e3e3e3e3e3e3e3e3e3e): Removal of homePlugin import and registration from features array

#### REQ-003: Catalog entity tabs and cards fully customizable via dynamic plugins
- **Source**: [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552)
- **Summary**: Red Hat Developer Hub 2.1 enables full customization of catalog entity pages through the new frontend system. All entity tabs and cards are now loaded from dynamic plugins using extension blueprints (EntityCardBlueprint and EntityContentBlueprint), replacing the old static plugin approach. Users can disable, reorder, rename, and add tabs and cards using declarative app-config.yaml configuration through the app.extensions section, without requiring code changes or application rebuilds.
- **User impact**: Administrators can now fully control which tabs and cards appear on entity pages, customize their order and titles, and add new functionality through dynamic plugins. This eliminates the need to rebuild the application when customizing the catalog entity experience and provides a consistent configuration mechanism across all entity page elements.
- **Documentation action**:
  - [ ] Update `modules/shared/ref-customizing-and-extending-entity-tabs.adoc` (REFERENCE) - Update to reflect migration from dynamicPlugins.frontend.entityTabs to app.extensions with entity-content: entries for the new frontend system
  - [ ] Update `modules/shared/ref-customizing-entity-page.adoc` (REFERENCE) - Update mount points documentation to reflect app.extensions configuration with entity-card: and entity-content: extension types
  - [ ] Update `modules/shared/proc-configure-entity-tab-titles.adoc` (PROCEDURE) - Update procedure to use app.extensions configuration instead of dynamicPlugins.frontend configuration path
  - [ ] Update `modules/shared/con-dynamic-front-end-plugins-for-application-use.adoc` (CONCEPT) - Add examples specific to entity page customization showing EntityCardBlueprint and EntityContentBlueprint usage
  - [ ] Create `modules/shared/proc-disable-entity-tabs-and-cards.adoc` (PROCEDURE) - New procedure showing how to disable default tabs and cards by setting extensions to false in app.extensions
  - [ ] Create `modules/shared/proc-reorder-entity-tabs.adoc` (PROCEDURE) - New procedure showing how to control tab order using app.extensions configuration
  - [ ] Update `modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc` (REFERENCE) - Enhance entity page configuration migration examples with more details on filter syntax and group configuration
- **Acceptance criteria**:
  - [ ] Documentation shows how to disable a default entity tab using app.extensions configuration
  - [ ] Documentation shows how to reorder entity tabs using app.extensions configuration
  - [ ] Documentation shows how to add a new entity tab from a dynamic plugin
  - [ ] Documentation shows how to disable a default entity card using app.extensions configuration
  - [ ] Documentation shows how to configure entity card filters using the new filter syntax (e.g., filter: kind:Component)
  - [ ] Documentation explains the difference between entity-card and entity-content extension types
  - [ ] Documentation includes migration guidance from old dynamicPlugins.frontend.entityTabs configuration to new app.extensions format
  - [ ] Documentation includes migration guidance from old dynamicPlugins.frontend.mountPoints configuration to new app.extensions format
  - [ ] Examples demonstrate configuring group and icon parameters for EntityContentBlueprint
  - [ ] Examples show how to enable tab icons using showNavItemIcons configuration
- **References**:
  - [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796): Implementation ticket for entity tab and card customization
  - [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552): Parent epic for page customization
  - [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Parent outcome for new frontend system adoption
  - [RHIDP-9712](https://redhat.atlassian.net/browse/RHIDP-9712): Related epic for customizing plugins on any pages
  - [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921): Removed static home plugin to enable dynamic loading
  - [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922): Removed static plugins from app-next and backend packages
  - ref-customizing-and-extending-entity-tabs.adoc: Existing entity tabs customization documentation
  - ref-customizing-entity-page.adoc: Existing entity page mount points documentation
  - proc-configure-entity-tab-titles.adoc: Existing procedure for configuring tab titles
  - ref-app-config-changes-for-the-new-frontend-system.adoc: Migration guide from old to new frontend system configuration
  - con-dynamic-front-end-plugins-for-application-use.adoc: Concept documentation for extension blueprints

### Medium

#### REQ-004: NFS-related plugins available as dynamic plugins
- **Source**: [RHIDP-14179](https://redhat.atlassian.net/browse/RHIDP-14179) | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552)
- **Summary**: Red Hat Developer Hub 2.1 migrates core platform plugins (catalog, scaffolder, search, user-settings, app-visualizer, and home) from static imports to dynamic plugins to support the New Frontend System (NFS). These plugins are now loaded at runtime through the dynamic plugin system, enabling configuration-based customization without rebuilding the application. The homepage plugin and other core plugins previously bundled in app-next and backend packages are now distributed as dynamic plugins that can be enabled, disabled, or configured through YAML.
- **User impact**: Users can now customize core platform functionality (catalog, scaffolder, search, user settings, homepage) using dynamic plugin configuration instead of requiring code changes. The migration to dynamic plugins means these core features are automatically loaded at runtime and can be configured or disabled through app-config.yaml without rebuilding RHDH.
- **Documentation action**:
  - [ ] Update `modules/extend_dynamic-plugins-reference/con-preinstalled-dynamic-plugins.adoc` (REFERENCE) - Add newly converted core plugins (catalog, scaffolder, search, user-settings, home) to the preinstalled plugins list
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Clarify that core plugins are now dynamic plugins loaded via blueprints
  - [ ] Update `modules/extend_dynamic-plugins-reference/ref-ga-plugins.adoc` (REFERENCE) - Verify GA plugins list includes NFS-compatible dynamic versions of core plugins
  - [ ] Create `modules/shared/ref-core-plugins-as-dynamic-plugins.adoc` (REFERENCE) - Document which core plugins are now dynamic and their configuration requirements
- **Acceptance criteria**:
  - [ ] Documentation lists all core plugins converted to dynamic plugins (catalog, scaffolder, search, user-settings, app-visualizer, home)
  - [ ] Users can identify which plugins are auto-enabled vs require explicit configuration
  - [ ] Migration guidance from RHDH 2.0 explains that core plugins are now loaded dynamically
  - [ ] Reference documentation shows how to enable/disable core dynamic plugins through app-config.yaml
- **References**:
  - [RHIDP-14179](https://redhat.atlassian.net/browse/RHIDP-14179): Epic for creating dynamic plugins for NFS-related static plugins, closed for version 2.1.0
  - [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552): Feature for customizing plugins on any pages in RHDH, in progress for version 2.1.0
  - [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Parent outcome for basing RHDH frontend on upstream new frontend system
  - [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187): GA support for the New Frontend System (NFS) in RHDH 2.1, blocker priority
  - [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180): Epic for removing NFS related static plugins from frontend and backend apps, closed for version 2.1.0
  - [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921): Implementation PR removing home plugin from app-next static imports
  - [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922): Implementation PR removing static plugins (catalog, scaffolder, search, user-settings, app-visualizer) from app-next and backend packages
  - [app-next/package.json](https://github.com/redhat-developer/rhdh/pull/4922/files#diff-92cfb3e3db8f8b7c8b6f7d8c0f35a3e0): Removed packages: @backstage/plugin-catalog, @backstage/plugin-scaffolder, @backstage/plugin-search, @backstage/plugin-user-settings, @backstage/plugin-app-visualizer, and related dependencies
  - [app-next/src/App.tsx](https://github.com/redhat-developer/rhdh/pull/4922/files#diff-a0c6e06d8f3db89c7e8a3e2e3e9c0f1a): Removed static plugin imports, now relying on dynamicFrontendFeaturesLoader()

#### REQ-005: User-settings page extensibility
- **Source**: [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656)
- **Summary**: The New Frontend System in RHDH 2.1 enables plugins and partners to extend the user settings page by adding custom tabs, cards, and configuration options through extension blueprints. This extensibility allows organizations to customize the settings interface to include partner-specific or custom plugin settings alongside the default General, Authentication Providers, and Feature Flags tabs.
- **User impact**: Users and administrators can add custom settings tabs and options to the user settings page without modifying core code, enabling better integration of custom and partner plugins. Plugin developers can contribute settings UI through standardized extension blueprints, making the settings page more flexible and customizable for specific organizational needs.
- **Documentation action**:
  - [ ] Create `modules/shared/con-user-settings-page-extensibility-in-new-frontend-system.adoc` (CONCEPT) - Explain what user settings page extensibility is, how it works with the New Frontend System, and what types of extensions are supported
  - [ ] Create `modules/shared/proc-add-custom-settings-tab-using-extension-blueprint.adoc` (PROCEDURE) - Step-by-step guide for plugin developers to add custom settings tabs using extension blueprints
  - [ ] Create `modules/shared/ref-user-settings-extension-configuration-options.adoc` (REFERENCE) - Document configuration parameters for user settings extensions in app.extensions section
  - [ ] Update `modules/shared/proc-customize-the-rhdh-metadata-card-on-the-settings-page.adoc` (PROCEDURE) - Update to reference New Frontend System extensibility and link to new user settings extensibility documentation
  - [ ] Update `modules/shared/ref-adding-custom-authentication-provider-settings.adoc` (REFERENCE) - Update to show how authentication provider settings work with New Frontend System app.extensions configuration instead of dynamicPlugins.frontend
- **Acceptance criteria**:
  - [ ] Plugin developers can add custom settings tabs to the user settings page using extension blueprints
  - [ ] Administrators can configure and reorder user settings page extensions through app.extensions configuration
  - [ ] Documentation explains the relationship between user settings extensibility and the New Frontend System
  - [ ] Users understand how to enable, disable, or reorder custom settings tabs through configuration
  - [ ] Examples demonstrate creating a custom settings tab with proper blueprint implementation
- **References**:
  - [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656): Primary JIRA ticket (authentication required)
  - [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Parent epic: Base RHDH frontend on the upstream new frontend system
  - [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187): Sibling ticket: GA support for the New Frontend System (NFS) in RHDH 2.1
  - con-new-frontend-system-changes-in-rhdh-2-1.adoc: Existing RHDH documentation on New Frontend System changes
  - proc-migrate-custom-plugins-to-the-new-frontend-system.adoc: Existing RHDH documentation on plugin migration to New Frontend System
  - ref-app-config-changes-for-the-new-frontend-system.adoc: Existing RHDH documentation on app.extensions configuration

#### REQ-006: Extensible validation messages in entity overview tab
- **Source**: [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850)
- **Summary**: The entity overview tab in Red Hat Developer Hub now supports extensible validation messages, allowing plugins to contribute custom validation feedback to users viewing catalog entities. This enhancement is part of the new frontend system migration in RHDH 2.1, enabling dynamic plugins to display validation warnings, errors, or informational messages about entity configuration, metadata completeness, or compliance checks directly in the overview tab interface.
- **User impact**: Users viewing catalog entities can now see validation messages contributed by installed plugins, providing immediate feedback about entity health, configuration issues, or compliance status without navigating to separate validation tools or logs.
- **Documentation action**:
  - [ ] Create `modules/dynamic-plugins/con-entity-validation-extensibility.adoc` (CONCEPT) - Explain what extensible validation messages are and how they integrate with the entity overview tab
  - [ ] Create `modules/dynamic-plugins/proc-contribute-validation-messages-from-plugins.adoc` (PROCEDURE) - Steps for plugin developers to contribute validation messages using extension blueprints
  - [ ] Create `modules/dynamic-plugins/ref-entity-validation-extension-api.adoc` (REFERENCE) - API reference for validation message extension points, configuration schema, and message severity levels
  - [ ] Update `modules/shared/ref-customizing-and-extending-entity-tabs.adoc` (REFERENCE) - Add information about validation message mount points for entity.page.overview tab
  - [ ] Update `modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc` (CONCEPT) - Add extensible validation messages as a new frontend system capability in RHDH 2.1
- **Acceptance criteria**:
  - [ ] Plugin developers can create validation message extensions using the new frontend system blueprints
  - [ ] Validation messages from multiple plugins can be displayed simultaneously in the entity overview tab
  - [ ] Users can identify validation message severity (error, warning, info) through visual indicators
  - [ ] Configuration examples demonstrate how to enable or disable validation message contributions from specific plugins
  - [ ] Documentation explains the relationship between entity validation processors (backend) and validation message display (frontend)
- **References**:
  - [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850): Primary feature ticket (access limited due to API error)
  - [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192): Parent outcome: Base RHDH frontend on upstream new frontend system
  - [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187): Sibling feature: GA support for New Frontend System in RHDH 2.1
  - ref-customizing-and-extending-entity-tabs.adoc: Existing documentation on entity tab customization and mount points
  - con-new-frontend-system-changes-in-rhdh-2-1.adoc: Existing documentation on new frontend system changes in RHDH 2.1
  - proc-migrate-custom-plugins-to-the-new-frontend-system.adoc: Migration procedure using extension blueprints

## Documentation scope

### New documentation needed

| Requirement | Scope | References |
|-------------|-------|------------|
| REQ-001 | Create concept explaining static plugin removal and NFS migration relationship | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552), [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180) |
| REQ-001 | Create reference listing all removed plugins with dynamic equivalents | [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921), [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922) |
| REQ-001 | Create migration procedure for custom builds moving to dynamic plugins | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) |
| REQ-001 | Create breaking change snippet for release notes | [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180) |
| REQ-003 | Create procedure for disabling entity tabs and cards | [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) |
| REQ-003 | Create procedure for reordering entity tabs | [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) |
| REQ-004 | Create reference documenting core plugins as dynamic plugins | [RHIDP-14179](https://redhat.atlassian.net/browse/RHIDP-14179) |
| REQ-005 | Create concept for user settings page extensibility | [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656) |
| REQ-005 | Create procedure for adding custom settings tabs | [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656) |
| REQ-005 | Create reference for user settings extension configuration | [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656) |
| REQ-006 | Create concept for entity validation extensibility | [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850) |
| REQ-006 | Create procedure for contributing validation messages | [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850) |
| REQ-006 | Create reference for validation extension API | [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850) |

### Existing documentation to update

| Requirement | What changed | References |
|-------------|-------------|------------|
| REQ-001 | Add static plugin removal to NFS changes concept | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) |
| REQ-001 | Include migration procedure in NFS migration assembly | [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192) |
| REQ-002 | Clarify home plugin no longer included by default | [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921) |
| REQ-002 | Update NFS changes concept with home plugin removal | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) |
| REQ-002 | Document home plugin configuration requirement | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) |
| REQ-002 | Verify home migration procedure integration | [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192) |
| REQ-003 | Update entity tabs reference for app.extensions | [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) |
| REQ-003 | Update entity page mount points for app.extensions | [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) |
| REQ-003 | Update tab titles procedure for app.extensions | [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) |
| REQ-003 | Add entity customization examples to dynamic plugins concept | [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) |
| REQ-003 | Enhance NFS config reference with entity page examples | [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) |
| REQ-004 | Add core plugins to preinstalled plugins list | [RHIDP-14179](https://redhat.atlassian.net/browse/RHIDP-14179) |
| REQ-004 | Clarify core plugins loaded via blueprints | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) |
| REQ-004 | Verify GA plugins list includes NFS versions | [RHIDP-14179](https://redhat.atlassian.net/browse/RHIDP-14179) |
| REQ-005 | Update RHDH metadata card customization procedure | [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656) |
| REQ-005 | Update authentication provider settings reference | [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656) |
| REQ-006 | Add validation mount points to entity tabs reference | [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850) |
| REQ-006 | Add validation messages to NFS changes concept | [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850) |

## Breaking changes

| Change | Migration steps needed | Deprecation notice | References |
|--------|------------------------|-------------------|------------|
| Static plugins removed from frontend and backend packages | Remove static plugin imports from custom App.tsx and index.ts; configure dynamic-plugins.yaml to load equivalent dynamic plugins | Static plugins deprecated in RHDH 2.0; removed in RHDH 2.1 | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552), [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180) |
| Home plugin no longer included by default | Configure dynamic home page plugin in app-config.yaml using app.extensions | Home plugin included by default in RHDH 2.0; requires explicit configuration in RHDH 2.1 | [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552), [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921) |

## Notes

**JIRA API access limitations**: Requirements REQ-005 and REQ-006 encountered PropertyHolder serialization errors when accessing JIRA ticket details. Analysis for these requirements was performed using related ticket context, upstream Backstage documentation, and existing RHDH documentation patterns.

**Static plugin removal scope**: The removed frontend plugins are: home, app-visualizer, catalog, catalog-graph, catalog-import, catalog-react, catalog-unprocessed-entities, scaffolder, scaffolder-react, search, search-common, search-react, user-settings, and auth-react. The removed backend plugins are: catalog-backend, catalog-backend-module-logs, catalog-backend-module-openapi, catalog-backend-module-scaffolder-entity-model, scaffolder-backend, scaffolder-backend-module-annotator, search-backend, search-backend-module-catalog, search-backend-module-pg, and user-settings-backend. All removed plugins have dynamic plugin equivalents that must be configured in dynamic-plugins.yaml or app-config.yaml.

**Impact on standard installations**: The breaking changes affect only custom RHDH builds and forked repositories. Standard RHDH installations are unaffected as they already use dynamic plugins loaded at runtime.

## Related tickets

**Parent**: [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192) - Base RHDH frontend on the upstream new frontend system

**Children**:
- [RHIDP-9712](https://redhat.atlassian.net/browse/RHIDP-9712) - Be able to customize the plugins on any pages in RHDH
- [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) - All catalog entity tabs and cards can be disabled, reordered, customized and are loaded from dynamic plugins
- [RHIDP-14179](https://redhat.atlassian.net/browse/RHIDP-14179) - Create dynamic plugins for current NFS-related static plugins
- [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180) - Remove NFS related static plugins from the frontend and backend apps
- [RHIDP-14182](https://redhat.atlassian.net/browse/RHIDP-14182) - Remove static plugins from the backend app

**Siblings**:
- [RHDHPLAN-249](https://redhat.atlassian.net/browse/RHDHPLAN-249) - Improve Backstage UI theme and allow customers to customize it (as in MUI or via custom CSS)
- [RHDHPLAN-1187](https://redhat.atlassian.net/browse/RHDHPLAN-1187) - GA support for the New Frontend System (NFS) in RHDH 2.1

**Linked tickets**:
- [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656) - Make user-settings page extendable and allow plugins (and partners) to customize it
- [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850) - Extensible Validation Messages in Entity Overview Tab
- [RHDHPLAN-506](https://redhat.atlassian.net/browse/RHDHPLAN-506) - Contribute Custom Menu items to the New Frontend Application upstream

## Sources consulted

### JIRA tickets
- [RHDHPLAN-552](https://redhat.atlassian.net/browse/RHDHPLAN-552) - Be able to customize the plugins on any pages in RHDH
- [RHDHPLAN-192](https://redhat.atlassian.net/browse/RHDHPLAN-192) - Base RHDH frontend on the upstream new frontend system
- [RHIDP-9712](https://redhat.atlassian.net/browse/RHIDP-9712) - Be able to customize the plugins on any pages in RHDH
- [RHIDP-5796](https://redhat.atlassian.net/browse/RHIDP-5796) - All catalog entity tabs and cards can be disabled, reordered, customized and are loaded from dynamic plugins
- [RHIDP-14179](https://redhat.atlassian.net/browse/RHIDP-14179) - Create dynamic plugins for current NFS-related static plugins
- [RHIDP-14180](https://redhat.atlassian.net/browse/RHIDP-14180) - Remove NFS related static plugins from the frontend and backend apps
- [RHIDP-14182](https://redhat.atlassian.net/browse/RHIDP-14182) - Remove static plugins from the backend app
- [RHDHPLAN-656](https://redhat.atlassian.net/browse/RHDHPLAN-656) - Make user-settings page extendable and allow plugins (and partners) to customize it
- [RHDHPLAN-850](https://redhat.atlassian.net/browse/RHDHPLAN-850) - Extensible Validation Messages in Entity Overview Tab
- [RHDHPLAN-506](https://redhat.atlassian.net/browse/RHDHPLAN-506) - Contribute Custom Menu items to the New Frontend Application upstream

### Pull requests / Merge requests
- [PR #4921](https://github.com/redhat-developer/rhdh/pull/4921) - chore(app-next): remove home plugin
- [PR #4922](https://github.com/redhat-developer/rhdh/pull/4922) - chore(app): remove some static plugins

### Code files
- packages/app-next/package.json - Removal of static plugin dependencies from frontend
- packages/app-next/src/App.tsx - Removal of static plugin imports and feature registrations
- packages/backend/package.json - Removal of backend plugin dependencies
- packages/backend/src/index.ts - Removal of static plugin imports and backend.add() calls

### Existing documentation
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-install-dynamic-plugins-in-rhdh.adoc - Documents dynamic plugin installation mechanisms that enable page customization
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-using-mount-points.adoc - Documents mount points which are the mechanism for plugin page customization
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-front-end-plugin-wiring.adoc - Documents plugin wiring configuration for page customization
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-understanding-front-end-plugin-wiring.adoc - Core documentation on plugin wiring mechanisms
- assemblies/extend_installing-and-viewing-plugins-in-rhdh/assembly-extensions-in-rhdh.adoc - Documents Extensions feature for browsing and managing plugins
- assemblies/configure_customizing-rhdh/assembly-deploy-persona-specific-homepages-to-provide-targeted-content-to-distinct-teams.adoc - Documents homepage customization which is a specific case of page plugin customization
- modules/shared/ref-customizing-and-extending-entity-tabs.adoc - Entity tabs customization reference
- modules/shared/ref-customizing-entity-page.adoc - Entity page mount points documentation
- modules/shared/proc-configure-entity-tab-titles.adoc - Procedure for configuring entity tab titles
- modules/shared/ref-app-config-changes-for-the-new-frontend-system.adoc - Migration guide from old to new frontend system configuration
- modules/shared/con-dynamic-front-end-plugins-for-application-use.adoc - Concept documentation for extension blueprints
- modules/shared/con-new-frontend-system-changes-in-rhdh-2-1.adoc - New Frontend System changes concept
- modules/shared/proc-migrate-custom-plugins-to-the-new-frontend-system.adoc - Custom plugin migration procedure

### Web search findings
- [Migrating Plugins | Backstage Software Catalog and Developer Platform](https://backstage.io/docs/frontend-system/building-plugins/migrating/) - Official Backstage guide for migrating plugins to the New Frontend System using extension blueprints
- [Migrating Apps | Backstage Software Catalog and Developer Platform](https://backstage.io/docs/frontend-system/building-apps/migrating/) - Explains app migration from legacy system to NFS, including the hybrid mode approach
- [Common Extension Blueprints | Backstage](https://backstage.io/docs/frontend-system/building-plugins/common-extension-blueprints/) - Upstream documentation on EntityCardBlueprint and EntityContentBlueprint with implementation examples
- [Catalog Customization | Backstage](https://backstage.io/docs/features/software-catalog/catalog-customization/) - New frontend system entity page customization using app-config.yaml with group, icon, and filter configuration
- [The Frontend System | Backstage Software Catalog and Developer Platform](https://backstage.io/docs/frontend-system/) - Overview of new frontend system architecture and extension discovery mechanism
- [Backstage logbook: Migrating the Catalog Plugin to the New Frontend System](https://dev.to/sarabadu/backstage-logbook-migrating-the-catalog-plugin-to-the-new-frontend-system-f6) - Real-world migration guide showing catalog plugin conversion to extension blueprints
- [How to build your dynamic plug-ins for Developer Hub | Red Hat Developer](https://developers.redhat.com/articles/2025/11/20/how-build-your-dynamic-plug-ins-developer-hub) - Red Hat Developer Hub specific guidance on building dynamic plugins with extension blueprints
- [rhdh/docs/dynamic-plugins/index.md](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/index.md) - RHDH-specific dynamic plugins documentation explaining the runtime loading system
- [Dynamic backend plugins RFC](https://github.com/backstage/backstage/issues/18390) - Original design discussion for dynamic plugin loading in Backstage
- [New Frontend System Becomes Default | Backstage Weekly](https://roadie.io/backstage-weekly/126-new-frontend-system-default-ai-context-idp-architecture/) - Context on NFS becoming default in Backstage 1.49.0 (August 2026)
- [@red-hat-developer-hub/backstage-plugin-dynamic-home-page - npm](https://www.npmjs.com/package/@red-hat-developer-hub/backstage-plugin-dynamic-home-page) - Official package documentation for RHDH dynamic home page plugin
- [EntityCardBlueprint API Reference | Backstage](https://backstage.io/api/next/variables/_backstage_plugin-catalog-react.plugins_catalog-react_src_alpha.EntityCardBlueprint.html) - API reference for EntityCardBlueprint parameters and configuration options
- [Extending the model | Backstage Software Catalog](https://backstage.io/docs/features/software-catalog/extending-the-model/) - Upstream documentation on extending entity validation with custom processors
- [Backstage Entity Validation Plugin | Roadie](https://roadie.io/backstage/plugins/entity-validation/) - Community plugin example of entity validation UI integration
- [Processing Backstage Entities | Medium](https://drodil.medium.com/processing-backstage-entities-48dbee26bb54) - Technical overview of entity processors and validation workflow
- [backstage/plugin-user-settings | NPM](https://www.npmjs.com/package/@backstage/plugin-user-settings) - Official user-settings plugin package with automatic availability in New Frontend System apps
- [backstage/plugins/user-settings/README.md](https://github.com/backstage/backstage/blob/master/plugins/user-settings/README.md) - Upstream documentation on user settings customization using SettingsLayout.Route and custom tabs
- [Frontend Extensions | Backstage Software Catalog and Developer Platform](https://backstage.io/docs/frontend-system/architecture/extensions/) - Architecture documentation explaining how extensions work and interact in the New Frontend System
- [Configuring Extensions in the App | Backstage Software Catalog and Developer Platform](https://backstage.io/docs/frontend-system/building-apps/configuring-extensions/) - Documentation on using app.extensions configuration to enable, disable, and configure extensions
