#!/bin/bash

# ANSI color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No color

# Find all YAML files
files=$(git ls-files | grep yaml)  # get all the yaml files tracked by git
files=$(echo "$files" | grep --invert-match ".sops.yaml")  # remove sops files

# Remove k8s files
files=$(echo "$files" | grep --invert-match -v "namespace.yaml")
files=$(echo "$files" | grep --invert-match -v "configmap.yaml")
files=$(echo "$files" | grep --invert-match -v "deployment.yaml")
files=$(echo "$files" | grep --invert-match -v "volume.yaml")
files=$(echo "$files" | grep --invert-match -v ".reflected-secret.yaml")

# Remove misc files with no schema
files=$(echo "$files" | grep --invert-match -v "talenv.yaml")
files=$(echo "$files" | grep --invert-match -v ".github/labels.yaml")
files=$(echo "$files" | grep --invert-match -v ".sh")
files=$(echo "$files" | grep --invert-match -v ".terraform.yaml")

# Remove helm values files
files=$(echo "$files" | grep --invert-match -v ".helm-values.yaml")

# Flags
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

# Assume success
status=0

# Loop through all files
for f in $files; do
  # Look for the yaml schema store comment
  if grep -q '# yaml-language-server: $schema=' "$f"; then
    if [ "$verbose" = true ]; then
      echo -e "  - ${GREEN}YAML schema ok for $f${NC}"
    fi
  else
    if [ "$quiet" = false ]; then
      echo -e "  - ${RED}YAML schema check failed for $f${NC}"
    fi
    status=1
  fi
done

exit $status
