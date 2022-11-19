# Changelog

## v1.0.0 (TBD)

**Infra**:

- Automaton
  - Implemented backup & restore playbooks
  - Implemented config & deploy playbooks
  - Implemented start & stop playbooks
  - Implemented purge playbook
- Proxmox/Bingus:
  - Implemented initial-setup playbook

**Virtual-Machines**:

- opnSense
  - Implemented Ansible playbook to download the required ISO
  - Implemented VM provisioning via Packer and Terraform
  - Implemented Ansible playbook to auto-configure the firewall

**Docs**:

- Added documentation related to Automaton playbooks and services
- Added documentation related to the PVE playbooks
