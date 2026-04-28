# Red Hat Developer Hub Documentation

## CQA Compliance

When editing `.adoc` files, ALWAYS run the relevant CQA checks to validate and fix changes before considering the task done:

```bash
# Report issues for a title
node build/scripts/cqa/index.js titles/<title>/master.adoc

# Auto-fix issues
node build/scripts/cqa/index.js --fix titles/<title>/master.adoc

# Run a single check
node build/scripts/cqa/index.js --check NN titles/<title>/master.adoc
```

Output markers: `[AUTOFIX]` (auto-fixable), `[FIXED]` (applied), `[MANUAL]` (needs human), `[-> CQA-NN AUTOFIX]` / `[-> CQA-NN MANUAL]` (delegated).

The `project-cqa` plugin (`.claude/plugins/project-cqa/`) provides skills for the full CQA workflow and individual checks. The CQA spec is at `.claude/plugins/project-cqa/resources/cqa-spec.md`.

## Pull Requests

When creating PRs, follow `.github/pull_request_template.md`:

- **Title format:** `[RHIDP#<jira-id>]: <short description>` (no `GH#` or `BZ#` prefix needed unless applicable)
- **Body:** Must include the `IMPORTANT: Do Not Merge` banner, `Version(s):`, `Issue:` (Jira link), and `Preview:` (preview URL or N/A)
- **Target branch:** Open PRs against `main` and cherrypick to released branches as needed
- **Never use `#N` in PR title or body** — GitHub auto-links it to issues/PRs. Use dash notation (e.g., `CQA-05`) instead.

## GitHub Workflows (`.github/workflows/`)

| Workflow | Trigger | Purpose |
|---|---|---|
| `build-asciidoc.yml` | Push to main/release | Builds AsciiDoc docs and deploys to GitHub Pages (deploy includes cleanup of merged/closed PRs and deleted branches). |
| `pr.yml` | PR | Builds HTML preview, runs CQA checks, deploys to `gh-pages`, posts preview URL and CQA checklist as PR comments. Build scripts sourced from base branch. |
| `style-guide.yml` | PR | Runs Vale linter on `assemblies/` for style guide compliance. |
| `shellcheck.yml` | PR (`*.sh`) | Runs shellcheck on changed shell scripts via reviewdog. |
| `generate-supported-plugins-pr.yml` | Weekly schedule (Monday 04:00 UTC) and manual dispatch | Updates Dynamic Plugins tables for configured branches and creates a PR. |

**Security:** `pr` and `shellcheck` use `pull_request_target` with an authorization gate — fork PRs from non-team members require manual approval via the `external` environment.
