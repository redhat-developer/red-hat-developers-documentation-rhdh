# Dynamic plugins reference module

`rhdh-supported-plugins.sh` updates this module from two catalog index images:

* The [supported catalog index](https://quay.io/rhdh/plugin-catalog-index) provides the supported plugin tables and `rhdh-supported-plugins.csv`.
* The [community catalog index](https://github.com/redhat-developer/rhdh-plugin-export-overlays/pkgs/container/rhdh-plugin-export-overlays%2Fplugin-catalog-index/versions) provides `ref-community-supported-plugins.adoc` and `rhdh-community-plugins.csv`.

For `release-X.Y`, the script reads the `:X.Y` tag from each image; for `main`, it reads `:next`. It checks that the images have matching RHDH major and minor versions, then records their image digests and versions in `catalog-index-sources.json` for tracking.

## Run locally

Run the script from a checkout of the matching documentation branch. It requires `skopeo`, `jq` 1.6 or later, `tar`, Git, and Node.js.

```bash
bash modules/extend_dynamic-plugins-reference/rhdh-supported-plugins.sh -b main
```

The script updates both sources by default. Use `--skip-supported-tables` or `--skip-community-table` to update only one source. Run the script with `--help` for all options.

## Run through GitHub Actions

The [Generate update PR for the Dynamic Plugins tables workflow](https://github.com/redhat-developer/red-hat-developers-documentation-rhdh/actions/workflows/generate-supported-plugins-pr.yml) opens a pull request for generated changes. For a manual run, enter a branch listed in the workflow matrix in the `branch` input. Scheduled runs use the workflow configuration on the default branch.

Do not edit generated files here. Make source changes in [rhdh-plugin-export-overlays](https://github.com/redhat-developer/rhdh-plugin-export-overlays); its community catalog index publishes the community files, and the supported files are downstreamed into the Quay catalog index.

## Generate a release changelog

`generate-dynamic-plugin-changelog.py` compares four published catalog images and writes one AsciiDoc report. It requires Python 3, PyYAML (listed in the repository's `requirements.txt`), and `skopeo`. Give either a release or a supported image for each side of the comparison. For a major.minor input such as `1.10`, it selects the highest numeric patch tag from the public Quay supported catalog; a major.minor.patch input such as `1.10.6` selects that exact tag. When given a supported image instead, it reads the image's `rhdh.version` label. If both are supplied, the release line must match, and a specified patch must match exactly. By default, it derives the GHCR community tag from the supported image's release line, Backstage version, and `UPSTREAM_REPO` overlays commit, then verifies the community image's `build-info.json`. The public images are read anonymously without an auth file. The report records each resolved image digest.

```bash
python3 modules/extend_dynamic-plugins-reference/generate-dynamic-plugin-changelog.py \
  --from-release 1.10 \
  --from-community ghcr.io/redhat-developer/rhdh-plugin-export-overlays/plugin-catalog-index:1.10-bs_1.49.4-6687c44 \
  --to-release 2.1 \
  --output modules/extend_dynamic-plugins-reference/ref-dynamic-plugin-changes-1-10-to-2-1.adoc
```

The latest 1.10 supported image declares an overlays commit with no corresponding community image, so the example supplies `--from-community` explicitly. Supply `--from-community` or `--to-community` whenever an exact commit tag is unavailable. The script stops with the attempted tag and an override hint instead of silently selecting a different source commit. `--from-supported` and `--to-supported` can replace both release arguments; use a tag or immutable `@sha256:` reference from any registry that publishes the required catalog metadata. Matching is based on published metadata: a manual community workflow run targeting another branch can record the triggering commit instead of the checked-out source commit. For a repeatable report, pin the supplied images by digest; the report always records the resolved digests.

The supported inventory comes from `dynamic-plugins.default.yaml` and its Package entities; the community inventory comes from `index.json` and its Package entities. This includes packages omitted from the 1.10 CSV and works with the 1.10 community image, which has no CSV. Packages in both catalogs appear once. The report uses the supported images' RHDH patch versions as comparison endpoints and lists each image's declared version and digest. Separate columns show package additions, removals, version changes, support changes, default enablement changes, catalog moves, lifecycle changes when present, and changes to variable names in the first published configuration example. An em dash means no change or no variables. Run it again with the same output path to refresh that comparison.
