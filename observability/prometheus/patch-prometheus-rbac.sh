#!/bin/bash
# Post-deployment script to configure Prometheus RBAC for Kubernetes service discovery

echo "Configuring Prometheus RBAC for Kubernetes service discovery..."

# Create ServiceAccount for Prometheus if it doesn't exist
kubectl get serviceaccount prometheus > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating Prometheus ServiceAccount..."
    kubectl create serviceaccount prometheus
else
    echo "Prometheus ServiceAccount already exists"
fi

# Create ClusterRole for Prometheus
echo "Creating/updating ClusterRole for Prometheus..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources:
  - nodes
  - nodes/proxy
  - services
  - endpoints
  - pods
  verbs: ["get", "list", "watch"]
- apiGroups:
  - extensions
  resources:
  - ingresses
  verbs: ["get", "list", "watch"]
EOF

# Create ClusterRoleBinding for Prometheus
echo "Creating/updating ClusterRoleBinding for Prometheus..."
kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: prometheus
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: prometheus
subjects:
- kind: ServiceAccount
  name: prometheus
  namespace: default
EOF

# Patch Prometheus StatefulSet to use the ServiceAccount
echo "Patching Prometheus StatefulSet to use ServiceAccount..."
kubectl patch statefulset prometheus -p '{"spec":{"template":{"spec":{"serviceAccountName":"prometheus"}}}}'

# Restart Prometheus to apply RBAC changes
echo "Restarting Prometheus to apply RBAC changes..."
kubectl rollout restart statefulset/prometheus

echo "Waiting for Prometheus to be ready..."
kubectl rollout status statefulset/prometheus

echo "Prometheus RBAC configuration completed successfully!"
echo ""
echo "Prometheus should now be able to discover and scrape Kubernetes services."
echo "Check Prometheus targets at: http://localhost:9090/targets"