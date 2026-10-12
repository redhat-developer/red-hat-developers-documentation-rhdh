# Red Hat Documentation Theme Applied

This package contains your HTML documentation with Red Hat's documentation styling applied, matching the style and format used on https://docs.redhat.com/

## What Was Changed

### 1. New CSS File Added
- **File**: `redhat-docs-theme.css`
- **Location**: Root directory of the package
- Contains comprehensive Red Hat documentation styling

### 2. All HTML Files Updated
- **574 HTML files** have been updated
- Each file now includes a link to `redhat-docs-theme.css`
- The CSS link was added after the existing `commonltr.css` reference

## Styling Features Implemented

### Color Scheme
- **Light/Dark Mode Support**: Automatically adjusts based on user preference
- **Red Hat Brand Colors**:
  - Primary text: `#151515` (light) / `#ffffff` (dark)
  - Accent red: `#ee0000`
  - Accent blue: `#0066cc`
  - Links: `#0066cc` with hover states

### Typography
- **Font Families**:
  - Headings: Red Hat Display (with fallbacks)
  - Body text: Red Hat Text (with fallbacks)
  - Code: Red Hat Mono (with fallbacks)
- **Type Scale**: H1 (40px) down to H6 (16px)
- **Base font size**: 18px with 1.667 line-height

### Layout & Spacing
- **Consistent spacing scale**: 4px to 128px
- **Max content width**: 48rem for optimal readability
- **Responsive design**: Adapts to mobile, tablet, and desktop screens

### Enhanced Components
- **Code blocks**: Styled background with proper syntax highlighting support
- **Tables**: Hover states, proper borders, sticky headers
- **Notes/Admonitions**: Color-coded left borders (blue, green, yellow, red)
- **Task Steps**: Numbered with circular badges
- **Images**: Centered with proper captions
- **Links**: Proper hover and visited states

### Accessibility
- Proper focus indicators
- Screen reader support
- Skip link functionality
- High contrast ratios for text

## Usage

Simply open any HTML file in a web browser. The Red Hat theme will be automatically applied through the included CSS.

## Browser Compatibility

The styling works on all modern browsers:
- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers

## Notes

- The original `commonltr.css` and `commonrtl.css` files are preserved
- The new theme works in conjunction with existing DITA CSS
- Dark mode automatically activates based on system preferences
- All styling is contained in `redhat-docs-theme.css` for easy maintenance

## File Structure

```
rhdh-nav-with-redhat-theme/
├── redhat-docs-theme.css         # New Red Hat theme CSS
├── commonltr.css                  # Original DITA CSS (LTR)
├── commonrtl.css                  # Original DITA CSS (RTL)
├── Ansible-Automation-Platform/   # HTML files (updated)
├── red-hat-developer-hub/         # HTML files (updated)
└── README.md                      # This file
```

## Customization

To customize colors or spacing, edit the CSS custom properties at the top of `redhat-docs-theme.css`:

```css
:root {
  --rh-color-text-primary: #151515;
  --rh-color-accent-red: #ee0000;
  --rh-space-lg: 16px;
  /* etc. */
}
```

---

**Generated**: October 6, 2026
**Theme Version**: 1.0
**Based on**: Red Hat Ansible Automation Platform documentation styling
