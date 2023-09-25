#!/bin/bash

printf "Waiting for the kubernetes node to become ready: $NODE_IP "

while true; do
    output=$(talosctl get nodestatuses.kubernetes.talos.dev -n  $NODE_IP --output=yaml | grep -q "nodeReady: true" 2>&1)
    exit_status=$?

    if [ $exit_status -eq 0 ]; then
        echo ""
        echo "Node has joined the cluster and is ready: $NODE_IP"
        break
    else
        printf "."
        sleep 1
    fi
done
