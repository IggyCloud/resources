#!/bin/bash

# PostgreSQL Monitoring Validation Script
# This script validates the end-to-end PostgreSQL monitoring pipeline

set -e

echo "========================================"
echo "PostgreSQL Monitoring Validation Script"
echo "========================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed or not in PATH${NC}"
    exit 1
fi

echo "1. Checking PostgreSQL Exporter Pod Status..."
PG_EXPORTER_POD=$(kubectl get pods -l app=postgres-exporter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$PG_EXPORTER_POD" ]; then
    print_status 1 "PostgreSQL Exporter pod not found"
    exit 1
else
    PG_EXPORTER_STATUS=$(kubectl get pod $PG_EXPORTER_POD -o jsonpath='{.status.phase}')
    if [ "$PG_EXPORTER_STATUS" = "Running" ]; then
        print_status 0 "PostgreSQL Exporter pod is running ($PG_EXPORTER_POD)"
    else
        print_status 1 "PostgreSQL Exporter pod is not running (Status: $PG_EXPORTER_STATUS)"
        exit 1
    fi
fi

echo ""
echo "2. Checking PostgreSQL Exporter Service..."
PG_EXPORTER_SVC=$(kubectl get svc postgres-exporter -o jsonpath='{.metadata.name}' 2>/dev/null || echo "")
if [ -z "$PG_EXPORTER_SVC" ]; then
    print_status 1 "PostgreSQL Exporter service not found"
    exit 1
else
    NODEPORT=$(kubectl get svc postgres-exporter -o jsonpath='{.spec.ports[0].nodePort}')
    print_status 0 "PostgreSQL Exporter service exists (NodePort: $NODEPORT)"
fi

echo ""
echo "3. Testing PostgreSQL Exporter Metrics Endpoint..."
# Test metrics endpoint via port-forward
kubectl port-forward svc/postgres-exporter 9187:9187 &
PF_PID=$!
sleep 3

if curl -s http://localhost:9187/metrics > /dev/null; then
    print_status 0 "PostgreSQL Exporter metrics endpoint is accessible"

    # Check for specific PostgreSQL metrics
    if curl -s http://localhost:9187/metrics | grep -q "pg_up"; then
        print_status 0 "PostgreSQL connection metrics available"
    else
        print_status 1 "PostgreSQL connection metrics not found"
    fi

    if curl -s http://localhost:9187/metrics | grep -q "pg_stat_database"; then
        print_status 0 "PostgreSQL database statistics available"
    else
        print_warning "PostgreSQL database statistics not found - check exporter configuration"
    fi
else
    print_status 1 "PostgreSQL Exporter metrics endpoint is not accessible"
fi

# Kill port-forward
kill $PF_PID 2>/dev/null || true

echo ""
echo "4. Checking Prometheus Configuration..."
PROMETHEUS_POD=$(kubectl get pods -l app=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$PROMETHEUS_POD" ]; then
    print_warning "Prometheus pod not found - skipping configuration check"
else
    print_status 0 "Prometheus pod found ($PROMETHEUS_POD)"
fi

echo ""
echo "5. Testing Prometheus Scraping..."
if [ -n "$PROMETHEUS_POD" ]; then
    kubectl port-forward svc/prometheus 9090:9090 &
    PF_PID=$!
    sleep 3

    # Check if prometheus can reach postgres-exporter target
    if curl -s "http://localhost:9090/api/v1/targets" | grep -q "postgres-exporter"; then
        TARGET_STATUS=$(curl -s "http://localhost:9090/api/v1/targets" | jq -r '.data.activeTargets[] | select(.labels.job=="postgres-exporter") | .health')
        if [ "$TARGET_STATUS" = "up" ]; then
            print_status 0 "Prometheus is successfully scraping PostgreSQL Exporter"
        else
            print_status 1 "Prometheus target for PostgreSQL Exporter is down"
        fi
    else
        print_status 1 "PostgreSQL Exporter target not found in Prometheus"
    fi

    # Check for PostgreSQL metrics in Prometheus
    if curl -s "http://localhost:9090/api/v1/query?query=up{job=\"postgres-exporter\"}" | grep -q "\"value\""; then
        print_status 0 "PostgreSQL metrics available in Prometheus"
    else
        print_status 1 "PostgreSQL metrics not available in Prometheus"
    fi

    # Kill port-forward
    kill $PF_PID 2>/dev/null || true
fi

echo ""
echo "6. Checking Grafana Dashboard..."
GRAFANA_POD=$(kubectl get pods -l app=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -z "$GRAFANA_POD" ]; then
    print_warning "Grafana pod not found - skipping dashboard check"
else
    print_status 0 "Grafana pod found ($GRAFANA_POD)"

    # Check if grafana config contains postgres dashboard
    if kubectl get configmap grafana-enhanced-api-dashboard -o yaml | grep -q "PostgreSQL"; then
        print_status 0 "PostgreSQL dashboard configuration found"
    else
        print_warning "PostgreSQL dashboard configuration might be missing"
    fi
fi

echo ""
echo "========================================"
echo "Validation Complete!"
echo "========================================"

# Provide NodePort access information
if [ -n "$NODEPORT" ]; then
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo ""
    echo "External Access Information:"
    echo "PostgreSQL Exporter: http://$NODE_IP:$NODEPORT/metrics"
    echo ""
    echo "To access from outside the cluster:"
    echo "kubectl get nodes -o wide  # Get external IP"
    echo "curl http://EXTERNAL_IP:$NODEPORT/metrics"
fi

echo ""
echo "Next Steps:"
echo "1. If any checks failed, review the error messages above"
echo "2. Redeploy the updated configurations if needed"
echo "3. The PostgreSQL Exporter is now accessible via NodePort $NODEPORT"
echo "4. Prometheus will automatically discover and scrape the postgres-exporter service"