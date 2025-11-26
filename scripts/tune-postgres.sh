#!/usr/bin/env bash
set -euo pipefail

CONFIG_VALUES="max_connections=400 shared_buffers=512MB effective_cache_size=1536MB maintenance_work_mem=128MB checkpoint_completion_target=0.9 wal_buffers=16MB default_statistics_target=100 random_page_cost=1.1 effective_io_concurrency=200 work_mem=1285kB huge_pages=off min_wal_size=1GB max_wal_size=4GB shared_preload_libraries=pg_stat_statements logging_collector=on log_directory=pg_log log_filename=postgresql-%Y-%m-%d_%H%M%S.log log_rotation_age=5min log_rotation_size=50MB log_min_duration_statement=250ms log_statement=none log_checkpoints=on log_connections=off log_disconnections=off log_destination=stderr"

echo "[postgres-tune] Updating ConfigMap..."
kubectl patch configmap postgres-env --type merge --patch "{\"data\":{\"POSTGRES_CONFIG\":\"${CONFIG_VALUES}\"}}" >/dev/null

POSTGRES_PASSWORD="$(kubectl get configmap postgres-env -o jsonpath='{.data.POSTGRES_PASSWORD}')"
if [[ -z "${POSTGRES_PASSWORD}" ]]; then
  echo "[postgres-tune] ERROR: POSTGRES_PASSWORD missing in postgres-env ConfigMap" >&2
  exit 1
fi

SQL_CMDS=(
  "ALTER SYSTEM SET max_connections = 400;"
  "ALTER SYSTEM SET shared_buffers = '512MB';"
  "ALTER SYSTEM SET effective_cache_size = '1536MB';"
  "ALTER SYSTEM SET maintenance_work_mem = '128MB';"
  "ALTER SYSTEM SET checkpoint_completion_target = 0.9;"
  "ALTER SYSTEM SET wal_buffers = '16MB';"
  "ALTER SYSTEM SET default_statistics_target = 100;"
  "ALTER SYSTEM SET random_page_cost = 1.1;"
  "ALTER SYSTEM SET effective_io_concurrency = 200;"
  "ALTER SYSTEM SET work_mem = '1285kB';"
  "ALTER SYSTEM SET huge_pages = off;"
  "ALTER SYSTEM SET min_wal_size = '1GB';"
  "ALTER SYSTEM SET max_wal_size = '4GB';"
  "ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements';"
  "ALTER SYSTEM SET logging_collector = on;"
  "ALTER SYSTEM SET log_directory = 'pg_log';"
  "ALTER SYSTEM SET log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log';"
  "ALTER SYSTEM SET log_rotation_age = '5min';"
  "ALTER SYSTEM SET log_rotation_size = '50MB';"
  "ALTER SYSTEM SET log_min_duration_statement = '250ms';"
  "ALTER SYSTEM SET log_statement = 'none';"
  "ALTER SYSTEM SET log_checkpoints = on;"
  "ALTER SYSTEM SET log_connections = off;"
  "ALTER SYSTEM SET log_disconnections = off;"
  "ALTER SYSTEM SET log_destination = 'stderr';"
)

echo "[postgres-tune] Waiting for postgres-0 to be ready..."
kubectl rollout status statefulset/postgres --timeout=180s >/dev/null

TRACK_CMD="ALTER SYSTEM SET pg_stat_statements.track = 'all';"
track_set_ok=false

for sql in "${SQL_CMDS[@]}"; do
  echo "[postgres-tune] Executing: ${sql}"
  kubectl exec postgres-0 -- env PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -c "${sql}" >/dev/null
done

echo "[postgres-tune] Executing: ${TRACK_CMD}"
if kubectl exec postgres-0 -- env PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -c "${TRACK_CMD}" >/dev/null; then
  track_set_ok=true
else
  echo "[postgres-tune] WARN: pg_stat_statements.track not set (likely requires restart). Will retry after restart."
fi

echo "[postgres-tune] Ensuring pg_log directory exists..."
kubectl exec postgres-0 -- bash -c "mkdir -p /var/lib/postgresql/data/pg_log && chown postgres:postgres /var/lib/postgresql/data/pg_log"

echo "[postgres-tune] Restarting postgres StatefulSet..."
kubectl rollout restart statefulset/postgres >/dev/null
kubectl rollout status statefulset/postgres --timeout=180s >/dev/null

if [[ "${track_set_ok}" == "false" ]]; then
  echo "[postgres-tune] Retrying pg_stat_statements.track after restart..."
  if kubectl exec postgres-0 -- env PGPASSWORD="${POSTGRES_PASSWORD}" psql -U postgres -c "${TRACK_CMD}" >/dev/null; then
    echo "[postgres-tune] pg_stat_statements.track applied after restart."
  else
    echo "[postgres-tune] ERROR: Failed to set pg_stat_statements.track even after restart." >&2
    exit 1
  fi
fi

echo "[postgres-tune] Postgres tuning applied."
