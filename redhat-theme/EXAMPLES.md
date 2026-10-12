# Red Hat Theme Examples

This document shows common usage scenarios for the Red Hat documentation theme applicator.

## Scenario 1: Single Version Theme Application

You have one version of documentation to theme:

```bash
./apply-redhat-theme.sh ~/Downloads/rhdh-1-10-navigation.zip
```

**Output:**
```
✓ Success!
  - Updated 574 HTML files
  - Output: ~/Downloads/rhdh-1-10-navigation-themed.zip
```

## Scenario 2: Multiple Versions (Different Releases)

You receive new documentation exports for each release:

```bash
# Version 1.10
./apply-redhat-theme.sh ~/Downloads/rhdh-1-10-navigation.zip

# Version 1.11
./apply-redhat-theme.sh ~/Downloads/rhdh-1-11-navigation.zip

# Version 2.0
./apply-redhat-theme.sh ~/Downloads/rhdh-2-0-navigation.zip
```

Each creates its own `-themed.zip` file with consistent Red Hat styling.

## Scenario 3: Weekly Documentation Builds

You get weekly documentation exports:

```bash
# Week 1
./apply-redhat-theme.sh ~/Downloads/rhdh-docs-2026-10-01.zip

# Week 2
./apply-redhat-theme.sh ~/Downloads/rhdh-docs-2026-10-08.zip

# Week 3
./apply-redhat-theme.sh ~/Downloads/rhdh-docs-2026-10-15.zip
```

Same theme applied consistently to each build.

## Scenario 4: Batch Processing

Process multiple documentation sets at once:

```bash
#!/bin/bash
# batch-theme.sh

for zipfile in ~/Downloads/docs-*.zip; do
    echo "Processing $zipfile..."
    ./apply-redhat-theme.sh "$zipfile"
done
```

**Usage:**
```bash
chmod +x batch-theme.sh
./batch-theme.sh
```

## Scenario 5: Different Product Lines

Apply the same theme to different products:

```bash
# Red Hat Developer Hub docs
./apply-redhat-theme.sh ~/Downloads/rhdh-docs.zip

# Ansible docs
./apply-redhat-theme.sh ~/Downloads/ansible-docs.zip

# OpenShift docs
./apply-redhat-theme.sh ~/Downloads/openshift-docs.zip
```

## Scenario 6: CI/CD Pipeline Integration

### GitHub Actions Example

```yaml
name: Theme Documentation

on:
  release:
    types: [published]

jobs:
  theme-docs:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Download docs artifact
        run: |
          # Download your documentation zip from build artifacts
          wget https://example.com/docs-latest.zip

      - name: Apply Red Hat theme
        run: ./apply-redhat-theme.sh docs-latest.zip

      - name: Upload themed docs
        uses: actions/upload-artifact@v3
        with:
          name: themed-documentation
          path: docs-latest-themed.zip
```

### GitLab CI Example

```yaml
theme-docs:
  stage: publish
  script:
    - ./apply-redhat-theme.sh $CI_PROJECT_DIR/docs.zip
  artifacts:
    paths:
      - docs-themed.zip
```

## Scenario 7: Update Theme for Existing Files

You've already themed some docs but updated the CSS:

```bash
# Extract existing themed zip
unzip docs-themed.zip -d docs-working

# Remove old theme CSS
rm docs-working/redhat-docs-theme.css

# Copy new theme
cp redhat-theme/redhat-docs-theme.css docs-working/

# Recreate zip
cd docs-working
zip -r ../docs-rethemed.zip .
```

## Scenario 8: Custom Theme Variation

Create a custom theme variation for a specific product:

```bash
# 1. Copy the theme directory
cp -r redhat-theme redhat-theme-custom

# 2. Edit the CSS
vi redhat-theme-custom/redhat-docs-theme.css
# Change: --rh-color-accent-red: #cc0000; (darker red)

# 3. Update the script to use custom theme
cp apply-redhat-theme.sh apply-custom-theme.sh

# 4. Edit script to use redhat-theme-custom
vi apply-custom-theme.sh
# Change: THEME_DIR="$SCRIPT_DIR/redhat-theme-custom"

# 5. Apply custom theme
./apply-custom-theme.sh ~/Downloads/docs.zip
```

## Scenario 9: Testing Theme Changes

Before applying to production docs:

```bash
# 1. Make CSS changes
vi redhat-theme/redhat-docs-theme.css

# 2. Test on sample docs
./apply-redhat-theme.sh ~/Downloads/test-docs.zip

# 3. Extract and review
unzip test-docs-themed.zip -d /tmp/test-review
open /tmp/test-review/index.html

# 4. If good, apply to production
./apply-redhat-theme.sh ~/Downloads/production-docs.zip
```

## Scenario 10: Archive and Version Control

Keep themed documentation with version control:

```bash
# Create a themed-docs directory in your repo
mkdir -p themed-docs

# Apply theme and move to archive
./apply-redhat-theme.sh ~/Downloads/rhdh-1.10.zip
mv ~/Downloads/rhdh-1.10-themed.zip themed-docs/

# Commit to git (if needed)
git add themed-docs/rhdh-1.10-themed.zip
git commit -m "Add themed documentation for RHDH 1.10"
git push
```

## Troubleshooting Examples

### Permission Denied

```bash
# Make script executable
chmod +x apply-redhat-theme.sh
chmod +x redhat-theme/add-theme.py

# Run again
./apply-redhat-theme.sh ~/Downloads/docs.zip
```

### Spaces in Filename

```bash
# Use quotes
./apply-redhat-theme.sh "~/Downloads/my docs (1).zip"

# Or escape spaces
./apply-redhat-theme.sh ~/Downloads/my\ docs\ \(1\).zip
```

### Non-DITA HTML Structure

If your HTML doesn't use `commonltr.css`:

```python
# Edit redhat-theme/add-theme.py
# Change this line (around line 50):
pattern = r'(<link rel="stylesheet" type="text/css" href="[^"]*common(?:ltr|rtl)\.css">)'

# To match your CSS file:
pattern = r'(<link rel="stylesheet" type="text/css" href="[^"]*your-css-file\.css">)'
```

## Before and After

### Before Theme (DITA Default)
- Basic black text on white
- Generic fonts (serif/sans-serif)
- Minimal spacing
- No brand colors
- Basic code blocks
- Simple tables

### After Theme (Red Hat)
- Red Hat brand colors (#ee0000, #0066cc)
- Red Hat fonts (Display, Text, Mono)
- Proper spacing scale (4px - 128px)
- Light/Dark mode support
- Enhanced code blocks with syntax highlighting
- Styled tables with hover states
- Color-coded notes and admonitions
- Numbered task steps with badges
- Responsive design
- Accessibility features

## Success Metrics

After applying the theme, you should see:

✅ Consistent Red Hat branding across all HTML files
✅ Improved readability with proper typography
✅ Better visual hierarchy
✅ Professional code examples
✅ Responsive on all devices
✅ Dark mode support
✅ Accessibility compliance

---

**Last Updated**: October 6, 2026
