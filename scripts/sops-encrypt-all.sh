#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

while IFS= read -r path; do
    path=$(echo "$path" | sed 's/\(\.sops\)/ /g')
    find . -regextype egrep -regex ".*/$path" -type f | while IFS= read -r file; do
        encrypted_file="${file%.yaml}.sops.yaml"
        
        if [ -f "$encrypted_file" ]; then
            # Decrypt the encrypted version
            decrypted_temp=$(mktemp)
            sops --decrypt "$encrypted_file" > "$decrypted_temp"
            
            # Compare the decrypted version with the file on disk
            if cmp -s "$file" "$decrypted_temp"; then
                echo -e "${GREEN}No changes detected. Skipping encryption for file: $file${NC}"
            else
                echo -e "${RED}Changes detected. Re-encrypting file: $file${NC}"
                sops --encrypt "$file" > "$encrypted_file"
            fi
            
            rm "$decrypted_temp"
        else
            # No encrypted version exists, encrypt the file
            echo -e "${RED}Encrypting file: $file${NC}"
            sops --encrypt "$file" > "$encrypted_file"
        fi
    done
done < <(grep -oP '^\s*- path_regex:\s*\K.*' ".sops.yaml")
