#!/usr/bin/env bash
set -euo pipefail

# Bonus entrypoint: run all bonus steps in order.
# Usage:
#   bash scripts/setup.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(
  "00_check_prereqs.sh"
  "10_create_namespaces.sh"
  "20_install_gitlab.sh"
  "30_wait_gitlab.sh"
  "40_show_gitlab_access.sh"
  "45_push_funny_app_to_gitlab.sh"
  "50_register_gitlab_repo_in_argocd.sh"
  "60_apply_argocd_gitlab_app.sh"
  "65_apply_argocd_ingress.sh"
  "90_verify_bonus.sh"
)

echo "[BONUS] Start setup"
for step in "${STEPS[@]}"; do
  script_path="${SCRIPT_DIR}/${step}"
  if [[ ! -f "${script_path}" ]]; then
    echo "[ERROR] Missing script: ${script_path}"
    exit 1
  fi
  echo "[BONUS] Run ${step}"
  bash "${script_path}"
done

echo "[BONUS] Done"
