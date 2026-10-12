# Documentation Tools Plugin

Project-specific documentation workflow and analysis tools for Red Hat Developer Hub.

## Overview

This plugin provides skills for automating documentation workflows, bug analysis, and quality assessment tasks specific to the RHDH documentation repository.

## Available Skills

### bug-analysis

**Usage:** `/bug-analysis <JIRA-ID>`

Generate a comprehensive documentation bug analysis report from a JIRA ticket.

**Features:**
- Fetches JIRA ticket details automatically
- Identifies affected documentation files
- Analyzes current vs. required state
- Generates structured markdown report
- Provides implementation recommendations
- Includes impact assessment and success criteria

**Output:** Markdown report at `/Users/gforde/my-rhdh-fixes/<JIRA-ID>-documentation-fix.md`

**Example:**
```
/bug-analysis RHIDP-15155
```

This will analyze ticket RHIDP-15155 and generate a complete analysis report.

## Plugin Structure

```
.claude/plugins/docs-tools/
├── plugin.json              # Plugin metadata
├── README.md                # This file
└── skills/
    └── bug-analysis/
        └── SKILL.md         # Bug analysis skill definition
```

## Installation

This plugin is project-specific and already included in the repository. No additional installation is required.

## Usage

Skills from this plugin can be invoked using the `/` prefix:

```
/bug-analysis RHIDP-12345
```

Or by using the Skill tool in Claude Code.

## Development

To add new skills to this plugin:

1. Create a new directory under `skills/`
2. Add a `SKILL.md` file with frontmatter:
   ```markdown
   ---
   name: skill-name
   description: Brief description
   ---

   # Skill content...
   ```
3. Document the workflow, prerequisites, and expected outputs

## Related Plugins

- **project-cqa:** Content Quality Assessment tools
- **Global docs-tools:** System-wide documentation skills (jira-reader, vale-tools, etc.)

## Support

For issues or feature requests related to this plugin, contact the RHDH documentation team.
