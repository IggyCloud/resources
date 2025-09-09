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
cd ../../../IggyCloudResources
kubectl apply -f k8s/limit-range.yaml

# Configure observability stack
echo "📊 Configuring observability stack..."
./observability/scripts/post-deploy-monitoring.sh

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