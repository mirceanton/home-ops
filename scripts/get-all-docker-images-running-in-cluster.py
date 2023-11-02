from kubernetes import client, config
from tabulate import tabulate

def get_container_image_usage_with_unique_namespaces():
    # Load the Kubernetes configuration from the default location or a kubeconfig file
    config.load_kube_config()

    # Create a dictionary to store container image usage with unique namespaces
    image_usage = {}

    # Create a Kubernetes API client
    api_instance = client.CoreV1Api()

    try:
        # List all namespaces in the cluster
        namespaces = api_instance.list_namespace()

        for namespace in namespaces.items:
            # Get all pods in the current namespace
            pods = api_instance.list_namespaced_pod(namespace.metadata.name)

            for pod in pods.items:
                for container in pod.spec.containers:
                    container_image = container.image

                    # Update the usage counter for the container image
                    if container_image in image_usage:
                        image_usage[container_image]['usage_count'] += 1
                        image_usage[container_image]['namespaces'].add(namespace.metadata.name)
                    else:
                        image_usage[container_image] = {
                            'usage_count': 1,
                            'namespaces': {namespace.metadata.name}
                        }

    except Exception as e:
        print(f"Error: {str(e)}")

    return image_usage

if __name__ == "__main__":
    container_image_usage_with_unique_namespaces = get_container_image_usage_with_unique_namespaces()

    # Sort the images based on count in descending order
    sorted_images = sorted(
        container_image_usage_with_unique_namespaces.items(),
        key=lambda item: item[1]['usage_count'],
        reverse=True
    )

    table_data = []
    
    for image, info in sorted_images:
        count = info['usage_count']
        image_parts = image.split(':')
        image_name, image_tag = image_parts[0], image_parts[1]
        namespaces = ', '.join(info['namespaces'])
        table_data.append([count, image_name, image_tag, namespaces])
    
    # Print the data in a pretty table
    headers = ["COUNT", "IMAGE", "TAG", "NAMESPACE"]
    print(tabulate(table_data, headers, tablefmt="pretty"))
