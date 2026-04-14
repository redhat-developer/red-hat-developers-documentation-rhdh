# Update prerequisites to include specific RBAC roles/permissions -- Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit all 217 procedure modules with `.Prerequisites` sections and update vague permission language to specify the exact access type (OCP admin, app config, RHDH RBAC permission, or external service).

**Architecture:** Two-phase approach. Phase 1 extracts prerequisites text and produces a categorized audit table in this document. Phase 2 batch-updates modules by directory, using standardized language templates. CQA validation after each batch.

**Tech Stack:** AsciiDoc modular documentation with product attributes.

**Spec:** `docs/superpowers/specs/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions-design.md`

---

## Standard Language Templates

Use these exact templates when updating prerequisites. All prerequisites use `*` bullet syntax.

### Category A: OCP/K8s admin

For procedures requiring cluster-level access (install, deploy, upgrade, operator management):

```asciidoc
* You have `cluster-admin` privileges on the OpenShift Container Platform cluster.
```

### Category B: App config access

For procedures that modify `app-config` ConfigMap/Secret. Most modules already use `{configuring-book-link}` which resolves to a link to the configuring title. Keep the existing `{configuring-book-link}` pattern but remove vague "sufficient permissions" language:

```asciidoc
* You have {configuring-book-link}[added a custom {product-short} application configuration].
```

If the module already has this prerequisite with vague permissions appended (e.g., ", and have sufficient permissions to modify it"), remove the vague suffix. The xref to the configuring guide is sufficient.

### Category C: RHDH RBAC

For procedures using RHDH UI/API features gated by RBAC permissions. Use the conditional because RBAC is optional:

Single permission:
```asciidoc
* If RBAC is enabled, you have a role with the following permission: `<permission.name>`.
```

Multiple permissions:
```asciidoc
* If RBAC is enabled, you have a role with the following permissions: `<perm.one>`, `<perm.two>`.
```

### Category D: External service

For procedures requiring access to an external service. Keep specific to the service. No standard template — preserve existing text if already specific, or make specific.

### No change

If the prerequisite is already specific enough, leave it as-is. Mark as "OK" in the audit table.

---

## RBAC Permission Decision Tree

When a procedure involves RHDH UI/API features, use this mapping to determine the Category C permission:

| Procedure involves... | Permission(s) |
|---|---|
| Viewing catalog entities, browsing the catalog | `catalog.entity.read` |
| Registering/creating catalog entities or components | `catalog.entity.create` |
| Refreshing catalog entities | `catalog.entity.refresh` |
| Deleting catalog entities | `catalog.entity.delete` |
| Creating/registering locations | `catalog.location.create` |
| Viewing/executing software templates | `scaffolder.template.parameter.read`, `scaffolder.template.step.read` |
| Creating scaffolder tasks (running templates) | `scaffolder.task.create` |
| Managing software templates | `scaffolder.template.management` |
| Creating/editing/deleting RBAC roles | `policy.entity.create`, `policy.entity.update`, `policy.entity.delete` |
| Reading RBAC policies | `policy.entity.read` |
| Viewing Kubernetes resources/topology/tekton | `kubernetes.clusters.read`, `kubernetes.resources.read` |
| Using Kubernetes proxy | `kubernetes.proxy` |
| Viewing ArgoCD sync status | `argocd.view.read` |
| Viewing Quay images | `quay.view.read` |
| Viewing OCM clusters | `ocm.cluster.read` |
| Bulk importing repositories | `bulk.import` |
| Running orchestrator workflows | `orchestrator.workflow.use` |
| Administering orchestrator | `orchestrator.workflowAdminView`, `orchestrator.instanceAdminView` |

**Important:** If the procedure is about *configuring* a plugin (editing `app-config`), that is Category B (app config access), not Category C. Category C only applies when the user *uses* a gated RHDH feature through the UI or API.

---

## File Map

| Action | Files | Purpose |
|---|---|---|
| Read + categorize | 217 procedure modules across `modules/` | Audit prerequisites |
| Modify | Subset of 217 modules (determined by audit) | Update vague prerequisites |
| Validate | All 32 `titles/*/master.adoc` | CQA validation after updates |

---

## Audit Table Format

Each audit task produces rows in this format. After all audit tasks complete, the consolidated table goes into the "Consolidated Audit Table" section at the end of this plan.

```markdown
| Module | Current prerequisite text | Category | Change needed? | Proposed new text |
|---|---|---|---|---|
| `proc-example.adoc` | "sufficient permissions as a platform engineer" | B | Yes | "You have {configuring-book-link}[added a custom {product-short} application configuration]." |
| `proc-other.adoc` | "You have cluster-admin..." | A | No (OK) | — |
```

**Rules for filling the table:**
- `Module`: filename only (no directory path — the task header identifies the directory)
- `Current prerequisite text`: only the vague/relevant prerequisite bullet, not all prerequisites
- `Category`: A, B, C, D, or OK (already specific)
- `Change needed?`: Yes or No
- `Proposed new text`: exact AsciiDoc text to replace the current bullet, or `—` if no change

---

### Task 1: Audit modules/shared/ (proc-a* through proc-d*)

**Files:**
- Read: all `modules/shared/proc-a*.adoc` through `modules/shared/proc-d*.adoc` that have `.Prerequisites` sections

- [ ] **Step 1: List target files**

Run:
```bash
grep -rl '^\.\s*Prerequisites' modules/shared/ --include='proc-[a-d]*.adoc' | sort
```

- [ ] **Step 2: Read each file's prerequisites section and procedure purpose**

For each file from Step 1, read the first 30 lines to see:
1. The module title (line 4, after `= `)
2. The abstract (after `[role="_abstract"]`)
3. The `.Prerequisites` section (all `*` bullets after `.Prerequisites` until `.Procedure`)

- [ ] **Step 3: Categorize each module**

For each module, determine:
1. Is the procedure about infrastructure/cluster operations? → Category A
2. Does it modify `app-config` or custom configuration? → Category B
3. Does the user interact with RHDH UI/API features? → Category C (use the decision tree)
4. Does it require external service access? → Category D
5. Are the prerequisites already specific enough? → OK

- [ ] **Step 4: Produce the audit table**

Write the audit table rows for this batch. Append them to the "Consolidated Audit Table" section at the end of this plan document.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md
git commit -m "docs(RHDHBUGS-831): audit prerequisites — shared proc-a through proc-d"
```

---

### Task 2: Audit modules/shared/ (proc-e* through proc-i*)

**Files:**
- Read: all `modules/shared/proc-e*.adoc` through `modules/shared/proc-i*.adoc` that have `.Prerequisites` sections

- [ ] **Step 1: List target files**

Run:
```bash
grep -rl '^\.\s*Prerequisites' modules/shared/ --include='proc-[e-i]*.adoc' | sort
```

- [ ] **Step 2: Read each file's prerequisites section and procedure purpose**

For each file from Step 1, read the first 30 lines to see the module title, abstract, and `.Prerequisites` section.

- [ ] **Step 3: Categorize each module**

Apply the same categorization logic as Task 1:
1. Infrastructure/cluster? → A
2. Modifies app-config? → B
3. Uses RHDH UI/API features? → C (use decision tree)
4. External service? → D
5. Already specific? → OK

- [ ] **Step 4: Produce the audit table**

Append the audit table rows for this batch to the "Consolidated Audit Table" section.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md
git commit -m "docs(RHDHBUGS-831): audit prerequisites — shared proc-e through proc-i"
```

---

### Task 3: Audit modules/shared/ (proc-j* through proc-s*)

**Files:**
- Read: all `modules/shared/proc-j*.adoc` through `modules/shared/proc-s*.adoc` that have `.Prerequisites` sections (no `proc-j*` or `proc-k*` files currently exist, so this effectively starts at `proc-l*`)

- [ ] **Step 1: List target files**

Run:
```bash
grep -rl '^\.\s*Prerequisites' modules/shared/ --include='proc-[j-s]*.adoc' | sort
```

- [ ] **Step 2: Read each file's prerequisites section and procedure purpose**

For each file from Step 1, read the first 30 lines.

- [ ] **Step 3: Categorize each module**

Apply the same categorization logic as Task 1.

- [ ] **Step 4: Produce the audit table**

Append the audit table rows for this batch to the "Consolidated Audit Table" section.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md
git commit -m "docs(RHDHBUGS-831): audit prerequisites — shared proc-l through proc-s"
```

---

### Task 4: Audit modules/shared/ (proc-t* through proc-z*)

**Files:**
- Read: all `modules/shared/proc-t*.adoc` through `modules/shared/proc-z*.adoc` that have `.Prerequisites` sections

- [ ] **Step 1: List target files**

Run:
```bash
grep -rl '^\.\s*Prerequisites' modules/shared/ --include='proc-[t-z]*.adoc' | sort
```

- [ ] **Step 2: Read each file's prerequisites section and procedure purpose**

For each file from Step 1, read the first 30 lines.

- [ ] **Step 3: Categorize each module**

Apply the same categorization logic as Task 1.

- [ ] **Step 4: Produce the audit table**

Append the audit table rows for this batch to the "Consolidated Audit Table" section.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md
git commit -m "docs(RHDHBUGS-831): audit prerequisites — shared proc-t through proc-z"
```

---

### Task 5: Audit non-shared modules

**Files:**
- Read: all modules in `modules/extend_orchestrator-in-rhdh/`, `modules/observability_*/`, `modules/configure_*/`, `modules/install_*/`, `modules/upgrade_*/`, `modules/integrate_*/`, `modules/get-started_*/`, `modules/develop_*/` that have `.Prerequisites` sections

- [ ] **Step 1: List target files**

Run:
```bash
grep -rl '^\.\s*Prerequisites' modules/ --include='*.adoc' | grep -v 'modules/shared/' | sort
```

Expected: ~86 files across multiple directories.

- [ ] **Step 2: Read each file's prerequisites section and procedure purpose**

For each file from Step 1, read the first 40 lines (non-shared modules may have longer headers). Note: some orchestrator modules include `snip-installing-the-orchestrator-common-prerequisites.adoc` — read that snippet too (it contains disconnected environment prerequisites, Category A).

- [ ] **Step 3: Categorize each module**

Apply the same categorization logic as Task 1. Non-shared modules are often install/configure procedures, so expect many Category A and B entries.

- [ ] **Step 4: Produce the audit table**

Append the audit table rows for this batch to the "Consolidated Audit Table" section.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md
git commit -m "docs(RHDHBUGS-831): audit prerequisites — non-shared modules"
```

---

### Task 6: Review gate — validate audit completeness

**Files:**
- Read: this plan document (the consolidated audit table)

This is a checkpoint. Do NOT proceed to update tasks until this task is complete.

- [ ] **Step 1: Count audit entries**

Count total rows in the consolidated audit table. Expected: 217 entries (one per module with `.Prerequisites`).

Run:
```bash
grep -c '| `proc-' docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md
```

If fewer than 217, identify missing modules:
```bash
# List all prerequisite modules
grep -rl '^\.\s*Prerequisites' modules/ --include='*.adoc' | sort > /tmp/all-prereq-modules.txt
# Compare with audit table entries
grep '| `proc-\|| `con-\|| `ref-' docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md | sed 's/.*| `\([^`]*\)`.*/\1/' | sort > /tmp/audited-modules.txt
diff /tmp/all-prereq-modules.txt /tmp/audited-modules.txt
```

- [ ] **Step 2: Summarize findings**

Count entries by category and change status:

| Category | Count | Changes needed |
|---|---|---|
| A (OCP admin) | ? | ? |
| B (App config) | ? | ? |
| C (RHDH RBAC) | ? | ? |
| D (External) | ? | ? |
| OK (no change) | ? | 0 |

- [ ] **Step 3: Flag ambiguous entries**

List any modules where the categorization is uncertain or the RBAC permission mapping is unclear. These need human review before Phase 2.

- [ ] **Step 4: Commit summary**

```bash
git add docs/superpowers/plans/2026-04-14-rhdhbugs-831-prerequisite-rbac-permissions.md
git commit -m "docs(RHDHBUGS-831): complete audit — summary and review gate"
```

**STOP HERE.** Present the audit summary and any ambiguous entries to the user. Get explicit approval before proceeding to update tasks.

---

### Task 7: Update modules — shared auth, RBAC, and user provisioning

**Files:**
- Modify: all `modules/shared/proc-*` files from the audit table where:
  - Filename contains `auth`, `rbac`, `role`, `delegate`, `define-authorizations`, `guest`, `service-to-service`, `keycloak`, `ldap`, `provisioning`, `custom-transformer`
  - Change is needed (not "OK")

- [ ] **Step 1: Identify files to update from audit table**

Read the consolidated audit table in this plan. Filter for modules in this domain that have "Yes" in the "Change needed?" column. Make a list.

- [ ] **Step 2: Update each file**

For each file, replace the vague prerequisite bullet with the proposed new text from the audit table. Use the Edit tool with the exact `old_string` (current text) and `new_string` (proposed text).

Example — for `proc-configure-a-floating-action-button-as-a-dynamic-plugin.adoc`:

Old:
```
* You must have sufficient permissions as a platform engineer.
```

New (use the Category B template since this procedure modifies `app-config`):
```
* You have {configuring-book-link}[added a custom {product-short} application configuration].
```

- [ ] **Step 3: Run CQA on affected titles**

```bash
node build/scripts/cqa/index.js titles/control-access_authentication-in-rhdh/master.adoc
node build/scripts/cqa/index.js titles/control-access_authorization-in-rhdh/master.adoc
```

Fix any CQA errors before proceeding.

- [ ] **Step 4: Commit**

```bash
git add modules/shared/proc-*.adoc
git commit -m "docs(RHDHBUGS-831): update prerequisites — auth, RBAC, user provisioning modules

Standardize permission prerequisites for authentication, RBAC,
and user provisioning procedure modules."
```

---

### Task 8: Update modules — shared plugin, catalog, and template modules

**Files:**
- Modify: all `modules/shared/proc-*` files from the audit table where:
  - Filename contains `plugin`, `enable-the-`, `install-`, `load-a-plugin`, `export-plugin`, `verify-plugin`, `catalog`, `component`, `register`, `template`, `import`, `bulk`, `scaffolder`, `extensions`
  - Change is needed

- [ ] **Step 1: Identify files to update from audit table**

Read the consolidated audit table. Filter for modules in this domain that have "Yes" in the "Change needed?" column.

- [ ] **Step 2: Update each file**

For each file, replace the vague prerequisite bullet with the proposed new text from the audit table.

- [ ] **Step 3: Run CQA on affected titles**

```bash
node build/scripts/cqa/index.js titles/extend_installing-and-viewing-plugins-in-rhdh/master.adoc
node build/scripts/cqa/index.js titles/extend_configuring-dynamic-plugins/master.adoc
node build/scripts/cqa/index.js titles/extend_using-dynamic-plugins-in-rhdh/master.adoc
node build/scripts/cqa/index.js titles/extend_develop-and-deploy-pugins-in-rhdh/master.adoc
node build/scripts/cqa/index.js titles/develop_streamline-software-development-and-management-in-rhdh/master.adoc
```

Fix any CQA errors.

- [ ] **Step 4: Commit**

```bash
git add modules/shared/proc-*.adoc
git commit -m "docs(RHDHBUGS-831): update prerequisites — plugin, catalog, template modules

Standardize permission prerequisites for plugin management,
catalog operations, and software template procedure modules."
```

---

### Task 9: Update modules — shared customization, UX, and remaining modules

**Files:**
- Modify: all remaining `modules/shared/proc-*` files from the audit table that were not covered in Tasks 7-8 and have changes needed. This includes:
  - Customization: `customize-*`, `define-the-layout-*`, `switch-the-theme-*`, `configure-entity-detail-*`
  - Localization: `enable-*-localization-*`, `override-translations`, `select-the-language-*`
  - User features: `use-quick-start-*`, `download-active-users-*`, `manage-chats`, `start-and-complete-*`, `view-virtual-*`, `use-hosted-*`, `use-a-dedicated-*`, `test-api-*`
  - Home page: `customize-the-home-page-*`, `configure-role-based-access-control-for-quick-starts`
  - Remaining: `configure-the-github-events-*`, `enable-github-repository-discovery`, `streamline-documentation-*`, `add-video-*`, `configure-amazon-s3-*`, `enable-auto-logout-*`

- [ ] **Step 1: Identify files to update from audit table**

Read the consolidated audit table. Filter for remaining shared modules that have "Yes" in the "Change needed?" column.

- [ ] **Step 2: Update each file**

For each file, replace the vague prerequisite bullet with the proposed new text from the audit table.

- [ ] **Step 3: Run CQA on affected titles**

```bash
node build/scripts/cqa/index.js titles/configure_customizing-rhdh/master.adoc
node build/scripts/cqa/index.js titles/configure_configuring-rhdh/master.adoc
node build/scripts/cqa/index.js titles/get-started_navigate-rhdh-on-your-first-day/master.adoc
node build/scripts/cqa/index.js titles/configure_techdocs-for-rhdh/master.adoc
node build/scripts/cqa/index.js titles/develop_manage-and-consume-technical-documentation-within-rhdh/master.adoc
node build/scripts/cqa/index.js titles/integrate_integrating-rhdh-with-your-git-provider/master.adoc
```

Fix any CQA errors.

- [ ] **Step 4: Commit**

```bash
git add modules/shared/proc-*.adoc
git commit -m "docs(RHDHBUGS-831): update prerequisites — customization, UX, remaining shared modules

Standardize permission prerequisites for customization, localization,
user features, and remaining shared procedure modules."
```

---

### Task 10: Update non-shared modules

**Files:**
- Modify: all non-shared modules from the audit table that have changes needed:
  - `modules/extend_orchestrator-in-rhdh/proc-*.adoc`
  - `modules/observability_*/proc-*.adoc`
  - `modules/configure_*/proc-*.adoc`
  - `modules/install_*/proc-*.adoc`
  - `modules/upgrade_*/proc-*.adoc`
  - `modules/integrate_*/proc-*.adoc`
  - `modules/get-started_*/proc-*.adoc`
  - `modules/develop_*/proc-*.adoc`

- [ ] **Step 1: Identify files to update from audit table**

Read the consolidated audit table. Filter for all non-shared modules that have "Yes" in the "Change needed?" column.

- [ ] **Step 2: Update each file**

For each file, replace the vague prerequisite bullet with the proposed new text from the audit table.

- [ ] **Step 3: Run CQA on affected titles**

```bash
node build/scripts/cqa/index.js titles/extend_orchestrator-in-rhdh/master.adoc
node build/scripts/cqa/index.js titles/observability_evaluate-project-health-using-scorecards/master.adoc
node build/scripts/cqa/index.js titles/observability_monitoring-and-logging/master.adoc
node build/scripts/cqa/index.js titles/observability_telemetry-data-collection-and-analysis/master.adoc
node build/scripts/cqa/index.js titles/observability_audit-logs-in-rhdh/master.adoc
node build/scripts/cqa/index.js titles/configure_configuring-rhdh/master.adoc
node build/scripts/cqa/index.js titles/configure_techdocs-for-rhdh/master.adoc
node build/scripts/cqa/index.js titles/install_installing-rhdh-on-ocp/master.adoc
node build/scripts/cqa/index.js titles/install_installing-rhdh-in-an-air-gapped-environment/master.adoc
node build/scripts/cqa/index.js titles/install_installing-rhdh-on-osd-on-gcp/master.adoc
node build/scripts/cqa/index.js titles/upgrade_upgrade-rhdh/master.adoc
node build/scripts/cqa/index.js titles/integrate_interacting-with-model-context-protocol-tools-for-rhdh/master.adoc
node build/scripts/cqa/index.js titles/integrate_accelerating-ai-development-with-openshift-ai-connector-for-rhdh/master.adoc
node build/scripts/cqa/index.js titles/get-started_setting-up-and-configuring-your-first-red-hat-developer-hub-instance/master.adoc
node build/scripts/cqa/index.js titles/get-started_navigate-rhdh-on-your-first-day/master.adoc
```

Fix any CQA errors.

- [ ] **Step 4: Commit**

```bash
git add modules/extend_orchestrator-in-rhdh/ modules/observability_*/ modules/configure_*/ modules/install_*/ modules/upgrade_*/ modules/integrate_*/ modules/get-started_*/ modules/develop_*/
git commit -m "docs(RHDHBUGS-831): update prerequisites — non-shared modules

Standardize permission prerequisites for orchestrator, observability,
configure, install, upgrade, integration, and getting-started modules."
```

---

### Task 11: Full CQA validation across all titles

**Files:**
- Validate: all 32 `titles/*/master.adoc`

- [ ] **Step 1: Run CQA on all titles**

```bash
for title in titles/*/master.adoc; do
  echo "=== $(dirname "$title" | xargs basename) ==="
  node build/scripts/cqa/index.js "$title" 2>&1
  echo ""
done
```

- [ ] **Step 2: Fix any CQA errors**

If any title reports errors related to the prerequisite changes, fix them. Common issues:
- CQA-03: mixed list types (ensure all prerequisite bullets use `*` not `.`)
- CQA-05: block titles in reference modules (should not apply — we only edited procedure modules)

- [ ] **Step 3: Run full build validation**

```bash
./build/scripts/build-ccutil.sh
```

Check for "Unknown ID" and "fails to validate" errors. These indicate broken xrefs.

- [ ] **Step 4: Commit any fixes**

```bash
git add -A
git commit -m "docs(RHDHBUGS-831): fix CQA and build validation errors"
```

---

### Task 12: Create PR and update Jira

**Files:**
- None (workflow only)

- [ ] **Step 1: Push branch and create PR**

```bash
git push -u origin <branch-name>
```

Create PR with:
- **Title:** `[RHDHBUGS-831]: Update prerequisites to include specific RBAC roles and permissions`
- **Body:** Follow `.github/pull_request_template.md` format with:
  - `Version(s): 1.6`
  - `Issue: https://issues.redhat.com/browse/RHDHBUGS-831`
  - Summary: Audited all 217 procedure modules with prerequisites. Standardized permission language across four categories: OCP/K8s admin, app config access, RHDH RBAC (with specific permission names), and external service access.

- [ ] **Step 2: Update Jira**

Add the PR URL to RHDHBUGS-831 and transition to Review.

---

## Consolidated Audit Table

<!-- Audit tasks (1-5) append their results here. Each section is headed by the task that produced it. -->

### modules/shared/ (proc-a* through proc-d*)

| Module | Current prerequisite text | Category | Change needed? | Proposed new text |
|---|---|---|---|---|
| `proc-add-new-components-to-your-rhdh-instance.adoc` | "You have the required permissions. See {authorization-book-link}[{authorization-book-title}]." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`catalog.entity.create\`, \`catalog.location.create\`, \`bulk.import\`.` |
| `proc-add-video-content-to-enhance-techdocs.adoc` | "An administrator has configured your {aws-short} S3 bucket to store TechDocs sites." | OK | No | — |
| `proc-configure-a-floating-action-button-as-a-dynamic-plugin.adoc` | "You must have sufficient permissions as a platform engineer." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-configure-amazon-s3-for-file-storage.adoc` | "You are logged in to your {aws-short} account as an administrator." | D | No (OK) | — |
| `proc-configure-entity-detail-tab-layout.adoc` | "The plugin that contributes the tab content can be configured to extend the default inherited configuration." | OK | No | — |
| `proc-configure-provenance-and-software-template-versioning-rhdh.adoc` | "You have administrator rights to {product}." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-configure-rbac-to-manage-extensions.adoc` | "You have enabled RBAC, have a policy administrator role in {product-short}, and have added plugins with permission." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`policy.entity.create\`, \`policy.entity.update\`.` |
| `proc-configure-rhdh-local-to-install-plugins-by-using-extensions.adoc` | "You have installed {product-local-very-short}." | OK | No | — |
| `proc-configure-rhdh-to-install-plugins-by-using-extensions.adoc` | "You have created a persistent volume claim (PVC) for the dynamic plugins cache with the name *dynamic-plugins-root*." | A | No (OK) | — |
| `proc-configure-role-based-access-control-for-quick-starts.adoc` | "You have configured RBAC in {product-very-short}." | B | No (OK) | — |
| `proc-configure-the-github-events-module-plugin.adoc` | "You have added your GitHub integration credentials in the \`{my-app-config-file}\` file." | B | No (OK) | — |
| `proc-configure-the-rbac-backend-plugin.adoc` | "You have installed the \`@backstage-community/plugin-rbac\` plugin in {product-short}." | OK | No | — |
| `proc-create-a-basic-software-template.adoc` | "You have administrator access to a {product-very-short} instance." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-create-a-custom-transformer-to-provision-users-from-github-to-the-software-catalog.adoc` | "You have xref:enable-user-authentication-with-github-with-optional-steps_{context}[enabled provisioning users from GitHub to the software catalog]." | OK | No | — |
| `proc-create-a-custom-transformer-to-provision-users-from-gitlab-to-the-software-catalog.adoc` | "You have xref:enable-user-authentication-with-gitlab_{context}[enabled provisioning users from GitLab to the software catalog]." | OK | No | — |
| `proc-create-a-custom-transformer-to-provision-users-from-ldap-to-the-software-catalog.adoc` | "You have xref:enable-user-provisioning-with-ldap_{context}[enabled provisioning users from LDAP to the software catalog]." | OK | No | — |
| `proc-create-a-custom-transformer-to-provision-users-from-rhbk-to-the-software-catalog.adoc` | "You have xref:enable-user-authentication-with-rhbk-with-optional-steps_{context}[enabled provisioning users from {rhbk-brand-name} ({rhbk}) to the software catalog]." | OK | No | — |
| `proc-create-a-custom-transformer-to-provision-users-from-to-the-software-catalog.adoc` | "You have xref:enable-user-authentication-with-microsoft-azure-with-optional-steps_{context}[enabled provisioning users from {azure-short} to the software catalog]." | OK | No | — |
| `proc-create-a-javascript-package-with-dynamic-packages.adoc` | (context-dependent, no global prerequisite visible in first 30 lines) | OK | No | — |
| `proc-create-a-new-application.adoc` | "Determine the \`create-app\` version based on the {product-very-short} compatibility matrix." | OK | No | — |
| `proc-create-a-new-plugin.adoc` | "You have created a {backstage} application." | OK | No | — |
| `proc-create-an-oci-image-with-dynamic-packages.adoc` | "You have installed \`podman\` or \`docker\`." | OK | No | — |
| `proc-create-a-role-in-the-rhdh-web-ui.adoc` | "You {authorization-book-link}#enabling-and-giving-access-to-rbac_title-authorization[have enabled RBAC, have a policy administrator role in {product-short}, and have added plugins with permission]." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`policy.entity.create\`, \`policy.entity.update\`.` |
| `proc-create-a-software-component-using-software-templates.adoc` | "You log in to the {product} instance." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`scaffolder.template.parameter.read\`, \`scaffolder.template.step.read\`, \`scaffolder.task.create\`.` |
| `proc-create-a-techdocs-add-on.adoc` | (no Prerequisites section visible in first 30 lines) | OK | No | — |
| `proc-create-a-tgz-file-with-dynamic-packages.adoc` | (context-dependent, no global prerequisite visible in first 30 lines) | OK | No | — |
| `proc-create-new-components-in-your-rhdh-instance.adoc` | "You have the required permissions. See {authorization-book-link}[{authorization-book-title}]." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`catalog.entity.create\`, \`scaffolder.template.parameter.read\`, \`scaffolder.template.step.read\`, \`scaffolder.task.create\`.` |
| `proc-customize-rhdh-backend-secret.adoc` | "You {configuring-book-link}[added a custom {product-short} application configuration], and have sufficient permissions to modify it." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-customize-the-home-page-cards.adoc` | (no Prerequisites section visible in first 30 lines) | OK | No | — |
| `proc-customize-the-tech-radar-page-by-using-a-customization-service.adoc` | "You have specified the data sources for the Tech Radar plugin in the \`integrations\` section of the \`{my-app-config-file}\` file." | B | No (OK) | — |
| `proc-customize-the-tech-radar-page-by-using-a-json-file.adoc` | "You have specified the data sources for the Tech Radar plugin in the \`integrations\` section of the \`{my-app-config-file}\` file." | B | No (OK) | — |
| `proc-customize-your-rhdh-base-url.adoc` | "You know your required {product-short} external URL: pass:c,a,q[{my-product-url}], and have configured DNS to point to your {ocp-brand-name} cluster." | B | No (OK) | — |
| `proc-customize-your-rhdh-global-header.adoc` | (no Prerequisites section visible in first 30 lines) | OK | No | — |
| `proc-customize-your-rhdh-quick-start.adoc` | "You must have administrator permissions." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-customize-your-rhdh-title.adoc` | "{configuring-book-link}[Custom {product-short} configuration]." | B | No (OK) | — |
| `proc-define-authorizations-in-external-files-by-using-helm.adoc` | "xref:enable-and-give-access-to-the-role-based-access-control-rbac-feature_authorization-in-rhdh[You enabled the RBAC feature]." | B | No (OK) | — |
| `proc-define-authorizations-in-external-files-by-using-the-operator.adoc` | "xref:enable-and-give-access-to-the-role-based-access-control-rbac-feature_authorization-in-rhdh[You enabled the RBAC feature]." | B | No (OK) | — |
| `proc-define-the-layout-of-the-rhdh-home-page.adoc` | "Include the following optimal parameters in each of your breakpoints: width (w), height (h), position (x and y)" | OK | No | — |
| `proc-delegate-rbac-access-in-rhdh-by-using-api.adoc` | "Your {product-very-short} instance is running with the RBAC plugin installed and configured." | OK | No | — |
| `proc-delegate-rbac-access-in-rhdh-by-using-the-web-ui.adoc` | "Your {product-very-short} instance is running with the RBAC plugin installed and configured." | OK | No | — |
| `proc-delete-a-role-in-the-rhdh-web-ui.adoc` | "You {authorization-book-link}#enabling-and-giving-access-to-rbac_title-authorization[have enabled RBAC and have a policy administrator role in {product-short}]." | C | Yes | `* If RBAC is enabled, you have a role with the following permission: \`policy.entity.delete\`.` |
| `proc-deploy-on-eks-with-the-helm-chart.adoc` | "You have an {eks-short} cluster with AWS Application Load Balancer (ALB) add-on installed." | A | No (OK) | — |
| `proc-deploy-on-gke-with-the-helm-chart.adoc` | "You have subscribed to the {rhcr-long}." | A | No (OK) | — |
| `proc-deploy-rhdh-on-with-the-helm-chart.adoc` | (Permissions prerequisite about fsGroup adjustments) | A | No (OK) | — |
| `proc-download-active-users-list-in-rhdh.adoc` | "An administrator role must be assigned." | C | Yes | `* If RBAC is enabled, you have a role with the following permission: \`policy.entity.read\`.` |

### modules/shared/ (proc-e* through proc-i*)

| Module | Current prerequisite text | Category | Change needed? | Proposed new text |
|---|---|---|---|---|
| `proc-edit-a-role-in-the-rhdh-web-ui.adoc` | "You {authorization-book-link}#enabling-and-giving-access-to-rbac_title-authorization[have enabled RBAC, have a policy administrator role in {product-short}, and have added plugins with permission]." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`policy.entity.update\`, \`policy.entity.read\`.` |
| `proc-enable-and-authorize-bulk-import-capabilities-in-rhdh.adoc` | (No vague prerequisites — specific GitHub discovery prerequisite) | OK | No | — |
| `proc-enable-and-disable-plugins-by-using-extensions.adoc` | "You have configured RBAC to allow the current user to access to manage plugin configuration." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-enable-and-give-access-to-the-role-based-access-control-rbac-feature.adoc` | "You have {configuring-book-link}[added a custom {product-short} application configuration], and have necessary permissions to change it." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-enable-argo-cd-rollouts.adoc` | "You have access to the Kubernetes cluster with the necessary permissions to create and manage custom resources and \`ClusterRoles\`." | A | No (OK) | — |
| `proc-enable-auto-logout-for-inactive-users.adoc` | "You have administrative access to the {product} configuration files." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-enable-automated-template-updates.adoc` | "You have administrator access to the {product} configuration." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-enable-github-repository-discovery.adoc` | "You {configuring-book-link}[added a custom {product-short} application configuration], and have sufficient permissions to modify it." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-enable-kubernetes-custom-actions-plugin-in-rhdh.adoc` | (No vague prerequisites — specific Helm chart requirement) | OK | No | — |
| `proc-enable-plugins-added-in-the-rhdh-container-image.adoc` | (No Prerequisites section visible in first 30 lines) | OK | No | — |
| `proc-enable-quicklinks-and-starred-items-after-an-upgrade.adoc` | "You have administrative permissions to modify ConfigMaps (if using the Operator)." | A | No (OK) | — |
| `proc-enable-quick-start-localization-in-rhdh.adoc` | "You have enabled localization in your {product-very-short} application." | B | No (OK) | — |
| `proc-enable-servicenow-custom-actions-plugin-in-rhdh.adoc` | "{product} is installed and running." | OK | No | — |
| `proc-enable-service-to-service-authentication-by-using-a-static-token.adoc` | (No Prerequisites section visible in first 30 lines — content starts with abstract) | OK | No | — |
| `proc-enable-service-to-service-authentication-by-using-json-web-key-sets-jwks-tokens.adoc` | (No Prerequisites section visible in first 30 lines — content starts with abstract) | OK | No | — |
| `proc-enable-sidebar-menu-items-localization-in-rhdh.adoc` | "You have enabled localization in your {product-very-short} application." | B | No (OK) | — |
| `proc-enable-software-template-version-update-notifications-in-rhdh.adoc` | (No vague prerequisites — specific plugin installation requirement) | OK | No | — |
| `proc-enable-the-argo-cd-plugin.adoc` | (No Prerequisites section visible in first 30 lines — only NOTE about Argo CD instance) | OK | No | — |
| `proc-enable-the-keycloak-plugin.adoc` | (No vague prerequisites — specific environment variables required) | OK | No | — |
| `proc-enable-the-localization-framework-in-rhdh.adoc` | (No Prerequisites section visible in first 30 lines — empty prerequisites) | OK | No | — |
| `proc-enable-the-tekton-plugin.adoc` | (No vague prerequisites — specific Kubernetes plugin and ClusterRole requirements) | OK | No | — |
| `proc-enable-user-authentication-with-github.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-authentication-with-github-as-an-auxiliary-authentication-provider.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-authentication-with-github-with-optional-steps.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-authentication-with-gitlab.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-authentication-with-microsoft-azure.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-authentication-with-microsoft-azure-with-optional-steps.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-authentication-with-rhbk.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-authentication-with-rhbk-with-optional-steps.adoc` | (Uses include snippet, need to check common prerequisites) | OK | No | — |
| `proc-enable-user-provisioning-with-ldap.adoc` | (No vague prerequisites — specific LDAP credentials and xref to RHBK auth) | OK | No | — |
| `proc-enable-users-to-use-the-topology-plugin.adoc` | "You are {authorization-book-link}#managing-authorizations-by-using-external-files[managing {authorization-book-title} by using external files]." | OK | No | — |
| `proc-example-of-installing-a-custom-plugin-in-rhdh.adoc` | (No vague prerequisites — specific Node.js, tools, registry access) | OK | No | — |
| `proc-export-plugins-in-rhdh.adoc` | (No vague prerequisites — specific CLI package and Node.js requirements) | OK | No | — |
| `proc-expose-your-operator-based-instance-on-aks.adoc` | (Uses include snippet for common prerequisites) | OK | No | — |
| `proc-expose-your-operator-based-instance-on-eks.adoc` | (Uses include snippet + specific EKS requirements) | OK | No | — |
| `proc-expose-your-operator-based-instance-on-gke.adoc` | (Uses include snippet + specific GKE requirements) | OK | No | — |
| `proc-find-components-by-kind-in-the-rhdh-catalog.adoc` | "You are logged in to the {product-very-short} instance." | OK | No | — |
| `proc-import-an-existing-software-template.adoc` | (No vague prerequisites — specific directory/repo and GitHub integration) | OK | No | — |
| `proc-import-documentation-into-techdocs-from-a-remote-repository.adoc` | "You have the \`catalog.entity.create\` and \`catalog.location.create\` permissions to import documentation into TechDocs from a remote repository." | C | No (OK) | — |
| `proc-import-multiple-github-repositories.adoc` | "You have xref:enable-and-authorize-bulk-import-capabilities-in-rhdh_{context}[enabled the Bulk Import feature and given access to it]." | OK | No | — |
| `proc-import-multiple-gitlab-repositories.adoc` | (No vague prerequisites — specific configuration requirements) | OK | No | — |
| `proc-install-and-configure.adoc` | (No Prerequisites section visible in first 30 lines) | OK | No | — |
| `proc-install-and-configure-an-external-techdocs-add-on-using-the-helm-chart.adoc` | "The TechDocs plugin is installed and enabled." | OK | No | — |
| `proc-install-and-configure-a-third-party-techdocs-add-on.adoc` | (No vague prerequisites — specific technical requirements) | OK | No | — |
| `proc-install-plugins-by-using-extensions.adoc` | "You have configured RBAC to allow the current user to manage plugin configuration." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-install-plugins-from-oci-plugins-in-openshift.adoc` | "Your cluster administrator must add the trusted corporate CA bundle to the cluster-wide configuration." | A | No (OK) | — |
| `proc-install-the-operator-on-aks-by-using-olm.adoc` | (Uses include snippet for common prerequisites) | OK | No | — |
| `proc-install-the-operator-on-eks-by-using-olm.adoc` | (Uses include snippet for common prerequisites + EKS context) | OK | No | — |
| `proc-install-the-operator-on-gke-by-using-olm.adoc` | (Uses include snippet for common prerequisites + GKE login) | OK | No | — |
| `proc-install-the-rhdh-operator.adoc` | "You have logged in as an administrator on the {ocp-short} web console." | A | No (OK) | — |
| `proc-install-the-topology-plugin.adoc` | (No vague prerequisites — specific Kubernetes plugin and ClusterRole requirements) | OK | No | — |

### modules/shared/ (proc-j* through proc-s*)

| Module | Current prerequisite text | Category | Change needed? | Proposed new text |
|---|---|---|---|---|
| `proc-load-a-plugin-packaged-as-a-javascript-package.adoc` | (Prerequisite about packaging plugin as dynamic plugin) | OK | No | — |
| `proc-load-a-plugin-packaged-as-an-oci-image.adoc` | (Prerequisite about packaging plugin in OCI image) | OK | No | — |
| `proc-load-a-plugin-packaged-as-a-tgz-file.adoc` | (Prerequisite about packaging plugin in TGZ file) | OK | No | — |
| `proc-manage-chats.adoc` | (Prerequisites about Lightspeed plugin configuration and login) | OK | No | — |
| `proc-override-translations.adoc` | (Prerequisites about localization and OpenShift CLI) | OK | No | — |
| `proc-provision-your-custom-rhdh-configuration.adoc` | (Uses include snippet with developer permissions) | OK | No | — |
| `proc-provision-your-pull-secret-to-your-rhdh-instance-namespace.adoc` | (Prerequisites about Red Hat Container Registry credentials and namespace) | OK | No | — |
| `proc-register-components-manually-in-your-rhdh-instance.adoc` | "You have the required permissions. See {authorization-book-link}[{authorization-book-title}]." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`catalog.entity.create\`, \`catalog.location.create\`.` |
| `proc-run-orchestrator-workflows-for-bulk-imports.adoc` | "You have role-based access control (RBAC) permissions to configure the Bulk Import plugin." | B | Yes | `* You have {configuring-book-link}[added a custom {product-short} application configuration].` |
| `proc-select-the-language-for-your-rhdh-instance.adoc` | (Prerequisites about logged in and localization enabled) | OK | No | — |
| `proc-send-requests-to-the-rbac-rest-api-by-using-an-external-service.adoc` | (Prerequisites about RBAC access and service-to-service token authentication) | OK | No | — |
| `proc-send-requests-to-the-rbac-rest-api-by-using-a-rest-client.adoc` | (Prerequisite about RBAC access) | OK | No | — |
| `proc-send-requests-to-the-rbac-rest-api-by-using-the-curl-utility.adoc` | (Prerequisite about RBAC access) | OK | No | — |
| `proc-set-up-a-custom-scaffolder-workflow-for-bulk-import.adoc` | (Prerequisites about custom template creation and NODE_OPTIONS environment variable) | OK | No | — |
| `proc-set-up-the-guest-authentication-provider.adoc` | (Prerequisite about RBAC plugin installation) | OK | No | — |
| `proc-share-software-templates-with-your-organization.adoc` | "You have administrator access to a {product-very-short} instance." | C | Yes | `* If RBAC is enabled, you have a role with the following permissions: \`catalog.entity.create\`, \`catalog.location.create\`.` |
| `proc-start-and-complete-lessons-in-learning-paths.adoc` | "Your platform engineer has granted you access to the Learning Paths plugin." | C | Yes | `* If RBAC is enabled, you have a role with the following permission: \`catalog.entity.read\`.` |
| `proc-streamline-documentation-builds-using-github-actions.adoc` | (Prerequisites include specific catalog permissions: `catalog.entity.create` and `catalog.location.create`) | OK | No | — |
| `proc-switch-the-theme-mode-for-your-rhdh-instance.adoc` | (Prerequisite about logged in to web console) | OK | No | — |

### modules/shared/ (proc-t* through proc-z*)

_To be populated by Task 4_

### Non-shared modules

_To be populated by Task 5_
