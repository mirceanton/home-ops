#!/bin/bash

# Must prefix with sudo when calling script
if [[ $(id -u) -ne 0 ]]; then
    echo "I need sudo privileges!"
    exit 99
fi

# Export Variables
SOPS_ARCH=$(dpkg --print-architecture)
SOPS_VERSION=3.7.3

# Download release from Github
wget "https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.${SOPS_ARCH}"

# Rename downloaded release and move it to local bin dir
mv sops-v${SOPS_VERSION}.linux.${SOPS_ARCH} /usr/local/bin/sops

# Make file executable
chmod +x /usr/local/bin/sops
