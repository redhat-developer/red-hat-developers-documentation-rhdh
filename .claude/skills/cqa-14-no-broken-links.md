# CQA #14 - URLs and links

## No broken links

**Quality Level:** Required/non-negotiable

All links in the documentation must be valid and accessible. This includes:
- Internal cross-references (xrefs) within and between modules
- External URLs to Red Hat domains and third-party sites
- Cross-title links to other RHDH documentation titles

## Commands

### Step 1: Build Documentation and Run htmltest

**Build all titles for current branch:**
```bash
./build/scripts/build-ccutil.sh
```

This script:
- Uses Podman to run ccutil container (quay.io/ivanhorvath/ccutil:amazing)
- Processes all titles/*/master.adoc files (excludes rhdh-plugins-reference)
- Generates HTML single-page output in `titles-generated/${BRANCH}/`
- Copies referenced images to output directory
- Creates navigation index.html
- **Runs htmltest for link validation** (final step)

**What htmltest validates:**
- ✅ Internal links within the same title
- ✅ External URLs (HTTP/HTTPS links)
- ✅ Anchor links within the same page
- ✅ Image references
- ❌ **Does NOT test cross-title links** (links between different RHDH titles)

### Step 2: Check Cross-Title Links

Cross-title links reference other RHDH documentation titles. These must be validated manually.

**Find cross-title xrefs:**
```bash
# Search for xrefs that reference other titles
grep -rn "xref:.*\.adoc" titles/<your-title>/ assemblies/ modules/ | grep -v "^titles/<your-title>/"

# Common cross-title patterns to check
grep -rn "xref:.*installing.*\.adoc" titles/<your-title>/
grep -rn "xref:.*configuring.*\.adoc" titles/<your-title>/
grep -rn "xref:.*admin.*\.adoc" titles/<your-title>/
```

**Verify target files exist:**
```bash
# For each cross-title xref found, check if target file exists
# Example: xref:../installing-rhdh-ocp/proc-install-helm.adoc
ls -la titles/installing-rhdh-ocp/modules/proc-install-helm.adoc

# Check if anchor ID exists in target file
grep "id=\"install-helm" titles/installing-rhdh-ocp/modules/proc-install-helm.adoc
```

### Step 3: Review htmltest Output

**Check htmltest results:**
```bash
# htmltest output is displayed at end of build-ccutil.sh
# Look for errors in the build output

# Common htmltest error patterns:
# - "target does not exist" → broken internal link
# - "404" → broken external URL
# - "invalid anchor" → anchor ID doesn't exist
```

**Example htmltest error:**
```
✗✗✗ failed | titles-generated/main/installing-rhdh-ocp/index.html
  hash does not exist --- titles-generated/main/installing-rhdh-ocp/index.html --> #invalid-anchor
```

## Link Types and Validation

| Link Type | Example | Validated By | Notes |
|-----------|---------|--------------|-------|
| **Internal xref (same title)** | `xref:proc-install-helm.adoc[]` | htmltest | Must reference existing file in same title |
| **Cross-title xref** | `xref:../configuring-rhdh/con-auth-providers.adoc[]` | Manual check | htmltest skips these - verify manually |
| **Anchor link** | `xref:proc-install.adoc#prerequisites[]` | htmltest | Anchor ID must exist in target file |
| **External URL** | `link:https://access.redhat.com[]` | htmltest | Must return 200 status code |
| **Image reference** | `image::path/to/image.png[]` | htmltest | Image file must exist in images/ directory |

## Common Link Issues and Fixes

| Issue | Error | Fix |
|-------|-------|-----|
| **Broken xref after file rename** | `target does not exist` | Update xref to new filename, or use git mv to preserve references |
| **Missing anchor** | `hash does not exist` | Add anchor ID to target file, or remove anchor from xref |
| **Broken external URL** | `404 Not Found` | Update URL to correct location, or remove if no longer valid |
| **Wrong path in cross-title xref** | Manual: file not found | Fix relative path (use `../other-title/modules/file.adoc`) |
| **Missing image** | `target does not exist` | Copy image to images/ directory, or fix image path |

## Validation Workflow

1. **Build documentation:**
   ```bash
   ./build/scripts/build-ccutil.sh
   ```

2. **Review htmltest output** for errors (displayed at end of build)

3. **Fix broken links** identified by htmltest:
   - Update or remove broken xrefs
   - Fix external URLs
   - Add missing anchors
   - Copy missing images

4. **Check cross-title links manually:**
   ```bash
   # Find cross-title xrefs
   grep -rn "xref:\.\./.*\.adoc" titles/<your-title>/ assemblies/ modules/

   # For each match, verify target file exists
   ls -la <path-to-target-file>
   ```

5. **Re-run build** to verify all fixes:
   ```bash
   ./build/scripts/build-ccutil.sh
   ```

6. **Verify zero htmltest errors** in build output

## Assessment Checklist

- [ ] Build script runs successfully (`build-ccutil.sh`)
- [ ] htmltest reports zero errors for internal links
- [ ] htmltest reports zero errors for external URLs
- [ ] htmltest reports zero errors for anchor links
- [ ] htmltest reports zero errors for image references
- [ ] All cross-title xrefs verified manually (target files exist)
- [ ] All cross-title anchor references verified (anchor IDs exist in target files)
- [ ] No broken links in generated HTML output

## Assessment

```yaml

title:

status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable

notes: |



```
