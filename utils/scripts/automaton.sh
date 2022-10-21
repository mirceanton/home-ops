#!/bin/bash

PROJECT_DIR="/workspace/amir-hlb"
cd $PROJECT_DIR && ansible-playbook infra/automaton/$1/main.yml && cd -
