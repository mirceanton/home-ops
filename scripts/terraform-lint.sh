#!/bin/bash

# Color codes for pretty output
RED="\e[31m"
GREEN="\e[32m"
GREY="\e[90m"
RESET="\e[0m"

# Initialize a variable to track whether any directory is unformatted.
# Status:
#   - 0 -> at least one directory is not formatted
#   - 1 -> everything is ok
# Assume everything is ok initially.
formatted=1

# Loop through all directories in $DIR
for d in "$DIR"/*; do
  if [ -d "$d" ]; then
    # Check if there are any terraform files inside the subdirectory
    if ls "$d"/*.tf* 1> /dev/null 2>&1; then
      pushd "$d" > /dev/null

      # Check if terraform files are properly formatted
      if terraform fmt -check 1> /dev/null 2>&1; then
          echo -e "${GREEN}Terraform files in '$d' are properly formatted.${RESET}"
      else
          echo -e "${RED}Terraform files in '$d' are not properly formatted.${RESET}"
          formatted=0  # update flag
      fi

      popd > /dev/null
    else
      echo -e "${GREY}No Terraform files found in '$d'. Skipping...${RESET}"
    fi
  fi
done


if [ "$formatted" -eq 0 ]; then
  echo -e "${RED}Some directories have unformatted Terraform files.${RESET}"
  exit 1
else
  echo -e "${GREEN}All Terraform directories checked and formatted properly.${RESET}"
  exit 0
fi
