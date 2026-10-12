# Documentation Requirements

**Source**: [Docs] Configure dynamic plugins in Backstage CR
**Date**: 2026-09-11
**Release/Sprint**: 2.1.0

## Summary

- Total requirements analyzed: 4
- New modules needed: 4
- Existing modules to update: 5
- Breaking changes requiring docs: 0

## Requirements by priority

### High

#### REQ-001: Document inline dynamic plugins configuration in Backstage CR
- **Source**: [RHIDP-15060](https://redhat.atlassian.net/browse/RHIDP-15060) | [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507)
- **Summary**: RHDH 2.1.0 introduces a new spec.application.dynamicPlugins field in the Backstage CR that allows users to configure dynamic plugins directly inline, eliminating the need for a separate ConfigMap in simple use cases. This simplifies plugin configuration by reducing the number of Kubernetes resources needed and provides a more intuitive developer experience. The new field is mutually exclusive with the existing dynamicPluginsConfigMapName field.
- **User impact**: Users can now configure dynamic plugins with less boilerplate - they can specify plugin packages, enable/disable states, plugin-specific configuration, and integrity checksums directly in the Backstage CR. This reduces configuration complexity from two resources (CR + ConfigMap) to one for straightforward plugin setups, while still supporting the ConfigMap approach for complex scenarios.
- **Documentation action**:
  - [ ] Update `modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc` (CONCEPT) Add explanation of inline configuration option vs ConfigMap reference, explain mutual exclusivity
  - [ ] Update `modules/configure_configuring-rhdh/con-custom-resource.adoc` (CONCEPT) Add spec.application.dynamicPlugins to the field list, explain relationship with dynamicPluginsConfigMapName
  - [ ] Create `modules/shared/proc-configure-inline-dynamic-plugins-with-operator.adoc` (PROCEDURE) New procedure showing how to configure plugins inline in Backstage CR
  - [ ] Update `modules/shared/proc-install-dynamic-plugins-with-the-rhdh-operator.adoc` (PROCEDURE) Update to clarify this is the ConfigMap approach and link to inline alternative
  - [ ] Create `modules/shared/ref-dynamic-plugin-config-fields.adoc` (REFERENCE) Reference table documenting DynamicPluginConfig fields: package, enabled, pluginConfig, integrity
  - [ ] Create `modules/shared/ref-dynamic-plugin-package-formats.adoc` (REFERENCE) Reference documenting supported package formats: ref://, oci://, npm, file://, https://
- **Acceptance criteria**:
  - [ ] Users can configure at least one dynamic plugin inline in the Backstage CR following the procedure
  - [ ] Documentation explains all four DynamicPluginConfig fields (package, enabled, pluginConfig, integrity) with examples
  - [ ] Documentation lists all five supported package reference formats (ref://, oci://, npm, file paths, HTTP URLs) with examples
  - [ ] Documentation clearly explains the mutual exclusivity between spec.application.dynamicPlugins and spec.application.dynamicPluginsConfigMapName
  - [ ] Users can determine when to use inline configuration vs ConfigMap reference based on their use case
  - [ ] Verification steps confirm the inline configuration is loaded successfully
- **References**:
  - [RHIDP-15060](https://redhat.atlassian.net/browse/RHIDP-15060): Implementation epic for inline dynamic plugins configuration
  - [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507): Implementation PR adding spec.application.dynamicPlugins field to Backstage CR
  - [api/v1alpha5/backstage_types.go:22-41](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91f8a0a9d40e96e245b9c8dfeR22-R41): API definition showing mutual exclusivity validation and DynamicPlugins field
  - [api/v1alpha5/backstage_types.go:49-77](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91f8a0a9d40e96e245b9c8dfeR49-R77): DynamicPluginConfig struct definition with all fields and supported formats
  - [examples/inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-bc8a3b808ed1c7e0d7e0c5ffc20bd1e8edbf95ad): Example CR showing inline plugin configuration
  - [docs/configuration.md](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-77e487192b8a5bdbb7a5bdbb7b24bb24bb24bb24bb24bb24R530-R571): Operator documentation showing both inline and ConfigMap configuration options
  - [RHDHPLAN-455](https://redhat.atlassian.net/browse/RHDHPLAN-455): Parent feature for configure dynamic plugins in Backstage CR
  - [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628): Documentation task for this feature

#### REQ-002: Document plugin package reference formats for inline configuration
- **Source**: [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507)
- **Summary**: The RHDH Operator now supports configuring dynamic plugins directly in the Backstage CR using spec.application.dynamicPlugins field, eliminating the need for a separate ConfigMap. Users can specify plugins using multiple package reference formats including ref:// for built-in plugins from the default catalog, oci:// for OCI images with tags or digests, npm package names with scopes, HTTP/HTTPS URLs, and file paths. Each plugin entry supports optional fields for enabled state, plugin-specific configuration, and integrity checksums for package verification.
- **User impact**: Users can now configure dynamic plugins inline in the Backstage CR without creating a separate ConfigMap, simplifying plugin management. They need to understand the supported package reference formats (ref://, oci://, npm, HTTP/HTTPS, file paths) and when to use each format. The inline dynamicPlugins field is mutually exclusive with dynamicPluginsConfigMapName, requiring users to choose one configuration method.
- **Documentation action**:
  - [ ] Create `modules/configure_configuring-rhdh/ref-dynamic-plugin-package-reference-formats.adoc` (REFERENCE) Document all supported package reference formats with syntax and examples
  - [ ] Create `modules/configure_configuring-rhdh/proc-configure-dynamic-plugins-inline-operator.adoc` (PROCEDURE) Configure dynamic plugins inline in Backstage CR
  - [ ] Update `modules/configure_configuring-rhdh/con-custom-resource.adoc` (CONCEPT) Add spec.application.dynamicPlugins field description and mutual exclusivity note
  - [ ] Update `modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc` (CONCEPT) Add inline configuration option for Operator deployments
- **Acceptance criteria**:
  - [ ] Users can identify all supported package reference formats (ref://, oci://, npm, HTTP/HTTPS, file paths) from the reference documentation
  - [ ] Users can configure a built-in plugin using ref:// format following the procedure
  - [ ] Users can configure an OCI plugin using both tag and digest formats following the procedure
  - [ ] Users can configure plugins with integrity checksums for verification following the procedure
  - [ ] Users understand the mutual exclusivity between spec.application.dynamicPlugins and spec.application.dynamicPluginsConfigMapName
  - [ ] Users can specify plugin-specific configuration using the pluginConfig field following the procedure
- **References**:
  - [PR 3507](https://github.com/redhat-developer/rhdh-operator/pull/3507): Implementation of inline dynamic plugins configuration in Backstage CR
  - [api/v1alpha5/backstage_types.go:49-77](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-c27ea80e94e67733087dfee8f4a3e83ccba9ff8b0e3b98f6e2db8e0ab5b7c0b4R49-R77): DynamicPluginConfig struct defining package formats and fields
  - [config/crd/bases/rhdh.redhat.com_backstages.yaml:327-334](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-c3f7738b6fccc8ce6e4d2f02df02a8fff9f67dd78a6cc5dc88c8ce15950f7084R327-R334): CRD documentation for supported package formats
  - [docs/configuration.md:536-544](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-a95e89a67faef7e87c3b854e17a3a8c3764bb9ee8a40f5c5b3e3f61f0a5f3c09R536-R544): Operator documentation describing plugin configuration fields
  - [examples/inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-df851b70ea2a1dfc7653b8bd5b59d863f31c8ec59b2c7c4f948570ca35b12868): Example CR with inline plugin configuration
  - [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628): Documentation task for Configure dynamic plugins in Backstage CR

#### REQ-003: Document inline plugin configuration structure and fields
- **Source**: [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507)
- **Summary**: Red Hat Developer Hub 2.1.0 introduces the ability to configure dynamic plugins directly in the Backstage custom resource using the spec.application.dynamicPlugins field, eliminating the need for a separate ConfigMap in simple use cases. Each plugin entry in the array specifies its package reference, enabled state, optional plugin-specific configuration, and integrity checksum. This provides a more streamlined configuration experience while maintaining backward compatibility with the existing ConfigMap-based approach.
- **User impact**: Users can now configure dynamic plugins inline within the Backstage CR, reducing the number of Kubernetes resources to manage and simplifying the deployment process. This is particularly beneficial for straightforward plugin configurations that do not require the complexity of maintaining a separate ConfigMap.
- **Documentation action**:
  - [ ] Create `modules/shared/ref-backstage-cr-inline-dynamic-plugins-fields.adoc` (REFERENCE) Document the DynamicPluginConfig structure with all fields: package, enabled, pluginConfig, integrity
  - [ ] Create `modules/shared/proc-configure-dynamic-plugins-inline-operator.adoc` (PROCEDURE) Step-by-step procedure for configuring plugins inline in Backstage CR
  - [ ] Update `modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc` (CONCEPT) Add explanation that plugins can now be configured inline or via ConfigMap
  - [ ] Update `modules/shared/proc-install-dynamic-plugins-with-the-rhdh-operator.adoc` (PROCEDURE) Add note about inline configuration alternative and link to new procedure
- **Acceptance criteria**:
  - [ ] Users can identify all four fields of the DynamicPluginConfig structure (package, enabled, pluginConfig, integrity) and understand their purpose
  - [ ] Users can configure at least one plugin inline in a Backstage CR following the documented procedure
  - [ ] Users understand that spec.application.dynamicPlugins and spec.application.dynamicPluginsConfigMapName are mutually exclusive
  - [ ] Users can specify package references in all supported formats (ref://, oci://, npm, file paths, HTTP URLs)
  - [ ] Users understand that the enabled field defaults to true if not specified
  - [ ] Users can provide plugin-specific configuration using the pluginConfig field as arbitrary YAML
  - [ ] Users understand when and how to use integrity checksums for package verification
- **References**:
  - [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507): Implementation PR adding inline dynamic plugins configuration
  - [backstage_types.go:35-40](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91..40e96e245): DynamicPlugins field definition with mutual exclusion validation
  - [backstage_types.go:49-77](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91..40e96e245): DynamicPluginConfig struct with package, enabled, pluginConfig, integrity fields
  - [inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-bc8a3b808): Example showing inline plugin configuration in Backstage CR
  - [configuration.md](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-77e487192..51b5a9782): Operator documentation explaining both inline and ConfigMap configuration options
  - [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628): Documentation task for Configure dynamic plugins in Backstage CR
  - [RHDHPLAN-455](https://redhat.atlassian.net/browse/RHDHPLAN-455): Parent feature: Configure dynamic plugins in Backstage CR

### Medium

#### REQ-004: Update ConfigMap vs inline CR configuration guidance
- **Source**: [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628) | [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507)
- **Summary**: Red Hat Developer Hub 2.1.0 introduces the ability to configure dynamic plugins directly in the Backstage custom resource using spec.application.dynamicPlugins, eliminating the need for a separate ConfigMap in simple use cases. This enhancement provides users with two mutually exclusive configuration methods: inline CR configuration for simple plugin setups, and ConfigMap-based configuration for complex or reusable scenarios. Documentation must explain when to use each approach, provide examples for both methods, and clarify the CEL validation that enforces mutual exclusivity.
- **User impact**: Users can now choose between two configuration approaches based on their complexity and reusability needs. Simple deployments with a few plugins benefit from inline configuration that reduces the number of Kubernetes resources to manage. Complex deployments with shared configurations across multiple instances or environment-specific variations continue to benefit from ConfigMap-based configuration. Users need clear guidance on when to use each approach to avoid confusion and configuration errors.
- **Documentation action**:
  - [ ] Update `modules/shared/proc-install-dynamic-plugins-with-the-rhdh-operator.adoc` (PROCEDURE) Add guidance section explaining when to use inline vs ConfigMap configuration, update title to reflect both options, add inline configuration example before ConfigMap example
  - [ ] Update `modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc` (CONCEPT) Add inline CR configuration option to the provisioning methods section, explain mutual exclusivity
  - [ ] Update `modules/configure_configuring-rhdh/con-custom-resource.adoc` (CONCEPT) Add spec.application.dynamicPlugins field description, clarify mutual exclusivity with dynamicPluginsConfigMapName
  - [ ] Create `modules/shared/ref-dynamic-plugins-configuration-fields.adoc` (REFERENCE) Document all fields for DynamicPluginConfig: package, enabled, pluginConfig, integrity with supported formats
- **Acceptance criteria**:
  - [ ] Users can determine whether to use inline CR configuration or ConfigMap-based configuration based on their use case complexity
  - [ ] Examples demonstrate both inline CR configuration and ConfigMap-based configuration with identical plugin setups
  - [ ] Documentation clarifies that dynamicPlugins and dynamicPluginsConfigMapName are mutually exclusive via CEL validation
  - [ ] All supported package formats are documented: ref://, oci://, npm packages, file paths
  - [ ] Users understand that inline configuration reduces resource count for simple deployments while ConfigMaps enable reusability across instances
- **References**:
  - [PR #3507 description](https://github.com/redhat-developer/rhdh-operator/pull/3507): Primary implementation PR introducing inline dynamic plugins configuration
  - [api/v1alpha5/backstage_types.go:22-40]: Application struct with CEL validation enforcing mutual exclusivity between dynamicPlugins and dynamicPluginsConfigMapName
  - [api/v1alpha5/backstage_types.go:49-77]: DynamicPluginConfig struct defining package, enabled, pluginConfig, and integrity fields with supported formats
  - [docs/configuration.md:529-613]: Operator documentation showing inline configuration as recommended option with examples
  - [examples/inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/blob/dynaplugins-in-cr/examples/inline-dynamic-plugins.yaml): Example CR demonstrating inline dynamic plugins configuration
  - [RHDHPLAN-455](https://redhat.atlassian.net/browse/RHDHPLAN-455): Parent feature: Configure dynamic plugins in Backstage CR
  - [RHIDP-15060](https://redhat.atlassian.net/browse/RHIDP-15060): Implementation epic for inline dynamic plugins configuration

## Documentation scope

### New documentation needed

| Requirement | Scope | References |
|-------------|-------|------------|
| REQ-001 | Create new procedure for configuring dynamic plugins inline in Backstage CR, create reference tables for DynamicPluginConfig fields and package formats | [RHIDP-15060](https://redhat.atlassian.net/browse/RHIDP-15060), [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |
| REQ-002 | Create reference documentation for all supported package formats (ref://, oci://, npm, HTTP/HTTPS, file paths), create procedure for inline configuration | [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |
| REQ-003 | Create reference for DynamicPluginConfig structure, create procedure for inline plugin configuration | [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |
| REQ-004 | Create reference documenting DynamicPluginConfig fields with supported formats | [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628), [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |

### Existing documentation to update

| Requirement | What changed | References |
|-------------|-------------|------------|
| REQ-001 | Update concept modules to explain inline vs ConfigMap configuration, update existing ConfigMap procedure to link to inline alternative | [RHIDP-15060](https://redhat.atlassian.net/browse/RHIDP-15060), [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |
| REQ-002 | Update concept modules to add inline configuration option, update custom resource documentation with new field | [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |
| REQ-003 | Update concept to explain inline vs ConfigMap options, update existing procedure with link to inline alternative | [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |
| REQ-004 | Update procedure to explain both approaches with guidance on when to use each, update concepts with inline option and mutual exclusivity | [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628), [PR #3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) |

## Breaking changes

No breaking changes identified.

## Notes

- REQ-001: The implementation includes CEL validation to ensure spec.application.dynamicPlugins and spec.application.dynamicPluginsConfigMapName are mutually exclusive. The operator automatically generates a ConfigMap when inline plugins are specified. Plugin package references using ref:// are resolved to OCI URLs by the operator. The enabled field defaults to true if not specified. Integration tests verify the full flow including ConfigMap generation and plugin loading.

- REQ-002: The implementation introduces a new inline configuration method that is mutually exclusive with the existing ConfigMap-based approach. Both methods remain supported. Documentation should emphasize that ref:// references are resolved to OCI URLs from the default plugin catalog. The integrity field supports sha256, sha384, and sha512 formats similar to Subresource Integrity standards.

- REQ-003: The inline configuration is an additive feature that provides an alternative to the existing ConfigMap-based approach. The two approaches are mutually exclusive per CR instance, enforced by CEL validation rule. Users must choose one method or the other. Package reference formats support ref:// (catalog reference), oci:// (OCI image), npm packages, file paths, and HTTP/HTTPS URLs. The enabled field takes precedence over the legacy disabled field when both are present. PluginConfig uses x-kubernetes-preserve-unknown-fields to allow arbitrary YAML configuration. Integration tests verify ConfigMap generation, volume mounting, and proper handling of enabled/disabled states.

- REQ-004: The inline configuration feature is additive - existing ConfigMap-based configurations continue to work unchanged. The CEL validation at the API level prevents users from accidentally specifying both methods simultaneously. Documentation should emphasize inline configuration as the simpler, recommended approach for most users while preserving ConfigMap documentation for advanced use cases requiring configuration reuse or environment-specific variations.

## Related tickets

### Parent
- [RHDHPLAN-455](https://redhat.atlassian.net/browse/RHDHPLAN-455) - Configure dynamic plugins in Backstage CR

### Children
- [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628) - [Docs] Configure dynamic plugins in Backstage CR

### Siblings
- [RHIDP-15060](https://redhat.atlassian.net/browse/RHIDP-15060) - Configure dynamic plugins in Backstage CR - Implementation
- [RHIDP-6214](https://redhat.atlassian.net/browse/RHIDP-6214) - Configure dynamic plugins in Backstage CR

## Sources consulted

### JIRA tickets
- [RHIDP-8293](https://redhat.atlassian.net/browse/RHIDP-8293) - [Docs] Configure dynamic plugins in Backstage CR
- [RHIDP-8628](https://redhat.atlassian.net/browse/RHIDP-8628) - [Docs] Configure dynamic plugins in Backstage CR
- [RHIDP-15060](https://redhat.atlassian.net/browse/RHIDP-15060) - Configure dynamic plugins in Backstage CR - Implementation
- [RHDHPLAN-455](https://redhat.atlassian.net/browse/RHDHPLAN-455) - Configure dynamic plugins in Backstage CR
- [RHIDP-6214](https://redhat.atlassian.net/browse/RHIDP-6214) - Configure dynamic plugins in Backstage CR

### Pull requests / Merge requests
- [redhat-developer/rhdh-operator#3507](https://github.com/redhat-developer/rhdh-operator/pull/3507) - Add inline dynamic plugins configuration to Backstage CR

### Code files
- [api/v1alpha5/backstage_types.go:22-40](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91f8a0a9d40e96e245b9c8dfeR22-R41) - Application struct with CEL validation enforcing mutual exclusivity
- [api/v1alpha5/backstage_types.go:35-40](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91..40e96e245) - DynamicPlugins field definition with mutual exclusion validation
- [api/v1alpha5/backstage_types.go:49-77](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91f8a0a9d40e96e245b9c8dfeR49-R77) - DynamicPluginConfig struct definition with all fields and supported formats
- [api/v1alpha5/backstage_types.go:49-77](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-c27ea80e94e67733087dfee8f4a3e83ccba9ff8b0e3b98f6e2db8e0ab5b7c0b4R49-R77) - DynamicPluginConfig struct defining package formats and fields
- [backstage_types.go:49-77](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-b4f583a91..40e96e245) - DynamicPluginConfig struct with package, enabled, pluginConfig, integrity fields
- [config/crd/bases/rhdh.redhat.com_backstages.yaml:327-334](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-c3f7738b6fccc8ce6e4d2f02df02a8fff9f67dd78a6cc5dc88c8ce15950f7084R327-R334) - CRD documentation for supported package formats
- [configuration.md](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-77e487192..51b5a9782) - Operator documentation explaining both inline and ConfigMap configuration options
- [docs/configuration.md](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-77e487192b8a5bdbb7a5bdbb7b24bb24bb24bb24bb24bb24R530-R571) - Operator documentation showing both inline and ConfigMap configuration options
- [docs/configuration.md:529-613] - Operator documentation showing inline configuration as recommended option with examples
- [docs/configuration.md:536-544](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-a95e89a67faef7e87c3b854e17a3a8c3764bb9ee8a40f5c5b3e3f61f0a5f3c09R536-R544) - Operator documentation describing plugin configuration fields
- [examples/inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-bc8a3b808ed1c7e0d7e0c5ffc20bd1e8edbf95ad) - Example CR showing inline plugin configuration
- [examples/inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-df851b70ea2a1dfc7653b8bd5b59d863f31c8ec59b2c7c4f948570ca35b12868) - Example CR with inline plugin configuration
- [examples/inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/blob/dynaplugins-in-cr/examples/inline-dynamic-plugins.yaml) - Example CR demonstrating inline dynamic plugins configuration
- [inline-dynamic-plugins.yaml](https://github.com/redhat-developer/rhdh-operator/pull/3507/files#diff-bc8a3b808) - Example showing inline plugin configuration in Backstage CR

### Existing documentation
- modules/configure_configuring-rhdh/con-dynamic-plugins-configuration-file.adoc - Explains existing ConfigMap-based configuration method that inline CR configuration supplements
- modules/shared/proc-install-dynamic-plugins-with-the-rhdh-operator.adoc - Existing procedure for ConfigMap-based plugin installation that needs to be updated with inline CR option

### Web search findings
- [Kubernetes ConfigMap Best Practices for 2024](https://www.plural.sh/blog/kubernetes-configmap-guide/) - Best practices for when to use inline vs ConfigMap configuration in Kubernetes operators
- [Packaging Dynamic Plugins - RHDH GitHub](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/packaging-dynamic-plugins.md) - Documentation on plugin packaging formats (OCI, npm, tarball)
- [Installing and viewing plugins in Red Hat Developer Hub](https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/main/plugins-rhdh-install/) - Current documentation on plugin installation patterns
- [Configuring dynamic plugins - RHDH 1.8 Documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html-single/configuring_dynamic_plugins/index) - Existing patterns for dynamic plugin configuration
- [OCI Registry As Storage - Reference](https://oras.land/docs/concepts/reference/) - OCI reference format specification for registry, digest, and tag components
- [Package spec | npm Docs](https://docs.npmjs.com/cli/v11/using-npm/package-spec/) - NPM package reference format with scope and version syntax
- [Subresource Integrity - MDN Web Docs](https://developer.mozilla.org/en-US/docs/Web/Security/Subresource_Integrity) - Integrity checksum formats (sha256, sha384, sha512) for package verification
- [Dynamic plugins reference | Red Hat Developer Hub | 1.4](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/html-single/dynamic_plugins_reference/index) - Current RHDH dynamic plugins documentation structure and patterns
- [Extend the Kubernetes API with CustomResourceDefinitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) - Official Kubernetes documentation on CRD inline schema configuration patterns
- [Installing dynamic plugins | Red Hat Developer Hub](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.0/html/administration_guide_for_red_hat_developer_hub/rhdh-installing-dynamic-plugins) - Existing documentation on dynamic plugins package field structure and formats
- [Dynamic plugins reference | Red Hat Developer Hub 1.8](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html-single/dynamic_plugins_reference/index) - Reference documentation for plugin configuration fields including integrity checksums
- [OCI Content Descriptors - opencontainers/image-spec](https://github.com/opencontainers/image-spec/blob/main/descriptor.md) - OCI specification for digest format and integrity verification used in oci:// package references
- [Kubernetes Configuration Good Practices](https://kubernetes.io/docs/concepts/configuration/overview/) - Official Kubernetes guidance on when to use ConfigMaps vs inline configuration
- [ConfigMap Best Practices K8s Guide](https://kubernetes.recipes/recipes/configuration/kubernetes-configmap-best-practices/) - Best practices for ConfigMap versioning, organization, and when to use inline vs external configuration
- [Kubernetes Operators with External Configmap](https://medium.com/@aneeshputtur/kubernetes-operators-with-external-configmap-b972c9c36bbe) - Decision framework for CR inline configuration vs external ConfigMap in operator patterns
- [Installing and viewing plugins in Red Hat Developer Hub](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.4/html-single/installing_and_viewing_plugins_in_red_hat_developer_hub/index) - Current RHDH documentation for ConfigMap-based dynamic plugins configuration
