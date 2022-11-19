# Automaton

Automaton server is the center of all of the automation that is happening inside the Homelab.

## Services Matrix

|      Service      |            Version             |
| :---------------: | :----------------------------: |
|     `jenkins`     |            `2.371`             |
|      `homer`      |           `v22.08.1`           |
|    `gitlab-ce`    |         `15.4.0-ce.0`          |
|  `gitlab-runner`  |        `ubuntu-v15.2.2`        |
|      `minio`      | `RELEASE.2022-09-25T15-44-53Z` |
|      `vault`      |            `1.11.3`            |
|  `portainer-ce`   |        `2.15.1-alpine`         |
| `portainer-agent` |        `2.15.1-alpine`         |
|     `traefik`     |             `v2.6`             |

## Playbooks

### Config

This playbook will configure the server itself and prepare it both for hosting the required services and for local development of automation pipelines.

To manually run the config scenario, run the following commands from the root of this repo:

``` bash
# Prepare the server
ansible-playbook infra/automaton/config/main.yml
```

### Deploy

This is the main playbook for this server. Once docker is installed and the swarm initialized (by the [config](#config) scenario), this playbook comes in and templatizes all the required files and configurations, copies them to the required locations and then spin up all the services.

To manually run the deploy scenario, run the following commands from the root of this repo:

``` bash
# Deploy all the services
ansible-playbook infra/automaton/deploy/main.yml
```

### Purge

!!! WARNING
    This playbook will **remove everything**.  
    All containers and all data will be lost after running this playbook.

This playbook will run a `docker stack rm` against each service and then a `rm -rf` against their respective data directories. It will completely remove all the services and their data.

To manually run the purge scenario, run the following commands from the root of this repo:

``` bash
# Purge all services
ansible-playbook infra/automaton/start/main.yml
```

### Start

This playbook will create all the services.

Since there is no concept of `docker start` in the context of swarm, the playbook will simply run a `docker stack deploy` against the `docker-compose.yml` file of each service.

To manually run the start scenario, run the following commands from the root of this repo:

``` bash
# Start all the services
ansible-playbook infra/automaton/start/main.yml
```

!!! Note
    Since this playbook does nothing more than a `docker stack deploy -c <path-to-file> <service>`, it requires all the files and data to be in the proper place.  
    As such, this playbook is not what will actually install and do the initial deployment of the services. It will simply handle starting them up if they have been previously stopped with the [stop](#stop) playbook.

### Stop

This playbook will **delete** all services.

Since in the context of docker swarm there is no concept of `docker stop <service>`, what we are doing with this one is simply to run a `docker rm <service>` for each service deployed. Since we have all the data safe via bind mounts outside of the containers, the processes themselves are of no importance so we can remove them.

To manually run the stop scenario, run the following commands from the root of this repo:

``` bash
# Stop all the services
ansible-playbook infra/automaton/stop/main.yml
```

### Backup

The strategy for the backup playbook is simply to syncrhonize the data directory of each docker service to a path mounted on the storage server. A simple `rsync` would do the trick to keep the original and the snapshot in sync.

Once the data has made it into the storage server, it is no longer the responsability of this playbook to version/snapshot it or do anything else. From that point onwards, it is the duty of the storage server.

To manually run the backup scenario, run the following commands from the root of this repo:

``` bash
# Stop all the services
ansible-playbook infra/automaton/stop/main.yml

# Create the backup
ansible-playbook infra/automaton/backup/main.yml

# Start the services back up
ansible-playbook infra/automaton/start/main.yml
```

### Restore

The restore playbook will just make sure to prune the services so that none are running and their data directories are removed. After that, the synced directory created by the [`backup`](#backup) playbook will be synced back, so that the data is restored to the last snapshot.

To manually run the restore scenario, run the following commands from the root of this repo:

``` bash
# Stop all the services and remove all data dirs
ansible-playbook infra/automaton/purge/main.yml

# Restore the current backup
ansible-playbook infra/automaton/restore/main.yml

# Start the services back up
ansible-playbook infra/automaton/start/main.yml
```
