#!/bin/bash
set -euo pipefail
# Complete eShop Infrastructure as Code deployment
# This script deploys the entire eShop solution with monitoring and performance testing

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ESHOP_SRC_DIR="$(cd "${ROOT_DIR}/../src" && pwd)"
APPHOST_DIR="${ESHOP_SRC_DIR}/eShop.AppHost"

echo "[aspir8] Starting complete eShop IaC deployment..."
echo ""

# Start local Docker registry
echo "[aspir8] Starting local Docker registry..."
docker run -d -p 6000:5000 --name registry registry:latest 2>/dev/null || echo "Registry already running"

cd "${APPHOST_DIR}" || { echo "[aspir8] Failed to navigate to AppHost directory"; exit 1; }

echo "[aspir8] Installing aspirate tool..."
dotnet tool install -g aspirate 2>/dev/null || echo "Aspirate already installed"

if [[ -f "${APPHOST_DIR}/aspirate.json" ]]; then
  echo "[aspir8] Skipping aspirate init (configuration already present)..."
else
  echo "[aspir8] Initializing aspirate..."
  aspirate init --non-interactive --container-registry "localhost:6000" --disable-secrets
fi

echo "[aspir8] Generating Kubernetes manifests..."
aspirate generate --non-interactive --disable-secrets --include-dashboard --image-pull-policy "Always"

echo "[aspir8] Deploying to Kubernetes..."
aspirate apply --non-interactive --disable-secrets --kube-context "docker-desktop"

# Apply resource limits
echo "[aspir8] Applying Azure App Service B1 equivalent resource limits..."
cd "${ROOT_DIR}"
kubectl apply -f k8s/limit-range.yaml

echo "[catalog-conn] Ensuring catalog connection string has pooling and timeouts..."
bash ./scripts/patch-catalog-connection.sh

# Configure observability stack
echo "[aspir8] Configuring observability stack..."
./observability/scripts/post-deploy-monitoring.sh

# Apply Profiling (Pyroscope) and Tracing (Tempo)
echo "[aspir8] Applying Pyroscope and Tempo manifests..."
kubectl apply -f observability/pyroscope/pyroscope.yaml
kubectl apply -f observability/tempo/tempo.yaml

echo "OTLP exporters configured via appsettings; skipping ConfigMap patch."

PERF_MODE="${PERF_MODE:-false}"
DEPLOYMENTS=(catalog-api basket-api ordering-api order-processor payment-processor webhooks-api webapp identity-api webhooksclient mobile-bff)

if [[ "${PERF_MODE,,}" == "true" ]]; then
  echo "[aspir8] Enabling telemetry performance mode across deployments..."
  for DEP in "${DEPLOYMENTS[@]}"; do
    if kubectl get deploy "$DEP" >/dev/null 2>&1; then
      kubectl set env deploy "$DEP" Telemetry__PerfMode=true --namespace default --overwrite || true
    fi
  done
else
  echo "[aspir8] Telemetry performance mode disabled (PERF_MODE=${PERF_MODE}). Ensuring flag is removed..."
  for DEP in "${DEPLOYMENTS[@]}"; do
    if kubectl get deploy "$DEP" >/dev/null 2>&1; then
      kubectl set env deploy "$DEP" Telemetry__PerfMode- --namespace default >/dev/null 2>&1 || true
    fi
  done
fi

echo "[aspir8] Applying PostgreSQL tuning profile..."
bash ./scripts/tune-postgres.sh

echo "[aspir8] Ensuring pgBadger sidecars are deployed..."
bash ./scripts/deploy-pgbadger.sh

# Restart API deployments to pick up env changes
echo "[aspir8] Restarting API deployments..."
for DEP in catalog-api basket-api ordering-api payment-processor webhooks-api webapp order-processor; do
  if kubectl get deploy "$DEP" >/dev/null 2>&1; then
    kubectl rollout restart deploy "$DEP"
    kubectl rollout status deploy "$DEP" --timeout=180s || true
  fi
done

# Apply NodePort patches
echo "[aspir8] Configuring NodePort access..."
chmod +x k8s/patch-nodeports.sh
./k8s/patch-nodeports.sh

# Configure additional services as NodePort
echo "[aspir8] Configuring additional NodePort services..."
kubectl patch svc prometheus -p '{"spec":{"type":"NodePort","ports":[{"port":9090,"targetPort":9090,"nodePort":30090,"name":"http"}]}}' 2>/dev/null || echo "Prometheus already configured as NodePort"
kubectl patch svc webapp -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"targetPort":8080,"nodePort":30080,"name":"http"}]}}' 2>/dev/null || echo "WebApp already configured as NodePort"
kubectl patch svc basket-api -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"targetPort":8080,"nodePort":30081,"name":"http"}]}}' 2>/dev/null || echo "Basket API already configured as NodePort"

echo ""

echo "[aspir8] Complete eShop IaC deployment finished!"
echo ""

echo "[aspir8] Access URLs (All NodePort - No Port-forwarding needed):"
echo "  - Grafana: http://localhost:30300 (admin/admin123)"
echo "  - Prometheus: http://localhost:30090"
echo "  - Catalog API: http://localhost:31386"
echo "  - WebApp: http://localhost:30080"
echo "  - Basket API: http://localhost:30081"
echo ""

echo "[aspir8] Performance Testing:"
echo "  cd k6 && ./run-test.sh catalog-api-open-model-test.js"
echo ""

echo "[aspir8] Available Dashboards:"
echo "  - K6 Performance: Load testing metrics"
echo "  - API Monitoring: .NET API performance and resources"
