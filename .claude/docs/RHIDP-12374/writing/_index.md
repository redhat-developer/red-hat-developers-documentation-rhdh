# Documentation Modules: RHIDP-12374

**Ticket:** RHIDP-12374
**Generated:** 2026-09-04
**Placement mode:** UPDATE-IN-PLACE
**Build framework:** ccutil (Red Hat Customer Portal)
**Repository:** /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2

## Files Written

| Path | Type | Description |
|------|------|-------------|
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/extend_configuring-dynamic-plugins/con-primary-vs-extra-catalog-index-images.adoc | CONCEPT | Explains the distinction between primary and extra catalog index images |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/extend_configuring-dynamic-plugins/con-extra-catalog-naming-conventions.adoc | CONCEPT | Describes subdirectory naming rules for extra catalog index images |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/configure_configuring-rhdh/proc-configure-extra-catalog-index-images-helm.adoc | PROCEDURE | Steps to configure extra catalog index images in Helm deployments |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/configure_configuring-rhdh/proc-configure-extra-catalog-index-images-operator.adoc | PROCEDURE | Steps to configure extra catalog index images in Operator deployments |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/configure_configuring-rhdh/proc-configure-extra-catalog-index-images-disconnected.adoc | PROCEDURE | Steps to configure extra catalog index images in disconnected Operator deployments |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/configure_configuring-rhdh/proc-configure-extra-catalog-index-images-rhdh-local.adoc | PROCEDURE | Steps to configure extra catalog index images in RHDH Local deployments |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/extend_configuring-dynamic-plugins/ref-extra-catalog-index-images-environment-variable.adoc | REFERENCE | Reference documentation for the EXTRA_CATALOG_INDEX_IMAGES environment variable |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/extend_configuring-dynamic-plugins/ref-extra-catalog-index-directory-structure.adoc | REFERENCE | Reference documentation for the extra catalog index directory structure |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/modules/configure_configuring-rhdh/ref-helm-chart-catalog-index-extra-images.adoc | REFERENCE | Reference documentation for the Helm chart global.catalogIndex.extraImages parameter |
| /Users/gforde/mygit-rhdh/red-hat-developers-documentation-rhdh-v2/assemblies/extend_configuring-dynamic-plugins/assembly-manage-plugin-catalog-sources.adoc | ASSEMBLY | Assembly combining all modules into a complete user story for managing plugin catalog sources |

## Summary

Created 10 new files for the multi-source plugin catalog support feature:

- **2 concept modules** explaining primary vs extra catalog distinction and naming conventions
- **4 procedure modules** covering Helm, Operator, disconnected Operator, and RHDH Local configurations
- **3 reference modules** documenting the environment variable, directory structure, and Helm parameter
- **1 assembly** organizing all modules into a complete user story

All files follow Red Hat modular documentation conventions:
- Use `con-`, `proc-`, `ref-` prefixes
- Include `_{context}` in module anchor IDs
- Omit `_{context}` in assembly anchor ID
- Include `:_mod-docs-content-type:` attribute
- Use ventilated prose (one sentence per line)
- Include `[role="_abstract"]` short descriptions
- Follow outcome-focused titling

## Next Steps

1. Run Vale linting on all modules
2. Review for technical accuracy
3. Review for style compliance
4. Add navigation entries to appropriate title/category files
5. Build locally to verify include paths and rendering
6. Submit for peer review
