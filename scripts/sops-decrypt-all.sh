#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

force=false

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -f|--force)
            force=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

find . -regextype egrep -regex "\.\/.+\/.*.sops.yaml" -type f | while IFS= read -r file; do
    decrypted_file="${file%.sops.yaml}.yaml"
    
    if [ -f "$decrypted_file" ]; then
        # Decrypt the encrypted version
        decrypted_temp=$(mktemp)
        sops --decrypt "$file" > "$decrypted_temp"
        
        # Compare the decrypted version with the existing decrypted file
        if cmp -s "$decrypted_file" "$decrypted_temp"; then
            echo -e "${GREEN}No changes detected. Skipping decryption for file: $file${NC}"
        else
            if [ "$force" = true ]; then
                mv "$decrypted_temp" "$decrypted_file"
                echo -e "${RED}File replaced with the decrypted content: $decrypted_file${NC}"
            else
                echo -e "${RED}Changes detected. Use -f or --force flag to overwrite.${NC}"
            fi
        fi
        
        if [ -f "$decrypted_temp" ]; then
            rm "$decrypted_temp"
        fi
    else
        # No decrypted file exists, decrypt and create it
        echo -e "${RED}Decrypting file: $file${NC}"
        sops --decrypt "$file" > "$decrypted_file"
    fi
done
