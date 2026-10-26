#!/usr/bin/env python3
"""Update a branch's per-comparison dynamic plugin changelog files."""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

from changelog_paths import INDEX_NAME, MODULE_DIR, REPORT_NAME, TITLE_PATHS, require_document_path


SUPPORTED_INDEX = "quay.io/rhdh/plugin-catalog-index"
GENERATOR = Path(__file__).with_name("generate-dynamic-plugin-changelog.py")
PATCH = re.compile(r"(\d+)\.(\d+)\.(\d+)$")
RELEASE_BRANCH = re.compile(r"release-(\d+)\.(\d+)$")
INCLUDE = f"include::{(MODULE_DIR / INDEX_NAME).as_posix()}[leveloffset=+1]"


class ChangelogError(Exception):
    """The published indexes cannot produce a complete changelog."""


def release_line(version: str) -> str:
    """Return the major.minor line of an RHDH patch version."""

    match = PATCH.fullmatch(version)
    if not match:
        raise ChangelogError(f"Expected an RHDH patch version, got {version}")
    return f"{match[1]}.{match[2]}"


def patch_tags(tags: list[str], line: str) -> list[str]:
    """Select published patch tags for a line in numeric order."""

    matches = []
    for tag in tags:
        match = PATCH.fullmatch(tag)
        if match and f"{match[1]}.{match[2]}" == line:
            matches.append((int(match[3]), tag))
    # Numeric ordering matters: 1.10.10 must follow 1.10.9. Build tags such
    # as 2.1-113 and moving tags such as 2.1 are deliberately excluded.
    return [tag for _, tag in sorted(matches)]


def output_path(path: Path) -> Path:
    """Keep the index and its generated comparison files in the docs module."""

    return require_document_path("--output", path, MODULE_DIR, INDEX_NAME)


def comparisons(branch: str, tags: list[str], next_version: str = "") -> tuple[str, list[tuple[str, str]]]:
    """Plan the main baseline or adjacent patch comparisons for a release branch."""

    if branch == "main":
        # The supported :next image declares which release main is preparing.
        # Start its changelog at the latest published patch of the preceding
        # release, for example 2.1.0 -> 2.2.0.
        line = release_line(next_version)
        current = tuple(map(int, line.split(".")))
        previous_lines = set()
        for tag in tags:
            match = PATCH.fullmatch(tag)
            if match:
                candidate = (int(match[1]), int(match[2]))
                if candidate < current:
                    previous_lines.add(candidate)
        if not previous_lines:
            raise ChangelogError(f"No published release precedes RHDH {line}")
        # Example: :next=2.2.0 and tags include 1.10.7, 2.1.0, 2.1.3,
        # 2.2.0, 2.2.1. previous_lines={(1, 10), (2, 1)}; its maximum
        # becomes "2.1", the newest published line below "2.2".
        previous = ".".join(map(str, max(previous_lines)))
        # patch_tags(..., "2.1") -> ["2.1.0", "2.1.3"]. Its last tag,
        # "2.1.3", is the baseline: the image to compare against 2.2.
        baseline = patch_tags(tags, previous)[-1]
        # patch_tags(..., "2.2") -> ["2.2.0", "2.2.1"]. The resulting
        # comparisons are 2.1.3 -> 2.2.0, then 2.2.0 -> 2.2.1.
        current_tags = patch_tags(tags, line)
        # Before the first X.Y.0 patch tag exists, :next is the only current
        # image. Once patch tags exist, compare each adjacent pair as well.
        endpoints = current_tags or ["next"]
        pairs = [(baseline, endpoints[0])]
        pairs.extend(zip(endpoints, endpoints[1:]))
        return line, pairs

    match = RELEASE_BRANCH.fullmatch(branch)
    if not match:
        raise ChangelogError(f"Expected main or release-X.Y, got {branch}")
    line = f"{match[1]}.{match[2]}"
    published = patch_tags(tags, line)
    # A release branch contains only its own .z transitions: X.Y.0 -> X.Y.1,
    # X.Y.1 -> X.Y.2, and so on. With only .0 there is no pair to compare.
    return line, list(zip(published, published[1:]))


def published_tags() -> list[str]:
    """List the supported catalog's published patch tags anonymously."""

    result = subprocess.run(
        ["skopeo", "list-tags", "--no-creds", f"docker://{SUPPORTED_INDEX}"],
        check=True, capture_output=True, text=True,
    )
    tags = json.loads(result.stdout).get("Tags")
    if not isinstance(tags, list) or not all(isinstance(tag, str) for tag in tags):
        raise ChangelogError(f"Cannot read tags from {SUPPORTED_INDEX}")
    return tags


def main_version() -> str:
    """Read main's current RHDH patch version from the moving :next image."""

    result = subprocess.run(
        ["skopeo", "inspect", "--no-creds", "--no-tags", f"docker://{SUPPORTED_INDEX}:next"],
        check=True, capture_output=True, text=True,
    )
    version = (json.loads(result.stdout).get("Labels") or {}).get("rhdh.version", "")
    release_line(version)
    return version


def generate_section(before: str, after: str, next_version: str = "") -> str:
    """Reuse the single-pair generator for one comparison file."""

    # The generator resolves the community image for each supported endpoint,
    # preferring the exact overlays commit and labelling any fallback.
    result = subprocess.run(
        [
            sys.executable, str(GENERATOR),
            "--from-release", before,
            "--from-supported", f"{SUPPORTED_INDEX}:{before}",
            "--to-release", next_version if after == "next" else after,
            "--to-supported", f"{SUPPORTED_INDEX}:{after}",
            "--section",
        ],
        capture_output=True, text=True,
    )
    if result.returncode:
        raise ChangelogError(f"Cannot compare {before} to {after}: {result.stderr.strip()}")
    return result.stdout.strip()


def comparison_path(output: Path, before: str, after: str, next_version: str = "") -> Path:
    """Name a comparison file by the supported patch versions it describes."""

    # Tags and :next's declared version were validated as patch versions;
    # output_path() fixed the stem and directory. :next itself is moving, so
    # use its declared patch version in the filename.
    endpoint = next_version if after == "next" else after
    name = f"{output.stem}-{before.replace('.', '-')}-to-{endpoint.replace('.', '-')}.adoc"
    return require_document_path("comparison report", output.with_name(name), MODULE_DIR, REPORT_NAME)


def render(branch: str, line: str, reports: list[Path]) -> str:
    """Build the small reference page that includes each comparison file."""

    lines = [
        ":_mod-docs-content-type: REFERENCE", "",
        "// Generated by update-dynamic-plugin-changelog.py; do not edit manually.", "",
        '[id="dynamic-plugin-changes_{context}"]',
        f"= Dynamic plugin changes for RHDH {line}", "",
        "These comparisons cover packages in the supported default plugin configuration and the community catalog. "
        "Each comparison lists the immutable catalog image digests and identifies any community-image fallback. "
        "A fallback is the newest community build for the same release line and Backstage version. "
        "`Not listed` means a package is absent from the supported default configuration. "
        "`Removed` means a package is absent from both catalogs in the later release. "
        "A move between catalogs appears under `Updated`; a rename appears as a removal and an addition. "
        "Variables are names found in the published configuration examples. "
        "An em dash means no change or no variables.", "",
    ]
    if branch == "main":
        lines += ["The first comparison starts with the latest patch of the previous RHDH release.", ""]
    if reports:
        # Includes are relative to this reference page and ordered by release.
        lines.extend(f"include::{report.name}[]" for report in reports)
    else:
        # No pair exists yet; this differs from a completed comparison in
        # which the two images contain no plugin changes.
        lines.append(f"No patch updates have been published for RHDH {line}.")
    return "\n".join(lines) + "\n"


def include_in_titles() -> None:
    """Publish the generated reference in whichever documentation titles exist."""

    titles = []
    for relative in TITLE_PATHS:
        # Validate all existing titles before writing either one.
        path = require_document_path("title path", relative, relative.parent, relative.name)
        if not path.exists():
            continue
        if not path.is_file():
            raise ChangelogError(f"Title is not a file: {path}")
        titles.append(path)
    if not titles:
        raise ChangelogError("No dynamic plugin reference title exists in this checkout")

    for path in titles:
        content = path.read_text(encoding="utf-8")
        if INCLUDE not in content:
            path.write_text(content.rstrip() + f"\n\n{INCLUDE}\n", encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--branch", required=True, help="Documentation branch: main or release-X.Y")
    parser.add_argument(
        "--output", required=True, type=Path,
        help=f"AsciiDoc index at {MODULE_DIR / INDEX_NAME}; comparisons are saved beside it",
    )
    parser.add_argument("--update-includes", action="store_true", help="Include the report in available titles")
    args = parser.parse_args()
    try:
        args.output = output_path(args.output)
        tags = published_tags()
        next_version = main_version() if args.branch == "main" else ""
        line, pairs = comparisons(args.branch, tags, next_version)
        reports = [comparison_path(args.output, before, after, next_version) for before, after in pairs]
        # Build missing comparisons and refresh only the newest one. Earlier
        # files retain the digests recorded when they were last current.
        pending = {}
        for index, (before, after) in enumerate(pairs):
            report = reports[index]
            if report.exists() and index != len(pairs) - 1:
                continue
            pending[report] = generate_section(before, after, next_version)
        # Finish all registry reads before changing the documentation files.
        for report, section in pending.items():
            report.write_text(section + "\n", encoding="utf-8")
        args.output.write_text(render(args.branch, line, reports), encoding="utf-8")
        if args.update_includes:
            include_in_titles()
        print(f"Wrote {args.output} with {len(reports)} comparison(s); refreshed {len(pending)} file(s)")
    except (ChangelogError, OSError, ValueError, subprocess.CalledProcessError) as error:
        detail = error.stderr.strip() if isinstance(error, subprocess.CalledProcessError) and error.stderr else str(error)
        print(f"[ERROR] {detail}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
