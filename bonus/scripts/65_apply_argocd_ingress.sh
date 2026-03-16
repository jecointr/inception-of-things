#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INGRESS_FILE="${SCRIPT_DIR}/../confs/argocd/argocd-ingress.yaml"

if [[ ! -f "${INGRESS_FILE}" ]]; then
  echo "[ERROR] Missing ingress file: ${INGRESS_FILE}"
  exit 1
fi

kubectl apply -f "${INGRESS_FILE}"
kubectl -n argocd get ingress argocd-server-ingress -o wide

echo "[ARGOCD] Ingress applied: http://argocd.192.168.56.120.nip.io:8888"
