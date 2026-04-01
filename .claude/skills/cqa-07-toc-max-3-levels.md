# CQA-7 - Modularization

## TOC depth: Maximum 3 levels

**Quality Level:** Important/negotiable

Content hierarchy should not exceed 3 levels in TOC to improve navigation and prevent overwhelming users.

**Level counting:** For AEM migration, count from where your content starts (excluding Pantheon categories/book titles).

## Automated Validation and Fixing

**IMPORTANT:** ALWAYS run the script first, then fix. Do not manually inspect files without running the script.

```bash
# 1. Report issues
./build/scripts/cqa-07-toc-max-3-levels.sh titles/<your-title>/master.adoc

# 2. Auto-fix what can be fixed
./build/scripts/cqa-07-toc-max-3-levels.sh --fix titles/<your-title>/master.adoc

# 3. Re-run to verify remaining issues
./build/scripts/cqa-07-toc-max-3-levels.sh titles/<your-title>/master.adoc

# 4. Attempt manual fixes for remaining issues

# 5. Re-run to verify remaining issues

# 6. If issues remain, report as failed and list the remaining issues
```

**Additional options:** Use `--all` to run across all titles. Output markers: `[AUTOFIX]`, `[FIXED]`, `[MANUAL]`, `[-> CQA-NN]`.

**What the script validates:**
- Scans all included .adoc files for heading depth
- Identifies any headings deeper than level 3 (====)
- Reports maximum depth found across all files
- Shows line numbers of violating headings

**Example output:**
```
✓ All files comply with TOC depth requirement (max 3 levels)
Maximum heading depth found: 3
```

### Manual Verification

**Check specific files:**
```bash
# Find violations (4+ equals) in specific directories
grep -E "^====" assemblies/*.adoc modules/*/*.adoc
```

**Build and review:**
```bash
./build/scripts/build-ccutil.sh
# Open titles-generated/main/<title>/index.html and check left nav depth
```

**Checklist:**
- [ ] No content exceeds 3 levels in TOC
- [ ] Each level serves clear organizational purpose
- [ ] Deep nesting eliminated through modularization

## TOC Level Structure

| Level | Marker | Usage | Example |
|-------|--------|-------|---------|
| 1 | `=` | Book/main assembly | `= Installing Red Hat Developer Hub` |
| 2 | `==` | Major sections | `== Installing on OpenShift` |
| 3 | `===` | Sub-sections/procedure headings | `=== Installing the Helm chart` |
| **STOP** | ~~`====`~~ | ❌ DO NOT USE | Level 4+ breaks guideline |

## Examples

### ✅ CORRECT: 3 levels

```asciidoc
= Installing Red Hat Developer Hub                    (L1)
== Prerequisites                                      (L2)
== Installing on OpenShift                            (L2)
include::modules/admin/proc-install-helm.adoc[]       (L3 in module)
```

**TOC:**
```
Installing RHDH
├── Prerequisites
└── Installing on OpenShift
    └── Installing the Helm chart
```

### ❌ INCORRECT: 5 levels

```asciidoc
= Installing Red Hat Developer Hub                    (L1)
== Installation methods                               (L2)
=== Installing on OpenShift                           (L3)
==== Using Helm chart                                 (L4) ← TOO DEEP
===== Configuring values                              (L5) ← TOO DEEP
```

**TOC:**
```
Installing RHDH
└── Installation methods
    └── Installing on OpenShift
        └── Using Helm chart
            └── Configuring values    ← Level 5 ✗
```

## Common Violations

### Violation 1: Over-categorization

**Problem:** Too many intermediate grouping levels

❌ **Before (5 levels):**
```
Installation → Methods → Cloud → OpenShift → Helm Installation
```

✅ **After (2 levels):**
```
Installation
├── Installing on OpenShift with Helm
└── Installing on OpenShift with Operator
```

### Violation 2: Nested sub-procedures

**Problem:** Deep subsections in one file

❌ **Before:**
```asciidoc
== Configuring authentication
=== OAuth configuration
==== Setting up providers
===== Google OAuth                     ← L5
```

✅ **After:** Split into modules
```asciidoc
== Configuring authentication
include::modules/admin/proc-configure-oauth-google.adoc[]
include::modules/admin/proc-configure-oauth-github.adoc[]
```

### Violation 3: Deep reference sections

**Problem:** Excessive reference subsections

❌ **Before:**
```asciidoc
== Configuration reference
=== Application settings
==== Authentication settings
===== OAuth providers                  ← L5
```

✅ **After:** Use tables or modules
```asciidoc
== Configuration reference
include::modules/admin/ref-auth-config.adoc[]
```

## Avoid nested assemblies

Do not include an assembly from within another assembly. Nested assemblies add unnecessary TOC depth and cause context attribute conflicts (the inner assembly's `:!previouscontext:` unsets the outer assembly's saved context).

❌ **Before:** Nested assembly
```asciidoc
include::assembly-mounts-for-default-secrets.adoc[leveloffset=+1]
```

✅ **After:** Include modules directly
```asciidoc
include::../modules/configuring-rhdh/proc-configure-mount-paths.adoc[leveloffset=+1]
include::../modules/configuring-rhdh/proc-mount-secrets.adoc[leveloffset=+1]
```

## Restructuring Strategies

**1. Promote siblings:** Convert nested items to same-level siblings
- Before: `A → B → C → D → E` (5 levels)
- After: `A → B, A → C, A → D, A → E` (2 levels)

**2. Split assemblies:** Break large assemblies into focused sub-assemblies
- Creates multiple 2-3 level hierarchies instead of one deep hierarchy

**3. Use modules:** Replace deep sections with includes
- Before: `==== Deep section`
- After: `include::modules/*/proc-action.adoc[]`

**4. Flatten with context:** Add context to titles, remove intermediate levels
- Before: `Installation → Methods → Cloud → OpenShift → Helm`
- After: `Installing on OpenShift with Helm`

## Quick Checks

**Find Level 4+ violations:**
```bash
grep -n "^====" assemblies/*.adoc modules/*/*.adoc
```

**Count max depth:**
```bash
awk '/^=+ / {depth=gsub(/=/,""); if(depth>max)max=depth} END{print "Max:",max}' assemblies/assembly-*.adoc
```

**Expected:** Max: 3 or less

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
