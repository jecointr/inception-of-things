#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_load_config.sh"

# Register GitLab repo in Argo CD by creating a repository secret.

if [[ -z "${GITLAB_REPO_URL:-}" ]]; then
  echo "[WARN] GITLAB_REPO_URL is empty in config. Skip Argo CD repo registration."
  exit 0
fi

GITLAB_USERNAME="${GITLAB_USERNAME:-root}"
GITLAB_PASSWORD="${GITLAB_PASSWORD:-}"

if [[ -z "${GITLAB_PASSWORD}" ]]; then
  echo "[WARN] GITLAB_PASSWORD is not set. Repo secret will not be created."
  exit 0
fi

kubectl apply -n argocd -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: repo-gitlab-local
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  url: ${GITLAB_REPO_URL}
  username: ${GITLAB_USERNAME}
  password: ${GITLAB_PASSWORD}
  insecure: "true"
EOF

echo "[ARGOCD] GitLab repository secret applied"
