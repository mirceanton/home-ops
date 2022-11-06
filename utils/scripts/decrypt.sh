#!/bin/bash

find inventory/{host_vars,extra_vars} "*.yml" \
  -exec sops --decrypt --in-place \
  --age $(cat $SOPS_AGE_KEY_FILE | grep -oP "public key: \K(.*)") {} \;