#!/bin/bash

while IFS= read -r path; do
    path=$(echo "$path" | sed 's/\(\.sops\)/ /g')
    find . -regextype egrep -regex ".*/$path" -type f | while IFS= read -r file; do
        echo "Encrypting file: $file"
        sops --encrypt "$file" > "${file%.yaml}.sops.yaml"
    done
done < <(grep -oP '^\s*- path_regex:\s*\K.*' ".sops.yaml")
