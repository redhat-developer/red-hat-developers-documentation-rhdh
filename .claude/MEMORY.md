# Red Hat Developer Hub Documentation - Claude Memory

This file contains persistent knowledge about working with the RHDH documentation repository for Claude Code.

## CQA 2.1 Compliance Process

### Critical Workflow Rule

**ALWAYS use the checklist for CQA work:**

When starting CQA 2.1 compliance for any title:

1. **FIRST:** Load the workflow files
   ```
   Read .claude/skills/cqa-master-workflow.md, .claude/cqa-checklist.md, .claude/MEMORY.md
   ```
   - The master workflow orchestrates all 17 CQA requirements in optimal order
   - The checklist follows the same 5-phase structure (updated 2026-03-13)
   - **Idempotency requirement:** Re-execute each requirement until no changes, then re-run entire workflow until stable

2. **VERIFY required information** - If any are missing, ASK the user:
   - JIRA ticket number (e.g., RHIDP-12345)
   - Title name (e.g., "Installing Red Hat Developer Hub on OpenShift Container Platform") OR
   - Path to master.adoc file (e.g., `titles/installing-rhdh-ocp/master.adoc`)

3. **THEN:** Use the master workflow as the guide
   - Create a TodoWrite with items from cqa-master-workflow.md
   - Follow the 5 phases in sequence:
     - Phase 0: Resources
     - Phase 1: Structure & Content Type (CQA #3, #13)
     - Phase 2: Short Descriptions & Titles (CQA #8, #9, #10, #11)
     - Phase 3: Assembly Structure (CQA #2, #5, #4, #6, #7)
     - Phase 4: Names & Validation (CQA #16, #1, #12, #17)
     - Phase 5: Links & Build (CQA #14, #15)
   - Use individual CQA skills (.claude/skills/cqa-##-*.md) for detailed assessment

4. **IMPORTANT:** Fill in the checklist header:
   - Title name
   - JIRA number (RHIDP-XXXXX)
   - Target file path

5. **NEVER claim completion unless:**
   - ALL checkbox items are marked ✓
   - Idempotency verified (re-running workflow produces no changes)
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
   - Finds files not referenced by any include statement
   - **Dynamic attribute detection** (updated 2026-03-13):
     - Automatically detects ANY `{...}` attribute substitution
     - No hardcoded patterns - works with {platform-id}, {context}, {product}, future attributes
     - Converts include patterns to regex (e.g., `proc-install-on-{platform-id}.adoc` → `proc-install-on-.*[.]adoc`)
   - Excludes template files (*.template.adoc) - these are code generation sources
   - Uses `cut -d: -f2-` to extract only include paths (not grep filename prefixes)

4. **Short Description Verification:**
   ```bash
   ./build/scripts/verify-short-descriptions.sh titles/<title>/master.adoc
   ```
   - Verifies [role="_abstract"] presence
   - Checks 50-300 character requirement
   - Validates no empty line after marker

5. **Build and Preview Generation:**
   ```bash
   ./build/scripts/build-ccutil.sh              # Build all titles for current branch
   ./build/scripts/build-ccutil.sh -b <branch>  # Build for specific branch
   ```
   - Uses Podman to run ccutil container (quay.io/ivanhorvath/ccutil:amazing)
   - Processes all titles/*/master.adoc files (excludes rhdh-plugins-reference)
   - Generates HTML single-page output in titles-generated/${BRANCH}/
   - Copies referenced images to output directory
   - Creates navigation index.html
   - Runs htmltest for link validation
   - Supports branch-specific builds and PR previews

### Reference Materials

**CQA reference materials are updated using:**
```bash
./build/scripts/update-cqa-resources.sh
```
See `.claude/skills/update-all-resources.md` for details.

**Update frequency:** Weekly minimum (7 days), daily maximum (1 day)

**Resources maintained:**

1. **Red Hat Supplementary Style Guide (SSG):**
   - **Location:** `.claude/resources/red-hat-ssg.md`
   - **When to reference:** CQA #8, #9, #10, #12, #16 (grammar, style, formatting)
   - **Key topics:** Conscious language, short descriptions, titles, user-replaced values, Technology Preview

2. **Red Hat Peer Review Guide:**
   - **Location:** `.claude/resources/red-hat-peer-review.md`
   - **When to reference:** CQA #10 (titles), CQA #12 (grammar), editorial quality
   - **Key topics:** Style checklist, grammar rules, formatting standards, review workflow

3. **Red Hat Modular Documentation Guide:**
   - **Location:** `.claude/resources/red-hat-modular-docs.md`
   - **When to reference:** CQA #2, #3, #4, #5, #6, #10, #13 (modularization, content types)
   - **Key topics:** Content types (ASSEMBLY, CONCEPT, PROCEDURE, REFERENCE), module templates, file naming

4. **Vale Linting Rules:**
   - **Timestamp:** `.claude/.vale-sync-timestamp`
   - **Sync command:** `vale sync` (automated by update script)
   - **When to sync:** Before CQA #1 (DITA validation) or CQA #12 (grammar/style validation)
   - **Configurations:** `.vale-dita-only.ini` (CQA #1), `.vale.ini` (CQA #12)

### Best Practices Learned

1. **Scripts first, manual second:** Run all automated scripts before manual fixes
2. **One step at a time:** Don't batch steps, even if they seem related
3. **Verify after fixes:** Re-run scripts after manual changes to confirm alignment
4. **Git mv for renames:** Always use git mv to preserve history
5. **Update includes last:** Fix filenames before updating include statements
6. **Check SSG currency:** Before style-related CQA work, ensure SSG is current (within 7 days)
7. **Sync Vale styles:** Before Vale validation (CQA #1, #12), ensure Vale is synced (within 7 days)
8. **Idempotency:** Re-run each CQA requirement until no changes, then re-run full workflow until stable
9. **Settings.json hygiene:**
   - Use wildcard patterns (e.g., `Bash(find *)`) not specific commands
   - Never commit sensitive information (usernames, API keys, absolute paths with usernames)
   - Use relative paths (.claude, .claude/resources) not absolute paths
   - Alphabetize permissions for maintainability
   - Verify with `jq . .claude/settings.json` before committing

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
