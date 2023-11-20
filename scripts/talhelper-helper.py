import yaml
import os
import argparse

def bootstrap_config_command(ip_address, cluster_name, hostname):
    return f"talosctl apply-config --talosconfig=clusterconfig/talosconfig --nodes={ip_address} --file=./clusterconfig/{cluster_name}-{hostname}.yaml --insecure;"

def apply_config_command(ip_address, cluster_name, hostname):
    return f"talosctl apply-config --talosconfig=clusterconfig/talosconfig --nodes={ip_address} --file=./clusterconfig/{cluster_name}-{hostname}.yaml;"

def wait_node_command(ip_address, root_dir):
    return f"NODE_IP={ip_address} bash {root_dir}/scripts/talos-wait-node-kubelet-healthy.sh"

def reset_command(ip_address):
    return f"talosctl reset --reboot --graceful=false --wipe-mode=all --wait=false -n {ip_address}"

def shutdown_command(ip_address, root_dir):
    return f"talosctl shutdown --wait=false -n {ip_address}"

def parse_args():
    parser = argparse.ArgumentParser(description="Generate talosctl commands with different flags.")
    parser.add_argument("--bootstrap", action="store_true", help="Generate apply-config --insecure commands.")
    parser.add_argument("--apply", action="store_true", help="Generate apply-config commands.")
    parser.add_argument("--wait", action="store_true", help="Generate wait commands.")
    parser.add_argument("--reset-worker", action="store_true", help="Generate reset commands for workers.")
    parser.add_argument("--reset-controlplane", action="store_true", help="Generate reset commands for control planes.")
    parser.add_argument("--shutdown-worker", action="store_true", help="Generate shutdown commands for workers.")
    parser.add_argument("--shutdown-controlplane", action="store_true", help="Generate shutdown commands for control planes.")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()

    yaml_file = "talconfig.yaml"

    with open(yaml_file, "r") as file:
        config = yaml.safe_load(file)

    cluster_name = config["clusterName"]
    workers = [node for node in config["nodes"] if not node.get("controlPlane", False)]
    controlPlanes = [node for node in config["nodes"] if node.get("controlPlane", False)]

    for node in config["nodes"]:
        hostname = node["hostname"]
        ip_address = node["ipAddress"]

        if args.bootstrap:
            print(bootstrap_config_command(ip_address, cluster_name, hostname))
        elif args.apply:
            print(apply_config_command(ip_address, cluster_name, hostname))
        elif args.wait:
            root_dir = os.environ['ROOT_DIR']
            print(wait_node_command(ip_address, root_dir))
        elif args.reset_worker:
            print(reset_command(ip_address))
        elif args.reset_controlplane:
            print(reset_command(ip_address))
        elif args.shutdown_worker:
            root_dir = os.environ['ROOT_DIR']
            print(shutdown_command(ip_address, root_dir))
        elif args.shutdown_controlplane:
            root_dir = os.environ['ROOT_DIR']
            print(shutdown_command(ip_address, root_dir))
        else:
            print("Please specify at least one flag. Use --help for usage information.")
