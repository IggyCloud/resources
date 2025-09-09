#!/bin/bash
# Status check script for eShop Observability Stack

echo "📊 eShop Observability Stack Status"
echo "=================================="
echo ""

# Check Prometheus
echo "🔍 Prometheus Status:"
PROM_POD=$(kubectl get pods -l app=prometheus --no-headers -o custom-columns=":metadata.name" 2>/dev/null | head -1)
if [ -n "$PROM_POD" ]; then
    PROM_STATUS=$(kubectl get pod $PROM_POD --no-headers -o custom-columns=":status.phase" 2>/dev/null)
    echo "  • Pod: $PROM_POD ($PROM_STATUS)"
    echo "  • URL: http://localhost:9090"
    
    # Check targets
    TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"up"' | wc -l 2>/dev/null || echo "0")
    echo "  • Healthy targets: $TARGETS"
else
    echo "  • ❌ Prometheus pod not found"
fi
echo ""

# Check Grafana
echo "📈 Grafana Status:"
GRAFANA_POD=$(kubectl get pods -l app=grafana --no-headers -o custom-columns=":metadata.name" 2>/dev/null | head -1)
if [ -n "$GRAFANA_POD" ]; then
    GRAFANA_STATUS=$(kubectl get pod $GRAFANA_POD --no-headers -o custom-columns=":status.phase" 2>/dev/null)
    echo "  • Pod: $GRAFANA_POD ($GRAFANA_STATUS)"
    echo "  • URL: http://localhost:30300 (admin/admin123)"
    
    # Check service type
    SVC_TYPE=$(kubectl get svc grafana --no-headers -o custom-columns=":spec.type" 2>/dev/null)
    echo "  • Service type: $SVC_TYPE"
else
    echo "  • ❌ Grafana pod not found"
fi
echo ""

# Check API Services
echo "🔌 API Services Status:"
for service in catalog-api basket-api webapp ordering-api webhooks-api; do
    POD=$(kubectl get pods -l app=$service --no-headers -o custom-columns=":metadata.name" 2>/dev/null | head -1)
    if [ -n "$POD" ]; then
        STATUS=$(kubectl get pod $POD --no-headers -o custom-columns=":status.phase" 2>/dev/null)
        READY=$(kubectl get pod $POD --no-headers -o custom-columns=":status.containerStatuses[0].ready" 2>/dev/null)
        if [ "$READY" = "true" ]; then
            echo "  • ✅ $service: $STATUS"
        else
            echo "  • ⚠️  $service: $STATUS (not ready)"
        fi
    else
        echo "  • ❌ $service: not found"
    fi
done
echo ""

# Check ConfigMaps
echo "⚙️  Configuration Status:"
CONFIGS=("grafana-datasources" "grafana-dashboards-config" "grafana-k6-dashboard" "grafana-api-dashboard")
for config in "${CONFIGS[@]}"; do
    if kubectl get configmap $config >/dev/null 2>&1; then
        echo "  • ✅ $config"
    else
        echo "  • ❌ $config: not found"
    fi
done
echo ""

# Check RBAC
echo "🔐 RBAC Status:"
if kubectl get clusterrole prometheus >/dev/null 2>&1; then
    echo "  • ✅ prometheus ClusterRole"
else
    echo "  • ❌ prometheus ClusterRole: not found"
fi

if kubectl get clusterrolebinding prometheus >/dev/null 2>&1; then
    echo "  • ✅ prometheus ClusterRoleBinding"
else
    echo "  • ❌ prometheus ClusterRoleBinding: not found"
fi

if kubectl get serviceaccount prometheus >/dev/null 2>&1; then
    echo "  • ✅ prometheus ServiceAccount"
else
    echo "  • ❌ prometheus ServiceAccount: not found"
fi
echo ""

echo "🎯 Quick Links:"
echo "  • Grafana: http://localhost:30300"
echo "  • Prometheus: http://localhost:9090"
echo "  • Catalog API: http://localhost:31386"
echo "  • Prometheus Targets: http://localhost:9090/targets"