#!/usr/bin/env bash
set -euo pipefail

# Phase 2: Deploy application with Argo CD
# Prerequisites:
# 1) GitLab is already installed and reachable
# 2) The GitLab project "iot-funny" is created manually
# 3) The manifests have already been pushed to the GitLab repository
# 4) confs/bonus.env contains the internal GitLab repo URL for ArgoCD

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(
  "60_apply_argocd_gitlab_app.sh"
  "65_apply_argocd_ingress.sh"
  "90_verify_bonus.sh"
)

echo "[BONUS] Phase 2: Argo CD Application Setup"

for step in "${STEPS[@]}"; do
  script_path="${SCRIPT_DIR}/${step}"
  if [[ ! -f "${script_path}" ]]; then
    echo "[ERROR] Missing script: ${script_path}"
    exit 1
  fi

  echo "[BONUS] Run ${step}"
  bash "${script_path}"
done

echo ""
echo "=========================================="
echo "[BONUS] Phase 2 Complete!"
echo "=========================================="
echo ""
echo "The application should now be deployed."
echo ""
echo "Useful access methods:"
echo "- GitLab UI (via port-forward): http://localhost:8081"
echo "- Argo CD UI (via port-forward): http://localhost:8080"
echo "- App UI (via port-forward or ingress depending on setup)"
echo ""
echo "Reminder:"
echo "- GitLab project must already exist"
echo "- manifests/ must already be pushed to the GitLab repository"
echo ""