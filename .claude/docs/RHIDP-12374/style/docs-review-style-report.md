# Style Review Report

**Source**: Branch: RHIDP-12610 vs main
**Date**: 2026-09-07
**Commit**: 627ed07ab2 - RHIDP-12610 - Support several plugin catalogs in the Extensions plugin

## Summary

| Metric | Count |
|--------|-------|
| Files reviewed | 11 |
| Errors (must fix) | 35 |
| Warnings (should fix) | 14 |
| Suggestions (optional) | 6 |

## Files Reviewed

### New Files (10)
- `assemblies/extend_configuring-dynamic-plugins/assembly-manage-plugin-catalog-sources.adoc` (ASSEMBLY)
- `modules/extend_configuring-dynamic-plugins/con-extra-catalog-naming-conventions.adoc` (CONCEPT)
- `modules/extend_configuring-dynamic-plugins/con-primary-vs-extra-catalog-index-images.adoc` (CONCEPT)
- `modules/extend_configuring-dynamic-plugins/ref-extra-catalog-index-directory-structure.adoc` (REFERENCE)
- `modules/extend_configuring-dynamic-plugins/ref-extra-catalog-index-images-environment-variable.adoc` (REFERENCE)
- `modules/shared/proc-configure-extra-catalog-index-images-disconnected.adoc` (PROCEDURE)
- `modules/shared/proc-configure-extra-catalog-index-images-helm.adoc` (PROCEDURE)
- `modules/shared/proc-configure-extra-catalog-index-images-operator.adoc` (PROCEDURE)
- `modules/shared/proc-configure-extra-catalog-index-images-rhdh-local.adoc` (PROCEDURE)
- `modules/shared/ref-helm-chart-catalog-index-extra-images.adoc` (REFERENCE)

### Modified Files (1)
- `titles/extend_configuring-dynamic-plugins/master.adoc` (changed lines 17-18)

---

## Critical Issues (Errors - Must Fix)

### Modular Documentation Structure

#### 1. Assembly anchor ID format
**File**: `assemblies/extend_configuring-dynamic-plugins/assembly-manage-plugin-catalog-sources.adoc:4`
- **Issue**: Anchor ID includes `_{context}` suffix: `[id="manage-plugin-catalog-sources_{context}"]`
- **Reason**: Red Hat modular docs - assemblies must NOT include `_{context}` in anchor IDs
- **Fix**: Change to `[id="manage-plugin-catalog-sources"]`
- **Confidence**: 100%

#### 2. Missing anchor IDs on standard subheadings (34 instances)

**Red Hat modular documentation requires anchor IDs with `_{context}` suffix on all standard subheadings (level 2+) within modules.**

##### con-extra-catalog-naming-conventions.adoc (5 missing)
- Line 10: `== Why subdirectory names matter` → needs `[id="why-subdirectory-names-matter_{context}"]`
- Line 20: `== Explicit naming with the name=image_ref format` → needs anchor
- Line 37: `== Auto-derived naming from image references` → needs anchor
- Line 57: `== Duplicate subdirectory names` → needs anchor
- Line 72: `== Best practices for naming` → needs anchor

##### con-primary-vs-extra-catalog-index-images.adoc (5 missing)
- Line 9: `== What catalog index images contain` → needs anchor
- Line 19: `== Primary catalog index image` → needs anchor
- Line 30: `== Extra catalog index images` → needs anchor
- Line 41: `== Why this separation matters` → needs anchor
- Line 53: `== Common use cases` → needs anchor

##### ref-extra-catalog-index-directory-structure.adoc (6 missing)
- Line 9: `== Primary catalog directory structure` → needs anchor
- Line 25: `== Extra catalog directory structure` → needs anchor
- Line 51: `== Subdirectory naming rules` → needs anchor
- Line 63: `== Directory structure examples` → needs anchor
- Line 127: `== Fallback directory locations` → needs anchor
- Line 136: `== Verifying directory structure` → needs anchor

##### ref-extra-catalog-index-images-environment-variable.adoc (9 missing)
- Line 9: `== Variable name` → needs anchor
- Line 13: `== Purpose` → needs anchor
- Line 18: `== Format` → needs anchor
- Line 33: `== Behavior` → needs anchor
- Line 50: `== Subdirectory naming examples` → needs anchor
- Line 78: `== Relationship to CATALOG_INDEX_IMAGE` → needs anchor
- Line 93: `== Duplicate handling` → needs anchor
- Line 113: `== Supported deployment methods` → needs anchor
- Line 121: `== Disconnected environments` → needs anchor

##### ref-helm-chart-catalog-index-extra-images.adoc (9 missing)
- Line 9: `== Parameter path` → needs anchor
- Line 13: `== Parameter type` → needs anchor
- Line 17: `== Default value` → needs anchor
- Line 21: `== Purpose` → needs anchor
- Line 26: `== Sub-fields` → needs anchor
- Line 59: `== Behavior` → needs anchor
- Line 73: `== Configuration examples` → needs anchor
- Line 140: `== Duplicate handling` → needs anchor
- Line 168: `== Relationship to CATALOG_INDEX_IMAGE` → needs anchor

---

## Warnings (Should Fix)

### User-replaced values not italicized in running text (12 instances)

**RH SSG Formatting**: User-replaced values like `<pod_name>` should be italicized when referenced in running text outside code blocks.

#### ref-extra-catalog-index-directory-structure.adoc
- Line 144: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`
- Line 147: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`

#### proc-configure-extra-catalog-index-images-disconnected.adoc
- Line 34: `Replace <operator_namespace> with...` → `Replace _<operator_namespace>_ with...`
- Line 37: `Replace <operator_namespace> with...` → `Replace _<operator_namespace>_ with...`
- Line 110: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`
- Line 117: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`

#### proc-configure-extra-catalog-index-images-helm.adoc
- Line 73: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`

#### proc-configure-extra-catalog-index-images-operator.adoc
- Line 73: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`
- Line 79: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`
- Line 83: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`
- Line 92: `Replace <pod_name> with...` → `Replace _<pod_name>_ with...`

#### proc-configure-extra-catalog-index-images-rhdh-local.adoc
- Line 68: `Replace <container_name> with...` → `Replace _<container_name>_ with...`

### Bold formatting on negation words (2 instances)

**IBM SG Structure**: Bold should be used for UI elements, not for emphasis. Use rephrasing instead.

#### con-primary-vs-extra-catalog-index-images.adoc
- Line 44: `do *not* install automatically` → Remove bold: `do not install automatically`

#### ref-extra-catalog-index-directory-structure.adoc
- Line 49: `do *not* provide` → Remove bold: `do not provide`

---

## Suggestions (Optional Improvements)

### Passive voice to active voice (1 instance)

#### con-extra-catalog-naming-conventions.adoc
- Line 55: `For production deployments, explicit naming is recommended.`
  - **Better**: `Use explicit naming in production deployments.`

### Explanatory list structure after code examples (3 instances)

**Pattern**: "In this example:" followed by numbered explanatory items could use description list format instead.

#### proc-configure-extra-catalog-index-images-disconnected.adoc
- Line 55-59: Consider using description list or bullet points for explanatory content

#### proc-configure-extra-catalog-index-images-operator.adoc
- Line 38-40: Same pattern

#### proc-configure-extra-catalog-index-images-rhdh-local.adoc
- Line 30-33: Same pattern

### Minor improvements (2 instances)

#### con-extra-catalog-naming-conventions.adoc
- Line 14: Definition list term could be simplified for clarity

#### proc-configure-extra-catalog-index-images-helm.adoc
- Line 78: `Replace <pod_name> with the name of your {product} pod.` - user-replaced value should be italicized

---

## Review Notes

### Strengths
✅ Excellent modular documentation structure (concepts, procedures, references, assemblies properly separated)
✅ Consistent use of `:_mod-docs-content-type:` attributes
✅ Proper use of `[role="_abstract"]` and `[role="_additional-resources"]`
✅ Good cross-referencing between modules
✅ Clear, task-oriented content focused on user goals
✅ Comprehensive coverage of all deployment methods
✅ Proper AsciiDoc formatting for code blocks and examples

### Primary Issues
⚠️ **Missing anchor IDs**: 34 standard subheadings lack required anchor IDs with `_{context}` suffix
⚠️ **Assembly anchor ID**: Should not include `_{context}` suffix
⚠️ **User-replaced values**: 12 instances not italicized in running text
⚠️ **Emphasis formatting**: 2 instances using bold for negation words

---

*Generated with Claude Code on 2026-09-07*
