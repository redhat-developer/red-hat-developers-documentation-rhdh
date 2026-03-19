# Red Hat Developer Hub Documentation

## CQA Compliance

When editing `.adoc` files, ALWAYS run the relevant CQA scripts to validate and fix changes before considering the task done. Each CQA skill follows a 6-step workflow:

1. Report issues: `./build/scripts/cqa-XX-*.sh titles/<title>/master.adoc`
2. Auto-fix: `./build/scripts/cqa-XX-*.sh --fix titles/<title>/master.adoc`
3. Re-run to verify
4. Attempt manual fixes for remaining issues
5. Re-run to verify
6. If issues remain, report as failed and list remaining issues

Key scripts:
- **CQA 1** (DITA Vale): `./build/scripts/cqa-01-asciidoctor-dita-vale.sh`
- **CQA 2** (Assembly structure): `./build/scripts/cqa-02-assembly-structure.sh`
- **CQA 3** (Modularization): `./build/scripts/cqa-03-content-is-modularized.sh`

For full CQA workflow, load `.claude/skills/cqa-master-workflow.md`. Individual skill files are in `.claude/skills/cqa-*.md`.
