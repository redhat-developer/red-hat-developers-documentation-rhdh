# Documentation Requirements

**Source**: RHIDP-12374 - Multi-Source Plugin Catalog Support
**Date**: 2026-09-04
**Release/Sprint**: 1.10.0

## Summary

- Total requirements analyzed: 8
- New modules needed: 8
- Existing modules to update: 9
- Breaking changes requiring docs: 0

## Requirements by priority

### High

#### REQ-001: Document EXTRA_CATALOG_INDEX_IMAGES environment variable
- **Source**: [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933) | [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655)
- **Summary**: Red Hat Developer Hub 1.10 introduces support for configuring multiple catalog index images through the new EXTRA_CATALOG_INDEX_IMAGES environment variable in the install-dynamic-plugins script. This allows administrators to configure additional plugin catalog sources beyond the primary CATALOG_INDEX_IMAGE, making plugins from community, partner, or custom catalogs visible in the Extensions UI. Each extra catalog image is extracted to an isolated subdirectory under /extensions/extra/, keeping catalog entities separated from the primary index while enabling plugin discovery across multiple sources.
- **User impact**: Platform engineers and administrators can now configure RHDH to display plugins from multiple catalog sources (community, partner, certified, custom) in the Extensions UI without rebuilding container images. This supports multi-source plugin catalogs for larger organizations that maintain curated internal plugin registries alongside Red Hat's official catalog and community sources.
- **Documentation action**:
  - [ ] Create `ref-extra-catalog-index-images-environment-variable.adoc` (REFERENCE) - Document EXTRA_CATALOG_INDEX_IMAGES environment variable syntax, formats, behavior, and relationship to CATALOG_INDEX_IMAGE
  - [ ] Create `proc-configure-extra-catalog-index-images-helm.adoc` (PROCEDURE) - Procedure for configuring extra catalog images via Helm chart deployment
  - [ ] Create `proc-configure-extra-catalog-index-images-operator.adoc` (PROCEDURE) - Procedure for configuring extra catalog images via Operator deployment
  - [ ] Update `con-helm-chart-configuration-parameters.adoc` (REFERENCE) - Add global.catalogIndex.extraImages parameter documentation
  - [ ] Update `con-install-dynamic-plugins-script.adoc` (CONCEPT) - Add concept explanation of extra catalog index extraction behavior and directory structure
- **Acceptance criteria**:
  - [ ] Users can configure EXTRA_CATALOG_INDEX_IMAGES using both plain image references and name=image_ref format
  - [ ] Users understand that extra catalog images only contribute catalog entities for Extensions UI visibility, not dynamic-plugins.default.yaml configurations
  - [ ] Users can locate extracted catalog entities in the /extensions/extra/ directory structure
  - [ ] Documentation explains the difference between CATALOG_INDEX_IMAGE (primary, provides DPDY) and EXTRA_CATALOG_INDEX_IMAGES (additional, catalog entities only)
  - [ ] Users understand subdirectory naming behavior for both auto-derived and explicit names
  - [ ] Documentation includes example configurations for Helm and Operator deployments
  - [ ] Users are warned about duplicate subdirectory name behavior (later entry overwrites earlier)
  - [ ] Documentation clarifies that plugins from extra catalogs must be explicitly configured in dynamic-plugins.yaml to be installed
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent feature: Support several plugin catalogs in the Extensions plugin
  - [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655): Implementation PR with inline documentation
  - [install-dynamic-plugins.py lines 43-56](https://github.com/redhat-developer/rhdh/pull/4655/files#diff-cd75f40b25cba2a29aa4f4310ec114d362a3b93da55a7ff75ac0d2d1b1): Environment variable documentation in script header

#### REQ-002: Document Helm chart global.catalogIndex.extraImages configuration
- **Source**: [RHIDP-12934](https://redhat.atlassian.net/browse/RHIDP-12934) | [PR #368](https://github.com/redhat-developer/rhdh-chart/pull/368)
- **Summary**: RHDH 1.10 introduces support for multiple catalog index images through the new Helm chart field global.catalogIndex.extraImages. Users can now configure additional catalog index OCI images alongside the primary global.catalogIndex.image to make plugins from multiple sources discoverable in the Extensions UI. This enables organizations to combine the Red Hat supported plugin catalog with community plugins or internal custom plugin catalogs without rebuilding container images.
- **User impact**: Users can now configure multiple plugin catalog sources in their Helm deployments, enabling them to discover and use plugins from Red Hat, community repositories, and internal catalogs simultaneously. This simplifies plugin management in environments requiring plugins from diverse sources, particularly for organizations maintaining both standard and custom plugin catalogs.
- **Documentation action**:
  - [ ] Update `reference/con-helm-chart-configuration-parameters.html` (REFERENCE) - Add global.catalogIndex.extraImages field and its sub-fields (name, registry, repository, tag) to the Helm chart parameters table
  - [ ] Create `configure/proc-configure-multiple-catalog-index-images-helm.html` (PROCEDURE) - Step-by-step guide for configuring extraImages in Helm values.yaml
  - [ ] Update `extend/con-mirror-dynamic-plugins-in-disconnected-environments.html` (CONCEPT) - Update mirroring procedures to cover multiple catalog index images including extraImages
  - [ ] Update `extend/proc-enable-plugins-added-in-the-rhdh-container-image.html` (PROCEDURE) - Add note about catalog entities extracted from extra catalog index images
- **Acceptance criteria**:
  - [ ] Users can identify the global.catalogIndex.extraImages field in the Helm chart configuration reference
  - [ ] Users understand that extraImages entries require registry, repository, and tag fields, with optional name field
  - [ ] Users can configure one or more extra catalog index images following the documented YAML structure
  - [ ] Users understand that extraImages contribute only catalog entities to Extensions UI, not dynamic-plugins.default.yaml handling
  - [ ] Users understand the difference between primary catalogIndex.image and extraImages functionality
  - [ ] Documentation explains that the install-dynamic-plugins init container receives EXTRA_CATALOG_INDEX_IMAGES environment variable
  - [ ] Users working in air-gapped environments understand how to mirror extra catalog index images
  - [ ] Users understand that named entries produce cleaner extraction directory paths (e.g., /extensions/extra/community/)
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent feature: Support several plugin catalogs in Extensions plugin
  - [PR #368](https://github.com/redhat-developer/rhdh-chart/pull/368): Feature implementation and design rationale
  - [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933): Related: install-dynamic-plugins script support for multiple catalogs

#### REQ-003: Document Operator support for multiple catalog index images
- **Source**: [RHIDP-12935](https://redhat.atlassian.net/browse/RHIDP-12935) | [PR #2717](https://github.com/redhat-developer/rhdh-operator/pull/2717)
- **Summary**: The RHDH Operator now supports configuring multiple catalog index images through the EXTRA_CATALOG_INDEX_IMAGES environment variable on the install-dynamic-plugins init container. This enables users to load plugin configurations from multiple catalog sources for the Extensions UI. For disconnected environments, the Operator automatically collects RELATED_IMAGE_extra_catalog_index_{name} environment variables from the controller and forwards them to the init container, allowing administrators to configure multiple mirrored catalog images without manual intervention.
- **User impact**: Platform engineers can now configure multiple plugin catalog sources (Red Hat, community, partner, or internal) simultaneously, enabling richer plugin ecosystems. In disconnected or air-gapped environments, administrators can mirror and use multiple catalog index images using the standard RELATED_IMAGE pattern without complex workarounds.
- **Documentation action**:
  - [ ] Create `proc-configure-multiple-catalog-index-images-operator.adoc` (PROCEDURE) - Configure EXTRA_CATALOG_INDEX_IMAGES using extraEnvs in Backstage CR
  - [ ] Create `proc-configure-multiple-catalog-index-images-disconnected.adoc` (PROCEDURE) - Configure RELATED_IMAGE_extra_catalog_index_{name} for disconnected deployments
  - [ ] Update `con-mirror-dynamic-plugins-in-disconnected-environments.adoc` (CONCEPT) - Add section explaining catalog index image mirroring and RELATED_IMAGE_extra_catalog_index_{name} pattern
  - [ ] Update `proc-inject-extra-files-and-environment-variables-into-containers.adoc` (PROCEDURE) - Add example showing EXTRA_CATALOG_INDEX_IMAGES in extraEnvs targeting install-dynamic-plugins
  - [ ] Create `ref-extra-catalog-index-images-format.adoc` (REFERENCE) - Document EXTRA_CATALOG_INDEX_IMAGES format: comma-separated list supporting name=image_ref and image_ref formats
- **Acceptance criteria**:
  - [ ] Users can configure multiple catalog index images using EXTRA_CATALOG_INDEX_IMAGES via extraEnvs in the Backstage CR
  - [ ] Documentation explains both name=image_ref and plain image_ref formats with examples
  - [ ] Disconnected environment configuration using RELATED_IMAGE_extra_catalog_index_{name} is documented with complete examples
  - [ ] Relationship between primary CATALOG_INDEX_IMAGE and extra catalog images is clearly explained
  - [ ] Integration with existing plugin mirroring documentation shows how to mirror multiple catalog indexes
  - [ ] Documentation clarifies that extra catalogs contribute catalog entities only, not dynamic-plugins.default.yaml
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent feature: Support several plugin catalogs in the Extensions plugin
  - [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933): install-dynamic-plugins script implementation
  - [rhdh-operator/pull/2717](https://github.com/redhat-developer/rhdh-operator/pull/2717): Operator implementation PR with documentation updates

### Medium

#### REQ-004: Document directory structure for extra catalog entities
- **Source**: [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933) | [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655)
- **Summary**: Red Hat Developer Hub 1.10.0 introduces support for multiple plugin catalog index images through the new EXTRA_CATALOG_INDEX_IMAGES environment variable. Extra catalog entities are automatically extracted to isolated subdirectories under /extensions/extra/, enabling administrators to configure multiple plugin sources (community, partner, etc.) while maintaining clear separation from the primary catalog. This enhances the Extensions UI by making additional plugin catalogs discoverable without requiring container rebuilds.
- **User impact**: Administrators can now configure multiple plugin catalog sources simultaneously, making community and partner plugins visible in the Extensions UI alongside the primary Red Hat catalog. The isolated directory structure prevents naming conflicts and enables users to distinguish plugin sources by subdirectory name.
- **Documentation action**:
  - [ ] Update `con-install-dynamic-plugins.adoc` (CONCEPT) - Add explanation of extra catalog index images and directory isolation model
  - [ ] Create `proc-configuring-extra-catalog-index-images.adoc` (PROCEDURE) - Document how to configure EXTRA_CATALOG_INDEX_IMAGES with Helm and Operator
  - [ ] Create `ref-extra-catalog-index-directory-structure.adoc` (REFERENCE) - Document directory naming rules and extraction paths
  - [ ] Update `ref-install-dynamic-plugins-environment-variables.adoc` (REFERENCE) - Add EXTRA_CATALOG_INDEX_IMAGES variable documentation
- **Acceptance criteria**:
  - [ ] Users can configure the EXTRA_CATALOG_INDEX_IMAGES environment variable using both name=image_ref and plain image_ref formats
  - [ ] Documentation explains that extra catalog images provide catalog entities only, not dynamic-plugins.default.yaml
  - [ ] Directory naming conventions are documented: explicit names (community=image) vs auto-derived names (image becomes quay.io_org_image_tag)
  - [ ] The /extensions/extra/ parent directory structure is clearly documented with tree examples
  - [ ] Duplicate subdirectory name behavior (warning and overwrite) is documented
  - [ ] Users understand the difference between CATALOG_INDEX_IMAGE (primary, provides DPDY) and EXTRA_CATALOG_INDEX_IMAGES (visibility only)
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent epic: Support several plugin catalogs in Extensions UI
  - [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655): Feature implementation with inline documentation
  - [install-dynamic-plugins.py:40-56](https://github.com/redhat-developer/rhdh/pull/4655/files#diff-a32ed388ae33c59cd53e8dc5445bb8cab32e9c3d7f3fb5a7ff75ac0d2d1b1R40-R56): EXTRA_CATALOG_INDEX_IMAGES environment variable docstring

#### REQ-005: Document naming conventions for extra catalog images
- **Source**: [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933) | [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655)
- **Summary**: RHDH 1.10 introduces support for multiple plugin catalog index images through a new EXTRA_CATALOG_INDEX_IMAGES environment variable in the install-dynamic-plugins.py script. This allows administrators to configure additional plugin catalogs alongside the primary CATALOG_INDEX_IMAGE, making community, partner, and custom plugins discoverable in the Extensions UI without modifying the primary catalog. The feature supports both explicit naming (name=image_ref) and auto-derived subdirectory names from plain image references, with catalog entities extracted to isolated subdirectories under /extensions/extra/.
- **User impact**: Users can now discover and manage plugins from multiple catalog sources in the Extensions UI. This enables organizations to separate Red Hat supported plugins, community plugins, partner plugins, and custom internal plugins into distinct catalogs while maintaining a unified discovery experience. Users must still explicitly configure and install plugins from extra catalogs in their dynamic-plugins.yaml file - extra catalogs only provide discovery, not automatic installation.
- **Documentation action**:
  - [ ] Create `proc-configure-extra-catalog-index-images.adoc` (PROCEDURE) - Main procedure for configuring EXTRA_CATALOG_INDEX_IMAGES in Helm and Operator deployments
  - [ ] Create `ref-extra-catalog-naming-conventions.adoc` (REFERENCE) - Reference table documenting name=image_ref syntax, auto-derivation rules, subdirectory structure, and duplicate handling
  - [ ] Update `con-browse-and-manage-available-plugins-using-the-extensions-ui.adoc` (CONCEPT) - Add explanation of multiple catalog sources and how they appear in Extensions UI
  - [ ] Update `ref-helm-chart-configuration-parameters.adoc` (REFERENCE) - Add EXTRA_CATALOG_INDEX_IMAGES parameter to Helm chart environment variables table
  - [ ] Update `ref-operator-configuration-parameters.adoc` (REFERENCE) - Add EXTRA_CATALOG_INDEX_IMAGES parameter to Operator configuration reference
- **Acceptance criteria**:
  - [ ] Users can configure EXTRA_CATALOG_INDEX_IMAGES using both name=image_ref and plain image_ref formats following documented syntax
  - [ ] Users understand that extra catalog images only provide plugin discovery and do not enable automatic plugin installation
  - [ ] Users can predict subdirectory names created by auto-derivation rules (replacing /, :, @ with _)
  - [ ] Users understand duplicate subdirectory name behavior (later entries overwrite earlier ones with warning)
  - [ ] Users can configure extra catalog images in both Helm and Operator deployments
  - [ ] Helm chart reference documentation includes EXTRA_CATALOG_INDEX_IMAGES parameter with format examples
  - [ ] Operator reference documentation includes EXTRA_CATALOG_INDEX_IMAGES parameter with format examples
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent feature: Support several plugin catalogs in the Extensions plugin
  - [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655): Implementation PR introducing EXTRA_CATALOG_INDEX_IMAGES environment variable
  - [install-dynamic-plugins.py:134-165](https://github.com/redhat-developer/rhdh/pull/4655/files#diff-b5c0e38e8d6aad0d5a4c6a5e1f6e5c1e9e7e5c1eR134-R165): parse_extra_catalog_index_images() function implementing name=image_ref and auto-derivation logic

#### REQ-006: Document primary vs extra catalog index behavior
- **Source**: [RHIDP-12374](https://redhat.atlassian.net/browse/RHIDP-12374) | [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655)
- **Summary**: RHDH 1.10.0 introduces support for multiple plugin catalog index images, distinguishing between a primary CATALOG_INDEX_IMAGE that provides both the dynamic-plugins.default.yaml configuration file and catalog entities, and additional EXTRA_CATALOG_INDEX_IMAGES that contribute catalog entities only for display in the Extensions UI. This enables administrators to configure multiple plugin sources (e.g., Red Hat, community, partner catalogs) while maintaining a single authoritative source for default plugin configurations.
- **User impact**: Administrators can now configure additional plugin catalog sources from community, partner, or internal repositories, making them visible in the Extensions UI without conflicting default configurations. Users browsing the Extensions UI will see plugins from all configured catalog sources organized in separate subdirectories. However, plugins from extra catalog index images must still be explicitly configured in dynamic-plugins.yaml to be installed.
- **Documentation action**:
  - [ ] Create `con-primary-vs-extra-catalog-index-images.adoc` (CONCEPT) - Explain the distinction between primary and extra catalog index images, their different purposes, and how they interact
  - [ ] Create `proc-configure-extra-catalog-index-images.adoc` (PROCEDURE) - Step-by-step guide to configuring EXTRA_CATALOG_INDEX_IMAGES in Helm, Operator, and local deployments
  - [ ] Create `ref-extra-catalog-index-images-format.adoc` (REFERENCE) - Document the format for EXTRA_CATALOG_INDEX_IMAGES: comma-separated list, name=image_ref syntax, subdirectory naming rules, and duplicate handling behavior
  - [ ] Update `extend/con-dynamic-plugins.adoc` (CONCEPT) - Add cross-reference to multi-catalog support and clarify that CATALOG_INDEX_IMAGE is the primary source for dynamic-plugins.default.yaml
  - [ ] Update `extend/con-manage-plugins.adoc` (CONCEPT) - Add explanation that Extensions UI can display plugins from multiple catalog sources
- **Acceptance criteria**:
  - [ ] Users understand the difference between CATALOG_INDEX_IMAGE (provides dynamic-plugins.default.yaml + catalog entities) and EXTRA_CATALOG_INDEX_IMAGES (catalog entities only)
  - [ ] Users can successfully configure multiple catalog index images using the name=image_ref format in Helm values, Operator CR, or local environment variables
  - [ ] Users understand that catalog entities from extra images are extracted to /extensions/extra/<subdirectory>/catalog-entities directories
  - [ ] Users understand the subdirectory naming rules: explicit names vs auto-derived from image reference by replacing '/', ':', '@' with '_'
  - [ ] Users understand that duplicate subdirectory names trigger a warning and the later entry overwrites the earlier one
  - [ ] Users understand that plugins from extra catalog indexes are visible in Extensions UI but must be explicitly configured in dynamic-plugins.yaml to be installed
  - [ ] Documentation includes examples showing both named and auto-derived subdirectory configurations
  - [ ] Documentation clarifies that the marketplace/extensions directory fallback behavior applies to extra catalog indexes
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent feature: Support several plugin catalogs in the Extensions plugin
  - [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933): Implementation ticket for install-dynamic-plugins script changes
  - [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655): Implementation PR with documentation updates to docs/dynamic-plugins/installing-plugins.md

#### REQ-008: Document RHDH Local support for multiple catalog images
- **Source**: [RHIDP-12936](https://redhat.atlassian.net/browse/RHIDP-12936)
- **Summary**: RHDH 1.10 introduced support for configuring multiple catalog index images in RHDH Local deployments. Users can now specify a primary catalog index image (via CATALOG_INDEX_IMAGE) and additional catalog index images (via EXTRA_CATALOG_INDEX_IMAGES) to make plugins from multiple sources discoverable in the Extensions UI. Extra catalog images contribute catalog entities only and do not provide dynamic-plugins.default.yaml files, meaning plugins from extra catalogs appear in Extensions but must be explicitly configured to be installed.
- **User impact**: RHDH Local users can now discover and explore plugins from multiple catalog sources (community, partner, internal) simultaneously in the Extensions UI, while maintaining a single primary catalog for default plugin configurations. This enables local testing of multi-source plugin scenarios without deploying to Kubernetes.
- **Documentation action**:
  - [ ] Create `proc-configure-multiple-catalog-index-images-rhdh-local.adoc` (PROCEDURE) - Procedure for configuring EXTRA_CATALOG_INDEX_IMAGES in RHDH Local .env file
  - [ ] Update `con-rhdh-local-configuration.adoc` (CONCEPT) - Add EXTRA_CATALOG_INDEX_IMAGES to environment variables reference section
  - [ ] Update `ref-rhdh-local-environment-variables.adoc` (REFERENCE) - Document EXTRA_CATALOG_INDEX_IMAGES variable format and examples
- **Acceptance criteria**:
  - [ ] Users can configure multiple catalog index images in RHDH Local using the EXTRA_CATALOG_INDEX_IMAGES environment variable
  - [ ] Documentation explains the difference between primary (CATALOG_INDEX_IMAGE) and extra catalog index images
  - [ ] Users understand that extra catalog images only provide catalog entities for Extensions UI, not default plugin installations
  - [ ] Documentation provides examples of both named (name=image_ref) and unnamed (image_ref) formats
  - [ ] Users can configure multiple extra images as a comma-separated list
  - [ ] Documentation explains the extraction directory structure (/extensions/extra/<name>/)
  - [ ] Users understand the minimum RHDH version requirement (1.10+) for this feature
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent epic for multi-source plugin catalog support
  - [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933): install-dynamic-plugins implementation
  - [rhdh#4655](https://github.com/redhat-developer/rhdh/pull/4655): Core install-dynamic-plugins.py implementation adding EXTRA_CATALOG_INDEX_IMAGES support

### Low

#### REQ-007: Document duplicate subdirectory handling
- **Source**: [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933) | [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655)
- **Summary**: The install-dynamic-plugins script now handles duplicate subdirectory names when extracting multiple catalog index images by displaying a warning and allowing the later entry to overwrite the earlier one. This feature enables users to intentionally override catalog entities from one source with another by controlling the order in EXTRA_CATALOG_INDEX_IMAGES. The warning message clearly identifies which image's extraction is being overwritten, helping users understand when unintentional duplicates occur.
- **User impact**: Users configuring multiple catalog index images via EXTRA_CATALOG_INDEX_IMAGES may encounter duplicate subdirectory names either intentionally (to override catalog entities) or unintentionally (configuration error). The warning messages help users identify when overwrites occur, allowing them to correct accidental duplicates or confirm intentional override behavior.
- **Documentation action**:
  - [ ] Update `proc-enable-plugins-added-in-the-rhdh-container-image.html` (PROCEDURE) - Add note explaining duplicate subdirectory warning behavior in EXTRA_CATALOG_INDEX_IMAGES section
  - [ ] Update `con-helm-chart-configuration-parameters.html` (REFERENCE) - Document duplicate handling behavior in EXTRA_CATALOG_INDEX_IMAGES parameter description
  - [ ] Create `ref-extra-catalog-index-images-behavior.html` (REFERENCE) - Optional: Create dedicated reference explaining subdirectory naming, collision handling, and override patterns
- **Acceptance criteria**:
  - [ ] Users understand that duplicate subdirectory names in EXTRA_CATALOG_INDEX_IMAGES will trigger a warning message
  - [ ] Users know that later entries overwrite earlier entries when subdirectories collide
  - [ ] Documentation explains both explicit name= format and auto-derived subdirectory naming to help users avoid unintentional collisions
  - [ ] Users can identify intentional override patterns (using order to control precedence) versus accidental duplicates
  - [ ] Warning message format is documented so users know what to look for in logs
- **References**:
  - [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335): Parent epic for multi-source plugin catalog support
  - [PR #4655](https://github.com/redhat-developer/rhdh/pull/4655): Implementation PR with duplicate handling logic
  - [PR #4655 - docs/dynamic-plugins/installing-plugins.md:31](https://github.com/redhat-developer/rhdh/pull/4655): Documentation added: 'If multiple entries map to the same subdirectory name, a warning is printed and the later entry overwrites the earlier one.'

## Documentation scope

### New documentation needed

| Requirement | Scope | References |
|-------------|-------|------------|
| REQ-001 | Document EXTRA_CATALOG_INDEX_IMAGES environment variable syntax, formats, behavior, and relationship to CATALOG_INDEX_IMAGE; procedures for Helm and Operator configuration | RHIDP-12933, PR #4655 |
| REQ-002 | Document global.catalogIndex.extraImages Helm configuration including parameter reference, procedure, and mirroring support | RHIDP-12934, PR #368 |
| REQ-003 | Document Operator support for EXTRA_CATALOG_INDEX_IMAGES via extraEnvs and RELATED_IMAGE_extra_catalog_index_{name} for disconnected environments | RHIDP-12935, PR #2717 |
| REQ-004 | Document directory structure for extra catalog entities under /extensions/extra/ with naming rules and extraction paths | RHIDP-12933, PR #4655 |
| REQ-005 | Document naming conventions for name=image_ref syntax and auto-derivation rules | RHIDP-12933, PR #4655 |
| REQ-006 | Document distinction between primary CATALOG_INDEX_IMAGE and EXTRA_CATALOG_INDEX_IMAGES functionality | RHIDP-12374, PR #4655 |
| REQ-007 | Document duplicate subdirectory warning behavior and overwrite semantics | RHIDP-12933, PR #4655 |
| REQ-008 | Document RHDH Local support for EXTRA_CATALOG_INDEX_IMAGES configuration | RHIDP-12936 |

### Existing documentation to update

| Requirement | What changed | References |
|-------------|-------------|------------|
| REQ-001 | Add global.catalogIndex.extraImages to Helm parameters; update install-dynamic-plugins concept with extra catalog behavior | RHIDP-12933, PR #4655 |
| REQ-002 | Add extraImages to Helm chart reference; update mirroring procedures for multiple catalog images; add note about extra catalog entities in plugin enablement procedure | RHIDP-12934, PR #368 |
| REQ-003 | Update disconnected environment mirroring documentation for RELATED_IMAGE_extra_catalog_index_{name}; update extraEnvs injection procedure with EXTRA_CATALOG_INDEX_IMAGES example | RHIDP-12935, PR #2717 |
| REQ-004 | Add extra catalog explanation to install-dynamic-plugins concept; add EXTRA_CATALOG_INDEX_IMAGES to environment variables reference | RHIDP-12933, PR #4655 |
| REQ-005 | Add multi-catalog explanation to Extensions UI concept; add EXTRA_CATALOG_INDEX_IMAGES to Helm and Operator configuration references | RHIDP-12933, PR #4655 |
| REQ-006 | Update dynamic plugins concept with multi-catalog cross-reference; update plugin management concept with multi-source catalog explanation | RHIDP-12374, PR #4655 |
| REQ-007 | Add duplicate warning note to plugin enablement procedure; update Helm chart parameters with duplicate handling behavior | RHIDP-12933, PR #4655 |
| REQ-008 | Update RHDH Local configuration concept and environment variables reference with EXTRA_CATALOG_INDEX_IMAGES | RHIDP-12936 |

## Notes

This feature introduces multi-source plugin catalog support across all RHDH deployment methods (Helm, Operator, RHDH Local) in version 1.10.0. The implementation distinguishes between a primary catalog index (CATALOG_INDEX_IMAGE) that provides both dynamic-plugins.default.yaml and catalog entities, versus extra catalog indexes (EXTRA_CATALOG_INDEX_IMAGES) that contribute catalog entities only for Extensions UI discovery. Documentation must emphasize that extra catalogs enable plugin discovery but do not automatically install plugins - users must still configure desired plugins in dynamic-plugins.yaml. The feature supports both explicit naming (name=image_ref) and auto-derived subdirectory names from image references, with duplicate handling via warning messages and last-write-wins semantics.

## Related tickets

- **Parent**: [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335) - Support several plugin catalogs in the Extensions plugin
- **Children**:
  - [RHIDP-12421](https://redhat.atlassian.net/browse/RHIDP-12421) - Investigate QE work needed for: Multi-Source Plugin Catalog Support
  - [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933) - Update install-dynamic-plugins to parse and extract multiple catalog index images
  - [RHIDP-12934](https://redhat.atlassian.net/browse/RHIDP-12934) - Update Helm Chart to support configuring multiple catalog index images
  - [RHIDP-12935](https://redhat.atlassian.net/browse/RHIDP-12935) - Update Operator to support configuring multiple catalog index images
  - [RHIDP-12936](https://redhat.atlassian.net/browse/RHIDP-12936) - Update RHDH Local to support configuring multiple catalog index images

## Sources consulted

### JIRA tickets
- [RHIDP-12374](https://redhat.atlassian.net/browse/RHIDP-12374) - Multi-Source Plugin Catalog Support
- [RHDHPLAN-335](https://redhat.atlassian.net/browse/RHDHPLAN-335) - Support several plugin catalogs in the Extensions plugin
- [RHIDP-12933](https://redhat.atlassian.net/browse/RHIDP-12933) - Update install-dynamic-plugins to parse and extract multiple catalog index images
- [RHIDP-12934](https://redhat.atlassian.net/browse/RHIDP-12934) - Update Helm Chart to support configuring multiple catalog index images
- [RHIDP-12935](https://redhat.atlassian.net/browse/RHIDP-12935) - Update Operator to support configuring multiple catalog index images
- [RHIDP-12936](https://redhat.atlassian.net/browse/RHIDP-12936) - Update RHDH Local to support configuring multiple catalog index images

### Pull requests / Merge requests
- [rhdh/pull/4655](https://github.com/redhat-developer/rhdh/pull/4655) - feat: support extra catalog index images for Extensions UI [RHIDP-12933]
- [rhdh-chart/pull/368](https://github.com/redhat-developer/rhdh-chart/pull/368) - feat: support configuring multiple catalog index images [RHIDP-12934]
- [rhdh-operator/pull/2717](https://github.com/redhat-developer/rhdh-operator/pull/2717) - feat: support configuring multiple catalog index images [RHIDP-12935]

### Code files
- install-dynamic-plugins.py (EXTRA_CATALOG_INDEX_IMAGES environment variable implementation and parsing logic)
- rhdh-chart values.yaml (global.catalogIndex.extraImages configuration schema)
- rhdh-operator Backstage CR (extraEnvs and RELATED_IMAGE pattern support)

### Existing documentation
- docs/dynamic-plugins/installing-plugins.md - Updated to document EXTRA_CATALOG_INDEX_IMAGES environment variable
- docs/catalog-index-configuration.md - Updated to document global.catalogIndex.extraImages Helm configuration
- docs/dynamic-plugins.md - Updated to document operator support for extra catalog index images
- .rhdh/docs/mirror-dynamic-plugins.adoc - Updated to document mirroring extra catalog index images in disconnected environments

### Web search findings
- [Red Hat Developer Hub installing-plugins.md documentation](https://github.com/redhat-developer/rhdh/blob/main/docs/dynamic-plugins/installing-plugins.md) - Upstream documentation source for catalog index image concepts and usage patterns
- [Browse Red Hat Developer Hub's Extensive Plugins Catalog With The New Extensions Plugin](https://developers.redhat.com/blog/2025/04/02/browse-red-hat-developer-hubs-extensive-plugins-catalog-new-extensions-plugin) - Context on Extensions UI plugin catalog browsing feature
- [Installing and viewing plugins in Red Hat Developer Hub](https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/main/plugins-rhdh-install/) - Published documentation on plugin installation patterns
- [Configuring dynamic plugins - Red Hat Documentation](https://docs.redhat.com/en/documentation/red_hat_developer_hub/1.8/html-single/configuring_dynamic_plugins/index) - Official documentation for dynamic plugin configuration patterns
- [OCI Image Format Specification](https://github.com/opencontainers/image-spec) - OCI image structure and layer extraction best practices
- [Backstage Software Catalog Descriptor Format](https://backstage.io/docs/features/software-catalog/descriptor-format/) - Catalog entity format used in RHDH
