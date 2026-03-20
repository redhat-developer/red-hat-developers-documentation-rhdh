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

Output markers: `[AUTOFIX]` (auto-fixable), `[FIXED]` (applied), `[MANUAL]` (needs human), `[-> CQA #NN]` (delegated).

For full CQA workflow, load `.claude/skills/cqa-main-workflow.md`. Individual skill files are in `.claude/skills/cqa-*.md`.
