# The `./infra/` directory

The infra directory will hold one directory per main infrastructure component. An infrastructure component is either a bare-metal OS installation (say, for example, a system running Ubuntu or Windows) or a platform for hosting services (such as Kubernetes, Proxmox VE, Docker/Docker Swarm etc.).

For any bare-metal installed system, the directory will have Ansible Playbooks that will configure it.

For any platform, the directory will most likely hold Terraform and Packer scripts to provision the hosts (if required) and then Ansible Playbooks to configure the hosts. Additionally, one or more Ansible Playbooks will also be present in order to configure the service running on the host that makes it a platform (for example to configure the k3s/k8s cluster or docker swarm cluster).
