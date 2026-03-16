#!/usr/bin/env bash
set -euo pipefail

# Wait for GitLab core deployments to be ready
# GitLab can take 10-15 minutes on low-resource VMs

DEPLOYMENTS=(
  "gitlab-webservice-default"
  "gitlab-sidekiq-all-in-1-v2"
  "gitlab-kas"
)

for dep in "${DEPLOYMENTS[@]}"; do
  echo "[GITLAB] Waiting for ${dep}..."
  if kubectl -n gitlab get deployment "${dep}" &>/dev/null; then
    kubectl -n gitlab rollout status deployment/"${dep}" --timeout=30m
  else
    echo "[GITLAB] ${dep} not found, skipping"
  fi
done

echo "[GITLAB] Waiting for PostgreSQL..."
kubectl rollout status statefulset/gitlab-postgresql -n gitlab --timeout=600s

echo "[GITLAB] Waiting for Redis..."
kubectl rollout status statefulset/gitlab-redis-master -n gitlab --timeout=600s

echo "[GITLAB] Waiting for Gitaly..."
kubectl rollout status statefulset/gitlab-gitaly -n gitlab --timeout=600s

echo "[GITLAB] Core services ready."
