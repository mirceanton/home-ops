#!/bin/bash

find inventory -name "*.yml" -type f \
  -exec sops --decrypt --in-place \
  --age $(cat $SOPS_AGE_KEY_FILE | grep -oP "public key: \K(.*)") {} \;