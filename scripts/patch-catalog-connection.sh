#!/usr/bin/env bash
set -euo pipefail

NS="${1:-default}"
CM="catalog-api-env"
KEY="ConnectionStrings__catalogdb"

log() {
  echo "[catalog-conn] $*"
}

trim() {
  local var="${1#"${1%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "${var}"
}

log "Reading ${KEY} from ConfigMap ${CM} in namespace ${NS}..."
conn_raw="$(kubectl -n "${NS}" get configmap "${CM}" -o "jsonpath={.data.${KEY}}" 2>/dev/null || true)"
if [[ -z "${conn_raw}" ]]; then
  log "ERROR: ${KEY} missing or ConfigMap not found."
  exit 1
fi

IFS=';' read -ra parts <<< "${conn_raw}"
kept=()
for part in "${parts[@]}"; do
  part_trimmed="$(trim "${part}")"
  key="${part_trimmed%%=*}"
  case "${key}" in
    "Maximum Pool Size"|"Timeout"|"Command Timeout")
      continue
      ;;
    *)
      if [[ -n "${part_trimmed}" ]]; then
        kept+=("${part_trimmed}")
      fi
      ;;
  esac
done

conn=""
for entry in "${kept[@]}"; do
  if [[ -z "${conn}" ]]; then
    conn="${entry}"
  else
    conn="${conn};${entry}"
  fi
done

if [[ -n "${conn}" ]]; then
  conn="${conn};"
fi
conn="${conn}Maximum Pool Size=300;Timeout=15;Command Timeout=30"

escaped_conn="${conn//\"/\\\"}"

log "Updating ${KEY} with pooling and timeouts..."
kubectl -n "${NS}" patch configmap "${CM}" --type merge -p "{\"data\":{\"${KEY}\":\"${escaped_conn}\"}}" >/dev/null
log "Patch applied."
