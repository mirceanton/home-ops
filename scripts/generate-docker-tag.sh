#!/bin/bash

# Check if REGISTRY_USER is set
if [ -z "$REGISTRY_USER" ]; then
  echo "Error: Please set the environment variable REGISTRY_USER"
  exit 1
fi

# Check if REGISTRY_TOKEN is set and base64 encode it
if [ -z "$REGISTRY_TOKEN" ]; then
  echo "Error: Please set the environment variable REGISTRY_TOKEN"
  exit 1
fi
REGISTRY_TOKEN_BASE64=$(echo -n "$REGISTRY_TOKEN" | base64)

# Check if REGISTRY_URL is set
if [ -z "$REGISTRY_URL" ]; then
  echo "Error: Please set the environment variable REGISTRY_URL"
  exit 1
fi

# Check if IMAGE_NAME is set
if [ -z "$IMAGE_NAME" ]; then
  echo "Error: Please set the environment variable IMAGE_NAME"
  exit 1
fi

# Function to fetch existing tags from a container registry
fetch_tags() {
  tags=$(curl -s -H "Authorization: Bearer $REGISTRY_TOKEN_BASE64" https://$REGISTRY_URL/v2/$REGISTRY_USER/$IMAGE_NAME/tags/list | jq -r .tags[] | grep "^$1\.[0-9]*$")
  echo "$tags"
}

# Function to determine the next patch number
determine_patch() {
  if [ -z "$1" ]; then
    echo "0"
  else
    latest_patch=$(echo "$1" | awk -F'.' '{print $NF}' | sort -n | tail -n 1)
    echo $((latest_patch + 1))
  fi
}

# Extract current date
calver=$(date -u +'%Y.%m')

# Determine the next patch number
patch=$(determine_patch "$(fetch_tags $calver)")

echo "$calver.$patch"
