#!/usr/bin/env bash
set -euo pipefail

echo "[VERIFY] Namespaces"
kubectl get ns | grep -E "argocd|dev|gitlab" || true

echo "[VERIFY] GitLab objects"
kubectl -n gitlab get pods,svc,ingress || true

echo "[VERIFY] Argo CD objects"
kubectl -n argocd get applications.argoproj.io || true
kubectl -n argocd get ingress -o wide || true

echo "[VERIFY] Dev objects"
kubectl -n dev get deploy,svc,pods,ingress || true

echo "[VERIFY] Expected routes"
echo "  Argo CD: http://argocd.192.168.56.120.nip.io:8888"
echo "  Funny app: http://funny.192.168.56.120.nip.io:8888"
