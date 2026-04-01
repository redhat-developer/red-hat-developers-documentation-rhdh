# Claude Code Configuration

This directory contains configuration and documentation for working with [Claude Code](https://claude.com/claude-code) on the RHDH documentation repository.

## Files

### `settings.json`
Claude Code repository-specific permissions and settings. Defines:
- Allowed bash commands and scripts
- File read permissions
- Additional working directories

**Important:** Keep permissions minimal and use wildcard patterns instead of individual file paths.

### `MEMORY.md`
Persistent knowledge for Claude Code about this repository:
- CQA 2.1 workflow rules
- Automation script quick reference
- Best practices and common pitfalls
- Repository structure overview

This file helps Claude Code maintain context about project-specific conventions and workflows across sessions.

### `cqa-checklist.md`
Comprehensive checklist template for CQA 2.1 compliance work. Contains:
- All 17 main steps from CQA.md with sub-steps
- Script commands with exact syntax
- Verification checkpoints
- Acceptance criteria tracking

**Usage:** When starting CQA work with Claude Code, load this checklist to ensure all steps are tracked and completed systematically.

## Directories

### `skills/`
CQA 2.1 compliance assessment skills:

**Main Workflow:**
- `cqa-main-workflow.md` - Complete CQA process orchestrating all 17 requirements in optimal order

**Individual Skills (17 total):**
- `cqa-01-*.md` through `cqa-17-*.md` - One skill per Pre-migration requirement
- Each skill includes: requirement description, reference links, quality level, assessment template

**Usage:** Start with the master workflow, which guides you through all requirements in the correct sequence aligned with the CQA 2.1 checklist.

### `resources/`
CQA 2.1 reference materials and style guides:

**CQA Requirements:**
- `CQA 2.1 -- Content Quality Assessment.zip` - Official CQA spreadsheet export (HTML format, preserves links)
- `cqa-requirements.md` - All 17 Pre-migration requirements in structured Markdown
- `generate_cqa_skills.py` - Script to regenerate skills from the ZIP file

**Style References:**
- `red-hat-ssg.md` - Red Hat Supplementary Style Guide (SSG) for product documentation
  - Updated weekly minimum, daily maximum
  - Source: https://redhat-documentation.github.io/supplementary-style-guide/ssg.md
  - Used for CQA-8, #9, #10, #12, #16 (grammar, style, formatting)
- `red-hat-peer-review.md` - Red Hat Peer Review Guide for technical documentation
  - Updated weekly minimum, daily maximum
  - Source: https://redhat-documentation.github.io/peer-review/
  - Used for CQA-10 (titles), CQA-12 (grammar), editorial quality
- `red-hat-modular-docs.md` - Red Hat Modular Documentation Reference Guide
  - Updated weekly minimum, daily maximum
  - Source: https://redhat-documentation.github.io/modular-docs/
  - Used for CQA-2, #3, #4, #5, #6, #10, #13 (modularization, content types, templates)

**Vale Configuration:**
- `.vale-sync-timestamp` - Tracks last Vale sync time (Unix timestamp)
- Vale styles synced weekly minimum, daily maximum
- Command: `vale sync` updates RedHat, AsciiDocDITA style rules
- Used for CQA-1 (DITA validation) and CQA-12 (grammar/style)

**Regenerating skills:** If the official CQA spreadsheet is updated, re-export to ZIP, replace the file, and run:
```bash
cd .claude/resources
python3 generate_cqa_skills.py
```

**Updating references:**
```bash
./build/scripts/update-cqa-resources.sh
```
See [update-all-resources.md](skills/update-all-resources.md) skill for details.

## For Team Members Using Claude Code

1. **Starting CQA work:**
   - Ask Claude to "Read .claude/MEMORY.md and .claude/cqa-checklist.md"
   - Create a TodoWrite with all checklist items
   - Fill in the header (Title, JIRA, Target file)

2. **Tracking progress:**
   - Mark each item ✓ immediately when done
   - Ask Claude to "Show CQA progress" at any time

3. **Before claiming completion:**
   - Verify ALL checklist items are marked ✓
   - Don't accept completion claims without seeing the full checklist

## Benefits

- **Systematic execution:** Prevents skipped steps in long multi-step processes
- **Explicit tracking:** TodoWrite integration ensures nothing is forgotten
- **Team consistency:** Everyone follows the same CQA workflow
- **Knowledge preservation:** MEMORY.md captures lessons learned and best practices

## Contributing

If you discover new patterns, best practices, or common issues while working with Claude Code on this repository:

1. Update `MEMORY.md` with the new knowledge
2. Update `cqa-checklist.md` if the CQA process changes
3. Commit changes with a clear explanation
4. Share learnings with the team

This helps build institutional knowledge and improves the workflow for everyone.
