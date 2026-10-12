#!/usr/bin/env python3
"""
Add Red Hat documentation theme CSS to all HTML files in a directory
"""
import os
import re
import sys
from pathlib import Path


def add_css_link(html_file_path, base_dir):
    """Add the redhat-docs-theme.css link to an HTML file"""

    # Read the file
    try:
        with open(html_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Warning: Could not read {html_file_path}: {e}")
        return False

    # Check if already added
    if 'redhat-docs-theme.css' in content:
        return False

    # Calculate relative path from HTML file to CSS file
    html_path = Path(html_file_path)
    css_path = Path(base_dir) / 'redhat-docs-theme.css'

    # Get relative path
    try:
        rel_path = os.path.relpath(css_path, html_path.parent)
    except ValueError:
        # On Windows, relpath can fail if paths are on different drives
        rel_path = str(css_path)

    # Convert Windows backslashes to forward slashes for URLs
    rel_path = rel_path.replace('\\', '/')

    # Create the new link tag
    new_link = f'<link rel="stylesheet" type="text/css" href="{rel_path}">'

    # Find the existing link tag for commonltr.css or commonrtl.css
    # and add our new link after it
    pattern = r'(<link rel="stylesheet" type="text/css" href="[^"]*common(?:ltr|rtl)\.css">)'

    if re.search(pattern, content):
        new_content = re.sub(
            pattern,
            r'\1' + new_link,
            content
        )
    else:
        # If no common css found, try to add before </head>
        if '</head>' in content:
            new_content = content.replace('</head>', f'{new_link}</head>')
        else:
            print(f"Warning: Could not find insertion point in {html_file_path}")
            return False

    # Write back
    try:
        if new_content != content:
            with open(html_file_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
    except Exception as e:
        print(f"Warning: Could not write {html_file_path}: {e}")
        return False

    return False


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 add-theme.py <directory>")
        print("Example: python3 add-theme.py /path/to/extracted/docs")
        sys.exit(1)

    base_dir = sys.argv[1]

    if not os.path.isdir(base_dir):
        print(f"Error: {base_dir} is not a directory")
        sys.exit(1)

    # Find all HTML files
    html_files = list(Path(base_dir).rglob('*.html'))

    if not html_files:
        print(f"Warning: No HTML files found in {base_dir}")
        sys.exit(0)

    print(f"Found {len(html_files)} HTML files")

    updated = 0
    for html_file in html_files:
        if add_css_link(str(html_file), base_dir):
            updated += 1

    print(f"Updated {updated} HTML files")


if __name__ == '__main__':
    main()
