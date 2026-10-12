# Bug Analysis Report Workflow

Generate a comprehensive documentation bug analysis report from a JIRA ticket.

## Quick Start

To generate a report for a JIRA ticket, tell Claude:

```
Generate a bug analysis report for RHIDP-15155
```

Or more explicitly:

```
Follow the bug analysis workflow in .claude/workflows/bug-analysis.md for ticket RHIDP-15155
```

## What This Workflow Does

1. Fetches JIRA ticket details
2. Identifies affected documentation files
3. Analyzes current vs. required state
4. Generates a structured markdown report at `/Users/gforde/my-rhdh-fixes/<JIRA-ID>-documentation-fix.md`

## Expected Output

A comprehensive report including:
- Executive Summary
- Problem Statement (from JIRA)
- Solution Analysis (current state, gaps)
- Recommended Implementation (specific changes with line numbers)
- Impact Assessment (customer, documentation, risk)
- Success Criteria
- Full proposed file content (if extensive changes)

## Steps Claude Will Follow

### 1. Gather Information
- Ask for JIRA ticket ID if not provided
- Optionally use jira-reader to fetch ticket details
- Extract problem description, required configuration, and context

### 2. Identify Affected Files
- Search for relevant content using Grep
- Find modules and assemblies mentioned in the ticket
- Read current documentation state using Read

### 3. Analyze the Problem
Document:
- What is reported vs. what exists
- Current documentation strengths
- Gaps and missing information
- Required vs. actual configuration

### 4. Develop Recommendations
Propose:
- Specific file changes with line numbers
- Exact AsciiDoc markup for new content
- Rationale for each change
- Alternative approaches considered

### 5. Assess Impact
Evaluate:
- **Customer Impact:** Severity, frequency, affected users
- **Documentation Impact:** Complexity, maintenance, localization
- **Risk Assessment:** What could go wrong, mitigation

### 6. Generate Report
Create `/Users/gforde/my-rhdh-fixes/<JIRA-ID>-documentation-fix.md` with full analysis

### 7. Provide Summary
- Report location
- Key findings
- Recommended next actions

## Example Usage

**User says:**
```
Generate a bug analysis report for RHIDP-15155
```

**Claude will:**
1. Search for "Install dynamic plugins in an air-gapped environment" content
2. Read affected .adoc files
3. Compare bug report requirements with current documentation
4. Generate `/tmp/RHIDP-15155-documentation-fix.md`
5. Summarize findings

## Best Practices

**Do:**
- ✅ Read all affected files before proposing changes
- ✅ Preserve existing correct examples
- ✅ Use proper AsciiDoc formatting
- ✅ Reference specific line numbers
- ✅ Consider CQA compliance
- ✅ Assess multiple audiences

**Don't:**
- ❌ Replace working examples without verification
- ❌ Make assumptions without reading files
- ❌ Propose changes without rationale
- ❌ Ignore related documentation
- ❌ Skip impact assessment

## Quality Checklist

Before completing, verify:
- [ ] JIRA ticket fully analyzed
- [ ] All affected files identified and read
- [ ] Problem clearly articulated
- [ ] Solution justified with evidence
- [ ] Implementation details are actionable
- [ ] Impact assessment is realistic
- [ ] Success criteria are measurable
- [ ] Report follows standard structure

## Report Template Structure

```markdown
# Documentation Fix: <Title>
**Document ID:** <JIRA-ID>
**Date:** <Date>
**Affected File(s):** <paths>

## Executive Summary
[One paragraph]

## Problem Statement
### Reported Issue
### Required Configuration
### Current Documentation State

## Solution Analysis
### Current Documentation Strengths
### Gaps Identified

## Recommended Solution
### Approach
### Proposed Changes

## Implementation Details
### Files to Modify
### Change Summary
### Validation Steps

## Impact Assessment
### Customer Impact
### Documentation Impact
### Risk Assessment

## Success Criteria
✅ [Criteria]

## Next Steps
1. [Steps]

## Appendix: Full Updated File Content
[If extensive]
```

## Related Resources

- `.claude/plugins/project-cqa/` - CQA compliance checks
- `.github/pull_request_template.md` - PR requirements
- JIRA: https://issues.redhat.com/

## Notes

- This is a manual workflow, not an automated skill
- Claude will follow these steps when you request a bug analysis
- Reports are saved to `/Users/gforde/my-rhdh-fixes/` for easy access
- Can be rerun if ticket changes
