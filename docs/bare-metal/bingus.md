# Bingus

Bingus is the name of my main production server. It is a bare-metal installation of Proxmox VE. As such, in this directory we assume the hypervisor is already installed and that some basic network connectivity is in place for the controller node to reach it.

As such, there should be a few playbooks in this directory, to cover the main aspects:

- `configure.yaml` -> will run all the setup and initial configuration tasks to prepare the server(s) to host VMs
- `backup.yaml` -> will back up any important data on the host to the backup server


``` yaml
infra:
  bingus:
    scripts:
      - configure.yaml
      - backup.yaml
```

> Note that in this directory, no VMs or Containers are deployed on the server. This will just handle basic management of the host OS.
