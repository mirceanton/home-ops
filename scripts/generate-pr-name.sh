#!/bin/bash

# Check if the environment variable is set
if [ -z "$GITHUB_REF_NAME" ]; then
  echo "GITHUB_REF_NAME is not set"
  exit 1
fi

# Split the string by '/'
IFS='/' read -r -a parts <<< "$GITHUB_REF_NAME"

# Check the number of parts after splitting
case ${#parts[@]} in
  2)
    # Format: <type>/<message>
    type="${parts[0]}"
    message="${parts[1]}"
    echo "type: $message"
    ;;
  3)
    # Format: <type>/<scope>/<message>
    type="${parts[0]}"
    scope="${parts[1]}"
    message="${parts[2]}"
    echo "$type($scope): $message"
    ;;
  *)
    # If the format does not match either case, exit with failure
    echo "Invalid branch name format"
    exit 1
    ;;
esac
