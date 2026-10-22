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
