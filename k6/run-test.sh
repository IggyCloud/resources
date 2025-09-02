#!/bin/bash
# Delete existing job and configmap
kubectl delete job k6-load-test -n k6-loadtest --ignore-not-found=true
kubectl delete configmap k6-scripts -n k6-loadtest --ignore-not-found=true

# Create ConfigMap from scripts directory
kubectl create configmap k6-scripts --from-file=scripts/ -n k6-loadtest

# Create new k6 job
kubectl apply -f k8s/k6-job.yaml

echo "K6 test started. Monitor with:"
echo "kubectl logs -f job/k6-load-test -n k6-loadtest"
echo "View results: http://localhost:30300"
echo "Press any key to continue..."
read -n 1 -s