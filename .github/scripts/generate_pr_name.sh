#!/bin/bash

# Store the GitHub branch name in a variable
branch="$GITHUB_REF_NAME"

# Split the string at the '/' character
IFS='/' read -ra parts <<< "$branch"

# Extract the topic and description parts
topic="${parts[0]}"
description="${parts[1]}"

# Replace underscores with spaces in the description
description="${description//_/ }"

# Convert the description to title case
description="$(echo "$description" | awk '{ for(i=1;i<=NF;i++) $i= toupper(substr($i,1,1)) tolower(substr($i,2)); }1')"

# Format the output
output="(${topic}): ${description}"

# Print the result
echo "$output"
