#!/usr/bin/env bash
set -euo pipefail

# Installe Docker, kubectl, k3d et Argo CD CLI, puis crée le cluster k3d.
# Usage:
#   sudo bash scripts/install_tools_create_k3d_cluster_and_bootstrap_argocd.sh
# Variables optionnelles :
#   CLUSTER_NAME=iot
#   K3D_AGENTS=1
#   KUBECONFIG_USER=vagrant

CLUSTER_NAME="${CLUSTER_NAME:-iot}"
K3D_AGENTS="${K3D_AGENTS:-1}"
KUBECONFIG_USER="${KUBECONFIG_USER:-${SUDO_USER:-$USER}}"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "[ERROR] Run this script as root (use sudo)."
  exit 1
fi

echo "[SETUP] Install prerequisites"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg lsb-release apt-transport-https software-properties-common

echo "[DOCKER] Install and start Docker"
apt-get install -y --no-install-recommends docker.io
systemctl enable --now docker
usermod -aG docker "$KUBECONFIG_USER" || true

if ! command -v kubectl >/dev/null 2>&1; then
  echo "[KUBECTL] Install kubectl"
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  chmod +x /usr/local/bin/kubectl
else
  echo "[KUBECTL] kubectl already installed"
fi

if ! command -v k3d >/dev/null 2>&1; then
  echo "[K3D] Install k3d"
  curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
else
  echo "[K3D] k3d already installed"
fi

if ! command -v argocd >/dev/null 2>&1; then
  echo "[ARGOCD] Install Argo CD CLI"
  curl -fsSL -o /usr/local/bin/argocd "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
  chmod +x /usr/local/bin/argocd
else
  echo "[ARGOCD] Argo CD CLI already installed"
fi

if ! k3d cluster list | awk '{print $1}' | grep -qx "$CLUSTER_NAME"; then
  echo "[K3D] Create cluster '${CLUSTER_NAME}'"
  k3d cluster create "$CLUSTER_NAME" \
    --servers 1 \
    --agents "$K3D_AGENTS" \
    --port "8888:80@loadbalancer"
else
  echo "[K3D] Cluster '${CLUSTER_NAME}' already exists"
fi

echo "[K3D] Export kubeconfig for user '${KUBECONFIG_USER}'"
mkdir -p "/home/${KUBECONFIG_USER}/.kube"
k3d kubeconfig get "$CLUSTER_NAME" > "/home/${KUBECONFIG_USER}/.kube/config"
chown -R "${KUBECONFIG_USER}:${KUBECONFIG_USER}" "/home/${KUBECONFIG_USER}/.kube"
chmod 600 "/home/${KUBECONFIG_USER}/.kube/config"

export KUBECONFIG="/home/${KUBECONFIG_USER}/.kube/config"

echo "[INFO] Outils installés et cluster '${CLUSTER_NAME}' prêt."
echo "[INFO] Relancer le shell pour les droits Docker : newgrp docker"
echo "[INFO] Vérifier le cluster : kubectl get nodes -o wide"