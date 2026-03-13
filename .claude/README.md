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
