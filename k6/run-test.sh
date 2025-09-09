#!/bin/bash

# Check if script name is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <script-name.js>"
    echo "Available scripts:"
    ls scripts/*.js 2>/dev/null | xargs -n 1 basename
    exit 1
fi

SCRIPT_NAME=$1

# Validate script exists
if [ ! -f "scripts/$SCRIPT_NAME" ]; then
    echo "Error: Script 'scripts/$SCRIPT_NAME' not found!"
    echo "Available scripts:"
    ls scripts/*.js 2>/dev/null | xargs -n 1 basename
    exit 1
fi

echo "Running K6 test with script: $SCRIPT_NAME"

# Delete existing job and configmap
kubectl delete job k6-load-test -n k6-loadtest --ignore-not-found=true
kubectl delete configmap k6-scripts -n k6-loadtest --ignore-not-found=true

# Create ConfigMap from scripts directory
kubectl create configmap k6-scripts --from-file=scripts/ -n k6-loadtest

# Create temporary job file with the script name substituted
sed "s|/scripts/catalog-api-open-model-test.js|/scripts/$SCRIPT_NAME|g" k8s/k6-job.yaml > /tmp/k6-job-temp.yaml

# Create new k6 job
kubectl apply -f /tmp/k6-job-temp.yaml

# Clean up temporary fileznajdz 
rm /tmp/k6-job-temp.yaml

echo "K6 test started. Monitor with:"
echo "kubectl logs -f job/k6-load-test -n k6-loadtest"
echo "View results: http://localhost:30300"
echo "Press any key to continue..."
read -n 1 -s