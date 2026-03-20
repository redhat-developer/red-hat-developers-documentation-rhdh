# Red Hat Developer Hub Documentation

## CQA Compliance

When editing `.adoc` files, ALWAYS run the relevant CQA scripts to validate and fix changes before considering the task done. Run all 17 checks at once with `build/scripts/cqa.sh`, or run individual scripts. All share a common interface via `build/scripts/cqa-lib.sh`:

```bash
# Report issues for a title
./build/scripts/cqa.sh titles/<title>/master.adoc

# Auto-fix issues
./build/scripts/cqa.sh --fix titles/<title>/master.adoc

# Run across all titles
./build/scripts/cqa.sh --all

# Auto-fix across all titles
./build/scripts/cqa.sh --fix --all
```

Output markers: `[AUTOFIX]` (auto-fixable), `[FIXED]` (applied), `[MANUAL]` (needs human), `[-> CQA #NN AUTOFIX]` / `[-> CQA #NN MANUAL]` (delegated).

For full CQA workflow, load `.claude/skills/cqa-main-workflow.md`. Individual skill files are in `.claude/skills/cqa-*.md`.

## GitHub Workflows (`.github/workflows/`)

| Workflow | Trigger | Purpose |
|---|---|---|
| `content-quality-assessment.yml` | PR (`.adoc`, `build/scripts/`) | Runs `cqa.sh --all` on entire repo. Posts checklist as PR comment, uploads SARIF to Code Scanning. Scripts sourced from `main` branch (not base) for backport compatibility. |
| `build-asciidoc.yml` | Push to main/release | Builds AsciiDoc docs and deploys to GitHub Pages. Cleans up merged PR preview branches. |
| `pr.yml` | PR | Builds HTML preview, deploys to `gh-pages`, posts preview URL as PR comment. |
| `style-guide.yml` | PR | Runs Vale linter on `assemblies/` for style guide compliance. |
| `shellcheck.yml` | PR (`*.sh`) | Runs shellcheck on changed shell scripts via reviewdog. |
| `generate-supported-plugins-pr.yml` | Manual dispatch | Updates Dynamic Plugins tables and creates a PR. |

**Security:** `content-quality-assessment`, `pr`, and `shellcheck` use `pull_request_target` with an authorization gate — fork PRs from non-team members require manual approval via the `external` environment.
