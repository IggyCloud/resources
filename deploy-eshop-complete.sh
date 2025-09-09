#!/bin/bash
# Complete eShop Deployment with Observability - Infrastructure as Code
# Single script to deploy eShop with monitoring, metrics, and performance testing capability

set -e

echo "🚀 eShop Complete Deployment - Infrastructure as Code"
echo "=================================================="
echo ""

# Configuration
ESHOP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPHOST_DIR="$(dirname "$ESHOP_ROOT")/src/eShop.AppHost"

if [ ! -d "$APPHOST_DIR" ]; then
    echo "❌ AppHost directory not found at: $APPHOST_DIR"
    echo "Please run this script from IggyCloudResources directory"
    exit 1
fi

echo "📁 Working directories:"
echo "  • IggyCloudResources: $ESHOP_ROOT"
echo "  • AppHost: $APPHOST_DIR"
echo ""

# Step 1: Deploy eShop with Aspire/Aspirate
echo "🏗️  Step 1: Deploying eShop Application..."
echo "----------------------------------------"

cd "$APPHOST_DIR"
if command -v aspirate >/dev/null 2>&1; then
    echo "Using aspirate for deployment..."
    aspirate apply --non-interactive || {
        echo "❌ Aspirate deployment failed"
        exit 1
    }
else
    echo "⚠️  Aspirate not found. Please deploy manually with: cd $APPHOST_DIR && aspirate apply"
    echo "Press any key when deployment is complete..."
    read -n 1 -s
fi

cd "$ESHOP_ROOT"

echo "✅ eShop application deployed"
echo ""

# Step 2: Wait for core services
echo "⏳ Step 2: Waiting for core services to be ready..."
echo "------------------------------------------------"

kubectl wait --for=condition=available --timeout=300s deployment/prometheus 2>/dev/null || echo "Prometheus deployment not found (using StatefulSet)"
kubectl wait --for=condition=available --timeout=300s deployment/grafana 2>/dev/null || echo "Grafana deployment not found (using StatefulSet)"

# Wait for StatefulSets if deployments don't exist
kubectl wait --for=condition=ready --timeout=300s statefulset/prometheus 2>/dev/null || echo "Prometheus not ready yet"
kubectl wait --for=condition=ready --timeout=300s statefulset/grafana 2>/dev/null || echo "Grafana not ready yet"

echo "✅ Core services ready"
echo ""

# Step 3: Configure Observability Stack
echo "📊 Step 3: Configuring Observability Stack..."
echo "--------------------------------------------"

echo "  • Applying Grafana configurations..."
kubectl apply -f observability/grafana/consolidated-grafana-config.yaml

echo "  • Deploying monitoring dashboards..."
kubectl apply -f observability/grafana/grafana-k6-dashboard.yaml
kubectl apply -f observability/grafana/grafana-api-dashboard.yaml

echo "  • Configuring Prometheus RBAC..."
bash observability/prometheus/patch-prometheus-rbac.sh

echo "✅ Observability stack configured"
echo ""

# Step 4: Configure Network Access
echo "🌐 Step 4: Configuring Network Access..."
echo "---------------------------------------"

# Apply NodePort patches
bash k8s/patch-nodeports.sh

echo "✅ Network access configured"
echo ""

# Step 5: Apply Resource Limits (Azure B1 equivalent)
echo "⚖️  Step 5: Applying Resource Limits..."
echo "-------------------------------------"

kubectl apply -f k8s/limit-range.yaml

echo "✅ Resource limits applied (Azure App Service B1 equivalent)"
echo ""

# Step 6: Setup Performance Testing
echo "🧪 Step 6: Setting up Performance Testing..."
echo "-------------------------------------------"

# Create k6 namespace and configure
kubectl apply -f k6/k8s/namespace.yaml
kubectl apply -f k6/k8s/

echo "✅ Performance testing configured"
echo ""

# Final Status Check
echo "🎯 Deployment Complete!"
echo "======================="
echo ""
echo "📊 Access URLs:"
echo "  • Grafana:        http://localhost:30300 (admin/admin123)"
echo "  • Prometheus:     http://localhost:9090"
echo "  • eShop Web App:  http://localhost:30080"
echo "  • Catalog API:    http://localhost:31386"
echo ""
echo "📈 Available Dashboards:"
echo "  • K6 Performance: Load testing metrics and performance insights"
echo "  • API Monitoring: .NET API metrics, resource utilization, and health"
echo ""
echo "🧪 Performance Testing:"
echo "  • Run tests: cd k6 && ./run-test.sh catalog-api-open-model-test.js"
echo "  • View results in Grafana K6 dashboard"
echo ""
echo "🔍 Health Check:"
echo "  • Status: ./observability/scripts/status-check.sh"
echo "  • Cleanup: ./observability/scripts/cleanup-observability.sh"
echo ""
echo "✨ Your complete eShop environment with observability is ready!"