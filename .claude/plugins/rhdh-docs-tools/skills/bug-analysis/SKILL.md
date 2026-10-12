---
name: bug-analysis
description: Generate a comprehensive documentation bug analysis report from a JIRA ticket. Analyzes current documentation, identifies gaps, and provides implementation recommendations.
---

# Documentation Bug Analysis Report Generator

Generate a structured markdown report for documentation bugs that includes problem statement, solution analysis, implementation recommendations, and impact assessment.

## Overview

This skill automates the creation of standardized bug analysis reports for documentation issues. It fetches JIRA ticket details, analyzes affected documentation files, and produces a comprehensive report ready for review and implementation.

## When to Use

- Analyzing documentation bugs from JIRA tickets
- Preparing implementation plans for doc fixes
- Generating evidence-based change proposals
- Creating downloadable reports for stakeholder review

## Prerequisites

Before running this skill, ensure:
- You have a JIRA ticket ID (e.g., RHIDP-15155)
- The ticket describes a documentation issue
- You have access to the JIRA instance (Red Hat Issue Tracker)

## Workflow

### 1. Gather JIRA Information

Ask the user for:
- JIRA ticket ID (required)
- Any additional context about the issue (optional)

### 2. Fetch JIRA Ticket Details

Use the JIRA reader to fetch issue information:

```bash
# The jira-reader skill or tool will be used internally
# No manual execution needed
```

Extract from JIRA:
- Summary and description
- Reporter and assignee
- Priority and status
- Comments with technical details
- Affected versions/components

### 3. Identify Affected Documentation Files

Based on the JIRA description and context:

1. Search for relevant text in .adoc files:
   ```
   Use Grep to find content mentioned in the JIRA ticket
   Pattern: search for key phrases, section titles, or code examples
   ```

2. Locate the affected files:
   - Primary module files (modules/*)
   - Assembly files that include the modules (assemblies/*)
   - Related reference or procedure files

3. Read the current content:
   ```
   Use Read to examine the current state of each file
   ```

### 4. Analyze the Problem

Document the following:

**Problem Statement:**
- What is the reported issue?
- Why is it a problem for users?
- What is the current documentation state?
- What configuration/code is mentioned in the bug?

**Current Documentation Strengths:**
- What is already correct?
- What examples are already present?
- What structure is in place?

**Gaps Identified:**
- Missing warnings or context
- Unclear instructions
- Ambiguous examples
- Missing cross-references
- Incomplete procedures

### 5. Develop Solution Recommendations

**Solution Approach:**
- Should we enhance existing content or create new content?
- What specific changes are needed?
- Why is this the best approach?

**Implementation Details:**
- Specific files to modify
- Line number ranges for changes
- Exact wording for new content (using proper AsciiDoc formatting)
- Callouts, admonitions, or code examples to add

**Validation:**
- How to verify the fix works?
- What CQA checks should pass?
- What build/preview steps are needed?

### 6. Assess Impact

**Customer Impact:**
- Severity (High/Medium/Low)
- Frequency (how often users hit this)
- Affected user base
- Current workarounds

**Documentation Impact:**
- Complexity of changes
- Maintenance burden
- Localization requirements
- Backward compatibility

**Risk Assessment:**
- What could go wrong?
- Can changes be cherry-picked?
- Are there related dependencies?

### 7. Generate the Report

Create a markdown file at `/Users/gforde/my-rhdh-fixes/<jira-id>-documentation-fix.md` with:

```markdown
# Documentation Fix: <Brief Title>

**Document ID:** <JIRA-ID>
**Date:** <Current Date>
**Component:** Red Hat Developer Hub Documentation
**Affected File(s):** <file paths>

---

## Executive Summary
[One paragraph overview]

---

## Problem Statement

### Reported Issue
[Full description from JIRA]

### Required Configuration
[Code/config from bug report]

### Current Documentation State
[What currently exists, with line number references]

---

## Solution Analysis

### Current Documentation Strengths
[What's already correct]

### Gaps Identified
1. [Gap 1]
2. [Gap 2]
...

---

## Recommended Solution

### Approach
[Why this approach vs alternatives]

### Proposed Changes

#### 1. [Change Type - e.g., "Add IMPORTANT Admonition"]

**File:** `path/to/file.adoc`
**Location:** After line X or before section Y

[Show exact AsciiDoc markup]

[Explain rationale]

#### 2. [Next Change]
...

---

## Implementation Details

### Files to Modify
[Table of files, change types, descriptions]

### Change Summary
[Line-by-line breakdown]

### Validation Steps
[How to verify, CQA commands, build steps]

---

## Impact Assessment

### Customer Impact
- **Severity:** High/Medium/Low
- **Frequency:** [How often]
- **Affected Users:** [Who]
- **Current Workarounds:** [If any]

### Documentation Impact
- **Complexity:** High/Medium/Low
- **Maintenance:** [Ongoing burden]
- **Localization:** [Translation needs]
- **Backward Compatibility:** [Any concerns]

### Risk Assessment
[What could go wrong, mitigation strategies]

---

## Success Criteria
✅ [Criterion 1]
✅ [Criterion 2]
...

---

## Next Steps
1. [Step 1]
2. [Step 2]
...

---

## Appendix: Full Updated File Content
[Complete proposed file if changes are extensive]

---

**End of Report**
```

### 8. Deliver the Report

Inform the user:
- Report location: `/Users/gforde/my-rhdh-fixes/<jira-id>-documentation-fix.md`
- Summary of findings
- Recommended next actions

## Output Format

The skill produces:
- **Primary Output:** Markdown report at `/Users/gforde/my-rhdh-fixes/<jira-id>-documentation-fix.md`
- **Console Summary:** Key findings and recommendations
- **Action Items:** Clear next steps for implementation

## Example Invocation

When the user provides a JIRA ID like:
```
/bug-analysis RHIDP-15155
```

The skill will:
1. Fetch JIRA ticket RHIDP-15155
2. Extract problem description
3. Search for affected .adoc files
4. Analyze current vs. required state
5. Generate `/tmp/RHIDP-15155-documentation-fix.md`
6. Provide summary to user

## Best Practices

**Do:**
- ✅ Read all affected files before proposing changes
- ✅ Preserve existing correct examples
- ✅ Use proper AsciiDoc formatting (admonitions, callouts, attributes)
- ✅ Reference line numbers for precision
- ✅ Consider CQA compliance in recommendations
- ✅ Assess impact on multiple audiences (users, maintainers, translators)

**Don't:**
- ❌ Replace working examples with unverified code from bug reports
- ❌ Make assumptions without reading current docs
- ❌ Propose changes without explaining rationale
- ❌ Ignore related documentation that might need updates
- ❌ Skip impact assessment

## Quality Checks

Before completing the report, verify:
- [ ] JIRA ticket fully analyzed
- [ ] All affected files identified and read
- [ ] Problem clearly articulated
- [ ] Solution justified with evidence
- [ ] Implementation details are actionable
- [ ] Impact assessment is realistic
- [ ] Success criteria are measurable
- [ ] Report follows template structure

## Notes

- This skill does NOT make actual code changes - it only generates analysis reports
- User must review and approve recommendations before implementation
- Report is saved to `/tmp/` for easy download
- Can be rerun with updated JIRA context if ticket changes
- Integrates with existing CQA workflow for validation

## Related Skills

- `jira-reader` - Fetch JIRA ticket details
- `cqa-main-workflow` - Run CQA checks on modified files
- `docs-review-style` - Validate style guide compliance

## Troubleshooting

**JIRA ticket not found:**
- Verify ticket ID format (e.g., RHIDP-15155)
- Check JIRA access/authentication
- Confirm ticket exists on Red Hat Issue Tracker

**Cannot find affected files:**
- Ask user for file paths or keywords
- Use broader search terms
- Check if content is in modules/ vs assemblies/

**Incomplete analysis:**
- Request more context from JIRA comments
- Ask user for additional background
- Review related tickets in JIRA
