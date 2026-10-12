#!/bin/zsh

# Define the file list
files=(
  "modules/dynamic-plugins/con-rhdh-plugins.adoc"
  "modules/dynamic-plugins/con-understand-dynamic-plugins-in-red-hat-developer-hub.adoc"
  "modules/dynamic-plugins/con-setting-up-the-development-toolchain.adoc"
  "modules/dynamic-plugins/proc-developing-plugins-from-scratch.adoc"
  "modules/dynamic-plugins/proc-converting-a-custom-plugin-into-an-rhdh-dynamic-plugin.adoc"
  "modules/dynamic-plugins/proc-packaging-and-publishing-artifacts.adoc"
  "modules/dynamic-plugins/con-testing-with-rhdh-local.adoc"
  "modules/dynamic-plugins/proc-deployment-configurations.adoc"
  "modules/dynamic-plugins/ref-best-practices-and-reference.adoc"
)

# Loop through each file
for file in "${files[@]}"; do
  # Extract the base filename
  basename=$(basename "$file" .adoc)
  
  # Determine content type based on prefix
  case $basename in
    con-*) type="CONCEPT" ;;
    proc-*) type="PROCEDURE" ;;
    ref-*) type="REFERENCE" ;;
    *) type="CONCEPT" ;;
  esac

  # Format the title: remove prefix, replace dashes with spaces, capitalize words
  title_raw=${basename#*-}
  title=$(echo "$title_raw" | sed -E 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

  # Write the content
cat << EOF > "$file"
:_mod-docs-content-type: $type

[id="${basename}_{context}"]
= $title
EOF

done

echo "Files generated successfully in modules/dynamic-plugins/"