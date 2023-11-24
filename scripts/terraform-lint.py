import os
from python_terraform import *
from colorama import Fore, Style

# Set the base directory
DIR = "./infra/"

# Initialize a variable to track whether any directory is unformatted.
formatted = True

# Loop through all directories in $DIR
for d in os.listdir(DIR):
	full_path = os.path.join(DIR, d)

	if os.path.isdir(full_path):
		# Check if there are any terraform files inside the subdirectory
		tf_files = [f for f in os.listdir(full_path) if f.endswith('.tf') or f.endswith('.tfvars')]

		if tf_files:
			tf = Terraform(working_dir=full_path)

			# Check if terraform files are properly formatted
			try:
				tf.fmt(check=True, no_color=IsFlagged)
				print(f"{Fore.GREEN}Terraform files in '{full_path}' are properly formatted.{Style.RESET_ALL}")
			except TerraformCommandFailed as e:
				print(f"{Fore.RED}Terraform files in '{full_path}' are not properly formatted.{Style.RESET_ALL}")
				formatted = False
		else:
			print(f"{Fore.CYAN}No Terraform files found in '{full_path}'. Skipping...{Style.RESET_ALL}")

# Check the overall status and exit accordingly
if not formatted:
	print(f"{Fore.RED}Some directories have unformatted Terraform files.{Style.RESET_ALL}")
	exit(1)

print(f"{Fore.GREEN}All Terraform directories checked and formatted properly.{Style.RESET_ALL}")
