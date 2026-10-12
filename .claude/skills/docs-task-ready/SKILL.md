# Documentation Task Readiness Analyzer

Analyze a single JIRA documentation ticket to determine if it's ready to work on by examining parent status, blockers, and engineering progress.

## Usage

Invoke this skill with a JIRA ticket ID:

```
Check if RHIDP-14652 is ready to work on
```

```
Is RHIDP-15445 ready for docs?
```

```
Analyze readiness for RHIDP-12345
```

```
Can I start working on RHIDP-14652?
```

## What This Skill Does

1. **Fetches ticket details** including relationship graph (parents, blockers, siblings)
2. **Analyzes readiness** based on engineering status and dependencies
3. **Provides clear recommendation** with reasoning and next actions
4. **Highlights risks** or missing information

## Readiness Criteria

A documentation task is considered **READY** when:

- ✅ **Parent exists:** Task has a parent Epic or Feature for context
- ✅ **Engineering started:** Parent Feature/Epic is in `In Progress`, `Code Review`, or `Done` (not `New`, `To Do`, `Blocked`)
- ✅ **No active blockers:** No blocking issues in non-closed states
- ✅ **Not already started:** Task status is `New`, `Backlog`, or `To Do`
- ✅ **Assigned to release:** Has a fix version set

## Status Categories

### 🟢 READY TO START
All criteria met - documentation work can begin immediately.

**Actions:**
- Contact engineering SME for details
- Review similar existing documentation
- Prepare documentation structure
- Consider running `/bug-analysis` for detailed report

### 🟡 WAITING ON ENGINEERING
Parent feature exists but engineering not yet started or still early.

**Actions:**
- Monitor parent issue for updates
- Prepare documentation templates
- Identify information needs
- Schedule sync with engineering when parent moves to `In Progress`

### 🔴 BLOCKED
Active blocking issues prevent work from starting.

**Actions:**
- Identify who owns the blocker
- Determine if blocker is critical for docs
- Consider if preliminary work is possible
- Track blocker resolution

### ⚠️ NEEDS TRIAGE
Missing critical information (no parent, no fix version, incomplete context).

**Actions:**
- Request parent Epic/Feature assignment
- Ask for fix version
- Request engineering contact
- Clarify scope and requirements

## Implementation Steps

### Step 1: Fetch Issue Graph

Use `jira-reader` with `--graph` to get complete relationship context:

```bash
python3 /Users/gforde/.claude/plugins/cache/redhat-docs-agent-tools/docs-tools/0.0.58/skills/jira-reader/scripts/jira_reader.py \
  --graph <JIRA-ID>
```

This returns:
- `parent`: Direct parent issue
- `ancestors`: Full parent chain (Epic → Feature)
- `children`: Subtasks
- `siblings`: Related tasks under same parent
- `issue_links`: Blocking/blocked relationships
- `web_links`: PRs, documentation links

### Step 2: Fetch Issue Details

If needed, get full issue details including comments:

```bash
python3 /Users/gforde/.claude/plugins/cache/redhat-docs-agent-tools/docs-tools/0.0.58/skills/jira-reader/scripts/jira_reader.py \
  --issue <JIRA-ID> --include-comments
```

### Step 3: Fetch Parent's Siblings

To understand the broader context, query for ALL siblings under the parent Feature, regardless of status:

**Method 1: Direct JQL query (recommended - shows all siblings)**
```bash
python3 /Users/gforde/.claude/plugins/cache/redhat-docs-agent-tools/docs-tools/0.0.58/skills/jira-reader/scripts/jira_reader.py \
  --jql "parent = <GRANDPARENT-FEATURE-ID> AND type = Epic ORDER BY created ASC"
```

**Method 2: Graph query (only shows active/done siblings)**
```bash
python3 /Users/gforde/.claude/plugins/cache/redhat-docs-agent-tools/docs-tools/0.0.58/skills/jira-reader/scripts/jira_reader.py \
  --graph <PARENT-ID>
```

**Note:** The `--graph` siblings field filters to "active" statuses only (In Progress, In Review, Code Review, Done). Use Method 1 for complete sibling visibility.

This shows:
- **All epics** under the same Feature (regardless of status)
- **Status of sibling epics** (New, In Progress, Done, etc.)
- **Patterns to follow** from completed siblings
- **Coordination needs** if siblings are in progress
- **Future work** from siblings in New/To Do status

**Example for RHIDP-14652:**
- Input task: RHIDP-14652 (docs task)
- Parent: RHIDP-13987 (docs epic)
- Grandparent: RHDHPLAN-1102 (feature)
- Query: `parent = RHDHPLAN-1102 AND type = Epic` → shows ALL epics under the Feature

### Step 4: Analyze Readiness

Apply logic:

```
IF no parent THEN status = NEEDS_TRIAGE
ELIF parent.status IN ("Done", "Closed") THEN status = READY (implementation complete)
ELIF parent.status IN ("In Progress", "Code Review") THEN status = READY (can start docs)
ELIF parent.status IN ("New", "To Do", "Backlog") THEN status = WAITING
ELIF parent.status = "Blocked" THEN status = BLOCKED

IF has blocking issues AND any blocker.status NOT IN ("Done", "Closed") THEN status = BLOCKED

IF task.status IN ("In Progress", "Done", "Closed") THEN status = ALREADY_STARTED

# Check parent's sibling statuses for delivery risk
IF any parent sibling has status NOT IN ("New", "Planning", "In Progress", "To Do", "Done", "Closed")
THEN add WARNING: "Review with sibling epic owners to confirm sprint delivery timeline"
```

**Sibling status risk levels:**
- ✅ **Done, Closed** - Work complete (no risk)
- ⚠️ **New, Planning, To Do** - Not started yet (delivery timing risk - might not start in sprint)
- ⚠️ **In Progress** - Work started but not complete (delivery timing risk - might not finish in sprint)
- 🔴 **Blocked, On Hold** - Work stopped (high delivery risk)
- 🔴 **Cancelled, Deferred** - Work won't happen (feature scope change)
- 🔴 **Other non-standard statuses** - Unclear state

**Action required:**
- For **any** sibling NOT in "Done" or "Closed" status, recommend contacting sibling epic owners to confirm sprint delivery timeline
- Only siblings with "Done" or "Closed" status provide confidence that the work is complete

### Step 5: Analyze Context Quality

Check for sufficient information:

- **Parent has description:** Can extract requirements
- **Parent has comments:** Engineering discussion available
- **Parent has git links:** Implementation PRs exist
- **Siblings exist:** Similar docs tasks for reference
- **Fix version set:** Clear target release

### Step 6: Generate Recommendation

Output structured analysis with:

1. **Status indicator** (🟢/🟡/🔴/⚠️)
2. **Task summary** (title, priority, assignee, fix version)
3. **Parent context** (full ancestor chain with statuses)
4. **Blocker list** (if any)
5. **Readiness signals** (what criteria are met/not met)
6. **Risk flags** (missing info, unclear scope, complex changes)
7. **Recommended actions** (what to do next)
8. **Related tasks** (siblings for reference)

## Output Format

```markdown
# <JIRA-ID> Readiness Analysis

## Status: <STATUS-EMOJI> <STATUS-TEXT>

**Task:** <Summary>
**Priority:** <Priority>
**Fix Version:** <Version>
**Assignee:** <Name>
**JIRA:** <URL>

---

## Parent Context

**Feature:** <Feature-ID> - <Summary> (Status: <Status>)
**Epic:** <Epic-ID> - <Summary> (Status: <Status>)

<If parent has description, show excerpt>

---

## Blockers

<If no blockers>
✅ No blocking issues

<If blockers exist>
🔴 **<Blocker-ID>:** <Summary> (Status: <Status>)
   - Type: <Bug/Task/etc>
   - Assigned to: <Name>
   - Link: <URL>

---

## Readiness Signals

✅ <Criteria met>
❌ <Criteria not met>
⚠️ <Warnings>

---

## Context Quality

**Information Available:**
- Parent description: <Yes/No - length>
- Parent comments: <Count>
- Git links: <Count PRs>
- Sibling tasks: <Count>
- Web links: <Count>

**Potential Risks:**
- <List any concerns>

---

## Recommendation

<Clear recommendation paragraph>

**Next Actions:**
1. <Specific action>
2. <Specific action>
3. <Specific action>

---

## Related Tasks

<If siblings exist, list them>

**Other docs tasks under same parent:**
- <Sibling-ID>: <Summary> (Status: <Status>)

---

## Parent's Sibling Epics

<If parent has siblings, list them - use JQL query for complete list>

**All epics under the same Feature:**
- <Sibling-Epic-ID>: <Summary> (Status: <Status>, Type: <Type>)
  - Assignee: <Name>
  - Fix Version: <Version>

**Analysis:**
- ✅ **Completed:** List siblings Done/Closed
- ⚠️ **In Progress:** List siblings In Progress/In Review/Code Review (delivery timing risk)
- ⚠️ **Not Started:** List siblings New/To Do/Planning (delivery timing risk)
- 🔴 **High Risk:** List siblings Blocked/On Hold/Cancelled/Deferred (critical delivery risk)

**Delivery Risk Assessment:**

<If all siblings are Done/Closed>
✅ **No delivery risks detected** - All sibling epics are complete (Done/Closed).

<If any sibling is NOT Done/Closed>
⚠️ **DELIVERY TIMING RISK:** Some sibling epics are not yet complete. **Please review with the sibling epic owners to confirm they will be delivered in the current sprint timeframe.**

**Incomplete siblings:**
- **New/Planning/To Do** siblings: Work hasn't started - may not begin in time
- **In Progress** siblings: Work started but not finished - may not complete in time
<If any Blocked/On Hold/Cancelled/Deferred siblings exist>
- 🔴 **High Risk** siblings (Blocked/On Hold/Cancelled/Deferred): Critical delivery issues - feature may be incomplete

**Benefits:**
- See complete picture of feature implementation
- Understand work sequencing (what's done, active, planned)
- Identify coordination opportunities across teams
- Learn from completed siblings
- Spot delivery risks early
```

## Example Output

```markdown
# RHIDP-14652 Readiness Analysis

## Status: 🟢 READY TO START

**Task:** [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
**Priority:** Major
**Fix Version:** 2.1.0
**Assignee:** Gerry Forde
**JIRA:** https://redhat.atlassian.net/browse/RHIDP-14652

---

## Parent Context

**Feature:** RHDHPLAN-1102 - Integration of DORA Metrics into RHDH Scorecard Plugin (Status: In Progress)
**Epic:** RHIDP-13987 - [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin (Status: New)

Engineering is actively implementing the DORA metrics feature. The Feature is in progress, indicating code development is underway.

---

## Blockers

✅ No blocking issues

---

## Readiness Signals

✅ Parent Feature exists (RHDHPLAN-1102)
✅ Parent Feature is In Progress (engineering underway)
✅ No blocking issues detected
✅ Task is in New status (not started)
✅ Assigned to fix version 2.1.0
✅ Has parent Epic for docs context
⚠️ Parent Feature description unavailable (API limitation)

---

## Context Quality

**Information Available:**
- Parent description: Unavailable (API error)
- Parent comments: 0
- Git links: 0 (no PRs yet)
- Sibling tasks: 0
- Web links: 0

**Potential Risks:**
- No PRs linked yet - implementation may be early stage
- No sibling docs tasks - first documentation effort for this feature
- Limited parent context due to API issues
- May need to sync with engineering to understand scope

---

## Recommendation

**You can start this task.** The parent Feature is In Progress, indicating engineering work is underway. However, the lack of linked PRs and parent context suggests this may be early in the development cycle.

**Recommended approach:**
1. Contact the engineering SME or Feature owner for implementation details
2. Review existing Scorecard plugin documentation patterns (GitHub, Jira, OpenSSF integrations)
3. Prepare documentation skeleton with placeholders for missing details
4. Run `/bug-analysis RHIDP-14652` for detailed gap analysis
5. Schedule follow-up sync when first PR is available for technical review

**Start with low-risk preparation work:**
- Identify documentation structure based on existing patterns
- Create placeholder procedure modules
- List questions for engineering team
- Prepare reference table entries

---

## Related Tasks

No sibling documentation tasks found under the same parent.

---

## Parent's Sibling Epics

**All epics under the same Feature (RHDHPLAN-1102):**

### RHIDP-13678: [Backend] Integration of DORA Metrics into RHDH Scorecard Plugin
- **Status:** In Progress ✅
- **Assignee:** Dominika Zemanovicova
- **Fix Version:** 2.1.0
- **Type:** Epic

### RHIDP-13983: [Frontend] Integration of DORA Metrics into RHDH Scorecard Plugin
- **Status:** New 🔜
- **Assignee:** Eswaraiah Sapram
- **Fix Version:** 2.1.0
- **Type:** Epic

### RHIDP-13984: [QE] Integration of DORA Metrics into RHDH Scorecard Plugin
- **Status:** New 🔜
- **Assignee:** Unassigned
- **Fix Version:** 2.1.0
- **Type:** Epic

### RHIDP-13987: [Docs] Integration of DORA Metrics into RHDH Scorecard Plugin
- **Status:** New 🔜
- **Assignee:** Gerry Forde (you)
- **Fix Version:** 2.1.0
- **Type:** Epic

**Analysis:**
- ✅ **Active work:** Backend epic is In Progress
- 🔜 **Planned:** Frontend, QE, and Docs epics are New (waiting to start)
- **Work sequencing:** Backend → Frontend → QE/Docs (typical pattern)
- **Coordination opportunity:** Backend epic owner can provide implementation details

**Benefits:**
- Backend being In Progress confirms active engineering work
- You can coordinate with backend team for implementation details
- Frontend and QE teams are also waiting, so you're not alone
- Classic cross-functional feature breakdown
```

## Advanced Features

### Show Full Ancestor Chain

For complex hierarchies (Task → Epic → Feature → Initiative):

```
Show full context for RHIDP-14652
```

Output includes all ancestors with detailed status and descriptions.

### Compare with Similar Tasks

Find and compare with similar documentation tasks:

```
Check RHIDP-14652 and compare with similar scorecard tasks
```

Searches for tasks with similar summaries or components.

### Include Historical Context

Check comments and history for engineering updates:

```
Check RHIDP-14652 with full history
```

Includes comment analysis for implementation progress signals.

## Integration with Other Tools

### Chain with Bug Analysis Workflow

If task is READY, automatically run detailed analysis:

```
Check RHIDP-14652 and run bug analysis if ready
```

### Update Task Status

If starting work, offer to update JIRA:

```
Check RHIDP-14652 and assign to me if ready
```

(Requires `jira-writer` skill integration)

### Create Tracking Card

For READY tasks, create a local tracking file:

```
Check RHIDP-14652 and create task card
```

Saves to `/Users/gforde/my-rhdh-fixes/task-cards/RHIDP-14652.md`

## Troubleshooting

**Issue:** "Parent description unavailable" errors
**Cause:** JIRA API returns `PropertyHolder` objects for some fields
**Solution:** Rely on parent status and git links; sync with SME for context

**Issue:** All tasks show as WAITING
**Cause:** Parent Epic created but Feature not started
**Solution:** Check Feature status, not Epic status, for engineering progress

**Issue:** No parent found
**Cause:** Task not properly linked in JIRA
**Solution:** Request parent Epic/Feature assignment in JIRA

## Configuration

### Status Mapping

Customize how JIRA statuses map to readiness:

```yaml
ready_statuses:
  - "In Progress"
  - "Code Review"
  - "Testing"
  - "Done"

waiting_statuses:
  - "New"
  - "To Do"
  - "Backlog"

blocked_statuses:
  - "Blocked"
  - "On Hold"
```

### Ignored Blocker Types

Some blockers may not affect docs:

```yaml
ignore_blocker_types:
  - "Spike"
  - "Research"
```

## Notes

- Analysis uses `--graph` which is subject to API rate limits (2 calls per 5 seconds)
- Parent Feature status is more reliable than Epic status for readiness
- Tasks with no parent should be triaged before documentation work begins
- Engineering PRs are the strongest signal of implementation progress
- Comments may contain implementation updates not reflected in status

## Related Resources

- `.claude/workflows/bug-analysis.md` - Detailed analysis workflow
- `.claude/plugins/rhdh-docs-tools/` - RHDH-specific documentation tools
- JIRA: https://issues.redhat.com/projects/RHIDP
- jira-reader skill documentation
