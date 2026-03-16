#!/usr/bin/env bash
set -euo pipefail

# Ensure required tools exist and cluster is reachable.
for cmd in kubectl curl git; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "[ERROR] Missing command: ${cmd}"
    exit 1
  fi
done

HELM_DESIRED_VERSION="v3.17.1"
HELM_MIN_MAJOR=4
install_helm() {
  echo "[PREREQS] Installing helm ${HELM_DESIRED_VERSION}"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | \
    DESIRED_VERSION="${HELM_DESIRED_VERSION}" bash
}

if ! command -v helm >/dev/null 2>&1; then
  install_helm
elif [[ "$(helm version --short 2>/dev/null | grep -oP 'v\K[0-9]+' | head -1)" -lt "${HELM_MIN_MAJOR}" ]]; then
  echo "[PREREQS] helm $(helm version --short) < ${HELM_MIN_MAJOR}.x — upgrading to ${HELM_DESIRED_VERSION}"
  install_helm
else
  echo "[PREREQS] helm already installed: $(helm version --short)"
fi

if ! command -v argocd >/dev/null 2>&1; then
  echo "[WARN] argocd CLI not found. Repo registration script will be skipped unless CLI is installed."
fi

kubectl cluster-info >/dev/null
echo "[PREREQS] Cluster reachable"

if ! command -v docker >/dev/null 2>&1; then
  echo "[WARN] docker not found. Build/push step will be skipped."
fi
