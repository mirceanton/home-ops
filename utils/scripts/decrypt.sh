#!/bin/bash

find inventory/host_vars -name "*.yml" -exec sops --decrypt --in-place --age $(cat $SOPS_AGE_KEY_FILE | grep -oP "public key: \K(.*)") {} \;