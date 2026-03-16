#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_load_config.sh"

PASSWORD="$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode 2>/dev/null || true)"

echo "[INFO] GitLab URL (ingress): ${GITLAB_BASE_URL}"
echo "[INFO] Alternative (port-forward): kubectl -n gitlab port-forward svc/gitlab-webservice-default 8181:8181"
echo "[INFO] GitLab user: ${GITLAB_USERNAME}"
if [[ -n "${PASSWORD}" ]]; then
  echo "[INFO] GitLab root password: ${PASSWORD}"
else
  echo "[WARN] Could not read initial root password yet. Try again after pods are ready."
fi
