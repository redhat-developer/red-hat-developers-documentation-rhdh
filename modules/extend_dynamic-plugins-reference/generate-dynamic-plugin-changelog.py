#!/usr/bin/env python3
"""Compare two releases of the published supported and community catalogs.

Pin each image by digest, combine its package inventories by release, and
render the package changes and image provenance as AsciiDoc.
"""

import argparse
import json
import re
import subprocess
import sys
import tarfile
import tempfile
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

import yaml


PACKAGE_DIR = "catalog-entities/extensions/packages/"
BUILD_INFO_FILE = "build-info.json"
RHDH_VERSION_LABEL = "rhdh.version"
VARIABLE = re.compile(r"\$\{([^}]+)\}")
DIGEST = re.compile(r"sha256:[0-9a-f]{64}$")
VERSION = re.compile(r"(\d+)\.(\d+)(?:\.(\d+))?$")
SUPPORT = {
    "generally-available": "Generally Available",
    "tech-preview": "Red Hat Tech Preview",
    "community": "Community Support",
    "dev-preview": "Developer Preview",
}
# Keep this order aligned with plugin_state() and plugin_changes().
DETAIL_FIELDS = ("Version", "Support", "Default", "Catalog", "Lifecycle", "Variables")
DETAIL_WIDTHS = ("1", "2", "1", "2", "1", "3")
EMPTY = "—"
SUPPORTED_INDEX = "quay.io/rhdh/plugin-catalog-index"
COMMUNITY_INDEX = "ghcr.io/redhat-developer/rhdh-plugin-export-overlays/plugin-catalog-index"
MODULE_DIR = Path("modules/extend_dynamic-plugins-reference")
REPORT_NAME = re.compile(
    r"ref-dynamic-plugin-changes-[0-9]+-[0-9]+(?:-[0-9]+)?-to-[0-9]+-[0-9]+(?:-[0-9]+)?\.adoc$"
)
OVERLAYS_REPO = "https://github.com/redhat-developer/rhdh-plugin-export-overlays"
OVERLAYS_SOURCE = re.compile(
    rf"{re.escape(OVERLAYS_REPO)}/tree/(main|release-\d+\.\d+) @ ([0-9a-f]{{8,40}})$"
)


class CatalogError(Exception):
    """A catalog image cannot be compared safely."""


@dataclass(frozen=True)
class Image:
    """An inspected image and the catalog files needed for the comparison."""

    reference: str
    repository: str
    digest: str
    files: dict[str, bytes]
    labels: dict[str, str]
    environment: tuple[str, ...]
    selection: str = "Specified image"

    @property
    def immutable_reference(self) -> str:
        return f"{self.repository}@{self.digest}"


@dataclass(frozen=True)
class Plugin:
    """The reportable state of one package in one release."""

    package: str
    version: str
    support: str
    lifecycle: str
    variables: frozenset[str]
    default: str | None
    catalogs: frozenset[str]


def required_file(files: dict[str, bytes], name: str) -> bytes:
    if name not in files:
        raise CatalogError(f"Catalog image is missing {name}")
    return files[name]


def output_path(path: Path) -> Path:
    """Allow report writes only to version-named files in the docs module."""

    module = Path.cwd().resolve() / MODULE_DIR
    expected = f"--output must be a version-named report under {MODULE_DIR} in this checkout"
    # A bad CLI path must not escape the docs module or overwrite its index.
    # Resolving ensures any symlinked parent still leads into this module.
    if ".." in path.parts or not REPORT_NAME.fullmatch(path.name):
        raise CatalogError(expected)
    if not module.is_dir() or module.resolve() != module or path.is_symlink():
        raise CatalogError(expected)
    resolved = path.resolve()
    if resolved.parent != module:
        raise CatalogError(expected)
    return resolved


def image_repository(reference: str) -> str:
    """Strip a tag or digest while keeping the registry and repository path."""

    reference = reference.removeprefix("docker://")
    if "@" in reference:
        return reference.split("@", 1)[0]
    last_colon = reference.rfind(":")
    return reference[:last_colon] if last_colon > reference.rfind("/") else reference


def archive_files(path: Path) -> dict[str, bytes]:
    """Read only the catalog files from a skopeo archive in layer order."""
    files: dict[str, bytes] = {}
    with tarfile.open(path) as archive:
        manifest_file = archive.extractfile("manifest.json")
        if manifest_file is None:
            raise CatalogError(f"Invalid image archive: {path}")
        manifest = json.load(manifest_file)
        # Later layers can replace files from earlier layers.
        for layer_name in manifest[0]["Layers"]:
            layer_file = archive.extractfile(layer_name)
            if layer_file is None:
                raise CatalogError(f"Missing image layer: {layer_name}")
            with tarfile.open(fileobj=layer_file, mode="r:*") as layer:
                for member in layer:
                    # Match ./index.json and /index.json as the same relative file.
                    # The normalized name is only a lookup key; no archive
                    # member is extracted to the filesystem. Ignore entries
                    # containing .. rather than treating them as catalog files.
                    name = member.name.removeprefix("./").lstrip("/")
                    if ".." in name.split("/"):
                        continue
                    if not member.isfile() or not (
                        name in {"index.json", "dynamic-plugins.default.yaml", BUILD_INFO_FILE}
                        or name.startswith(PACKAGE_DIR) and name.endswith(".yaml")
                    ):
                        continue
                    content = layer.extractfile(member)
                    if content is not None:
                        files[name] = content.read()
    return files


def inspect_image(reference: str) -> dict:
    """Read public image metadata without downloading its layers."""

    inspected = subprocess.run(
        ["skopeo", "inspect", "--no-creds", "--no-tags", f"docker://{reference}"],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(inspected.stdout)


def image_digest(metadata: dict, reference: str) -> str:
    """Require a usable immutable digest from registry metadata."""

    digest = metadata.get("Digest", "")
    if not DIGEST.fullmatch(digest):
        raise CatalogError(f"Invalid digest for {reference}: {digest}")
    return digest


def fetch_image(reference: str, selection: str = "Specified image") -> Image:
    """Read a public registry image, then extract files from its pinned digest."""

    reference = reference.removeprefix("docker://")
    repository = image_repository(reference)
    metadata = inspect_image(reference)
    digest = image_digest(metadata, reference)
    if "@" in reference and reference.rsplit("@", 1)[1] != digest:
        raise CatalogError(f"Digest changed while inspecting {reference}")
    # Copy by digest so a moving tag cannot change the content after inspection.
    with tempfile.TemporaryDirectory() as directory:
        archive = Path(directory) / "catalog.tar"
        subprocess.run(
            [
                "skopeo", "copy", "--src-no-creds",
                f"docker://{repository}@{digest}", f"docker-archive:{archive}",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        files = archive_files(archive)
    return Image(
        reference, repository, digest, files, metadata.get("Labels") or {},
        tuple(metadata.get("Env") or ()), selection,
    )


def release_minor(version: str) -> str:
    """Normalize either a minor or patch version to its major.minor line."""

    match = VERSION.fullmatch(version)
    if not match:
        raise CatalogError(f"Invalid RHDH version: {version}")
    return f"{match[1]}.{match[2]}"


def default_supported_reference(release: str) -> tuple[str, str]:
    """Select a requested patch, or the highest patch tag on the supported index."""

    minor = release_minor(release)
    if VERSION.fullmatch(release)[3] is not None:
        return f"{SUPPORTED_INDEX}:{release}", release

    listed = subprocess.run(
        ["skopeo", "list-tags", "--no-creds", f"docker://{SUPPORTED_INDEX}"],
        check=True,
        capture_output=True,
        text=True,
    )
    tags = json.loads(listed.stdout).get("Tags")
    if not isinstance(tags, list):
        raise CatalogError(f"Cannot read supported tags from {SUPPORTED_INDEX}")
    patches = []
    for tag in tags:
        if not isinstance(tag, str):
            continue
        # Ignore moving release-line tags and unrelated build tags.
        match = VERSION.fullmatch(tag)
        if match and match[3] is not None and release_minor(tag) == minor:
            patches.append((int(match[3]), tag))
    if not patches:
        raise CatalogError(f"No supported patch tags found for RHDH {release} in {SUPPORTED_INDEX}")
    # Sort numerically so, for example, .10 is newer than .9.
    tag = max(patches)[1]
    return f"{SUPPORTED_INDEX}:{tag}", tag


def supported_version(image: Image) -> str:
    """Read the RHDH version declared by a supported image."""

    version = image.labels.get(RHDH_VERSION_LABEL, "")
    if not VERSION.fullmatch(version):
        raise CatalogError(f"{image.reference} has no valid {RHDH_VERSION_LABEL} label")
    return version


def validate_release(image: Image, catalog: str, release: str) -> None:
    """Check the release line and any requested supported patch version."""

    if catalog == "Supported":
        version = supported_version(image)
    else:
        info = json.loads(required_file(image.files, BUILD_INFO_FILE))
        version = info.get("rhdh-version", "")
    expected_minor = release_minor(release)
    expected_patch = VERSION.fullmatch(release)[3]
    # Community build-info records only the release line, not a patch version.
    if release_minor(version) != expected_minor or (
        catalog == "Supported" and expected_patch is not None and version != release
    ):
        raise CatalogError(
            f"{image.reference} contains RHDH {version}, expected {release}"
        )


def overlays_source(image: Image) -> tuple[str, str]:
    """Read the overlays branch and SHA declared by a supported image.

    The OCI revision label refers to the midstream catalog repository instead.
    """

    upstream = next(
        (value.removeprefix("UPSTREAM_REPO=") for value in image.environment
         if value.startswith("UPSTREAM_REPO=")),
        "",
    )
    match = OVERLAYS_SOURCE.fullmatch(upstream)
    if not match:
        raise CatalogError(
            f"Cannot derive a community image from {image.reference}: "
            "missing or invalid UPSTREAM_REPO; supply --from-community or --to-community"
        )
    return match[1], match[2]


def derived_community_reference(supported: Image, release: str) -> str:
    """Build the community publisher's release, Backstage, and SHA tag."""

    _, sha = overlays_source(supported)
    backstage = supported.labels.get("backstage.version", "")
    if not VERSION.fullmatch(backstage):
        raise CatalogError(
            f"Cannot derive a community image from {supported.reference}: "
            "missing or invalid backstage.version label"
        )
    return f"{COMMUNITY_INDEX}:{release_minor(release)}-bs_{backstage}-{sha[:7]}"


def validate_derived_community(supported: Image, community: Image) -> None:
    """Confirm a derived image declares the expected overlays source and Backstage version."""

    branch, sha = overlays_source(supported)
    info = json.loads(required_file(community.files, BUILD_INFO_FILE))
    # The image tag uses seven SHA characters; build-info.json records eight.
    expected_source = f"{OVERLAYS_REPO}/tree/{branch} @ {sha[:8]}"
    if info.get("source-repo") != expected_source or (
        info.get("backstage-version") != supported.labels.get("backstage.version")
    ):
        raise CatalogError(
            f"{community.reference} does not match the overlays source or Backstage version "
            f"declared by {supported.reference}; supply the community image explicitly"
        )


def created_at(value: str, reference: str) -> datetime:
    """Parse an OCI creation timestamp to order community builds."""

    try:
        created = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as error:
        raise CatalogError(f"Invalid creation time for {reference}: {value}") from error
    if created.tzinfo is None:
        raise CatalogError(f"Missing creation time zone for {reference}: {value}")
    return created


def latest_community_image(supported: Image, release: str) -> Image:
    """Find the newest published community build for this release line.

    A workflow-only overlays commit can appear in UPSTREAM_REPO without having
    produced a community image. Match the release line and Backstage version,
    then choose the newest community build independently of when the supported
    image was created.
    """

    line = release_minor(release)
    backstage = supported.labels.get("backstage.version", "")
    pattern = re.compile(rf"{re.escape(line)}-bs_{re.escape(backstage)}-[0-9a-f]{{7}}$")
    listed = subprocess.run(
        ["skopeo", "list-tags", "--no-creds", f"docker://{COMMUNITY_INDEX}"],
        check=True, capture_output=True, text=True,
    )
    tags = json.loads(listed.stdout).get("Tags")
    if not isinstance(tags, list) or not all(isinstance(tag, str) for tag in tags):
        raise CatalogError(f"Cannot read community tags from {COMMUNITY_INDEX}")
    matches = [tag for tag in tags if pattern.fullmatch(tag)]
    # A publisher might retain only its moving release tag. Use it when no
    # build-specific tag remains, then verify its Backstage metadata below.
    if not matches and line in tags:
        matches = [line]
    if not matches:
        raise CatalogError(f"No community builds found for RHDH {line} and Backstage {backstage}")

    def candidate(tag: str) -> tuple[datetime, str, str]:
        reference = f"{COMMUNITY_INDEX}:{tag}"
        metadata = inspect_image(reference)
        return created_at(metadata.get("Created") or "", reference), tag, image_digest(metadata, reference)

    # Registry tag order is unspecified, so rank matching builds by their OCI
    # creation time. Do not use the supported image's creation time as a bound.
    with ThreadPoolExecutor(max_workers=8) as pool:
        latest = max(pool.map(candidate, matches))
    _, tag, digest = latest
    # Fetch by the inspected digest, so even a retag cannot change this run.
    community = fetch_image(f"{COMMUNITY_INDEX}@{digest}", selection=f"Fallback (`:{tag}`)")
    validate_release(community, "Community", release)
    info = json.loads(required_file(community.files, BUILD_INFO_FILE))
    if info.get("backstage-version") != backstage:
        raise CatalogError(f"{community.reference} does not match Backstage {backstage}")
    return community


def package_entities(files: dict[str, bytes]) -> list[dict]:
    """Load Package entities from the extracted catalog YAML files."""

    entities = []
    for name, content in files.items():
        if not (name.startswith(PACKAGE_DIR) and name.endswith(".yaml")):
            continue
        # BaseLoader preserves unquoted version strings such as 1.10.
        for entity in yaml.load_all(content, Loader=yaml.BaseLoader):
            if isinstance(entity, dict) and entity.get("kind") == "Package":
                entities.append(entity)
    if not entities:
        raise CatalogError("Catalog image has no Package entities")
    return entities


def required_string(value: object, field: str, package: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise CatalogError(f"Missing {field} for {package}")
    return value


def plugin_from_entity(entity: dict, catalog: str, default: str | None) -> Plugin:
    """Read package metadata and variables from its first config example."""

    spec = entity["spec"]
    package = required_string(spec.get("packageName"), "packageName", catalog)
    examples = spec.get("appConfigExamples") or []
    first_example = (
        examples[0]
        if isinstance(examples, list) and examples and isinstance(examples[0], dict)
        else {}
    )
    content = first_example.get("content", "")
    serialized = content if isinstance(content, str) else yaml.safe_dump(content)
    return Plugin(
        package=package,
        version=required_string(spec.get("version"), "version", package),
        support=required_string(spec.get("support"), "support", package),
        lifecycle=required_string(spec.get("lifecycle"), "lifecycle", package),
        variables=frozenset(VARIABLE.findall(serialized)),
        default=default,
        catalogs=frozenset({catalog}),
    )


def supported_plugins(image: Image) -> dict[str, Plugin]:
    """Inventory packages in the supported runtime defaults, including disabled ones."""

    config = yaml.safe_load(required_file(image.files, "dynamic-plugins.default.yaml"))
    if not isinstance(config, dict) or not isinstance(config.get("plugins"), list):
        raise CatalogError("Invalid dynamic-plugins.default.yaml")
    entries = config.get("plugins", [])
    by_artifact = {}
    for entity in package_entities(image.files):
        artifact = entity["spec"].get("dynamicArtifact")
        if artifact:
            if artifact in by_artifact:
                raise CatalogError(f"Duplicate Package artifact: {artifact}")
            by_artifact[artifact] = entity

    plugins = {}
    for entry in entries:
        artifact = entry.get("package")
        if artifact not in by_artifact:
            raise CatalogError(f"Default-configured artifact has no Package entity: {artifact}")
        if "enabled" in entry:
            enabled = entry["enabled"]
        elif "disabled" in entry:
            enabled = not entry["disabled"]
        else:
            raise CatalogError(f"Default-configured artifact has no enablement: {artifact}")
        if not isinstance(enabled, bool):
            raise CatalogError(f"Invalid default enablement: {artifact}")
        plugin = plugin_from_entity(by_artifact[artifact], "Supported", "Enabled" if enabled else "Disabled")
        if plugin.package in plugins:
            raise CatalogError(f"Duplicate default-configured package: {plugin.package}")
        plugins[plugin.package] = plugin
    return plugins


def community_plugins(image: Image) -> dict[str, Plugin]:
    """Inventory packages selected by the community index.json file."""

    index = json.loads(required_file(image.files, "index.json"))
    if not isinstance(index, dict):
        raise CatalogError("Invalid community index.json")
    entities = {}
    for entity in package_entities(image.files):
        spec = entity["spec"]
        package = spec.get("packageName", "")
        # index.json flattens @scope/name to scope-name.
        key = package.lstrip("@").replace("/", "-")
        if key in index:
            if key in entities:
                raise CatalogError(f"Duplicate community Package entity: {key}")
            entities[key] = entity

    plugins = {}
    for key, entry in index.items():
        if key not in entities:
            raise CatalogError(f"Indexed community package has no Package entity: {key}")
        entity = entities[key]
        spec = entity["spec"]
        if spec.get("support") != entry.get("support"):
            raise CatalogError(f"Support mismatch for community package: {key}")
        plugin = plugin_from_entity(entity, "Community", None)
        plugins[plugin.package] = plugin
    return plugins


def release_plugins(supported: Image, community: Image) -> dict[str, Plugin]:
    """Merge both inventories by package name and check overlapping metadata."""

    plugins = supported_plugins(supported)
    for package, plugin in community_plugins(community).items():
        if package not in plugins:
            plugins[package] = plugin
            continue
        previous = plugins[package]
        if (previous.version, previous.support, previous.lifecycle, previous.variables) != (
            plugin.version, plugin.support, plugin.lifecycle, plugin.variables
        ):
            raise CatalogError(f"Supported and community catalogs disagree about {package}")
        plugins[package] = Plugin(
            package=previous.package,
            version=previous.version,
            support=previous.support,
            lifecycle=previous.lifecycle,
            variables=previous.variables,
            default=previous.default,
            catalogs=previous.catalogs | plugin.catalogs,
        )
    return plugins


def display_support(value: str) -> str:
    return SUPPORT.get(value, value)


def display_catalogs(value: frozenset[str]) -> str:
    return " + ".join(catalog for catalog in ("Supported", "Community") if catalog in value)


def inline(value: str) -> str:
    """Keep values safe inside a single AsciiDoc table cell."""

    return value.replace("|", "\\|").replace("\n", " ")


def plugin_state(plugin: Plugin) -> tuple[str, ...]:
    """Format an added or removed package into the report's detail columns."""

    variables = ", ".join(f"`{inline(value)}`" for value in sorted(plugin.variables))
    return (
        f"`{inline(plugin.version)}`",
        display_support(plugin.support),
        plugin.default or "Not listed",
        display_catalogs(plugin.catalogs),
        inline(plugin.lifecycle),
        variables or EMPTY,
    )


def changed(old: str, new: str) -> str:
    return f"{inline(old)} → {inline(new)}" if old != new else EMPTY


def plugin_changes(before: Plugin, after: Plugin) -> tuple[str, ...]:
    """Format each field's transition, using an em dash when unchanged."""

    added = after.variables - before.variables
    removed = before.variables - after.variables
    variables = [f"`+{inline(name)}`" for name in sorted(added)]
    variables += [f"`-{inline(name)}`" for name in sorted(removed)]
    return (
        changed(before.version, after.version),
        changed(display_support(before.support), display_support(after.support)),
        changed(before.default or "Not listed", after.default or "Not listed"),
        changed(display_catalogs(before.catalogs), display_catalogs(after.catalogs)),
        changed(before.lifecycle, after.lifecycle),
        ", ".join(variables) or EMPTY,
    )


def render_table(
    title: str, rows: list[tuple[str, tuple[str, ...]]], fields: tuple[int, ...],
    heading_level: int = 2,
) -> list[str]:
    """Render one change category with its selected detail columns."""

    output = [f"{'=' * heading_level} {title}", ""]
    if not rows:
        return output + ["None.", ""]
    widths = ",".join(["3", *(DETAIL_WIDTHS[index] for index in fields)])
    headers = " ".join(f"|{DETAIL_FIELDS[index]}" for index in fields)
    output += [f'[cols="{widths}",options="header"]', "|===", f"|Package {headers}"]
    for package, details in rows:
        output.append(f"|`{inline(package)}`")
        output.extend(f"|{details[index]}" for index in fields)
    return output + ["|===", ""]


def render(
    from_release: str, to_release: str,
    before: dict[str, Plugin], after: dict[str, Plugin],
    images: dict[tuple[str, str], Image],
    section: bool = False,
) -> str:
    """Classify package changes and render the report with image provenance."""

    # Membership is the union of supported defaults and the community index.
    # A catalog move keeps the package name in both releases, so it is Updated.
    added = [(name, plugin_state(after[name])) for name in sorted(after.keys() - before.keys())]
    removed = [(name, plugin_state(before[name])) for name in sorted(before.keys() - after.keys())]
    updated = []
    for name in sorted(before.keys() & after.keys()):
        changes = plugin_changes(before[name], after[name])
        if any(change != EMPTY for change in changes):
            updated.append((name, changes))

    # Omit Lifecycle when every reported package is active.
    reported = [after[name] for name, _ in added]
    reported += [before[name] for name, _ in removed]
    reported += [plugin for name, _ in updated for plugin in (before[name], after[name])]
    show_lifecycle = any(plugin.lifecycle != "active" for plugin in reported)
    fields = tuple(
        index for index, field in enumerate(DETAIL_FIELDS)
        if field != "Lifecycle" or show_lifecycle
    )
    from_version = images[(from_release, "Supported")].labels.get(RHDH_VERSION_LABEL) or from_release
    to_version = images[(to_release, "Supported")].labels.get(RHDH_VERSION_LABEL) or to_release

    identifier = f"dynamic-plugin-changes-{from_release.replace('.', '-')}-to-{to_release.replace('.', '-')}"
    output = [] if section else [
        ":_mod-docs-content-type: REFERENCE", "",
        "// Generated by generate-dynamic-plugin-changelog.py; do not edit manually.", "",
    ]
    heading_level = 2 if section else 1
    output += [
        f'[id="{identifier}"]',
        f"{'=' * heading_level} Dynamic plugin changes from {from_version} to {to_version}",
        "",
    ]
    if not section:
        output += [
            "The comparison covers packages in the supported catalog's default plugin configuration and packages in the community catalog. "
            "`Not listed` means the package is absent from the supported default configuration. "
            "`Removed` means the package is absent from both inventories in the later release; a catalog move appears under `Updated`. "
            "Package renames appear as a removal and an addition. "
            "Variables are names found in the published configuration examples. "
            "An em dash means no change or no variables. "
            "When the exact community image is absent, the fallback is the newest community build for the same release line and Backstage version.",
            "",
        ]
    if added or removed or updated:
        output += [f"{len(added)} added; {len(removed)} removed; {len(updated)} updated.", ""]
        output += render_table("Added", added, fields, heading_level + 1)
        output += render_table("Removed", removed, fields, heading_level + 1)
        output += render_table("Updated", updated, fields, heading_level + 1)
    else:
        output += ["No plugins were updated in this release.", ""]
    output += [
        f"{'=' * (heading_level + 1)} Catalog images", "",
        "The supported images record the RHDH patch version; community images record the release line.",
        "", '[cols="1,1,1,2,5",options="header"]', "|===",
        "|Release line |Catalog |Image RHDH version |Selection |Immutable image reference",
    ]
    for release in (from_release, to_release):
        for catalog in ("Supported", "Community"):
            image = images[(release, catalog)]
            if catalog == "Supported":
                version = image.labels.get(RHDH_VERSION_LABEL) or release
                selection = "Published patch image"
            else:
                version = json.loads(required_file(image.files, BUILD_INFO_FILE))["rhdh-version"]
                selection = image.selection
            output += [
                f"|{release_minor(release)} |{catalog} |{version} |{selection} |`{image.immutable_reference}`"
            ]
    output += ["|===", ""]
    return "\n".join(output)


def main() -> int:
    """Resolve the four images, validate their pairing, then write the report."""

    parser = argparse.ArgumentParser(description=__doc__)
    for side in ("from", "to"):
        parser.add_argument(f"--{side}-release", help="RHDH major.minor[.patch] version")
        parser.add_argument(
            f"--{side}-supported",
            help="Supported catalog image tag or digest (default: latest patch tag on Quay when a release is given)",
        )
        parser.add_argument(
            f"--{side}-community",
            help="Community image tag or digest (default: exact overlays commit, then latest eligible build)",
        )
    parser.add_argument(
        "--output", type=Path,
        help=f"Write a version-named AsciiDoc report under {MODULE_DIR} (default: stdout)",
    )
    parser.add_argument("--section", action="store_true", help="Emit a section for a combined changelog")
    args = parser.parse_args()
    for side in ("from", "to"):
        if getattr(args, f"{side}_release") is None and getattr(args, f"{side}_supported") is None:
            parser.error(f"one of --{side}-release or --{side}-supported is required")
    try:
        if args.output is not None:
            args.output = output_path(args.output)
        supported_images = {}
        releases = {}
        for side in ("from", "to"):
            release = getattr(args, f"{side}_release")
            supported_ref = getattr(args, f"{side}_supported")
            if release is not None:
                release_minor(release)
            if supported_ref is not None:
                reference, expected_supported_version = supported_ref, release
            else:
                reference, expected_supported_version = default_supported_reference(release)
            supported = fetch_image(reference)
            if expected_supported_version is not None:
                validate_release(supported, "Supported", expected_supported_version)
            releases[side] = release if release is not None else supported_version(supported)
            supported_images[side] = supported
        if releases["from"] == releases["to"]:
            raise CatalogError("From and to releases must differ")

        images = {}
        for side in ("from", "to"):
            release = releases[side]
            supported = supported_images[side]
            community_ref = getattr(args, f"{side}_community")
            images[(release, "Supported")] = supported
            if community_ref:
                community = fetch_image(community_ref)
            else:
                reference = derived_community_reference(supported, release)
                try:
                    community = fetch_image(reference, selection="Exact overlays commit")
                except subprocess.CalledProcessError as error:
                    # Not all overlay commits (ex: workflow-only change) publish a new
                    # community catalog. Fall back only when its tag is absent.
                    if "manifest unknown" not in (error.stderr or "").lower():
                        raise
                    try:
                        community = latest_community_image(supported, release)
                    except CatalogError as fallback_error:
                        raise CatalogError(
                            f"Exact community image {reference} is absent; {fallback_error}"
                        ) from fallback_error
                else:
                    validate_derived_community(supported, community)
            validate_release(community, "Community", release)
            images[(release, "Community")] = community
        before = release_plugins(images[(releases["from"], "Supported")], images[(releases["from"], "Community")])
        after = release_plugins(images[(releases["to"], "Supported")], images[(releases["to"], "Community")])
        report = render(releases["from"], releases["to"], before, after, images, args.section)
        if args.output:
            args.output.write_text(report, encoding="utf-8")
            print(f"Wrote {args.output}")
        else:
            sys.stdout.write(report)
    except (CatalogError, OSError, ValueError, KeyError, yaml.YAMLError, subprocess.CalledProcessError) as error:
        detail = error.stderr.strip() if isinstance(error, subprocess.CalledProcessError) and error.stderr else str(error)
        print(f"[ERROR] {detail}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
