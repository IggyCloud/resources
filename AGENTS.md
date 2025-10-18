# Repository Guidelines

## Project Structure & Module Organization
- `k8s/` - Kubernetes manifests and helper scripts (e.g., NodePort patches).
- `observability/` - Prometheus, Grafana, Tempo, Pyroscope configs and scripts.
- `k6/` - Load-testing suite: `scripts/` for tests, `k8s/` for k6 jobs, run helpers.
- `aspir8/` - Aspire/Aspirate deployment helpers for eShop to Kubernetes.
- `docs/` and `evidence/` - Performance docs and captured results (CSV, PNG).
- `scripts/` - Utilities; includes a pinned `kubectl.exe` for convenience.

## Build, Test, and Development Commands
- Deploy eShop: `cd aspir8 && ./Aspir8.sh` (Windows: use WSL/Git Bash) 
- Run k6 tests (Windows): `cd k6 && run-test.bat`
- Run k6 tests (Linux/macOS): `cd k6 && ./deploy.sh && ./run-test.sh catalog-api-open-model-read-test.js`
- Apply limits/NodePorts: `k8s/apply-limits.sh`, `k8s/patch-nodeports.sh`
- Observability post-deploy: `cd observability && ./scripts/post-deploy-monitoring.sh`

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
