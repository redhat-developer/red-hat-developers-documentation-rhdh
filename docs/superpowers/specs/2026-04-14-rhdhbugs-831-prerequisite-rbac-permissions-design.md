# Update prerequisites to include specific RBAC roles/permissions

**Jira:** RHDHBUGS-831
**SP:** 13
**Affects:** 1.6.0

## Problem

217 procedure modules have `.Prerequisites` sections. Many use vague language ("sufficient permissions as a platform engineer", "administrator permissions", "sufficient permissions to modify it") instead of specifying the actual access required. Users cannot determine what permissions they need before attempting a procedure.

## Approach

Two-phase approach: audit then update.

**Phase 1 — Audit:** Scan all 217 modules with `.Prerequisites` sections. For each, categorize the prerequisite into one of four access types and note the specific permission or role needed. Produce a markdown table in the plan document for review before making changes.

**Phase 2 — Update:** Using the audit table as input, batch-update all modules that need changes. Standardize prerequisite language per category. Run CQA validation on all modified titles.

## Prerequisite categories

### Category A: OCP/K8s admin

**When:** Install, deploy, upgrade, and operator procedures that require cluster-level access.

**Standard language:**
```
You have `cluster-admin` privileges on the OpenShift Container Platform cluster.
```

### Category B: App config access

**When:** Procedures that modify the `app-config` ConfigMap or Secret (the custom RHDH application configuration).

**Standard language:**
```
You have access to modify the {product-short} custom configuration. For more information, see <xref to configuring>.
```

The xref target depends on the deployment method context. Use the appropriate link to the configuring procedure for the title.

### Category C: RHDH RBAC

**When:** Procedures that use RHDH UI or API features gated by RBAC permissions.

**Standard language (single permission):**
```
If RBAC is enabled, you have a role with the following permission: `<permission.name>`.
```

**Standard language (multiple permissions):**
```
If RBAC is enabled, you have a role with the following permissions: `<perm.one>`, `<perm.two>`.
```

The conditional "If RBAC is enabled" is required because RBAC is optional and not all deployments use it.

### Category D: External service

**When:** Procedures requiring access to an external service (GitHub, Azure AD, PingIdentity, etc.).

**Standard language:** Keep specific to the service. Example:
```
You have permissions to create and manage a GitHub App.
```

These prerequisites are often already specific enough and may not need changes.

## Available RHDH RBAC permissions

The following 31 permissions across 11 namespaces are documented in existing reference modules:

| Namespace | Permissions | Reference module |
|---|---|---|
| catalog | `catalog.entity.read`, `.create`, `.refresh`, `.delete`, `catalog.location.read`, `.create`, `.delete` | `ref-catalog-permissions.adoc` |
| policy | `policy.entity.read`, `.create`, `.update`, `.delete` | `ref-rbac-permissions.adoc` |
| scaffolder | `scaffolder.action.execute`, `scaffolder.template.parameter.read`, `.step.read`, `.management`, `scaffolder.task.create`, `.cancel`, `.read` | `ref-scaffolder-permissions.adoc` |
| kubernetes | `kubernetes.clusters.read`, `kubernetes.resources.read`, `kubernetes.proxy` | `ref-kubernetes-permissions.adoc` |
| argocd | `argocd.view.read` | `ref-argocd-permissions.adoc` |
| tekton | (uses kubernetes permissions) | `ref-tekton-permissions.adoc` |
| topology | (uses kubernetes permissions) | `ref-topology-permissions.adoc` |
| ocm | `ocm.entity.read`, `ocm.cluster.read` | `ref-ocm-permissions.adoc` |
| quay | `quay.view.read` | `ref-quay-permissions.adoc` |
| orchestrator | `orchestrator.workflow`, `.workflow.[workflowId]`, `.workflow.use`, `.workflow.use.[workflowId]`, `.workflowAdminView`, `.instanceAdminView` | `ref-orchestrator-plugin-permissions.adoc` |
| bulk-import | `bulk.import` | `ref-bulk-import-permission.adoc` |

## Scope rules

- **No change needed** if the prerequisite is already specific enough.
- **Multiple categories per module** are possible — e.g., a procedure may need both app config access (Category B) and an RHDH RBAC permission (Category C).
- **External service prerequisites** (Category D) that are already specific get left as-is.

## Out of scope

- Creating new RBAC permission reference modules (all 11 namespaces are already documented).
- Changing the RBAC permission model itself.
- Rewriting prerequisites unrelated to permissions (e.g., "You have installed {product-short}").

## Deliverables

1. **Audit table** (markdown in plan doc): all 217 modules categorized with current prerequisite text, proposed category, and proposed new text.
2. **Updated `.adoc` modules**: all modules with vague prerequisites updated to use standardized language.
3. **CQA validation**: all modified titles pass CQA checks.
