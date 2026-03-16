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

### Common Product Attributes

**Red Hat Developer Hub:**
- `{product}` → Red Hat Developer Hub (first occurrence)
- `{product-short}` → Developer Hub (subsequent)
- `{product-very-short}` → RHDH (very short)

**OpenShift:**
- `{ocp-brand-name}` → Red Hat OpenShift Container Platform (first)
- `{ocp-short}` → OpenShift Container Platform (subsequent)
- `{osd-brand-name}` → Red Hat OpenShift Dedicated
- `{osd-short}` → OpenShift Dedicated

**Cloud Providers:**
- `{aws-brand-name}` → Amazon Web Services
- `{aws-short}` → AWS
- `{gcp-brand-name}` → Google Cloud Platform
- `{gcp-short}` → GCP
- `{azure-brand-name}` → Microsoft Azure

## Automated Validation

### Run Complete Validation Script

```bash
./build/scripts/cqa-16-verify-product-names.sh titles/<your-title>/master.adoc
```

**What the script validates:**
- Hardcoded "Red Hat Developer Hub" (should use `{product}` or `{product-short}`)
- Hardcoded "Developer Hub" (should use `{product-short}`)
- Hardcoded "Backstage" (should use `{backstage}`)
- Hardcoded "Red Hat OpenShift Container Platform" (should use `{ocp-brand-name}`)
- Hardcoded "OpenShift Container Platform" (should use `{ocp-short}`)

**Skips:** source blocks, attribute definitions, comments, attributes.adoc, snippets

**Fix mode:**
```bash
./build/scripts/cqa-16-verify-product-names.sh --fix titles/<your-title>/master.adoc
```

After fixing, manually verify first occurrence in abstract uses `{product}` (not `{product-short}`).

### Manual Check for Hardcoded Product Names

```bash
# Find hardcoded "Red Hat Developer Hub"
grep -rn "Red Hat Developer Hub" modules/ assemblies/ titles/ --include="*.adoc"

# Find hardcoded "Developer Hub" (should use {product-short})
grep -rn "Developer Hub" modules/ assemblies/ titles/ --include="*.adoc" | grep -v "{product"

# Find hardcoded "RHDH" (should use {product-very-short})
grep -rn "RHDH" modules/ assemblies/ titles/ --include="*.adoc" | grep -v "{product"
```

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
