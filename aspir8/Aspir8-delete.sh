#!/bin/bash
# Complete eShop Infrastructure Destruction Script
# This script removes the entire eShop solution including monitoring and testing infrastructure

echo "🗑️ Starting complete eShop infrastructure destruction..."
echo ""

# Get current directory for restoration
ORIGINAL_DIR=$(pwd)

# Function to restore directory on exit
cleanup() {
    cd "$ORIGINAL_DIR"
}
trap cleanup EXIT

echo "⚠️  WARNING: This will destroy the entire eShop deployment!"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment destruction cancelled."
    exit 1
fi

echo ""

# Stop and cleanup K6 load tests
echo "🧪 Cleaning up K6 load tests..."
kubectl delete namespace k6-loadtest --ignore-not-found=true 2>/dev/null || echo "K6 namespace not found"

# Remove observability stack
echo "📊 Cleaning up observability stack..."
if [ -f "./observability/scripts/cleanup-observability.sh" ]; then
    chmod +x ./observability/scripts/cleanup-observability.sh
    ./observability/scripts/cleanup-observability.sh
else
    echo "  • Removing Grafana..."
    kubectl delete statefulset grafana --ignore-not-found=true
    kubectl delete pvc grafana-data-grafana-0 --ignore-not-found=true
    kubectl delete service grafana --ignore-not-found=true
    kubectl delete configmap grafana-config grafana-datasources grafana-dashboards-config grafana-dashboards-provisioning --ignore-not-found=true
    kubectl delete configmap grafana-api-dashboard grafana-k6-dashboard grafana-enhanced-api-dashboard --ignore-not-found=true
    
    echo "  • Removing Prometheus..."
    kubectl delete statefulset prometheus --ignore-not-found=true
    kubectl delete pvc prometheus-data-prometheus-0 --ignore-not-found=true
    kubectl delete service prometheus --ignore-not-found=true
    kubectl delete configmap prometheus-config --ignore-not-found=true
    kubectl delete serviceaccount prometheus --ignore-not-found=true
    kubectl delete clusterrole prometheus --ignore-not-found=true
    kubectl delete clusterrolebinding prometheus --ignore-not-found=true
fi

# Remove resource limits
echo "⚡ Removing resource limits..."
kubectl delete limitrange default-limit-range --ignore-not-found=true

# Navigate to AppHost directory and cleanup aspirate deployment
echo "🚢 Cleaning up Kubernetes deployment..."
cd ../../src/eShop.AppHost || { echo "Failed to navigate to AppHost directory"; cd "$ORIGINAL_DIR"; }

# Remove aspirate deployment if aspirate is available
if command -v aspirate &> /dev/null; then
    echo "🔧 Running aspirate destroy..."
    aspirate destroy --non-interactive --kube-context "docker-desktop" 2>/dev/null || echo "Aspirate destroy completed or already clean"
else
    echo "  • Aspirate not found, manually cleaning up eShop resources..."
fi

# Return to IggyCloudResources directory
cd ../../../IggyCloudResources

# Manual cleanup of common eShop resources
echo "🧹 Manual cleanup of eShop resources..."

# Remove eShop applications
kubectl delete deployment catalog-api basket-api ordering-api payment-api webapp aspire-dashboard --ignore-not-found=true
kubectl delete service catalog-api basket-api ordering-api payment-api webapp aspire-dashboard --ignore-not-found=true

# Remove databases and infrastructure
kubectl delete statefulset postgres eventbus --ignore-not-found=true
kubectl delete service postgres eventbus --ignore-not-found=true
kubectl delete pvc data-postgres-0 eventbus-data-eventbus-0 --ignore-not-found=true

# Remove configuration
kubectl delete configmap catalog-api-env basket-api-env ordering-api-env payment-api-env webapp-env postgres-env eventbus-env aspire-dashboard-env --ignore-not-found=true

# Remove secrets (if any were created outside aspirate)
kubectl delete secret postgres-secret eventbus-secret --ignore-not-found=true

# Clean up any remaining eShop resources by label (if aspirate adds labels)
echo "🏷️ Cleaning up labeled eShop resources..."
kubectl delete all,configmap,secret,pvc --selector="app.kubernetes.io/part-of=eshop-apphost" --ignore-not-found=true 2>/dev/null || echo "No labeled resources found"

# Stop and remove local Docker registry
echo "🐳 Stopping local Docker registry..."
docker stop registry 2>/dev/null || echo "Registry not running"
docker rm registry 2>/dev/null || echo "Registry container not found"

# Clean up any dangling eShop images
echo "🗑️ Cleaning up eShop Docker images..."
docker images | grep "localhost:6000" | awk '{print $1":"$2}' | xargs -r docker rmi -f 2>/dev/null || echo "No eShop images to clean"

echo ""
echo "✅ Complete eShop infrastructure destruction finished!"
echo ""
echo "📝 Summary of cleaned resources:"
echo "  • All eShop application deployments and services"
echo "  • PostgreSQL and EventBus (RabbitMQ) infrastructure"  
echo "  • Grafana and Prometheus monitoring stack"
echo "  • K6 load testing infrastructure"
echo "  • Local Docker registry and images"
echo "  • Configuration maps and secrets"
echo "  • Persistent volumes and claims"
echo ""
echo "🔍 To verify cleanup, run:"
echo "  kubectl get all,pvc,configmap,secret --all-namespaces | grep -E '(eshop|catalog|basket|ordering|payment|postgres|eventbus|grafana|prometheus)'"
echo ""
echo "🚀 To redeploy, run:"
echo "  ./Aspir8.sh"