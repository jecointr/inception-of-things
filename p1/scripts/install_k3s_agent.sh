#!/bin/bash
set -euo pipefail

: "${K3S_URL:?K3S_URL is required (example: https://192.168.56.110:6443)}"
: "${K3S_TOKEN:?K3S_TOKEN is required (provide the shared token from p1/confs/token)}"

K3S_NODE_IP="${K3S_NODE_IP:-192.168.56.111}"
export DEBIAN_FRONTEND=noninteractive

if systemctl is-active --quiet k3s-agent; then
  echo "[INFO] k3s agent already running, skipping installation"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1 || ! command -v nc >/dev/null 2>&1; then
  apt-get update
  apt-get install -y --no-install-recommends curl ca-certificates netcat-openbsd
fi

SERVER_HOSTPORT="${K3S_URL#https://}"
SERVER_HOSTPORT="${SERVER_HOSTPORT#http://}"
SERVER_HOST="${SERVER_HOSTPORT%%:*}"
SERVER_PORT="${SERVER_HOSTPORT##*:}"

echo "[INFO] Waiting for server API ${SERVER_HOST}:${SERVER_PORT} ..."
for i in $(seq 1 180); do
  if nc -z "${SERVER_HOST}" "${SERVER_PORT}" >/dev/null 2>&1; then
    echo "[INFO] Server API TCP port is reachable"
    break
  fi
  sleep 2
  if [ "${i}" -eq 180 ]; then
    echo "[ERROR] Timeout waiting for server API ${SERVER_HOST}:${SERVER_PORT}"
    exit 1
  fi
done

INSTALL_K3S_EXEC="agent --node-ip=${K3S_NODE_IP}"

echo "[INFO] Installing K3s agent..."
curl -sfL https://get.k3s.io | \
  INSTALL_K3S_EXEC="${INSTALL_K3S_EXEC}" \
  INSTALL_K3S_SKIP_ENABLE="true" \
  INSTALL_K3S_SKIP_START="true" \
  K3S_URL="${K3S_URL}" \
  K3S_TOKEN="${K3S_TOKEN}" \
  sh -

echo "[INFO] Enabling and starting k3s-agent service..."
systemctl daemon-reload
systemctl enable k3s-agent
systemctl restart k3s-agent

echo "[INFO] Waiting for k3s-agent service..."
for i in $(seq 1 90); do
  if systemctl is-active --quiet k3s-agent; then
    echo "[INFO] k3s-agent service is active"
    break
  fi
  sleep 2
  if [ "${i}" -eq 90 ]; then
    echo "[ERROR] k3s-agent service is not active"
    systemctl status k3s-agent --no-pager || true
    journalctl -u k3s-agent -n 80 --no-pager || true
    exit 1
  fi
done

echo "[INFO] K3s agent installed successfully"