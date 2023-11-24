import os
import glob

def process_files(filename_regex, yaml_schema_source):
	# Find all files matching the provided regex recursively under the current directory
	files = glob.glob(filename_regex, recursive=True)

	# Loop through each file
	for file_path in files:
		with open(file_path, 'r') as f:
			lines = f.readlines()

		# Check if the second line is the specified string
		if len(lines) < 2 or yaml_schema_source not in lines[1].strip():
			# Add the specified string as the second line
			lines.insert(1, f"# yaml-language-server: $schema={yaml_schema_source}\n")

			# Write the updated lines back to the file
			with open(file_path, 'w') as f:
				f.writelines(lines)

			print(f"Added second line to {file_path}")

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

for file_type, schema_source in schema_mappings.items():
	process_files(file_type, schema_source)
