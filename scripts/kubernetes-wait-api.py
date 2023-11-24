from kubernetes import client, config
import time

config.load_kube_config()
v1 = client.CoreV1Api()

print("Waiting for the Kubernetes API to become available ", end="")
while True:
	try:
		v1.list_node(watch=False)
		print("\nOK")
		exit(1)
	except Exception as e:
		print(".", end="", flush=True)
		time.sleep(1)
