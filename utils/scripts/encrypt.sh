#!/bin/bash

find inventory/{host_vars,extra_vars} -name "*.yml" \
  -exec sops --encrypt --in-place \
  --age $(cat $SOPS_AGE_KEY_FILE | grep -oP "public key: \K(.*)") \
  --encrypted-regex '(ansible_host|ansible_user|pass|token)' {} \;