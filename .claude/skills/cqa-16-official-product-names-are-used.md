# CQA #16 - Legal and Branding

## Official product names are used

**Reference:** http://red.ht/opl

**Quality Level:** Required/non-negotiable

## Product Attribute Usage Rules

**CRITICAL:** Always use AsciiDoc attributes for product names, never hardcode product names.

### Red Hat Developer Hub Attributes

**IMPORTANT:** The title does NOT count as the first occurrence. The `[role="_abstract"]` paragraph is the first occurrence.

**First occurrence in a file (in the abstract paragraph):**
- Use `{product}` for the full official product name
- Example: `{product}` expands to "Red Hat Developer Hub"
- **Location:** The `[role="_abstract"]` paragraph immediately after the title

**Subsequent occurrences in the same file:**
- Use `{product-short}` for standard references
- Use `{product-very-short}` for very short references (e.g., in tables, tight spaces)
- Example: `{product-short}` expands to "Developer Hub"
- Example: `{product-very-short}` expands to "RHDH"

**Title usage:**
- Titles should use `{product}` (full official product name)
- Title usage does NOT affect what counts as "first occurrence" in the content

### All Product Attributes

**Red Hat Developer Hub:**
- `{product}` → Red Hat Developer Hub (first occurrence)
- `{product-short}` → Developer Hub (subsequent)
- `{product-very-short}` → RHDH (very short)
- `{product-local-very-short}` → RHDH Local
- `{backstage}` or `{product-custom-resource-type}` → Backstage
- `{rhdeveloper-name}` → Red Hat Developer

**OpenShift:**
- `{ocp-brand-name}` → Red Hat OpenShift Container Platform
- `{ocp-short}` → OpenShift Container Platform
- `{ocp-very-short}` → RHOCP
- `{osd-brand-name}` → Red Hat OpenShift Dedicated
- `{osd-short}` → OpenShift Dedicated
- `{logging-brand-name}` → Red Hat OpenShift Logging
- `{logging-short}` → OpenShift Logging
- `{rhoserverless-brand-name}` → Red Hat OpenShift Serverless
- `{rhoai-brand-name}` → Red Hat OpenShift AI
- `{rhoai-short}` → RHOAI
- `{odf-name}` → OpenShift Data Foundation
- `{openshift-ai-connector-name}` → OpenShift AI Connector for {product}
- `{openshift-ai-connector-name-short}` → OpenShift AI Connector for {product-very-short}

**Other Red Hat Products:**
- `{rhads-brand-name}` → Red Hat Advanced Developer Suite - secure supply chain
- `{rhacs-brand-name}` → Red Hat Advanced Cluster Security
- `{rhacs-short}` → Advanced Cluster Security
- `{rhacs-very-short}` → ACS
- `{ls-brand-name}` → Red Hat Developer Lightspeed for {product}
- `{ls-short}` → Developer Lightspeed for {product-very-short}
- `{lcs-name}` → Lightspeed Core Service
- `{lcs-short}` → LCS
- `{rhbk-brand-name}` → Red Hat Build of Keycloak
- `{rhbk}` → RHBK
- `{rhcr}` → Red Hat Container Registry
- `{rhec}` → Red Hat Ecosystem Catalog
- `{rhel}` → Red Hat Enterprise Linux
- `{rhtas-brand-name}` → Red Hat Trusted Artifact Signer
- `{rhtas-short}` → Trusted Artifact Signer
- `{rhtas-very-short}` → TAS
- `{rhtpa-brand-name}` → Red Hat Trusted Profile Analyzer
- `{rhtpa-short}` → Trusted Profile Analyzer
- `{rhtpa-very-short}` → TPA

**Cloud Providers:**
- `{aws-brand-name}` → Amazon Web Services
- `{aws-short}` → AWS
- `{eks-brand-name}` → Amazon Elastic Kubernetes Service
- `{eks-name}` → Elastic Kubernetes Service
- `{eks-short}` → EKS
- `{aks-brand-name}` → Microsoft Azure Kubernetes Service
- `{aks-name}` → Azure Kubernetes Service
- `{aks-short}` → AKS
- `{azure-brand-name}` → Microsoft Azure
- `{azure-short}` → Azure
- `{gcp-brand-name}` → Google Cloud
- `{gke-brand-name}` → Google Kubernetes Engine
- `{gke-short}` → GKE

## Automated Validation

### Vale Rule

The Vale rule `.vale-styles/DeveloperHub/Attributes.yml` checks for hardcoded product names inline during editing. It flags the same patterns as the script below.

```bash
# 1. Report issues
./build/scripts/cqa-16-official-product-names-are-used.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-16-official-product-names-are-used.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-16-official-product-names-are-used.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA #NN]`.

**What the script validates:**
- All Red Hat product names (Developer Hub, OpenShift, ACS, Keycloak, RHEL, TAS, TPA, etc.)
- All partner platform names (AWS, Azure, Google Cloud, EKS, AKS, GKE)
- Backstage (should use `{backstage}` or `{product-custom-resource-type}`)

**Skips:** source blocks, attribute definitions, comments, attributes.adoc, snippets

After fixing, manually verify first occurrence in abstract uses `{product}` (not `{product-short}`).

### Check for Missing First Occurrence

```bash
# Find files using {product-short} before {product}
for file in modules/**/*.adoc assemblies/**/*.adoc; do
  first_product=$(grep -n "{product}" "$file" | head -1 | cut -d: -f1)
  first_short=$(grep -n "{product-short}" "$file" | head -1 | cut -d: -f1)
  if [ -n "$first_short" ] && [ -z "$first_product" ]; then
    echo "$file: Uses {product-short} but never {product}"
  fi
done
```

## Common Violations

| Violation | Incorrect | Correct |
|-----------|-----------|---------|
| **Hardcoded full name** | `Red Hat Developer Hub` | `{product}` (first) or `{product-short}` (subsequent) |
| **Hardcoded short name** | `Developer Hub` | `{product-short}` |
| **Hardcoded abbreviation** | `RHDH` | `{product-very-short}` |
| **Wrong first occurrence** | `{product-short}` in abstract paragraph | `{product}` in abstract paragraph (title doesn't count) |
| **Inconsistent usage** | Mix of hardcoded and attributes | Use attributes consistently |
| **Title treated as first** | Using `{product-short}` in abstract because title has `{product}` | Abstract is first occurrence, not title |

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
