#!/bin/bash
set -euo pipefail

P2_MANIFESTS_DIR="${P2_MANIFESTS_DIR:-/tmp/p2_manifests}"

if [ ! -d "$P2_MANIFESTS_DIR" ]; then
  echo "[ERROR] Manifests directory not found: $P2_MANIFESTS_DIR"
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "[ERROR] kubectl not found. Ensure K3s server is installed first."
  exit 1
fi

echo "[INFO] Waiting for Kubernetes API to be ready..."
for i in $(seq 1 60); do
  if kubectl get --raw='/readyz' >/dev/null 2>&1; then
    echo "[INFO] Kubernetes API is ready"
    break
  fi
  sleep 2
  if [ "$i" -eq 60 ]; then
    echo "[ERROR] Timeout waiting for Kubernetes API readiness"
    exit 1
  fi
done

echo "[INFO] Applying manifests from $P2_MANIFESTS_DIR"
kubectl apply -R -f "$P2_MANIFESTS_DIR"

echo "[INFO] Applied resources summary:"
kubectl get deploy,svc,ingress -n iot-p2 || true