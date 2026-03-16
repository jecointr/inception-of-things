#!/bin/bash
set -euo pipefail

K3S_TOKEN="${K3S_TOKEN:-iot-p1-shared-token}"
K3S_NODE_IP="${K3S_NODE_IP:-192.168.56.110}"

export DEBIAN_FRONTEND=noninteractive

if systemctl is-active --quiet k3s; then
  echo "[INFO] k3s server already running, skipping installation"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends curl ca-certificates
fi

INSTALL_K3S_EXEC="server --node-ip=${K3S_NODE_IP} --flannel-iface=eth1 --write-kubeconfig-mode=644 --token=${K3S_TOKEN}"

echo "[INFO] Installing K3s server..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="${INSTALL_K3S_EXEC}" sh -

echo "[INFO] Waiting for k3s service..."
for i in $(seq 1 30); do
  if systemctl is-active --quiet k3s; then
    echo "[INFO] k3s service is active"
    break
  fi
  sleep 2
  if [ "${i}" -eq 30 ]; then
    echo "[ERROR] k3s service is not active"
    systemctl status k3s --no-pager || true
    exit 1
  fi
done

echo "[INFO] K3s server installed successfully"
echo "[INFO] Node token:"
cat /var/lib/rancher/k3s/server/node-token || true