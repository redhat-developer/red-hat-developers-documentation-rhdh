# CQA #16 - Legal and Branding

## Official product names are used

**Reference:** http://red.ht/opl

**Quality Level:** Required/non-negotiable

## Product Attribute Usage Rules

**CRITICAL:** Always use AsciiDoc attributes for product names, never hardcode product names.

### Red Hat Developer Hub Attributes

**First occurrence in a file:**
- Use `{product}` for the full official product name
- Example: `{product}` expands to "Red Hat Developer Hub"

**Subsequent occurrences in the same file:**
- Use `{product-short}` for standard references
- Use `{product-very-short}` for very short references (e.g., in tables, tight spaces)
- Example: `{product-short}` expands to "Developer Hub"
- Example: `{product-very-short}` expands to "RHDH"

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

## Validation

### Check for Hardcoded Product Names

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
| **Wrong first occurrence** | `{product-short}` as first mention | `{product}` for first occurrence |
| **Inconsistent usage** | Mix of hardcoded and attributes | Use attributes consistently |

## Assessment

```yaml

title: 

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |

  

```
