# eShop k8s Troubleshooting Notes

Quick checks to run when RPS collapses or services flap after config changes.

## 1) Postgres auth failures (HTTP 0 from APIs)
- Symptom: API pods crash-loop with `28P01 password authentication failed for user "postgres"`.
- Check live password: `kubectl get configmap postgres-env -o yaml | rg POSTGRES_PASSWORD`.
- Check service configs (example): `kubectl get configmap catalog-api-env -o yaml | rg ConnectionStrings__catalogdb`.
- Fix: align the app connection string password with the Postgres password, then `kubectl rollout restart deployment <api>` (or recreate the secret/ConfigMap if templated).

## 2) LimitRange defaulting pods to 1 CPU / 1.8Gi
- Symptom: throughput stuck ~600 RPS; pods show CPU throttling.
- Confirm defaults: `kubectl get limitrange pod-resource-limits -o yaml`.
- Spot effective limits: `kubectl get pod <name> -o jsonpath='{.spec.containers[*].resources}'`.
- Fix: set explicit resources on heavy pods (e.g., Postgres, APIs) or raise the LimitRange defaults for the namespace.

## 3) pgBadger sidecar consuming CPU
- Symptom: `kubectl top pod postgres-0 --containers` shows `pgbadger` at ~1000m while Postgres is idle.
- Root cause: sidecar re-parses large `pg_log` continuously.
- Fix options:
  - Disable/remove the sidecar from the Postgres StatefulSet (remove containers index 1 and 1 again for nginx, rollout restart).
  - Or cap its CPU (e.g., 100m) and/or trim `pg_log` before running.

## 4) Perf mode for APIs
- Symptom: higher latencies due to tracing/logging/profiling overhead.
- Check: `Telemetry__PerfMode` env var or `Telemetry:PerfMode` in settings.
- Fix: set `Telemetry__PerfMode=true` in the service ConfigMap/secret and restart the deployment.

## 5) k6 job cleanup
- Symptom: stale load test still hammering services.
- Check: `kubectl get jobs --all-namespaces | rg k6`.
- Fix: `kubectl delete job k6-load-test -n k6-loadtest`.

## 6) NodePorts / tooling
- pghero: service `pghero` NodePort 30306 (`http://localhost:30306/`). Ensure the secret `pghero-env` uses the current DB password.
- pgBadger (if enabled): service `pgbadger` NodePort 30305 (`http://localhost:30305/index.html`).

## 7) Common commands
- Pod metrics: `kubectl top pod <name> --containers`.
- Pod status: `kubectl get pods -l app=<label>`.
- Pod logs: `kubectl logs <pod> [-c <container>] --tail=200`.
- Rollout: `kubectl rollout restart deployment/<name>` or `statefulset/<name>`; check with `kubectl rollout status ...`.
