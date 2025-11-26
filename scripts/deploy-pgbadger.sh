#!/usr/bin/env bash
set -euo pipefail

STATEFULSET="postgres"
NODEPORT="${PG_BADGER_NODEPORT:-30305}"

container_names=$(kubectl get statefulset ${STATEFULSET} -o jsonpath="{range .spec.template.spec.containers[*]}{.name}{' '} {end}" 2>/dev/null)
if echo "$container_names" | grep -qw pgbadger; then
  echo "[pgbadger] Sidecar already present; enforcing pgBadger command args..."
  read -r -d '' EXISTING_PATCH <<'EOF' || true
{"spec":{"template":{"spec":{"containers":[{"name":"pgbadger","command":["/bin/sh","-c"],"args":["mkdir -p /pgbadger && while true; do if ls /var/lib/postgresql/data/pg_log/*.log 1>/dev/null 2>&1; then pgbadger -f stderr -p '%m [%p] ' /var/lib/postgresql/data/pg_log/*.log -o /pgbadger/index.html; else echo '[pgbadger] waiting for log files'; fi; sleep 300; done"],"image":"dalibo/pgbadger:latest","imagePullPolicy":"IfNotPresent","volumeMounts":[{"name":"eshop-apphost-70ba1f416c-postgres-data","mountPath":"/var/lib/postgresql/data","readOnly":true},{"name":"pgbadger-output","mountPath":"/pgbadger"}]}]}}}}
EOF
  kubectl patch statefulset ${STATEFULSET} --type strategic -p "${EXISTING_PATCH}"
  kubectl rollout restart statefulset ${STATEFULSET}
  kubectl rollout status statefulset ${STATEFULSET} --timeout=180s
else
  echo "[pgbadger] Adding emptyDir volume for HTML output..."
  volumes=$(kubectl get statefulset ${STATEFULSET} -o jsonpath="{.spec.template.spec.volumes}" 2>/dev/null)
  if [[ -z "$volumes" ]]; then
    kubectl patch statefulset ${STATEFULSET} --type json -p '[{"op":"add","path":"/spec/template/spec/volumes","value":[{"name":"pgbadger-output","emptyDir":{}}]}]'
  else
    kubectl patch statefulset ${STATEFULSET} --type json -p '[{"op":"add","path":"/spec/template/spec/volumes/-","value":{"name":"pgbadger-output","emptyDir":{}}}]'
  fi

  echo "[pgbadger] Adding pgBadger generator sidecar..."
  read -r -d '' SIDECAR_PATCH <<'EOF' || true
[{"op":"add","path":"/spec/template/spec/containers/-","value":{"name":"pgbadger","image":"dalibo/pgbadger:latest","imagePullPolicy":"IfNotPresent","command":["/bin/sh","-c"],"args":["mkdir -p /pgbadger && while true; do if ls /var/lib/postgresql/data/pg_log/*.log 1>/dev/null 2>&1; then pgbadger -f stderr -p '%m [%p] ' /var/lib/postgresql/data/pg_log/*.log -o /pgbadger/index.html; else echo '[pgbadger] waiting for log files'; fi; sleep 300; done"],"volumeMounts":[{"name":"eshop-apphost-70ba1f416c-postgres-data","mountPath":"/var/lib/postgresql/data","readOnly":true},{"name":"pgbadger-output","mountPath":"/pgbadger"}]}}]
EOF
  kubectl patch statefulset ${STATEFULSET} --type json -p "${SIDECAR_PATCH}"

  echo "[pgbadger] Adding nginx sidecar for serving reports..."
  kubectl patch statefulset ${STATEFULSET} --type json -p '[{"op":"add","path":"/spec/template/spec/containers/-","value":{"name":"pgbadger-server","image":"nginx:1.27-alpine","imagePullPolicy":"IfNotPresent","ports":[{"containerPort":80,"name":"pgbadger"}],"volumeMounts":[{"name":"pgbadger-output","mountPath":"/usr/share/nginx/html","readOnly":true}]}}]'

  echo "[pgbadger] Restarting postgres pods so sidecars come up..."
  kubectl rollout restart statefulset ${STATEFULSET}
  kubectl rollout status statefulset ${STATEFULSET} --timeout=180s
fi

cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: pgbadger
  namespace: default
spec:
  selector:
    app: postgres
  ports:
    - name: http
      port: 8080
      targetPort: pgbadger
EOF

kubectl patch svc pgbadger --type merge -p "{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"name\":\"http\",\"port\":8080,\"targetPort\":\"pgbadger\",\"nodePort\":${NODEPORT}}]}}"

echo "[pgbadger] Reports available at http://localhost:${NODEPORT}/ (NodePort)."
