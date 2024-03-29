#!/bin/bash

printf "Waiting for node $NODE_IP to join the cluster "

while ! kubectl get nodes -o wide 2>/dev/null | grep $NODE_IP | grep -q $NODE_ROLE >/dev/null 2>/dev/null; do
    printf "."
    sleep 1
done

echo ""
echo "OK"
