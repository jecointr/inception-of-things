#!/usr/bin/env bash
set -euo pipefail

# Bootstrap Argo CD and the GitOps Application in an existing cluster.
# Usage:
#   bash scripts/bootstrap_argocd_and_apply_gitops_app.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_YAML="${SCRIPT_DIR}/../confs/argocd/application-template.yaml"
ARGOCD_INGRESS_YAML="${SCRIPT_DIR}/../confs/argocd/argocd-ingress.yaml"
ARGOCD_INSTALL_URL="https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"

if [[ ! -f "${APP_YAML}" ]]; then
  echo "[ERROR] Missing application file: ${APP_YAML}"
  exit 1
fi

echo "[ARGOCD] Check cluster"
kubectl cluster-info >/dev/null

echo "[K8S] Create namespaces"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "[ARGOCD] Install controller"
kubectl apply --server-side --force-conflicts -n argocd -f "${ARGOCD_INSTALL_URL}"
echo "[ARGOCD] Wait for pods"
kubectl wait -n argocd --for=condition=Ready pods --all --timeout=600s

# Ingress works reliably with insecure mode enabled.
echo "[ARGOCD] Patch server mode"
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge -p '{"data":{"server.insecure":"true"}}'
kubectl -n argocd rollout restart deployment/argocd-server
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

echo "[DEV] Apply Argo CD Application"
kubectl apply -f "${APP_YAML}"

if [[ -f "${ARGOCD_INGRESS_YAML}" ]]; then
  echo "[ARGOCD] Apply ingress"
  kubectl apply -f "${ARGOCD_INGRESS_YAML}"
fi

kubectl -n argocd get applications.argoproj.io
kubectl -n dev get deploy,svc,pods || true

echo "[INFO] Argo CD bootstrap finished."
echo "[INFO] To access UI quickly: kubectl -n argocd port-forward svc/argocd-server 8080:443"
echo "[INFO] Default admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"
