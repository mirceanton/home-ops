#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

PROJECT_DIR="/workspace/amir-hlb"
BACKUP_DIR="/var/log/backup_playbook"
BACKUP_FILE="$BACKUP_DIR/$(date '+%Y-%m-%d-%H-%M-%S').log"

# Make sure backup log dir is created
sudo mkdir -p $BACKUP_DIR

# Stop the services
cd $PROJECT_DIR && ansible-playbook infra/automaton/stop/main.yml >> $BACKUP_FILE

# # Back up the data
cd $PROJECT_DIR && ansible-playbook infra/automaton/backup/main.yml >> $BACKUP_FILE

# # Start all the services back up
cd $PROJECT_DIR && ansible-playbook infra/automaton/start/main.yml >> $BACKUP_FILE