# Docker Swarm Central

The core Docker Swarm cluster is a 3-node docker cluster running on 2Gb Raspberry Pi 4 devices. As such, the playbooks required for this cluster will include:

- `configure.yaml` -> will run all the setup and initial configuration tasks to prepare the base OS
- `backup.yaml` -> will back up any important data on the host to the backup server
- `restore.yaml` -> will restore the latest (or the specified) backup from the backup server
- `install.yaml` -> will actually install and configure Docker Swarm on the Pis
- `uninstall.yaml` -> will clean the OS from anything Docker related

> Note that in this directory, no services or applications are deployed on the cluster. This is just for the management of the host OS.

``` yaml
infra:
  dsc:
    scripts:
      configure:
        - configure.yaml
      backup:
        - backup.yaml
      restore:
        - restore.yaml
      install:
        - install.yaml
      uninstall:
        - uninstall.yaml
    - configure.Jenkinsfile
    - backup.Jenkinsfile
    - restore.Jenkinsfile
    - install.Jenkinsfile
    - uninstall.Jenkinsfile
```