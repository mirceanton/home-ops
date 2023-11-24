#!/bin/bash

function process_files() {
    local filename_regex="$1"
    local yaml_language_server_comment="$2"

    # Find all files matching the provided regex recursively under the current directory
    files=$(find . -type f -regex "$filename_regex")

    # Loop through each file
    for file in $files; do
        # Check if the first line is '---', if not, add it
        if [[ $(head -n 1 "$file") != '---' ]]; then
            echo "---" | cat - "$file" >tempfile && mv tempfile "$file"
            echo "Added '---' to $file"
        fi

        # Check if the second line is the specified string, if not, add it as the second line
        if [[ $(sed -n '2p' "$file") != "$yaml_language_server_comment" ]]; then
            sed -i '2i '"$yaml_language_server_comment" "$file"
            echo "Added second line to $file"
        fi
    done
}

process_files '.*\.ks\.yaml' "# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/kustomization-kustomize-v1.json"
process_files '.*\.helm-release\.yaml' "# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrelease-helm-v2beta1.json"
process_files '.*\.helm-repository\.yaml' "# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrepository-source-v1beta2.json"
process_files '.*\.git-repository\.yaml' "# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/gitrepository-source-v1.json"
process_files '.*\.oci-repository\.yaml' "# yaml-language-server: \$schema=https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/ocirepository-source-v1beta2.json"
process_files 'kustomization\.yaml' "# yaml-language-server: \$schema=https://json.schemastore.org/kustomization"
process_files '.*\.cluster-issuer\.yaml' "# yaml-language-server: \$schema=https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/cert-manager.io/clusterissuer_v1.json"
