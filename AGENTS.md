# Repository Guidelines

## Project Structure & Module Organization
- `k8s/` - Kubernetes manifests and helper scripts (e.g., NodePort patches).
- `observability/` - Prometheus, Grafana, Tempo, Pyroscope configs and scripts.
- `k6/` - Load-testing suite: `scripts/` for tests, `k8s/` for k6 jobs, run helpers.
- `aspir8/` - Aspire/Aspirate deployment helpers for eShop to Kubernetes.
- `docs/` and `evidence/` - Performance docs and captured results (CSV, PNG).
- `scripts/` - Utilities; includes a pinned `kubectl.exe` for convenience.

## Build, Test, and Development Commands
- Deploy eShop: `cd aspir8 && ./Aspir8.sh` (Windows: `"%ProgramFiles%\Git\bin\bash.exe" -lc "cd aspir8 && ./Aspir8.sh"`) 
- Run k6 tests (Windows): `cd k6 && run-test.bat`
- Run k6 tests (Linux/macOS): `cd k6 && ./deploy.sh && ./run-test.sh catalog-api-open-model-read-test.js`
- Apply limits/NodePorts: `k8s/apply-limits.sh`, `k8s/patch-nodeports.sh`
- Observability post-deploy: `cd observability && ./scripts/post-deploy-monitoring.sh`
- Learnings (recent incidents)
  - Keep DB password aligned: `postgres-env` (live password) must match all app connection strings. If you rotate or re-seed Postgres, immediately patch app ConfigMaps/secrets (e.g., `catalog-api-env`) or rerun aspir8 with the current password, then restart deployments.
  - Pool caps vs max_connections: Npgsql defaults to 100. If you raise `Maximum Pool Size` (e.g., 300), ensure Postgres `max_connections` has headroom and that other clients (exporter/pgAdmin) won’t exhaust the limit. Adjust in AppHost manifest so aspir8 regeneration preserves it.
  - NodePort/service patches: aspir8 re-applies ClusterIP services. If you need NodePorts (catalog-api 30509, etc.), patch after aspir8 or bake NodePort into manifests. Conflicts will appear on re-apply; use `--force-conflicts` only if you intend to own those fields.
  - pgBadger CPU drain: pgBadger sidecar can peg 1 CPU parsing large `pg_log`. Disable or cap it for load tests; trim logs before enabling.

## Coding Style & Naming Conventions
- YAML/JSON: 2-space indent, lowercase keys; avoid trailing spaces.
- Scripts: bash files use `kebab-case.sh`; Windows helpers use `.bat`.
- k6 tests: `{service}-{model}-{operation}-test.js` (e.g., `catalog-api-closed-model-write-test.js`).
- Keep manifests small and composable; prefer overlays/patches over in-place edits.

## Testing Guidelines
- Framework: k6. Place tests in `k6/scripts/` and follow naming convention.
- Local run: `k6 run k6/scripts/<file>.js` or use provided wrappers above.
- Record evidence: export CSV/PNG to `evidence/<experiment>/<op>/` to keep history.
- Validate dashboards after runs (Grafana `http://localhost:30300`).

## Catalog API Tests
- Endpoints: `GET /catalog/items` (read) and `POST/PUT/DELETE /catalog/items` (write).
- Windows: `cd k6 && run-test.bat` and pick read/write for Catalog API.
- Linux/macOS: `cd k6 && ./run-test.sh catalog-api-closed-model-read-test.js` or `catalog-api-closed-model-write-test.js`.
- Base URL typically via NodePort (eShop at `http://localhost:30509`); adjust if different.

## Evidence Conventions
- Export consolidated CSV from Grafana/K6 panels focusing on RPS, VUs, and response times.
- Place files under `evidence/<experiment>/<op>/data/` with names like `read-1.csv`, `write-1.csv` and normalized variants `*-normalized.csv`.
- Store screenshots alongside (e.g., `k6-1.png`, `k6-2.png`) to match each run.

## Commit & Pull Request Guidelines
- Commits: short, imperative subject; scope optional (e.g., `grafana: compact dashboard`).
- Group related changes; avoid committing generated artifacts or secrets.
- PRs must include: purpose, affected areas, test commands run, and screenshots/links to Grafana panels or k6 output; reference issues when applicable.

## Security & Configuration Tips
- Do not commit credentials; use Kubernetes secrets and local env files.
- Be mindful of NodePort exposure in `k8s/`; restrict on shared clusters.
- Confirm `kubectl` context before applying changes. Example: `kubectl config current-context`.

## Observability & Tracing Rules
- Configure OTLP via appsettings, not ConfigMaps. Use `OTEL_EXPORTER_OTLP_ENDPOINT` and `OTEL_EXPORTER_OTLP_PROTOCOL` in each service's `appsettings*.json`. These are baked into images.
- ServiceDefaults reads configuration and applies the OTLP exporter for logs, metrics, and traces. Do not add per-service exporter configuration.
- EF Core tracing is enabled centrally: `OpenTelemetry.Instrumentation.EntityFrameworkCore` is referenced in `eShop.ServiceDefaults` and wired via `.AddEntityFrameworkCoreInstrumentation()`. Avoid duplicating instrumentation in individual services.
- `Telemetry:PerfMode` (or env var `Telemetry__PerfMode=true`) trims instrumentation for load tests: Pyroscope is disabled, EF/Core/Grpc/HttpClient instrumentation and OTLP log exporting are skipped, and the trace sampler is clamped to <=1%. Use this flag for k6 runs to prevent tracing from throttling RPS.
- To capture traces/logs again, set `Telemetry__PerfMode=false` (or remove the var) on the target deployment(s) and restart before debugging.
- Tempo is the in-cluster OTLP target (`grpc` at `tempo:4317`). Grafana uses the Tempo datasource for traces.

## Database Connection Settings
- Targets
  - API pool: use `Maximum Pool Size=300` for Npgsql.
  - Postgres (k8s default pod): tune for 2 GB RAM / SSD / 400 connections — `max_connections=400`, `shared_buffers=512MB`, `effective_cache_size=1536MB`, `work_mem=1285kB`, `maintenance_work_mem=128MB`, `checkpoint_completion_target=0.9`, `wal_buffers=16MB`, `default_statistics_target=100`, `random_page_cost=1.1`, `effective_io_concurrency=200`, `huge_pages=off`, `min_wal_size=1GB`, `max_wal_size=4GB`.
- Persistence (do this in source, not K8s overlays)
  - Prefer baking connection string settings into `appsettings*.json` in each service image so they survive re-deployments.
  - Do not hardcode passwords in JSON. Source secrets from Aspire/Aspirate parameters and Kubernetes Secrets.
- Recommended pattern
  - Keep pooling/timeouts in appsettings and layer the password via environment/Secret.
  - Example snippet to place in the service’s `appsettings.Production.json` (source repo):
    - `"ConnectionStrings": { "catalogdb": "Host=postgres;Port=5432;Database=catalogdb;Maximum Pool Size=300;Timeout=15;Command Timeout=30" }`
  - Provide the password via environment/Secret at runtime (Aspire/Aspirate). If you combine at runtime in code, read the base string from configuration and append the password from a Secret.
- Kubernetes overlays
  - If a temporary override is needed via ConfigMap, ensure `ConnectionStrings__catalogdb` includes `;Maximum Pool Size=300`.
  - Avoid storing or rotating DB passwords in ConfigMaps or scripts; rely on Aspirate-managed parameters and Secrets.
  - `scripts/tune-postgres.sh` patches the ConfigMap, runs the matching `ALTER SYSTEM` statements, and restarts the StatefulSet; `aspir8/Aspir8.sh` invokes it automatically after every deploy. Run it manually (`bash scripts/tune-postgres.sh`) if you tweak Postgres outside the normal pipeline.
  - `scripts/deploy-pgbadger.sh` patches the `postgres` StatefulSet with `pgbadger` + `nginx` sidecars and exposes them via the `pgbadger` NodePort service (`http://localhost:30305`). Aspir8 runs it automatically; rerun manually if you recycle the StatefulSet outside the script.
- Verification
  - API: `kubectl -n default get configmap catalog-api-env -o json | jq -r '.data["ConnectionStrings__catalogdb"]'`
  - DB: `show max_connections; show shared_buffers; show work_mem; show effective_cache_size;`

## Aspir8/Aspirate Rules
- Do not patch OTLP exporter env via ConfigMaps from `aspir8/Aspir8.sh`. OTLP endpoint comes from appsettings.
- `aspir8/Aspir8.sh` accepts `PERF_MODE=true ./Aspir8.sh` (Git Bash/WSL) to roll out the `Telemetry__PerfMode` flag across every deployment; omit or set `false` for the normal observability profile.
- Do not reconcile or rewrite database passwords in scripts. PostgreSQL password and all connection strings are sourced from Aspire manifest parameters (e.g., `postgres-password`) and persisted `aspirate-state.json`.
- Rely on Aspirate-generated manifests and Kubernetes Secrets for credentials. Avoid committing plaintext secrets.

## Operational Runbook
- Traces to Tempo
- After `aspirate apply`, ensure OTLP exports go to Tempo gRPC via the baked appsettings; the deployment script no longer patches ConfigMaps.
- `PERF_MODE=true ./Aspir8.sh` enables the perf telemetry profile cluster-wide (sets `Telemetry__PerfMode=true` on each deployment and restarts them). Use this before k6 runs; rerun without `PERF_MODE` afterward to restore full observability.
- Secrets and rotations
  - Keep `src/eShop.AppHost/aspirate-state.json` stable to avoid rotating `postgres/redis/rabbitmq` passwords unintentionally.
  - If Postgres password rotates but PVC persists, auth will fail. Either do not rotate, or delete the Postgres StatefulSet AND its PVC to reinitialize with the new password.
  - For Redis/RabbitMQ rotations, rollout restart their deployments and dependent services (e.g., Basket.API, Catalog.API) to pick up new env/config.
- NodePorts
  - Grafana Service must be NodePort 30300; WebApp 30080; Basket API 30081. `aspir8/Aspir8.sh` and `k8s/patch-nodeports.sh` enforce this.
- Logs vs Traces
  - Application logs go to Loki via Promtail DaemonSet; OTLP logs to Tempo are not used. Query Loki by `app` label and message text (e.g., `{app="webapp"} |= "Exception"`).
  - Optional: add Promtail stage to extract `level` from log text if `level="error"` queries are desired.
- Troubleshooting
  - Terminate k6: `kubectl delete job k6-load-test -n k6-loadtest`.
  - Force services to pick up new config: `kubectl rollout restart deploy/<name>` then `kubectl rollout status ...`.
  - If Grafana goes unreachable, ensure Service type is NodePort with `nodePort: 30300`.
