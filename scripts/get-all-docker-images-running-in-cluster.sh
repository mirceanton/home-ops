#!/bin/bash

# Get the list of unique docker images
images=$(kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec['initContainers', 'containers'][*].image}" | tr -s '[[:space:]]' '\n' | sort | uniq -c)

# Initialize arrays to store the values for each column
count_arr=()
image_arr=()
tag_arr=()

# Loop through each line of the output and populate the arrays
while read -r line; do
  count=$(echo "$line" | awk '{print $1}')
  image=$(echo "$line" | awk '{$1=""; print $0}' | cut -d ":" -f 1)
  tag=$(echo "$line" | awk '{$1=""; print $0}' | cut -d ":" -f 2)

  count_arr+=("$count")
  image_arr+=("$image")
  tag_arr+=("$tag")
done <<< "$images"

# Determine the maximum string length for each column
max_count_length=$(printf "%s\n" "${count_arr[@]}" | awk '{ print length }' | sort -n | tail -n 1)
max_count_length=$((max_count_length > 5 ? max_count_length : 5))  # Account for the "COUNT" column name
max_image_length=$(printf "%s\n" "${image_arr[@]}" | awk '{ print length }' | sort -n | tail -n 1)
max_image_length=$((max_image_length > 5 ? max_image_length : 5))  # Account for the "IMAGE" column name
max_tag_length=$(printf "%s\n" "${tag_arr[@]}" | awk '{ print length }' | sort -n | tail -n 1)
max_tag_length=$((max_tag_length > 3 ? max_tag_length : 3))  # Account for the "TAG" column name

# Print the table header with column sizing
printf "| %-*s | %-*s | %-*s |\n" "$max_count_length" "COUNT" "$max_image_length" "IMAGE" "$max_tag_length" "TAG"

# Loop through the arrays and print the formatted table
for ((i = 0; i < ${#count_arr[@]}; i++)); do
  printf "| %-*s |%-*s  | %-*s |\n" "$max_count_length" "${count_arr[i]}" "$max_image_length" "${image_arr[i]}" "$max_tag_length" "${tag_arr[i]}"
done
