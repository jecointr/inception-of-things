#!/usr/bin/env bash
set -euo pipefail

# Phase 1: Install GitLab infrastructure
# Run this first, then manually create the project in GitLab UI
# Usage:
#   bash scripts/1-setup-gitlab-infrastructure.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STEPS=(
  "00_check_prereqs.sh"
  "10_create_namespaces.sh"
  "20_install_gitlab.sh"
  "30_wait_gitlab.sh"
  "40_show_gitlab_access.sh"
)

echo "[BONUS] Phase 1: GitLab Infrastructure Setup"
for step in "${STEPS[@]}"; do
  script_path="${SCRIPT_DIR}/${step}"
  if [[ ! -f "${script_path}" ]]; then
    echo "[ERROR] Missing script: ${script_path}"
    exit 1
  fi
  echo "[BONUS] Run ${step}"
  bash "${script_path}"
done

# Retrieve initial root password
INITIAL_PASSWORD="$(kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode 2>/dev/null || true)"

echo ""
echo "=========================================="
echo "[BONUS] Phase 1 Complete!"
echo "=========================================="
echo ""
echo "---------- GitLab Credentials ----------"
echo "  URL      : http://gitlab.192.168.56.120.nip.io:8888"
echo "  Login    : root"
if [[ -n "${INITIAL_PASSWORD}" ]]; then
  echo "  Password : ${INITIAL_PASSWORD}"
else
  echo "  Password : kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 --decode"
fi
echo "-----------------------------------------"
echo ""
echo "---------- Manual Steps Requis ----------"
echo ""
echo "1. Connecte-toi a GitLab:  http://gitlab.192.168.56.120.nip.io:8888"
echo "   Login: root / mot de passe affiche ci-dessus"
echo ""
echo "2. Cree le projet iot-funny:"
echo "   New project > Create blank project"
echo "   Name: iot-funny  |  Visibility: Public  |  Uncheck README"
echo ""
echo "3. Cree un Access Token (pour les scripts):"
echo "   Profile > Access Tokens > nom: bonus, scopes: api + write_repository"
echo "   Puis mets le token dans confs/bonus.env -> GITLAB_TOKEN"
echo ""
echo "4. Lance la Phase 2:"
echo "   bash scripts/2-setup-argocd-application.sh"
echo "-----------------------------------------"
echo ""
