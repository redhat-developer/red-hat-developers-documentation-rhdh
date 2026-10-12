# Red Hat Documentation Theme Tool

A reproducible tool for applying Red Hat's documentation styling to DITA HTML exports.

## Quick Start

```bash
./apply-redhat-theme.sh ~/Downloads/your-documentation.zip
```

This creates `your-documentation-themed.zip` with Red Hat styling applied.

## Examples

```bash
# Apply theme to RHDH 1.10 navigation docs
./apply-redhat-theme.sh ~/Downloads/rhdh-1-10-navigation.zip

# Apply theme to RHDH 1.11 navigation docs
./apply-redhat-theme.sh ~/Downloads/rhdh-1-11-navigation.zip

# Works with any DITA HTML export
./apply-redhat-theme.sh ~/Downloads/my-docs.zip
```

## What Gets Applied

- ✅ Red Hat brand colors (red `#ee0000`, blue `#0066cc`)
- ✅ Red Hat typography (Display, Text, Mono fonts)
- ✅ Light/Dark mode support (automatic)
- ✅ Responsive design (mobile, tablet, desktop)
- ✅ Enhanced code blocks, tables, notes, steps
- ✅ Accessibility features (WCAG 2.1 AA)

## Output

The script creates a new zip file with:
- All original HTML files updated with theme CSS link
- `redhat-docs-theme.css` - The complete Red Hat theme
- `README.md` - Documentation for end users

## File Structure

```
.
├── apply-redhat-theme.sh     # Main script (run this)
└── redhat-theme/
    ├── README-USAGE.md        # Detailed usage guide
    ├── README.md              # End user documentation
    ├── redhat-docs-theme.css  # The CSS theme
    └── add-theme.py           # HTML updater script
```

## Requirements

- bash
- Python 3
- zip/unzip utilities

## Customization

To modify the theme styling, edit `redhat-theme/redhat-docs-theme.css` and adjust the CSS custom properties:

```css
:root {
  --rh-color-accent-red: #ee0000;
  --rh-color-accent-blue: #0066cc;
  --rh-font-size-base: 1.125rem;
  /* etc. */
}
```

## Documentation

For detailed documentation, see [`redhat-theme/README-USAGE.md`](redhat-theme/README-USAGE.md)

## Styling Reference

Based on: https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/2.6

---

**Version**: 1.0
**Last Updated**: October 6, 2026
