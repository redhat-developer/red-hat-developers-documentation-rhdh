#!/usr/bin/env python3
"""
Generate CQA 2.1 skill files from Pre-migration.html
"""
import re
from html.parser import HTMLParser
from pathlib import Path

class SimpleTableParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_row = False
        self.in_cell = False
        self.cells = []
        self.rows = []
        self.cell_text = []
        self.cell_link = None
        
    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        if tag == "tr":
            self.in_row = True
            self.cells = []
        elif tag == "td" and self.in_row:
            self.in_cell = True
            self.cell_text = []
            self.cell_link = None
        elif tag == "a" and self.in_cell:
            href = attrs_dict.get("href", "")
            if href and not href.startswith("#"):
                self.cell_link = href
    
    def handle_endtag(self, tag):
        if tag == "td" and self.in_cell:
            text = "".join(self.cell_text).strip()
            self.cells.append({"text": text, "link": self.cell_link})
            self.in_cell = False
        elif tag == "tr" and self.in_row:
            if self.cells:
                self.rows.append(self.cells[:])
            self.in_row = False
    
    def handle_data(self, data):
        if self.in_cell:
            self.cell_text.append(data)

def clean_filename(text):
    """Create safe filename from text"""
    text = re.sub(r'\s+', ' ', text).strip()[:50]
    text = re.sub(r'[^a-z0-9-]', '-', text.lower())
    return re.sub(r'-+', '-', text).strip('-')

def main():
    resources_dir = Path(__file__).parent
    html_file = resources_dir / "Pre-migration.html"
    skills_dir = resources_dir.parent / "skills"
    
    # Parse HTML
    with open(html_file) as f:
        parser = SimpleTableParser()
        parser.feed(f.read())
    
    # Extract requirements
    requirements = []
    section = ""
    quality_patterns = ["Required/non-negotiable", "Important/negotiable"]
    
    for i, row in enumerate(parser.rows):
        if len(row) >= 5:
            req_text = row[0]["text"]
            quality = row[1]["text"]
            
            if req_text == "Requirement":
                continue
            
            # Section header
            if req_text and not quality and len(req_text) < 100:
                if req_text not in ["Assessment levels", "Basic information", "Vale instructions"]:
                    section = req_text
            # Actual requirement
            elif any(pattern in quality for pattern in quality_patterns):
                requirements.append({
                    "row": i + 1,
                    "section": section,
                    "requirement": row[0],
                    "quality_level": row[1],
                    "assessment": row[2],
                    "notes": row[4] if len(row) > 4 else {"text": "", "link": None}
                })
    
    print(f"Found {len(requirements)} requirements")
    
    # Generate Markdown documentation
    md = ["# CQA 2.1 Pre-Migration Requirements\n"]
    md.append("*Extracted from official CQA 2.1 Google Sheets*\n")
    md.append("---\n")
    
    current_section = None
    for idx, req in enumerate(requirements, 1):
        if req["section"] != current_section:
            current_section = req["section"]
            md.append(f"\n## {current_section}\n")
        
        md.append(f"### #{idx} - {req['requirement']['text'][:60]}...\n")
        
        r = req["requirement"]
        if r["link"]:
            md.append(f"**Requirement:** [{r['text']}]({r['link']})\n")
        else:
            md.append(f"**Requirement:** {r['text']}\n")
        
        md.append(f"**Quality Level:** {req['quality_level']['text']}\n")
        md.append(f"**Current Assessment:** {req['assessment']['text']}\n")
        
        if req["notes"]["text"]:
            n = req["notes"]
            if n["link"]:
                md.append(f"**Notes:** [{n['text']}]({n['link']})\n")
            else:
                md.append(f"**Notes:** {n['text']}\n")
        md.append("\n")
    
    md_file = resources_dir / "cqa-requirements.md"
    md_file.write_text("\n".join(md))
    print(f"✓ Generated: {md_file}")
    
    # Generate skill files
    skills_dir.mkdir(exist_ok=True)
    
    for idx, req in enumerate(requirements, 1):
        filename = f"cqa-{idx:02d}-{clean_filename(req['requirement']['text'])}.md"
        skill_file = skills_dir / filename
        
        skill = []
        skill.append(f"# CQA-{idx} - {req['section']}\n")
        skill.append(f"## {req['requirement']['text']}\n")
        
        if req["requirement"]["link"]:
            skill.append(f"**Reference:** {req['requirement']['link']}\n")
        
        skill.append(f"**Quality Level:** {req['quality_level']['text']}\n")
        
        if req["notes"]["text"]:
            skill.append("\n## Notes\n")
            skill.append(f"{req['notes']['text']}\n")
            if req["notes"]["link"]:
                skill.append(f"\n**Reference:** {req['notes']['link']}\n")
        
        skill.append("\n## Assessment\n")
        skill.append("```yaml\n")
        skill.append("title: \n")
        skill.append("status: No data  # Meets criteria | Mostly meets | Mostly does not meet | Does not meet | Not applicable\n")
        skill.append("notes: |\n")
        skill.append("  \n")
        skill.append("```\n")
        
        skill_file.write_text("\n".join(skill))
    
    print(f"✓ Generated {len(requirements)} skill files in: {skills_dir}")
    
    # Create index
    index = ["# CQA 2.1 Compliance Skills\n"]
    index.append("Individual assessment skills for each Pre-migration requirement.\n")
    index.append("---\n")
    
    current_section = None
    for idx, req in enumerate(requirements, 1):
        if req["section"] != current_section:
            current_section = req["section"]
            index.append(f"\n## {current_section}\n")
        
        filename = f"cqa-{idx:02d}-{clean_filename(req['requirement']['text'])}.md"
        title = req['requirement']['text'][:80]
        index.append(f"{idx}. [{title}]({filename})\n")
    
    index_file = skills_dir / "README.md"
    index_file.write_text("\n".join(index))
    print(f"✓ Generated: {index_file}")
    
    print("\n✓ Done! Next steps:")
    print(f"  1. Review: {md_file}")
    print(f"  2. Review skills: {skills_dir}")
    print(f"  3. Use skills to assess CQA compliance for each title")

if __name__ == "__main__":
    main()
