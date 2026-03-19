# Red Hat Developer Hub Documentation - Claude Memory

This file contains persistent knowledge about working with the RHDH documentation repository for Claude Code.

## CQA 2.1 Compliance Process

**ALWAYS use the checklist for CQA work:**

1. **FIRST:** Load the workflow files
   ```
   Read .claude/skills/cqa-master-workflow.md, .claude/cqa-checklist.md, .claude/MEMORY.md
   ```
   - The master workflow orchestrates all 17 CQA requirements in optimal order
   - The checklist follows the same 5-phase structure
   - **Idempotency requirement:** Re-execute each requirement until no changes, then re-run entire workflow until stable

2. **VERIFY required information** - If any are missing, ASK the user:
   - JIRA ticket number (e.g., RHIDP-12345)
   - Title name or path to master.adoc file

3. **THEN:** Use the master workflow as the guide
   - Create a TodoWrite following the sequence in cqa-master-workflow.md
   - Read individual CQA skills (.claude/skills/cqa-##-*.md) for detailed assessment
   - Run each step sequentially; respect the sequence order

4. **NEVER claim completion unless:**
   - ALL checkbox items are marked with a checkmark
   - Idempotency verified (re-running workflow produces no changes)
   - TodoWrite shows all tasks complete

### Reference Materials

Updated using `./build/scripts/update-cqa-resources.sh` (weekly minimum, daily maximum).
See `.claude/skills/update-all-resources.md` for details.

- **SSG:** `.claude/resources/red-hat-ssg.md` — grammar, style, formatting (CQA 8, 9, 10, 12, 16)
- **Peer Review:** `.claude/resources/red-hat-peer-review.md` — titles, grammar, editorial quality (CQA 10, 12)
- **Modular Docs:** `.claude/resources/red-hat-modular-docs.md` — content types, module templates (CQA 2-6, 10, 13)
- **Vale:** `.vale-dita-only.ini` (CQA 1), `.vale.ini` (CQA 12). Sync with `vale sync`. `attributes.adoc` excluded from Vale.

### Best Practices

1. **Scripts first, manual second:** Run all automated scripts before manual fixes
2. **One step at a time:** Don't batch steps, even if they seem related
3. **Verify after fixes:** Re-run scripts after manual changes to confirm alignment
4. **Git mv for renames:** Always use git mv to preserve history
5. **Idempotency:** Re-run each CQA requirement until no changes, then re-run full workflow until stable

### Pull Request Guidelines

**Never use `#` notation for CQA numbers** in PR descriptions (e.g., write "CQA 1" not "CQA #1"). GitHub auto-links `#number` to unrelated issues/PRs.

PR description format is in `.claude/cqa-checklist.md`.

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
