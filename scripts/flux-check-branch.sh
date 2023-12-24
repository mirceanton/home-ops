#!/bin/bash

# Specify the path of the folder you want to loop through
parent_folder="clusters/"

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No color

# Initialize variables to track verbosity
quiet=false
verbose=false

# Process command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--quiet)
      quiet=true
      shift
      ;;
    -v|--verbose)
      verbose=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Loop through all folders inside the parent folder
for folder in "$parent_folder"/*/; do
  # Ensure that the entry is a directory (folder)
  if [ -d "$folder" ]; then
    # Print the name of the folder
    if [ "$verbose" = true ]; then
      echo -e "Processing folder: $(basename "$folder")"
    fi
    pushd "$folder" > /dev/null

    # Find the git-repository file
    gitrepo_file=$(find . -type f -name 'home-ops.git-repository.yaml');
    if [ "$verbose" = true ]; then
      echo -e "  - Found git-repo file: $folder/$gitrepo_file"
    fi

    # Check if the git-repository file exists
    if [ -z "$gitrepo_file" ]; then
      if [ "$quiet" = false ]; then
        echo -e "${RED}No git-repository.yaml file found in $folder${NC}"
      fi
      exit 1
    fi

    # Check if the sync branch is set to main
    if grep -q 'branch: main' "$gitrepo_file"; then
      if [ "$verbose" = true ]; then
        echo -e "  - ${GREEN}Sync branch ok!${NC}"
      fi
    else
      if [ "$quiet" = false ]; then
        echo -e "  - ${RED}Sync branch check failed for $gitrepo_file${NC}"
      fi
      exit 1
    fi

    popd > /dev/null;
    if [ "$verbose" = true ]; then
      echo
    fi
  fi
done
