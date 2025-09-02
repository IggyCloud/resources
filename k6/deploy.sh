#!/bin/bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n k6-loadtest
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n k6-loadtest
echo "Grafana: http://localhost:30300 (admin/admin123)"
echo "Prometheus: http://localhost:30090"
echo "Press any key to continue..."
read -n 1 -s