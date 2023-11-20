import yaml

yaml_file = "talconfig.yaml"

with open(yaml_file, "r") as file:
    config = yaml.safe_load(file)

# Extract cluster configuration
cluster_name = config["clusterName"]

# Apply config
for node in config["nodes"]:
    hostname = node["hostname"]
    ip_address = node["ipAddress"]

    # Execute talosctl command
    print(
        f"talosctl apply-config --talosconfig=clusterconfig/talosconfig --nodes={ip_address} --file=./clusterconfig/{cluster_name}-{hostname}.yaml --insecure;"
    )
