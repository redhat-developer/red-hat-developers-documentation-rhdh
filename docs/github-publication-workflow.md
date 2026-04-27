# GitHub Publication Workflow Architecture

## Overview

The RHDH documentation project uses GitHub Actions to build AsciiDoc documentation and deploy HTML previews to GitHub Pages via the `gh-pages` branch. Two workflows handle this:

- **`build-asciidoc.yml`** -- triggered on branch pushes, builds and deploys production documentation.
- **`pr.yml`** -- triggered on pull requests, builds preview HTML and posts a PR comment with a preview link and CQA checklist.

Both workflows produce HTML output under `titles-generated/<branch>/`, then push the result to the `gh-pages` branch using `deploy-gh-pages.sh`.

## Triggers and Branch Matrix

| Workflow | Event | Branches | Build Script |
|---|---|---|---|
| `build-asciidoc.yml` | `push` | `main`, `release-1.**`, `rhdh-1.**`, `1.**.x` | `build-orchestrator.js --no-cqa` |
| `pr.yml` | `pull_request_target` | `main`, `release-1.**`, `release-2.**` | release-1.9+/main: `build-orchestrator.js`; release-1.8: `build-ccutil.sh` (base branch scripts) |

The `build-asciidoc.yml` workflow calls `build-orchestrator.js --no-cqa` (CQA results aren't surfaced in branch builds, only in PR comments). The `pr.yml` workflow detects whether `build-orchestrator.js` exists on the base branch and uses it when available (release-1.9+, main), falling back to `build-ccutil.sh` on older branches (release-1.8). The orchestrator wraps ccutil with parallel execution, lychee link validation, CQA assessment, and JSON reporting.

## Security Model

The `pr.yml` workflow uses `pull_request_target` instead of `pull_request` so it can access repository secrets (needed for `RHDH_BOT_TOKEN` to push to `gh-pages` and post PR comments). This event runs workflow code from the base branch, not the PR, which avoids exfiltration of secrets from untrusted PRs.

### Two-checkout pattern

To separate trusted code from untrusted content:

1. **Trusted checkout** -- checks out `build/scripts` from the base branch (`sparse-checkout: build/scripts`) into `trusted-scripts/`.
2. **Content checkout** -- checks out the full PR head into `pr-content/`.
3. **Merge** -- the workflow replaces `pr-content/build/scripts` with `trusted-scripts/build/scripts` via `rsync`, then runs the build from `pr-content/`.

Build scripts are always sourced from the base branch, never from the PR. This prevents a malicious PR from modifying build scripts to exfiltrate secrets.

### Authorization gate

The workflow enforces team-based authorization before running the build:

1. `check-commit-author` -- uses a GitHub App token to check if the PR author is a member of the `rhdh` team in the `redhat-developer` organization.
2. `authorize` -- selects the `internal` or `external` environment:
   - **Internal**: PR author is in the `rhdh` team, or the PR is from the same repository (not a fork). Runs immediately.
   - **External**: fork PRs from non-team members. The `external` environment requires manual approval from the `rhdh-content` team before the build proceeds.
3. `adoc_build` -- depends on `authorize`, so it only runs after the gate passes.

## Build Pipeline

### build-orchestrator.js

The orchestrator replaces the sequential `build-ccutil.sh` with parallel title builds, structured error reporting, and a JSON report.

**Phases:**

1. **Title discovery** -- scans `titles/` for directories containing `master.adoc`, excluding `rhdh-plugins-reference`.
2. **Parallel builds** -- runs `podman run ... ccutil compile` for each title, limited by a semaphore (`--jobs`, defaults to CPU count). Each title produces HTML under `titles-generated/<branch>/<title>/`.
3. **Image copy** -- parses each generated `index.html` to find image references and copies them into the output directory.
4. **Branch index** -- generates `titles-generated/<branch>/index.html` listing all successfully built titles, with an optional release notes link.
5. **Lychee link validation** -- runs `lychee` against `titles-generated/` with cross-title link remapping (rewrites `docs.redhat.com` links to local file paths). Broken links are traced back to `.adoc` source files via `grep`.
6. **Preliminary report** -- writes `build-report.json` with lychee results and CQA status "pending". This allows CQA-14 to read lychee results without triggering a rebuild.
7. **CQA assessment** -- sets `CQA_RUNNING=1` in `process.env`, then runs `node build/scripts/cqa/index.js --all`. The env var propagates to CQA-14, which skips its internal orchestrator call and reads the preliminary report instead.
8. **Final report** -- overwrites `build-report.json` with completed CQA results.

**Error classification:** the orchestrator loads `build/scripts/error-patterns.json`, which maps regex patterns to structured error messages with `cause` and `fix` fields. These appear in the JSON report and PR comment.

**CQA-14 recursion guard:** CQA-14 (lychee link validation check) can trigger the orchestrator internally. To prevent infinite recursion, the orchestrator sets `CQA_RUNNING=1` when invoking CQA, so CQA-14 reads existing lychee results from the report instead of triggering a full rebuild.

**CLI usage:**

```bash
node build/scripts/build-orchestrator.js -b <branch>
node build/scripts/build-orchestrator.js -b pr-123 --verbose
node build/scripts/build-orchestrator.js -b main --jobs 4
node build/scripts/build-orchestrator.js -b main --no-cqa --no-lychee
```

The `-b` flag determines the output directory name under `titles-generated/`. `--no-cqa` and `--no-lychee` skip CQA and lychee respectively (used by `build-asciidoc.yml` where CQA results aren't surfaced). The orchestrator exits with code 1 if any enabled phase fails.

## Deploy Pipeline

### deploy-gh-pages.sh

Handles deployment of built content to the `gh-pages` branch, including cleanup and index regeneration in a single commit.

**Sequence:**

1. Detect the branch directory from `<publish_dir>` (single top-level directory, e.g., `main/`, `pr-123/`).
2. Create a temporary git repo with `github-actions[bot]` identity.
3. Fetch `gh-pages` (shallow, depth=1).
4. Copy `<publish_dir>` contents into the working tree.
5. For branch deploys: run cleanup (see Cleanup section below).
6. Regenerate indexes from current directories on `gh-pages` (see below).
7. Stage all changes (content + cleanup deletions + indexes), commit, and push.

**Index regeneration:** rebuilds HTML indexes from directories present on `gh-pages`:
- `index.html` -- lists all non-`pr-*` directories with optional release notes links (for `release-1.9+` and `main`).
- `pulls.html` -- lists all `pr-*` directories.

Branch deploys regenerate both indexes. PR deploys regenerate `pulls.html` only.

**Retry logic:** on push rejection, the script attempts `git pull --rebase`. If rebase succeeds, it pushes immediately. If rebase conflicts, it aborts, re-fetches `gh-pages`, re-applies content and cleanup, and retries. Maximum 3 attempts.

**Invocation:**

```bash
# Branch deploy
bash build/scripts/deploy-gh-pages.sh ./titles-generated --message "Deploy main"

# PR deploy (from pr.yml, using trusted scripts)
bash trusted-scripts/build/scripts/deploy-gh-pages.sh ./pr-content/titles-generated --message "Deploy PR 123 preview"
```

### Branch vs PR deploys

- **Branch deploys** (`build-asciidoc.yml`): deploy content + cleanup stale PRs/branches + regenerate both `index.html` and `pulls.html` → single commit.
- **PR deploys** (`pr.yml`): deploy content under `pr-<N>/` + regenerate `pulls.html` only → single commit. No cleanup runs.

## gh-pages Branch Structure

```
gh-pages/
|-- index.html          # Links to branch builds + release notes
|-- pulls.html          # Links to PR preview builds
|-- main/               # Main branch build
|   |-- index.html      # Per-branch title listing
|   +-- <title>/        # Individual title HTML
|       +-- index.html
|-- release-1.9/        # Release branch build
|-- release-1.8/        # Legacy release branch
+-- pr-123/             # PR preview build
    |-- index.html
    +-- <title>/
```

**Preview URL pattern:**

```
https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/<branch-or-pr>/
```

For PR previews:

```
https://redhat-developer.github.io/red-hat-developers-documentation-rhdh/pr-<N>/
```

## PR Preview Lifecycle

1. PR opened, synchronized, reopened, or marked ready for review -- `pr.yml` triggers.
2. Authorization gate checks team membership. Fork PRs from non-team members require manual approval via the `external` environment.
3. Trusted build scripts are checked out from the base branch. PR content is checked out separately.
4. Build scripts from the base replace `pr-content/build/scripts`. The orchestrator (or `build-ccutil.sh` on older branches) runs with `-b pr-<N>`.
5. If HTML was successfully generated (checked via `build-report.json`), `deploy-gh-pages.sh` pushes the output to `gh-pages` under `pr-<N>/`.
6. A consolidated PR comment is posted (or updated) with:
   - Build status (passed/failed) with title counts and duration.
   - Preview link (marked stale if title build failed).
   - Build error details with classified causes and fixes.
   - CQA checklist with pass/fail counts (when available).
   - Link to full CI logs.
7. Old standalone CQA comments (from the previous two-comment format) are cleaned up.
8. When the PR is merged or closed, the next branch deploy cleans up the `pr-<N>/` directory from `gh-pages`.

**Concurrency:** the workflow uses `concurrency` groups keyed on the PR number. If a new push arrives while a build is in progress, the in-progress run is cancelled.

## Cleanup

Cleanup is integrated into `deploy-gh-pages.sh` and runs during branch deploys only, not during PR deploys. It executes before index regeneration so indexes reflect the cleaned-up state. Cleanup, content deployment, and index regeneration are committed together in a single commit.

### PR cleanup

1. List `pr-*` directories on `gh-pages`.
2. For each, query the GitHub API (`GET /repos/{owner}/{repo}/pulls/{number}`).
3. If the PR is merged or closed, remove the `pr-<N>/` directory.

### Branch cleanup

1. List non-`pr-*` directories on `gh-pages`.
2. For each, run `git ls-remote --heads origin <branch>`.
3. If the remote branch no longer exists, remove the directory. This cleans up directories for deleted branches (e.g., `release-1.9-post-cqa`).

## Local Development

### Build all titles

```bash
node build/scripts/build-orchestrator.js -b main
```

Requires Podman. Builds all titles in parallel, runs lychee link validation, runs CQA, and writes `build-report.json`.

### Run CQA standalone

```bash
# All checks on a single title
node build/scripts/cqa/index.js titles/<title>/master.adoc

# Auto-fix issues
node build/scripts/cqa/index.js --fix titles/<title>/master.adoc

# Run a specific check
node build/scripts/cqa/index.js --check NN titles/<title>/master.adoc

# All checks on all titles
node build/scripts/cqa/index.js --all
```

CQA-14 (lychee link validation) in standalone mode runs the orchestrator internally. It sets `CQA_RUNNING=1` to prevent recursion -- the orchestrator skips CQA when this variable is set, so CQA-14 reads the lychee results from the existing `build-report.json` instead of triggering another full build.

### Legacy build

```bash
build/scripts/build-ccutil.sh -b <branch>
```

Used on `release-1.8` and as a fallback on branches where `build-orchestrator.js` does not exist. Runs title builds sequentially without lychee or CQA.
