#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALUES_FILE="${SCRIPT_DIR}/../confs/gitlab/values.yaml"

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "[ERROR] Missing values file: ${VALUES_FILE}"
  exit 1
fi

helm repo add gitlab https://charts.gitlab.io/ >/dev/null 2>&1 || true
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --namespace gitlab \
  --create-namespace \
  -f "${VALUES_FILE}" \
  --timeout 20m

echo "[GITLAB] Helm release installed/updated"
