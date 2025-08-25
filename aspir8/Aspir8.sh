docker run -d -p 6000:5000 --name registry registry:latest
dotnet tool install -g aspirate
aspirate init --non-interactive --container-registry "localhost:6000" --disable-secrets
aspirate generate --non-interactive --disable-secrets --include-dashboard --image-pull-policy "Always"
aspirate apply --non-interactive --disable-secrets --kube-context "docker-desktop"

kubectl port-forward service/webapp 8080:8080 & \
kubectl port-forward service/aspire-dashboard 18888:18888

# Destroy existing deployment
aspirate destroy --non-interactive --kube-context "docker-desktop"