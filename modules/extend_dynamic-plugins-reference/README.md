= Dynamic plugins reference module

The contents of this folder are updated by running the GH action in this repo against a specific branch

https://github.com/redhat-developer/red-hat-developers-documentation-rhdh/actions/workflows/generate-supported-plugins-pr.yml

The action which will extract the generated content from the latest catalog index at https://quay.io/rhdh/plugin-catalog-index using the related branch (release-1.10 => `:1.10`, main => `:next`), then a pull request will be created that can be reviewed before merging.

Currently, the community plugins table at ref-community-supported-plugins.adoc is not generated from the same catalog index container. Instead it uses the contents of rhdh-plugin-export-overlays to get the list of plugins.

== Contributing to the dynamic plugins tables

Do not edit the fetched files directly in this repository, as they will be overwritten. 

Instead, contribute changes to https://github.com/redhat-developer/rhdh-plugin-export-overlays[redhat-developer/rhdh-plugin-export-overlays], which will be either read directly (for community plugins) or downstreamed and built into a new image at https://quay.io/rhdh/plugin-catalog-index

== Automation

The GitHub Actions workflow `.github/workflows/generate-supported-plugins-pr.yml` runs `rhdh-supported-plugins.sh` weekly to open a pull request for updated content. It can also be run manually at any time.

== Requirements

Running the sync script locally requires:

* `skopeo`
* `jq`
* `yq` (the https://kislyuk.github.io/yq/[kislyuk/jq-wrapper] version, not mikefarah/yq)