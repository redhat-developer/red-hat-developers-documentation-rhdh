# Red Hat Documentation Theme Applicator

This directory contains a reusable tool for applying Red Hat's documentation styling to exported DITA HTML documentation.

## Quick Start

```bash
# From the repository root, run:
./apply-redhat-theme.sh ~/Downloads/your-documentation.zip

# This creates a new file:
# ~/Downloads/your-documentation-themed.zip
```

## Directory Structure

```
redhat-theme/
├── README-USAGE.md          # This file - usage instructions
├── README.md                # README included in themed output
├── redhat-docs-theme.css    # The Red Hat CSS theme
└── add-theme.py             # Python script to inject CSS links
```

## Files Explained

### `redhat-docs-theme.css`
The main CSS file containing all Red Hat documentation styling:
- Red Hat brand colors and typography
- Light/Dark mode support
- Responsive design
- Enhanced components (code blocks, tables, notes, etc.)
- Accessibility features

### `add-theme.py`
Python 3 script that:
1. Finds all HTML files in a directory
2. Injects a `<link>` tag to `redhat-docs-theme.css`
3. Calculates correct relative paths for each HTML file
4. Preserves existing DITA CSS (commonltr.css, commonrtl.css)

### `README.md`
Documentation file that gets included in the themed zip output to explain the styling to end users.

## Usage

### Basic Usage

```bash
./apply-redhat-theme.sh <path-to-zip-file>
```

**Example:**
```bash
./apply-redhat-theme.sh ~/Downloads/rhdh-1-10-navigation.zip
```

**Output:**
```
~/Downloads/rhdh-1-10-navigation-themed.zip
```

### What the Script Does

1. **Extracts** the zip file to a temporary directory
2. **Copies** `redhat-docs-theme.css` to the root
3. **Runs** `add-theme.py` to update all HTML files
4. **Adds** `README.md` documentation
5. **Creates** a new zip file with `-themed` suffix
6. **Cleans up** temporary files

### Advanced Usage

If you need to manually apply the theme to an already-extracted directory:

```bash
# Copy CSS file to the root of your docs directory
cp redhat-theme/redhat-docs-theme.css /path/to/docs/

# Run the Python script
python3 redhat-theme/add-theme.py /path/to/docs/

# Copy documentation
cp redhat-theme/README.md /path/to/docs/
```

## Requirements

- **bash** (macOS, Linux, WSL, or Git Bash on Windows)
- **Python 3** (any version 3.6+)
- **unzip** and **zip** utilities (standard on most systems)

## Customizing the Theme

To customize the Red Hat theme styling:

1. Edit `redhat-theme/redhat-docs-theme.css`
2. Modify CSS custom properties at the top of the file:

```css
:root {
  /* Change colors */
  --rh-color-text-primary: #151515;
  --rh-color-accent-red: #ee0000;
  --rh-color-accent-blue: #0066cc;

  /* Change spacing */
  --rh-space-lg: 16px;
  --rh-space-xl: 24px;

  /* Change fonts */
  --rh-font-family-body: 'Red Hat Text', sans-serif;
}
```

3. Run the script again on your zip file

## Testing Changes

To test your theme changes:

```bash
# Apply theme to a test zip
./apply-redhat-theme.sh test-docs.zip

# Extract the themed output
unzip test-docs-themed.zip -d test-output

# Open an HTML file in your browser
open test-output/path/to/some-file.html
```

## Troubleshooting

### Script not executable
```bash
chmod +x apply-redhat-theme.sh
chmod +x redhat-theme/add-theme.py
```

### Python not found
Make sure Python 3 is installed:
```bash
python3 --version
```

On some systems, you may need to use `python` instead of `python3`:
```bash
# Edit add-theme.py shebang to:
#!/usr/bin/env python
```

### Zip file structure issues

The script expects DITA-generated HTML with `commonltr.css` or `commonrtl.css` references. If your HTML uses a different structure, you may need to modify the regex pattern in `add-theme.py`.

## Version Control

This theme directory should be committed to your repository so:
- The theme travels with your documentation source
- Team members can apply consistent styling
- Theme changes are version controlled
- CI/CD pipelines can automatically apply themes

## Continuous Integration

Example GitHub Actions workflow:

```yaml
name: Apply Red Hat Theme to Docs

on:
  workflow_dispatch:
    inputs:
      zip_url:
        description: 'URL to documentation zip file'
        required: true

jobs:
  theme:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Download docs zip
        run: wget ${{ github.event.inputs.zip_url }} -O docs.zip

      - name: Apply theme
        run: ./apply-redhat-theme.sh docs.zip

      - name: Upload themed docs
        uses: actions/upload-artifact@v3
        with:
          name: themed-docs
          path: docs-themed.zip
```

## Styling Details

The Red Hat theme includes:

### Colors
- Primary Red: `#ee0000`
- Primary Blue: `#0066cc`
- Text: `#151515` (light mode) / `#ffffff` (dark mode)
- Automatic dark mode based on `prefers-color-scheme`

### Typography
- **Headings**: Red Hat Display (40px → 16px scale)
- **Body**: Red Hat Text (18px, 1.667 line-height)
- **Code**: Red Hat Mono (14px)
- Fallback fonts for all families

### Components
- **Code blocks**: Styled background, syntax highlighting ready
- **Tables**: Hover states, proper borders, responsive
- **Notes**: Color-coded (blue/green/yellow/red) with left border
- **Steps**: Numbered with circular badges
- **Links**: Proper states (default, hover, visited, focus)

### Accessibility
- WCAG 2.1 AA compliant color contrasts
- Focus indicators on all interactive elements
- Screen reader support
- Keyboard navigation friendly

### Responsive
- Mobile: < 768px
- Tablet: 768px - 1024px
- Desktop: > 1024px

## License

This theme is based on Red Hat's documentation design system and should be used for Red Hat product documentation or compatible projects.

## Support

For issues or questions about the theme applicator:
1. Check this README
2. Review the inline comments in the scripts
3. Test with the sample output

---

**Last Updated**: October 6, 2026
