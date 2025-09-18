#!/bin/bash
# Post-deployment script to configure eShop Observability Stack
# This script should be run AFTER aspirate deployment to configure Prometheus and Grafana properly

echo "🚀 Configuring eShop Observability Stack..."
echo ""

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBSERVABILITY_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 Working from: $OBSERVABILITY_ROOT"
echo ""

# Step 1: Apply consolidated Grafana configuration for default namespace
echo "📊 Applying Grafana dashboard configurations..."
kubectl apply -f "$OBSERVABILITY_ROOT/grafana/grafana-config.yaml"

# Step 2: Apply dashboard ConfigMaps  
echo "📈 Applying K6 and API monitoring dashboards..."
kubectl apply -f "$OBSERVABILITY_ROOT/grafana/k6-dashboard.yaml"
kubectl apply -f "$OBSERVABILITY_ROOT/grafana/api-dashboard.yaml"

# Step 3: Configure Prometheus RBAC for service discovery
echo "🔐 Configuring Prometheus RBAC for Kubernetes service discovery..."
bash "$OBSERVABILITY_ROOT/prometheus/patch-prometheus-rbac.sh"

# Step 4: Patch services to NodePort (if needed)
echo "🌐 Configuring NodePort access..."
kubectl patch svc grafana -p '{"spec":{"type":"NodePort","ports":[{"port":3000,"targetPort":3000,"nodePort":30300,"name":"http"}]}}' 2>/dev/null || echo "Grafana already configured as NodePort"
kubectl patch svc catalog-api -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"targetPort":8080,"nodePort":31386,"name":"http"},{"port":8443,"targetPort":8443,"name":"https"}]}}' 2>/dev/null || echo "Catalog-api already configured as NodePort"

echo ""
echo "✅ Monitoring stack configuration completed!"
echo ""
echo "🎯 Access URLs:"
echo "  • Grafana: http://localhost:30300 (admin/admin123)"
echo "  • Prometheus: http://localhost:9090"
echo "  • Catalog API: http://localhost:31386"
echo ""
echo "📋 Available Dashboards in Grafana:"
echo "  • K6 Performance folder: K6 load testing metrics"
echo "  • API Monitoring folder: .NET API performance and resource monitoring"
echo ""
echo "💡 Next steps:"
echo "  1. Run k6 tests: cd k6 && ./run-test.sh catalog-api-open-model-test.js"
echo "  2. View metrics in Grafana dashboards"
echo "  3. Monitor API performance in real-time"
echo ""
echo "🔍 Troubleshooting:"
echo "  • Check Prometheus targets: curl http://localhost:9090/targets"
echo "  • Verify API metrics: curl http://localhost:31386/metrics"
echo "  • View logs: kubectl logs -l app=prometheus"