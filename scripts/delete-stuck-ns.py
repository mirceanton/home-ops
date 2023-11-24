from kubernetes import client, config

# Get namespaces in "Terminating" state
config.load_kube_config()
v1 = client.CoreV1Api()

try:
	terminating_namespaces = [ns for ns in v1.list_namespace().items if ns.status.phase == "Terminating"]
	
	# Delete each terminating namespace
	for namespace in terminating_namespaces:
		if 'kubernetes' in namespace.metadata.finalizers:
			namespace.metadata.finalizers.remove('kubernetes')
			v1.replace_namespace_finalizer(namespace.metadata.name, namespace.metadata.finalizers)

except client.exceptions.ApiException as e:
	print(f"Error: {e}")
