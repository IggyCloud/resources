#!/bin/bash

echo "Patching services to NodePort..."

# Patch Grafana service to NodePort 30300
kubectl patch svc grafana -p '{"spec":{"type":"NodePort","ports":[{"port":3000,"targetPort":3000,"nodePort":30300,"name":"http"}]}}'

# Patch Catalog-API service to NodePort 31386  
kubectl patch svc catalog-api -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"targetPort":8080,"nodePort":31386,"name":"http"},{"port":8443,"targetPort":8443,"name":"https"}]}}'

echo "NodePort services configured:"
kubectl get svc grafana catalog-api