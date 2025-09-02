#!/bin/bash
kubectl delete namespace k6-loadtest --ignore-not-found=true
kubectl delete pv influxdb-pv grafana-pv --ignore-not-found=true
echo "Cleanup complete"
echo "Press any key to continue..."
read -n 1 -s