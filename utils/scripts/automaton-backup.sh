#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

BACKUP_DIR="/var/log/backup_playbook"
BACKUP_FILE="$BACKUP_DIR/$(date '+%Y-%m-%d-%H-%M-%S').log"

# Make sure backup log dir is created
sudo mkdir -p $BACKUP_DIR

# Stop the services
cd /workspace/amir-hlb && ansible-playbook infra/automaton/stop/main.yml >> $BACKUP_FILE

# # Back up the data
cd /workspace/amir-hlb && ansible-playbook infra/automaton/backup/main.yml >> $BACKUP_FILE

# # Start all the services back up
cd /workspace/amir-hlb && ansible-playbook infra/automaton/start/main.yml >> $BACKUP_FILE