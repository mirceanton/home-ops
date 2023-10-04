#!/bin/bash

printf "Waiting for the kubelet to become healthy on Talos node $NODE_IP "

while true; do
    output=$(talosctl dmesg -n $NODE_IP 2>&1)

    if echo "$output" | grep -Fq "service[kubelet](Running): Health check successful"; then
        echo ""
        echo "Kubelet is Healthy on node $NODE_IP!"
        break
    else
        printf "."
        sleep 1
    fi
done
