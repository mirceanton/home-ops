Virtual Machine: opnSense
=========================

This directory contains the required steps to create a new opnSense VM from scratch:

1. `download/`: an Ansible playbook that will download and unpack the opnSense ISO
2. `template/`: a Packer module that will create an opnSense VM template
3. `provision/`: a Terraform module that will create a new VM based on the template
4. `config/`: an Ansible playbook that will initialize and customize the opnSense instance
