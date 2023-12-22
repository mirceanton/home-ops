#!/bin/bash

# Specify the path of the folder you want to loop through
parent_folder="clusters/"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No color

# Loop through all folders inside the parent folder
for folder in "$parent_folder"/*/; do
  # Ensure that the entry is a directory (folder)
  if [ -d "$folder" ]; then
    # Print the name of the folder
    echo -e "Processing folder: $(basename "$folder")"
    pushd "$folder" > /dev/null

    # Find the git-repository file
    gitrepo_file=$(find . -type f -name 'home-ops.git-repository.yaml');
    echo -e "  - Found git-repo file: $folder/$gitrepo_file"

    # Check if the git-repository file exists
    if [ -z "$gitrepo_file" ]; then
      echo -e "${RED}No git-repository.yaml file found in $folder${NC}"
      exit 1
    fi

    # Check if the sync branch is set to main
    if grep -q 'branch: main' "$gitrepo_file"; then
      echo -e "  - ${GREEN}Sync branch ok!${NC}"
    else
      echo -e "  - ${RED}Sync branch check failed for $gitrepo_file${NC}"
      exit 1
    fi

    popd > /dev/null;
    echo
  fi
done
