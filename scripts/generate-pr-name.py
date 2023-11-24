import os

# Extract github branch name from environment
branch_name = os.environ.get("GITHUB_REF_NAME")

if not branch_name:
	print("GITHUB_REF_NAME environment variable is not set.")
	exit(1)

# branch naming convention: (topic)/(description)
if branch_name.count('/') != 1:
	print("GitHub branch naming convention not followed. Skipping...")
	exit(1)

# Extract the topic and description parts
parts = branch_name.split('/')
topic = parts[0]
description = ' '.join(word.capitalize() for word in parts[1].split('_'))

print(f"{topic}: {description}")
