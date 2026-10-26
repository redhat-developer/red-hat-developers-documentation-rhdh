"""Constrain dynamic plugin changelog writes to known documentation files."""

import re
from pathlib import Path


MODULE_DIR = Path("modules/extend_dynamic-plugins-reference")
INDEX_NAME = "ref-dynamic-plugin-changes.adoc"
REPORT_NAME = re.compile(
    r"ref-dynamic-plugin-changes-\d+-\d+(?:-\d+)?-to-\d+-\d+(?:-\d+)?\.adoc$"
)
TITLE_PATHS = (
    Path("titles/extend_dynamic-plugins-reference/master.adoc"),
    Path("titles/product_product/category-maps/reference/nav-dynamic-plugin-parameter-reference-for-configuration-paths.adoc"),
)


class PathNotContainedError(ValueError):
    """A path would write outside its allowed documentation location."""


def require_document_path(flag: str, arg: str | Path, directory: Path, name: str | re.Pattern[str]) -> Path:
    """Resolve a path from the checkout root to one allowed direct child.

    This follows the overlays repository's ``require_contained`` approach:
    resolve before checking containment, so a symlink or ``..`` cannot move a
    write elsewhere. Changelog files also have fixed locations and names, so
    reject symlinks and traversal components even if they lead back inside.
    ``directory`` and ``name`` are trusted constants supplied by the caller.
    """

    checkout = Path.cwd().resolve()
    supplied = Path(arg)
    allowed = checkout / directory
    candidate = checkout / supplied
    valid_name = candidate.name == name if isinstance(name, str) else bool(name.fullmatch(candidate.name))
    if (
        directory.is_absolute()
        or ".." in directory.parts
        or ".." in supplied.parts
        or not valid_name
        or allowed.resolve() != allowed
        or candidate.is_symlink()
    ):
        raise PathNotContainedError(f"{flag} must name an allowed file directly under {directory} in this checkout")
    resolved = candidate.resolve()
    if resolved.parent != allowed:
        raise PathNotContainedError(f"{flag} must resolve directly under {directory} in this checkout")
    return resolved
