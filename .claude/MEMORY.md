# Red Hat Developer Hub Documentation - Claude Memory

This file contains persistent knowledge about working with the RHDH documentation repository for Claude Code.

## CQA 2.1 Compliance Process

### Critical Workflow Rule

**ALWAYS use the checklist for CQA work:**

When starting CQA 2.1 compliance for any title:

1. **FIRST:** Load the checklist template
   ```
   Read .claude/cqa-checklist.md
   ```

2. **THEN:** Create a TodoWrite with ALL items from the checklist

3. **IMPORTANT:** Fill in the header:
   - Title name
   - JIRA number (RHIDP-XXXXX)
   - Target file path

4. **NEVER claim completion unless:**
   - ALL checkbox items are marked ✓
   - TodoWrite shows all tasks complete
   - User has explicitly verified completion

### Why This Matters

**The problem:** CQA has 17 main steps with multiple sub-steps. Without a checklist, steps get forgotten and completion is claimed prematurely.

**The solution:** The checklist is the single source of truth. If it's not checked, it's not done.

### Automation Scripts

Use these scripts for systematic tasks:

1. **Content Type Detection/Fixing:**
   ```bash
   ./build/scripts/fix-content-type.sh titles/<title>/master.adoc
   ```
   - Auto-detects and fixes content type metadata
   - Normalizes .Procedure and .Verification list formatting
   - Validates PROCEDURE structure
   - Shows violation breakdown

2. **Title/ID/Filename Alignment:**
   ```bash
   ./build/scripts/fix-title-id-filename.sh titles/<title>/master.adoc
   ```
   - Ensures content type metadata exists (calls fix-content-type.sh if needed)
   - Fixes title forms (gerund → imperative)
   - Aligns IDs to match titles
   - Renames files with git mv
   - Updates xrefs and includes automatically

3. **Orphaned Module Detection:**
   ```bash
   ./build/scripts/fix-orphaned-modules.sh          # Dry-run (lists only)
   ./build/scripts/fix-orphaned-modules.sh --execute # Actually deletes
   ```
   - Finds files not referenced by any include
   - Handles attribute substitution patterns

4. **Short Description Verification:**
   ```bash
   ./build/scripts/verify-short-descriptions.sh titles/<title>/master.adoc
   ```
   - Verifies [role="_abstract"] presence
   - Checks 50-300 character requirement
   - Validates no empty line after marker

### Best Practices Learned

1. **Scripts first, manual second:** Run all automated scripts before manual fixes
2. **One step at a time:** Don't batch steps, even if they seem related
3. **Verify after fixes:** Re-run scripts after manual changes to confirm alignment
4. **Git mv for renames:** Always use git mv to preserve history
5. **Update includes last:** Fix filenames before updating include statements

### Common Pitfalls to Avoid

❌ **Don't:** Skip the checklist and try to remember all steps
✅ **Do:** Load checklist first, mark items as done

❌ **Don't:** Claim "CQA complete" without showing all ✓ items
✅ **Do:** Show checklist with all items marked before claiming completion

❌ **Don't:** Run steps out of order
✅ **Do:** Follow exact sequence in checklist

❌ **Don't:** Batch steps together ("I'll do 2-4 at once")
✅ **Do:** Complete each step fully, mark it ✓, then proceed

## Repository Structure

- `titles/` - Top-level documentation titles (master.adoc files)
- `assemblies/` - Assembly files that combine modules
- `modules/` - Individual module files (proc-, con-, ref-, snip- prefixes)
- `artifacts/` - Reusable snippets and fragments
- `build/scripts/` - Automation scripts for CQA and validation
- `.claude/` - Claude Code configuration and documentation
  - `settings.json` - Repository-specific permissions and settings
  - `MEMORY.md` - This file - persistent knowledge for Claude
  - `cqa-checklist.md` - CQA 2.1 compliance checklist template

## User Preferences

- Uses wildcard patterns in .claude/settings.json (not individual files)
- Prefers focused, single-purpose tasks over large multi-step processes
- Values explicit tracking with TodoWrite for complex workflows
- Commits frequently with descriptive messages including "Co-Authored-By: Claude Sonnet 4.5"
