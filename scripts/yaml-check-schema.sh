#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No color

# Find all YAML files
files=$(find . -type f -name "*.yaml" )

status=0

# Loop through all files
for f in $files; do
  # Look for the yaml schema store comment
  if grep -q '# yaml-language-server: $schema=' "$f"; then
    echo -e "  - ${GREEN}YAML schema ok for $f${NC}"
  else
    echo -e "  - ${RED}YAML schema check failed for $f${NC}"
    status=1
  fi
done

exit status
