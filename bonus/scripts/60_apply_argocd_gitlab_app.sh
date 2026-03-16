#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_load_config.sh"

TEMPLATE_FILE="${SCRIPT_DIR}/../confs/argocd/application-gitlab-template.yaml"

if [[ ! -f "${TEMPLATE_FILE}" ]]; then
  echo "[ERROR] Missing template file: ${TEMPLATE_FILE}"
  exit 1
fi

if [[ -z "${GITLAB_REPO_URL:-}" ]]; then
  echo "[WARN] GITLAB_REPO_URL is empty in config. Skip Argo CD Application apply."
  exit 0
fi

# Check ArgoCD namespace
if ! kubectl get ns argocd >/dev/null 2>&1; then
  echo "[ERROR] ArgoCD namespace not found"
  exit 1
fi

echo "[CHECK] Using GitLab repository: ${GITLAB_REPO_URL}"

GITLAB_REPO_PATH="${GITLAB_REPO_PATH:-manifests}"
TMP_OUT="/tmp/application-gitlab.rendered.yaml"

sed \
  -e "s|__REPO_URL__|${GITLAB_REPO_URL}|g" \
  -e "s|__REPO_PATH__|${GITLAB_REPO_PATH}|g" \
  "${TEMPLATE_FILE}" > "${TMP_OUT}"

kubectl apply -f "${TMP_OUT}"

echo "[ARGOCD] Application applied from ${TMP_OUT}"
