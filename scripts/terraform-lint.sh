#!/bin/bash

TF_DIR=terraform

# Color codes for pretty output
RED="\e[31m"
GREEN="\e[32m"
GREY="\e[90m"
RESET="\e[0m"

# Initialize variables to track formatting status and verbosity
formatted=1
quiet=false
verbose=false

# Process command line options
while [[ $# -gt 0 ]]; do
  case "$1" in
  -q | --quiet)
    quiet=true
    shift
    ;;
  -v | --verbose)
    verbose=true
    shift
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

# Loop through all directories in $DIR
for d in "$TF_DIR"/*; do
  if [ -d "$d" ]; then
    # Check if there are any terraform files inside the subdirectory
    if ls "$d"/*.tf* 1>/dev/null 2>&1; then
      pushd "$d" >/dev/null

      # Check if terraform files are properly formatted
      if terraform fmt -check 1>/dev/null 2>&1; then
        if [ "$verbose" = true ]; then
          echo -e "${GREEN}Terraform files in '$d' are properly formatted.${RESET}"
        fi
      else
        if [ "$quiet" = false ]; then
          echo -e "${RED}Terraform files in '$d' are not properly formatted.${RESET}"
        fi
        formatted=0 # update flag
      fi

      popd >/dev/null
    else
      if [ "$verbose" = true ]; then
        echo -e "${GREY}No Terraform files found in '$d'. Skipping...${RESET}"
      fi
    fi
  fi
done

if [ "$formatted" -eq 0 ]; then
  if [ "$quiet" = false ]; then
    echo -e "${RED}Some directories have unformatted Terraform files.${RESET}"
  fi
  exit 1
else
  if [ "$verbose" = true ]; then
    echo -e "${GREEN}All Terraform directories checked and formatted properly.${RESET}"
  fi
  exit 0
fi
