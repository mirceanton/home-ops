import os
import glob
import argparse
from colorama import Fore, Style

# Include the @yaml_schema_source comment in the files matching the @filename_regex
def process_files(filename_regex, yaml_schema_source, check_mode=False):
	files = glob.glob(filename_regex, recursive=True)
	error_found = False

	for file_path in files:
		with open(file_path, 'r') as f:
			lines = f.readlines()

		if len(lines) > 0 and yaml_schema_source not in lines[1].strip():
			error_found = True

			if not check_mode:
				lines.insert(1, f"# yaml-language-server: $schema={yaml_schema_source}\n")
				with open(file_path, 'w') as f:
					f.writelines(lines)
				print(f"{Fore.YELLOW}Added yaml schema to {file_path}{Style.RESET_ALL}")
			else:
				print(f"{Fore.RED}File is missing the expected schema: {file_path}{Style.RESET_ALL}")
	
	return error_found


schema_mappings = {
	"**/kustomization.yaml": "https://json.schemastore.org/kustomization",

	# Flux stuff
	"**/*.ks.yaml": "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/kustomization-kustomize-v1.json",
	"**/*.helm-release.yaml": "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrelease-helm-v2beta1.json",
	"**/*.helm-repository.yaml": "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/helmrepository-source-v1beta2.json",
	"**/*.git-repository.yaml": "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/gitrepository-source-v1.json",
	"**/*.oci-repository.yaml": "https://raw.githubusercontent.com/fluxcd-community/flux2-schemas/main/ocirepository-source-v1beta2.json",

	# Cert manager stuff
	"**/*.cluster-issuer.yaml": "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/cert-manager.io/clusterissuer_v1.json",

	# Talhelper stuff
	"**/talconfig.yaml": "https://raw.githubusercontent.com/budimanjojo/talhelper/master/pkg/config/schemas/talconfig.json"
}


parser = argparse.ArgumentParser(description="Process files and ensure the specified schema is present in the second line.")
parser.add_argument("--check", action="store_true", help="Check mode. Exit with status 1 if any file is missing the schema.")
args = parser.parse_args()

error_found = False
for file_type, schema_source in schema_mappings.items():
	err = process_files(
		file_type,
		schema_source,
		check_mode = args.check
	)
	error_found = error_found or err

if error_found:
	exit(1)
