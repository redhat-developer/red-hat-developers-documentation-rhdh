# Documentation Plan

**Project**: Red Hat Developer Hub - Dynamic Plugins Configuration in Backstage CR
**Date**: 2026-09-11
**Ticket**: [RHIDP-8293](https://redhat.atlassian.net/browse/RHIDP-8293)

## What is the support status of the feature(s) being used to complete the user's JTBD (Job To Be Done)?

General Availability (RHDH 2.1.0)

## Why is this content important?

Users deploying Red Hat Developer Hub using the Operator currently must manage two separate Kubernetes resources to configure dynamic plugins: the Backstage custom resource and a ConfigMap. This increases complexity and cognitive load for simple plugin configurations. The new inline configuration capability reduces this to a single resource, eliminating boilerplate and providing a more intuitive developer experience. Users need documentation to understand when to use the simpler inline approach versus the ConfigMap approach, what package reference formats are supported, and how to correctly configure plugins inline without triggering validation errors.

## Who is the target persona(s)?

* SysAdmin: Primary user responsible for deploying and configuring Red Hat Developer Hub instances on OpenShift clusters
* Developer: Secondary user who may be configuring Developer Hub for local testing or contributing to deployment configurations
* IT Operations Leader: Tertiary user who needs to understand configuration patterns for standardizing deployments across teams

## What is the main JTBD? What user goal is being accomplished? What pain point is being avoided?

When I deploy Red Hat Developer Hub using the Operator with dynamic plugins enabled, I want to configure plugin packages and settings in a single Kubernetes resource, so that I can reduce configuration complexity and avoid managing multiple interdependent resources while avoiding errors from incorrectly referencing external ConfigMaps.

## How does the JTBD(s) relate to the overall real-world workflow for the user?

The user's broader workflow involves deploying Red Hat Developer Hub on OpenShift and configuring it for their organization's needs. Within this workflow, enabling dynamic plugins is a critical step that extends the platform with catalog providers, authentication backends, and other capabilities. The inline configuration option streamlines the deployment phase by allowing users to define the entire plugin configuration within the Backstage custom resource rather than separately creating and maintaining a ConfigMap. This reduces the number of steps in the deployment workflow and decreases the risk of configuration drift between the CR and its referenced ConfigMap. Users who need simple plugin configurations benefit from the inline approach, while users with complex, reusable, or environment-specific configurations continue to use the ConfigMap approach.

## What high-level steps does the user need to take to accomplish the goal?

1. Determine whether inline CR configuration or ConfigMap-based configuration is appropriate for the use case
2. Understand the structure of the spec.application.dynamicPlugins field and its mutual exclusivity with spec.application.dynamicPluginsConfigMapName
3. Identify the plugin packages to install using appropriate package reference formats (ref://, oci://, npm, file paths, HTTP URLs)
4. Define plugin configuration entries with package references, enabled state, plugin-specific configuration, and optional integrity checksums
5. Apply the Backstage custom resource to the cluster
6. Verify that the Operator generates the ConfigMap and loads the plugins correctly

**Prerequisites**:
* OpenShift cluster with Red Hat Developer Hub Operator installed
* Basic understanding of Kubernetes custom resources and YAML syntax
* Knowledge of which dynamic plugins are needed for the deployment
* Access to plugin package references (from default catalog, OCI registry, or npm)

## Is there a demo available or can one be created?

No demo is currently available. A demo could be created showing side-by-side comparisons of ConfigMap-based versus inline configuration for the same plugin setup.

## Are there special considerations for disconnected environments?

Yes. In disconnected environments, users must ensure that plugin packages are available from mirrored registries or pre-configured catalogs. The ref:// format resolves to OCI URLs from the default plugin catalog, which may not be accessible in disconnected environments. Users in disconnected environments should use oci:// references pointing to their mirrored registries with digest-based references for reproducibility, or use file:// paths for plugins included in custom images. Documentation should clarify these considerations when explaining package reference formats.

## Who can provide information and answer questions?

* PM: Check JIRA ticket assignee and reporter fields for RHIDP-8293, RHDHPLAN-455, RHIDP-15060
* Technical SME: PR author for redhat-developer/rhdh-operator#3507 and development team members associated with RHIDP-15060
* UX: Check JIRA watchers and related UX tickets for Developer Hub Operator configuration patterns

## Release Note needed?

Yes

Draft release note: Red Hat Developer Hub 2.1.0 introduces inline dynamic plugin configuration in the Backstage custom resource. Users can now configure dynamic plugins directly using the spec.application.dynamicPlugins field without creating a separate ConfigMap, simplifying deployments with straightforward plugin requirements. The ConfigMap-based configuration method remains fully supported for complex scenarios requiring configuration reuse or environment-specific variations.

## Links to existing content

* [Backstage custom resource concept](modules/configure_configuring-rhdh/con-custom-resource.adoc)
* [Dynamic plugins configuration file concept](modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc)
* [Install dynamic plugins with the RHDH Operator procedure](modules/shared/proc-install-dynamic-plugins-with-the-rhdh-operator.adoc)
* [PR #3507 - Implementation](https://github.com/redhat-developer/rhdh-operator/pull/3507)
* [RHIDP-15060 - Implementation epic](https://redhat.atlassian.net/browse/RHIDP-15060)
* [RHDHPLAN-455 - Parent feature](https://redhat.atlassian.net/browse/RHDHPLAN-455)
* [Operator configuration.md documentation](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-77e487192b8a5bdbb7a5bdbb7b24bb24bb24bb24bb24bb24R530-R571)
* [Example inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/blob/dynaplugins-in-cr/examples/inline-dynamic-plugins.yaml)

## New Docs

### Configure dynamic plugins inline in Backstage custom resource (Procedure)

**Filename**: `modules/shared/proc-configure-dynamic-plugins-inline-operator.adoc`
**Module Type**: PROCEDURE
**JTBD Category**: Configure
**Main Job**: Simplify plugin deployment by consolidating configuration
**User Story**: Configure dynamic plugins without external ConfigMaps
**Content Journey Phase**: Evaluate
**Persona**: SysAdmin
**Content Outline**:
* Introduction explaining the inline configuration alternative to ConfigMap approach
* Prerequisites including Operator installation and cluster access
* Step-by-step procedure:
  1. Create or edit Backstage custom resource
  2. Add spec.application.dynamicPlugins field
  3. Define plugin entries with package references, enabled state, and pluginConfig
  4. Apply the custom resource
  5. Verification steps using /api/dynamic-plugins-info/loaded-plugins endpoint
* Example showing at least two plugins configured inline (one with ref://, one with oci://)
* Example showing plugin-specific configuration using pluginConfig field
* Note about mutual exclusivity with dynamicPluginsConfigMapName
* Troubleshooting guidance for common validation errors
* Cross-reference to ConfigMap-based procedure for complex scenarios

### Dynamic plugin package reference formats (Reference)

**Filename**: `modules/shared/ref-dynamic-plugin-package-reference-formats.adoc`
**Module Type**: REFERENCE
**JTBD Category**: Reference
**Main Job**: Understand plugin package reference syntax
**User Story**: Identify the correct package reference format for a plugin
**Content Journey Phase**: Adopt
**Persona**: SysAdmin, Developer
**Content Outline**:
* Introduction explaining that package references identify plugin locations
* Table of supported formats:
  * ref:// - Built-in plugins from default catalog (explain resolution to OCI URLs)
  * oci:// - OCI images with registry, repository, tag or digest
  * npm - NPM package names with optional scope and version
  * file:// - File system paths for plugins in custom images
  * https:// and http:// - HTTP URLs for plugin archives
* Format column: syntax pattern
* Description column: when to use
* Example column: realistic examples
* Notes for disconnected environments (ref:// may not work, use oci:// with digest)
* Link to package integrity verification reference
* Cross-reference to dynamic plugin configuration concept

### Dynamic plugin configuration fields (Reference)

**Filename**: `modules/shared/ref-dynamic-plugin-config-fields.adoc`
**Module Type**: REFERENCE
**JTBD Category**: Reference
**Main Job**: Understand plugin configuration structure
**User Story**: Define correct fields when configuring a plugin inline
**Content Journey Phase**: Adopt
**Persona**: SysAdmin, Developer
**Content Outline**:
* Introduction explaining DynamicPluginConfig structure
* Table documenting all fields:
  * package: Package reference (required) - link to package reference formats
  * enabled: Boolean controlling plugin state (optional, defaults to true)
  * pluginConfig: Arbitrary YAML for plugin-specific configuration (optional)
  * integrity: Checksum for package verification (optional) - format: algorithm-base64hash
* Field column: field name
* Type column: data type (string, boolean, object)
* Required column: Yes/No
* Default column: default value if omitted
* Description column: purpose and behavior
* Example showing plugin entry with all fields populated
* Note about enabled field taking precedence over legacy disabled field
* Note about pluginConfig being merged into app-config at catalog.providers scope
* Cross-reference to inline configuration procedure
* Cross-reference to package reference formats

### Deciding between inline and ConfigMap plugin configuration (Concept)

**Filename**: `modules/shared/con-dynamic-plugins-configuration-methods.adoc`
**Module Type**: CONCEPT
**JTBD Category**: Configure
**Main Job**: Choose the appropriate configuration method for the use case
**User Story**: Determine whether to use inline or ConfigMap-based plugin configuration
**Content Journey Phase**: Discover
**Persona**: SysAdmin, IT Operations Leader
**Content Outline**:
* Introduction explaining two mutually exclusive configuration methods
* Section on inline configuration approach:
  * Use case: Simple deployments with plugins specific to one Backstage instance
  * Benefits: Fewer resources to manage, single-file configuration, reduced boilerplate
  * Limitations: Cannot share configuration across multiple Backstage instances, less flexible for environment-specific variations
* Section on ConfigMap-based approach:
  * Use case: Complex deployments requiring configuration reuse or environment-specific variations
  * Benefits: Shareable across instances, versioned independently, supports overlay patterns
  * Limitations: More resources to manage, requires maintaining reference consistency
* Decision matrix table:
  * Scenario column: deployment scenario
  * Recommended method column: inline or ConfigMap
  * Rationale column: why
* Examples:
  * Simple: Single instance with 2-3 plugins -> inline
  * Shared: Multiple instances with same plugin set -> ConfigMap
  * Environment-specific: Dev/staging/prod with different plugin configs -> ConfigMap
* Note about CEL validation preventing accidental use of both methods
* Cross-references to both procedure modules

## Updated Docs

### modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc

**Update Type**: Enhancement
**JTBD Category**: Configure
**Content Journey Phase**: Discover
**Changes Required**:
* Update abstract to mention both provisioning methods (ConfigMap and inline CR)
* Add new paragraph after existing content explaining inline configuration option:
  * Available in RHDH 2.1.0 and later when using the Operator
  * Allows defining plugins directly in spec.application.dynamicPlugins field
  * Mutually exclusive with dynamicPluginsConfigMapName
* Update "With the Operator" bullet to read: "Create a config map containing the `dynamic-plugins.yaml` data and reference it in the `Backstage` custom resource using `spec.application.dynamicPluginsConfigMapName`, or configure plugins inline using `spec.application.dynamicPlugins`"
* Add cross-reference to new concept module explaining when to use each method
* Add cross-reference to inline configuration procedure

### modules/shared/proc-install-dynamic-plugins-with-the-rhdh-operator.adoc

**Update Type**: Enhancement
**JTBD Category**: Configure
**Content Journey Phase**: Evaluate
**Changes Required**:
* Update title to clarify this is the ConfigMap-based approach: "Install dynamic plugins with the RHDH Operator using a ConfigMap"
* Add note at the beginning of the procedure:
  * "This procedure uses a ConfigMap to configure dynamic plugins. For simpler deployments, you can configure plugins inline in the Backstage custom resource. See xref:configure-dynamic-plugins-inline-operator[Configure dynamic plugins inline in Backstage custom resource]."
* Add note after dynamicPluginsConfigMapName example explaining mutual exclusivity:
  * "The dynamicPluginsConfigMapName field and the dynamicPlugins field are mutually exclusive. Use one or the other, not both."
* No other changes to existing procedure steps - ConfigMap method remains fully supported

### modules/configure_configuring-rhdh/con-custom-resource.adoc

**Update Type**: Enhancement
**JTBD Category**: Configure
**Content Journey Phase**: Discover
**Changes Required**:
* Add new field to the field list after spec.application.dynamicPluginsConfigMapName:
  ```
  `spec.application.dynamicPlugins`::
  Configures dynamic plugins inline without a separate ConfigMap. Mutually exclusive with `dynamicPluginsConfigMapName`.
  ```
* Update the spec.application.dynamicPluginsConfigMapName description to mention mutual exclusivity:
  ```
  `spec.application.dynamicPluginsConfigMapName`::
  References the config map containing the `dynamic-plugins.yaml` file. Mutually exclusive with `dynamicPlugins`.
  ```
* Add cross-reference to dynamic plugin configuration methods concept
* Add cross-reference to inline configuration procedure

---

## Gap Analysis

### Existing vs Needed Documentation

| Documentation Need | Current State | Gap Severity | Recommended Action |
|-------------------|---------------|--------------|-------------------|
| Inline plugin configuration procedure | Does not exist | High | Create new procedure module showing step-by-step inline configuration |
| Package reference format documentation | Not documented | High | Create new reference module documenting all five package formats |
| DynamicPluginConfig field reference | Not documented | High | Create new reference module documenting all four config fields |
| Decision guidance for inline vs ConfigMap | Partially covered - only ConfigMap method documented | Medium | Create new concept module explaining when to use each approach |
| Inline configuration mention in CR concept | Does not exist | Medium | Update existing concept to add dynamicPlugins field |
| Inline option in configuration file concept | Does not exist | Medium | Update existing concept to mention inline alternative |
| ConfigMap procedure context | Missing inline alternative note | Low | Update existing procedure to note the inline alternative exists |

### Coverage Analysis

**Undocumented Features**:
* spec.application.dynamicPlugins field and its structure
* DynamicPluginConfig fields (package, enabled, pluginConfig, integrity)
* Package reference formats (ref://, oci://, npm, file://, https://)
* Mutual exclusivity validation between dynamicPlugins and dynamicPluginsConfigMapName
* Guidance on when to use inline vs ConfigMap configuration

**Outdated Content**:
* con-custom-resource.adoc - Missing the new dynamicPlugins field introduced in RHDH 2.1.0
* con-dynamic-plugins-configuration-file.adoc - Only documents ConfigMap approach, does not mention inline alternative
* proc-install-dynamic-plugins-with-the-rhdh-operator.adoc - Does not indicate ConfigMap is one of two options

**Incomplete Procedures**:
* No verification steps exist for confirming inline configuration loaded correctly
* No troubleshooting guidance for CEL validation errors when both fields are specified
* No examples showing integrity checksum usage for package verification

**Structure Issues**:
* Current documentation structure assumes ConfigMap is the only way to configure plugins with Operator
* No concept module explaining the relationship between the two configuration methods
* No reference documentation for package formats or configuration fields

### Content Journey Phase Distribution

| Phase | Existing Modules | Planned Modules | Gap Assessment |
|-------|-----------------|-----------------|----------------|
| Expand | 0 | 0 | No gap - not applicable for configuration feature |
| Discover | 2 (concepts) | 1 (concept) | Adequate - users can understand what inline configuration is |
| Learn | 0 | 0 | Minor gap - could benefit from tutorial, but procedures provide sufficient guidance |
| Evaluate | 1 (procedure) | 1 (procedure) | Adequate - users can try inline configuration with hands-on procedure |
| Adopt | 0 | 2 (references) | Gap addressed - reference modules support day-to-day configuration work |

**Assessment**: The planned documentation adequately addresses the content journey. The Discover phase introduces the concept and decision criteria. The Evaluate phase provides hands-on procedures for trying inline configuration. The Adopt phase provides reference documentation for ongoing use. No tutorial is strictly necessary given the simplicity of the feature.

---

## Module Planning with JTBD

### JTBD Hierarchy Mapping

**Category**: Configure (job_map_stage)

**Main Job 1**: Simplify plugin deployment by consolidating configuration
* **Job Statement**: When I deploy Red Hat Developer Hub using the Operator with dynamic plugins, I want to configure plugin packages and settings in a single resource, so that I can reduce configuration complexity and management overhead.
* **User Stories**:
  1. Configure dynamic plugins without external ConfigMaps (inline configuration procedure)
  2. Choose the appropriate configuration method for the use case (decision concept)

**Main Job 2**: Understand plugin package reference syntax
* **Job Statement**: When I configure dynamic plugins inline, I want to identify the correct package reference format, so that I can reliably specify plugin sources from catalogs, registries, npm, or local paths.
* **User Stories**:
  1. Identify the correct package reference format for a plugin (package reference formats reference)

**Main Job 3**: Understand plugin configuration structure
* **Job Statement**: When I define plugin entries inline, I want to understand all available configuration fields, so that I can enable plugins, provide configuration, and verify package integrity.
* **User Stories**:
  1. Define correct fields when configuring a plugin inline (plugin config fields reference)

### JTBD Hierarchy Check

**Existing jobs in RHDH documentation** (based on Configure category):
* Configure Red Hat Developer Hub deployment
* Control access to resources
* Connect to external services
* Manage configuration files
* Configure dynamic plugins

**Assessment**: The user's goals fit within the existing "Configure dynamic plugins" job. This is an enhancement to an existing job, not a new parent topic. The inline configuration method is an alternative implementation path for the same underlying job: configuring dynamic plugins. Therefore, no new parent topic is needed. The planned modules are updates and additions to the existing "Configure dynamic plugins" job structure.

### Assembly Organization

**Assembly**: Configure dynamic plugins (existing assembly)

**Reading Order**:
1. con-dynamic-plugins-configuration-file.adoc (updated) - Introduces dynamic plugins configuration and both methods
2. con-dynamic-plugins-configuration-methods.adoc (new) - Explains when to use inline vs ConfigMap
3. proc-configure-dynamic-plugins-inline-operator.adoc (new) - Hands-on procedure for inline method
4. proc-install-dynamic-plugins-with-the-rhdh-operator.adoc (updated) - Hands-on procedure for ConfigMap method
5. ref-dynamic-plugin-package-reference-formats.adoc (new) - Reference for package formats
6. ref-dynamic-plugin-config-fields.adoc (new) - Reference for configuration fields
7. con-custom-resource.adoc (updated) - Technical reference for CR fields

**Shared Prerequisites**:
* OpenShift cluster with RHDH Operator installed
* Basic understanding of Kubernetes custom resources
* Knowledge of required plugin packages

**Dependencies**:
* Users must understand the concept before choosing a method
* Users must choose a method before following a procedure
* Users may need reference documentation while following procedures

---

## Implementation Order

### Priority 1: Foundation (Week 1)
1. Create `con-dynamic-plugins-configuration-methods.adoc` - Decision guidance is critical for users to understand the feature
2. Create `proc-configure-dynamic-plugins-inline-operator.adoc` - Primary new functionality users need to adopt
3. Update `con-dynamic-plugins-configuration-file.adoc` - Update existing content to mention inline option

### Priority 2: Reference Documentation (Week 2)
4. Create `ref-dynamic-plugin-package-reference-formats.adoc` - Essential reference for package syntax
5. Create `ref-dynamic-plugin-config-fields.adoc` - Essential reference for field structure
6. Update `con-custom-resource.adoc` - Add new dynamicPlugins field to CR documentation

### Priority 3: Enhancement (Week 2)
7. Update `proc-install-dynamic-plugins-with-the-rhdh-operator.adoc` - Add note about inline alternative

### Dependency Graph

```
Week 1 (Foundation):
con-dynamic-plugins-configuration-methods.adoc (no dependencies)
  └─> proc-configure-dynamic-plugins-inline-operator.adoc (references decision concept)
      └─> con-dynamic-plugins-configuration-file.adoc update (references procedure and concept)

Week 2 (Reference + Enhancement):
ref-dynamic-plugin-package-reference-formats.adoc (no dependencies, can be done in parallel)
ref-dynamic-plugin-config-fields.adoc (references package formats reference)
con-custom-resource.adoc update (references decision concept)
proc-install-dynamic-plugins-with-the-rhdh-operator.adoc update (references inline procedure)
```

---

## Content Sources and Traceability

### Primary Sources

**JIRA Tickets**:
* RHIDP-8293 - Documentation task ticket
* RHIDP-8628 - Related documentation task
* RHIDP-15060 - Implementation epic
* RHDHPLAN-455 - Parent feature ticket

**Code Changes**:
* PR #3507 (redhat-developer/rhdh-operator) - Primary implementation
  * api/v1alpha5/backstage_types.go - API definitions for DynamicPlugins and DynamicPluginConfig
  * config/crd/bases/rhdh.redhat.com_backstages.yaml - CRD with field documentation
  * docs/configuration.md - Operator documentation with examples
  * examples/inline-dynamic-plugins.yaml - Working example

**Existing Documentation**:
* modules/configure_configuring-rhdh/con-custom-resource.adoc - Backstage CR field reference
* modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc - Plugin configuration concept
* modules/shared/proc-install-dynamic-plugins-with-the-rhdh-operator.adoc - ConfigMap-based procedure

### Traceability Matrix

| Module | Source Requirements | Code References | Verification Method |
|--------|-------------------|----------------|---------------------|
| proc-configure-dynamic-plugins-inline-operator.adoc | REQ-001, REQ-002, REQ-003 | backstage_types.go:35-40, backstage_types.go:49-77, examples/inline-dynamic-plugins.yaml | Procedure steps should match operator behavior and example YAML structure |
| ref-dynamic-plugin-package-reference-formats.adoc | REQ-002 | backstage_types.go:49-77, config/crd/bases/rhdh.redhat.com_backstages.yaml:327-334 | Format documentation must match code comments and CRD validation |
| ref-dynamic-plugin-config-fields.adoc | REQ-001, REQ-003 | backstage_types.go:49-77, docs/configuration.md:536-544 | Field list must match struct definition exactly |
| con-dynamic-plugins-configuration-methods.adoc | REQ-004 | backstage_types.go:22-40 (CEL validation), docs/configuration.md:529-613 | Decision guidance should align with operator recommendations |

---

## Relationship Analysis

### Requirement Relationships

| Pair | Relationship Type | Overlap Risk | Consolidation Strategy |
|------|------------------|--------------|----------------------|
| REQ-001 ↔ REQ-002 | Overlapping | Medium | REQ-001 covers inline configuration generally, REQ-002 focuses on package formats specifically. Create separate modules: procedure (REQ-001) and reference (REQ-002) |
| REQ-001 ↔ REQ-003 | Overlapping | Medium | REQ-001 covers inline configuration generally, REQ-003 focuses on field structure specifically. Create separate modules: procedure (REQ-001) and reference (REQ-003) |
| REQ-002 ↔ REQ-003 | Complementary | Low | REQ-002 focuses on package field format, REQ-003 covers all four fields. Create separate reference modules that cross-reference each other |
| REQ-001 ↔ REQ-004 | Overlapping | High | Both cover inline vs ConfigMap decision. REQ-004 emphasizes decision guidance. Consolidate decision guidance into single concept module (REQ-004 scope), procedure module covers inline method (REQ-001 scope) |
| REQ-004 ↔ All others | Complementary | Low | REQ-004 provides decision framework that all other requirements depend on. Create concept module first |

### Theme Clustering

**Cluster 1: Inline Configuration Implementation**
* **Title**: Inline dynamic plugin configuration in Backstage CR
* **Summary**: Users configure dynamic plugins directly in spec.application.dynamicPlugins field using package references, enabled state, pluginConfig, and integrity checksums
* **Issues included**: REQ-001, REQ-002, REQ-003
* **Overlap risk**: Medium - all three requirements describe aspects of the same feature from different angles
* **Recommended ownership**: Create one procedure module for inline configuration (REQ-001), two reference modules for package formats (REQ-002) and config fields (REQ-003)

**Cluster 2: Configuration Method Decision**
* **Title**: Choosing between inline and ConfigMap-based plugin configuration
* **Summary**: Users must understand when to use inline configuration versus ConfigMap-based configuration based on deployment complexity and reusability requirements
* **Issues included**: REQ-004
* **Overlap risk**: Low - distinct conceptual content
* **Recommended ownership**: Create one concept module explaining decision criteria and tradeoffs

---

## Documentation Impact Assessment

| Requirement | Doc Impact Grade | Priority | Rationale |
|-------------|-----------------|----------|-----------|
| REQ-001 | High | Critical | Major new feature enabling simpler plugin configuration, requires new procedure and reference documentation |
| REQ-002 | High | High | Package reference formats are critical technical details users need to successfully configure plugins |
| REQ-003 | High | High | Field structure documentation is essential for users to correctly populate configuration |
| REQ-004 | Medium | High | Decision guidance improves user experience but feature is usable without it |

**Prioritization based on impact grades**:
1. REQ-001 (Critical) - Core functionality documentation
2. REQ-002, REQ-003 (High) - Essential reference documentation
3. REQ-004 (High) - Important decision guidance

---

## Special Considerations

### Disconnected Environments

The ref:// package format resolves to OCI URLs from the default Red Hat plugin catalog hosted on the internet. In disconnected environments, this resolution will fail. Documentation must clearly indicate that disconnected environment users should:
* Use oci:// references pointing to mirrored registries with digest-based references for reproducibility
* Use file:// paths for plugins pre-loaded into custom RHDH images
* Avoid ref:// format entirely

This consideration should be documented in:
* proc-configure-dynamic-plugins-inline-operator.adoc - Add disconnected environment note
* ref-dynamic-plugin-package-reference-formats.adoc - Add disconnected column to format table
* con-dynamic-plugins-configuration-methods.adoc - Add disconnected environment as a decision factor

### Mutual Exclusivity Validation

The CEL validation rule prevents users from specifying both dynamicPlugins and dynamicPluginsConfigMapName in the same Backstage CR. When users accidentally specify both, they will receive a validation error from the Kubernetes API server. Documentation should:
* Explain the mutual exclusivity clearly in concept modules
* Provide troubleshooting guidance in procedure modules
* Show the validation error message users will see
* Explain how to fix the error (remove one of the two fields)

### Migration Path

Users currently using ConfigMap-based configuration may want to migrate to inline configuration for simplicity. Documentation should:
* Clarify that migration is optional - ConfigMap method remains fully supported
* Provide guidance for migrating from ConfigMap to inline (copy plugin list from ConfigMap data to CR spec.application.dynamicPlugins)
* Note that both methods generate the same underlying ConfigMap (operator implementation detail)
* Recommend inline for new deployments, ConfigMap for existing deployments unless simplification is needed

---

## Self-Review Checklist

| Check | Status | Notes |
|-------|--------|-------|
| No placeholder syntax | ✓ | All [REPLACE] markers have been replaced with actual content |
| No hallucinated content | ✓ | All recommendations traceable to requirements analysis, PR #3507, and existing docs |
| Source traceability | ✓ | Each module links to specific requirements, code files, and tickets |
| No sensitive information | ✓ | No credentials, internal URLs, or tokens included |
| Persona limit | ✓ | Three personas identified (SysAdmin primary, Developer secondary, IT Operations Leader tertiary) |
| Template completeness | ✓ | All required sections populated with actual content |
| Impact consistency | ✓ | High-impact grades align with Priority 1-2 implementation order |
| Journey coverage | ✓ | Content journey phases mapped for all modules (Discover, Evaluate, Adopt) |
| JIRA description | ✓ | Five sections ready for JIRA ticket: JTBD, workflow, SME contacts, New Docs, Updated Docs |
| Persona separation | ✓ | Single capability serving primarily SysAdmin persona, no multi-persona separation needed |

---

## Notes for Implementation

* All new modules should follow AsciiDoc modular documentation structure with proper metadata
* Use conditional attributes for product name, custom resource type, and version references
* Include working YAML examples that can be copy-pasted and adapted by users
* Cross-reference related modules using xref with context variables
* Verification steps should use realistic API endpoints and expected output
* Examples should demonstrate best practices (e.g., using digest-based OCI references for reproducibility)
* Troubleshooting sections should anticipate common validation errors and provide clear resolution steps
