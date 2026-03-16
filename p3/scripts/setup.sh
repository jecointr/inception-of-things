#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# P3 — Point d'entrée unique
# Étape 1 : installe les outils et crée le cluster k3d
# Étape 2 : bootstrap Argo CD et déploie l'application GitOps
#
# Usage:
#   sudo bash scripts/setup.sh
#
# Variables optionnelles :
#   CLUSTER_NAME=iot        (défaut: iot)
#   K3D_AGENTS=1            (défaut: 1)
#   KUBECONFIG_USER=vagrant (défaut: utilisateur courant)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/install_tools_create_k3d_cluster_and_bootstrap_argocd.sh"
BOOTSTRAP_SCRIPT="${SCRIPT_DIR}/bootstrap_argocd_and_apply_gitops_app.sh"

for s in "${INSTALL_SCRIPT}" "${BOOTSTRAP_SCRIPT}"; do
  if [[ ! -f "$s" ]]; then
    echo "[ERROR] Script introuvable : $s"
    exit 1
  fi
done

echo "========================================"
echo " P3 — Setup K3d + Argo CD"
echo "========================================"
echo ""

echo "[STEP 1/2] Installation des outils + création du cluster k3d"
bash "${INSTALL_SCRIPT}"

echo ""
echo "[STEP 2/2] Bootstrap Argo CD + déploiement de l'application GitOps"
bash "${BOOTSTRAP_SCRIPT}"

echo ""
echo "========================================"
echo " P3 — Setup terminé avec succès !"
echo "========================================"
echo ""
echo "Vérifications rapides :"
echo "  kubectl get nodes -o wide"
echo "  kubectl -n argocd get pods"
echo "  kubectl -n argocd get applications.argoproj.io"
echo "  kubectl -n dev get deploy,svc,pods"
echo ""
echo "Accès Argo CD (port-forward) :"
echo "  kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "  Mot de passe admin : kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
echo ""
echo "Test de l'application :"
echo "  curl http://localhost:8888/"
