#!/bin/bash

printf "Waiting for the Kubernetes API to become available"

while ! kubectl get nodes >/dev/null 2>/dev/null; do
    printf "."
    sleep 1;
done

echo ""
echo "OK"
