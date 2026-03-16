#!/usr/bin/env bash
set -euo pipefail

kubectl create namespace gitlab --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

echo "[K8S] Namespaces ensured: gitlab, argocd, dev"
