import subprocess
import time
import sys
import os

node_ip = os.environ.get("NODE_IP")
if not node_ip:
	print("NODE_IP environment variable must be set.")
	exit(1)

print(f"Waiting for the kubelet to become healthy on Talos node {node_ip} ", end="")
while True:
	try:
		output = subprocess.check_output(["talosctl", "dmesg", "-n", node_ip], stderr=subprocess.STDOUT, text=True)
		if "service[kubelet](Running): Health check successful" in output:
			print(f"\nKubelet is Healthy on node {node_ip}!")
			break
		else:
			print(".", end="", flush=True)
			time.sleep(1)

	except subprocess.CalledProcessError as e:
		print(f"\nError: {e.output.strip()}")
		sys.exit(1)
