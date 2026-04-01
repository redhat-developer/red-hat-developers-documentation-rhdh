# Red Hat Developer Hub Documentation - Claude Memory

This file contains persistent knowledge about working with the RHDH documentation repository for Claude Code.

## CQA 2.1 Compliance

The `project-cqa` plugin (`.claude/plugins/project-cqa/`) provides:
- **Skills:** `cqa-main-workflow` orchestrates all 19 checks; individual `cqa-NN-*` skills for each check
- **Spec:** `resources/cqa-spec.md` is the single source of truth for all check logic
- **Resources:** Style guides, templates, and reference materials

**Script interface:**
```bash
node build/scripts/cqa/index.js [--fix] [--check NN] titles/<title>/master.adoc
```

**Never use `#` notation for CQA numbers** in PR descriptions — GitHub auto-links `#number`.

## Repository Structure

- `titles/` - Top-level documentation titles (master.adoc files)
- `assemblies/` - Assembly files that combine modules
- `modules/` - Individual module files (proc-, con-, ref-, snip- prefixes)
- `artifacts/` - Reusable snippets and fragments
- `build/scripts/` - Automation scripts for CQA and validation
- `.claude/` - Claude Code configuration and documentation

## User Preferences

- Uses wildcard patterns in .claude/settings.json (not individual files)
- Prefers focused, single-purpose tasks over large multi-step processes
- Values explicit tracking with TodoWrite for complex workflows
