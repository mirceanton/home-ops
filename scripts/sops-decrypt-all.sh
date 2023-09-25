#!/bin/bash

find . -regextype egrep -regex "\.\/.+\/.*.sops.yaml" -type f | while IFS= read -r file; do
    decrypted_file="${file%.sops.yaml}.yaml"
    echo "Decrypting file: $file"
    sops --decrypt "$file" > "$decrypted_file"
done
