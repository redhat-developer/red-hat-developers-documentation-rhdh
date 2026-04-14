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

_To be populated by Task 1_

### modules/shared/ (proc-e* through proc-i*)

_To be populated by Task 2_

### modules/shared/ (proc-j* through proc-s*)

_To be populated by Task 3_

### modules/shared/ (proc-t* through proc-z*)

_To be populated by Task 4_

### Non-shared modules

_To be populated by Task 5_
