import os
from kubernetes import client, config
import time

node_ip = os.environ.get("NODE_IP")
node_role = os.environ.get("NODE_ROLE")

if not node_ip or not node_role:
	print("NODE_IP and NODE_ROLE environment variables must be set.")
	os._exit(1)

config.load_kube_config()
v1 = client.CoreV1Api()

print(f"Waiting for node {node_ip} to join the cluster ", end="")

while True:
	nodes = v1.list_node(watch=False)
	for node in nodes.items:
		addresses = [addr.address for addr in node.status.addresses if addr.type == "InternalIP"]
		node_roles = [role for role in node.metadata.labels if role.startswith("node-role.kubernetes.io")]

		if node_ip in addresses and node_role in node_roles:
			print("\nOK")
			exit(0)

	print(".", end="", flush=True)
	time.sleep(1)
