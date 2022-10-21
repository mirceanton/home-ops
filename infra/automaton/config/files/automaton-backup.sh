#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

PROJECT_DIR="/workspace/amir-hlb"
LOG_DIR="/var/log/automaton_backup"
LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d-%H-%M-%S').log"

# Make sure backup log dir is created
sudo mkdir -p $LOG_DIR

# Stop the services
cd $PROJECT_DIR && ansible-playbook infra/automaton/stop/main.yml >> $LOG_FILE

# # Back up the data
cd $PROJECT_DIR && ansible-playbook infra/automaton/backup/main.yml >> $LOG_FILE

# # Start all the services back up
cd $PROJECT_DIR && ansible-playbook infra/automaton/start/main.yml >> $LOG_FILE