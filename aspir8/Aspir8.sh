#!/bin/bash
# Complete eShop Infrastructure as Code deployment
# This script deploys the entire eShop solution with monitoring and performance testing

echo "🚀 Starting complete eShop IaC deployment..."
echo ""

# Start local Docker registry
echo "🐳 Starting local Docker registry..."
docker run -d -p 6000:5000 --name registry registry:latest 2>/dev/null || echo "Registry already running"

# Navigate to AppHost directory
cd ../../src/eShop.AppHost || { echo "Failed to navigate to AppHost directory"; exit 1; }

# Install and configure aspirate
echo "⚙️ Installing aspirate tool..."
dotnet tool install -g aspirate 2>/dev/null || echo "Aspirate already installed"

echo "🔧 Initializing aspirate..."
aspirate init --non-interactive --container-registry "localhost:6000" --disable-secrets

echo "📦 Generating Kubernetes manifests..."
aspirate generate --non-interactive --disable-secrets --include-dashboard --image-pull-policy "Always"

echo "🚢 Deploying to Kubernetes..."
aspirate apply --non-interactive --disable-secrets --kube-context "docker-desktop"

# Apply resource limits
echo "⚡ Applying Azure App Service B1 equivalent resource limits..."
cd ../../IggyCloudResources
kubectl apply -f k8s/limit-range.yaml

# Configure observability stack
echo "📊 Configuring observability stack..."
./observability/scripts/post-deploy-monitoring.sh

# Apply Profiling (Pyroscope) and Tracing (Tempo)
echo "📦 Applying Pyroscope and Tempo manifests..."
kubectl apply -f observability/pyroscope/pyroscope.yaml
kubectl apply -f observability/tempo/tempo.yaml

# Point APIs to Tempo via OTLP (no image changes, uses existing OTEL exporter)
echo "🔧 Pointing APIs to Tempo OTLP endpoint..."
for CM in catalog-api-env basket-api-env ordering-api-env payment-api-env webapp-env; do
  if kubectl get configmap "$CM" >/dev/null 2>&1; then
    kubectl patch configmap "$CM" --type merge -p '{"data":{"OTEL_EXPORTER_OTLP_ENDPOINT":"http://tempo:4317","OTEL_EXPORTER_OTLP_PROTOCOL":"grpc"}}' || true
  fi
done

# Reconcile PostgreSQL password and set Catalog API connection string accordingly
echo "🔐 Reconciling PostgreSQL password for Catalog API..."
PG_POD=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [[ -n "$PG_POD" ]]; then
  # Candidate 1: password from current postgres-env
  NEW_PG_PASS=$(kubectl get configmap postgres-env -o jsonpath='{.data.POSTGRES_PASSWORD}' 2>/dev/null)
  # Candidate 2: known legacy value used previously in this repo
  LEGACY_PG_PASS="5mt1gDF2B6cNmsrjygTZVz"
  WORKING_PASS=""
  if [[ -n "$NEW_PG_PASS" ]]; then
    if kubectl exec "$PG_POD" -- bash -lc "PGPASSWORD='$NEW_PG_PASS' psql -U postgres -h 127.0.0.1 -tAc 'SELECT 1'" >/dev/null 2>&1; then
      WORKING_PASS="$NEW_PG_PASS"
    fi
  fi
  if [[ -z "$WORKING_PASS" ]]; then
    if kubectl exec "$PG_POD" -- bash -lc "PGPASSWORD='$LEGACY_PG_PASS' psql -U postgres -h 127.0.0.1 -tAc 'SELECT 1'" >/dev/null 2>&1; then
      WORKING_PASS="$LEGACY_PG_PASS"
    fi
  fi
  if [[ -n "$WORKING_PASS" ]] && kubectl get configmap catalog-api-env >/dev/null 2>&1; then
    kubectl patch configmap catalog-api-env --type merge -p "{\"data\":{\"ConnectionStrings__catalogdb\":\"Host=postgres;Port=5432;Username=postgres;Password=$WORKING_PASS;Database=catalogdb\"}}" || true
  else
    echo "⚠️  Could not determine working Postgres password; skipping catalog-api connection patch"
  fi
fi

# Restart API deployments to pick up env changes
echo "🔄 Restarting API deployments..."
for DEP in catalog-api basket-api ordering-api payment-api webapp; do
  if kubectl get deploy "$DEP" >/dev/null 2>&1; then
    kubectl rollout restart deploy "$DEP"
    kubectl rollout status deploy "$DEP" --timeout=180s || true
  fi
done

# Apply NodePort patches
echo "🌐 Configuring NodePort access..."
chmod +x k8s/patch-nodeports.sh
./k8s/patch-nodeports.sh

# Configure additional services as NodePort
echo "🌐 Configuring additional NodePort services..."
kubectl patch svc prometheus -p '{"spec":{"type":"NodePort","ports":[{"port":9090,"targetPort":9090,"nodePort":30090,"name":"http"}]}}' 2>/dev/null || echo "Prometheus already configured as NodePort"
kubectl patch svc webapp -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"targetPort":8080,"nodePort":30080,"name":"http"}]}}' 2>/dev/null || echo "WebApp already configured as NodePort"
kubectl patch svc basket-api -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"targetPort":8080,"nodePort":30081,"name":"http"}]}}' 2>/dev/null || echo "Basket API already configured as NodePort"

echo ""
echo "✅ Complete eShop IaC deployment finished!"
echo ""
echo "🎯 Access URLs (All NodePort - No Port-forwarding needed):"
echo "  • Grafana: http://localhost:30300 (admin/admin123)"
echo "  • Prometheus: http://localhost:30090"  
echo "  • Catalog API: http://localhost:31386"
echo "  • WebApp: http://localhost:30080"
echo "  • Basket API: http://localhost:30081"
echo ""
echo "🧪 Performance Testing:"
echo "  cd k6 && ./run-test.sh catalog-api-open-model-test.js"
echo ""
echo "📊 Available Dashboards:"
echo "  • K6 Performance: Load testing metrics"
echo "  • API Monitoring: .NET API performance and resources"

