#!/bin/bash
# Cleanup script for eShop Observability Stack

echo "🧹 Cleaning up eShop Observability Stack..."
echo ""

# Remove dashboard ConfigMaps
echo "📊 Removing Grafana dashboard configurations..."
kubectl delete configmap grafana-datasources 2>/dev/null || echo "  • grafana-datasources not found"
kubectl delete configmap grafana-dashboards-config 2>/dev/null || echo "  • grafana-dashboards-config not found"
kubectl delete configmap grafana-k6-dashboard 2>/dev/null || echo "  • grafana-k6-dashboard not found"
kubectl delete configmap grafana-api-dashboard 2>/dev/null || echo "  • grafana-api-dashboard not found"

# Remove Prometheus RBAC
echo "🔐 Removing Prometheus RBAC configuration..."
kubectl delete clusterrolebinding prometheus 2>/dev/null || echo "  • prometheus clusterrolebinding not found"
kubectl delete clusterrole prometheus 2>/dev/null || echo "  • prometheus clusterrole not found"
kubectl delete serviceaccount prometheus 2>/dev/null || echo "  • prometheus serviceaccount not found"

# Remove K6 namespace and resources
echo "🧪 Removing K6 testing resources..."
kubectl delete namespace k6-loadtest 2>/dev/null || echo "  • k6-loadtest namespace not found"

echo ""
echo "✅ Observability stack cleanup completed!"
echo ""
echo "ℹ️  Note: Core eShop services (Grafana, Prometheus from aspirate) are preserved"
echo "   These are managed by your AppHost deployment"