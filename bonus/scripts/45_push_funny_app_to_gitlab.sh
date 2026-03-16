#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/_load_config.sh"

# ----------------------------------------------------------------
# Creates the iot-funny project on local GitLab via API,
# then pushes funny-app sources + Kubernetes manifests into it.
# The manifests point to DOCKERHUB_IMAGE:v1 (changeable to v2 later
# to trigger Argo CD rollout during the defense demo).
# ----------------------------------------------------------------

PROJECT_NAME="${GITLAB_PROJECT_PATH##*/}"
PROJECT_ENCODED="$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1],''))" "${GITLAB_PROJECT_PATH}")"

# --- Create GitLab project via API when token is provided ---
if [[ -n "${GITLAB_TOKEN:-}" && "${GITLAB_TOKEN}" != "CHANGE_ME" ]]; then
  echo "[GITLAB] Ensure project '${PROJECT_NAME}' exists"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
    "${GITLAB_BASE_URL}/api/v4/projects/${PROJECT_ENCODED}" 2>/dev/null || echo "000")

  if [[ "${HTTP_CODE}" != "200" ]]; then
    echo "[GITLAB] Project not found (HTTP ${HTTP_CODE}), creating..."
    curl -fsS -X POST \
      -H "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"${PROJECT_NAME}\",\"path\":\"${PROJECT_NAME}\",\"visibility\":\"public\",\"initialize_with_readme\":false}" \
      "${GITLAB_BASE_URL}/api/v4/projects" > /dev/null
    echo "[GITLAB] Project '${PROJECT_NAME}' created"
  else
    echo "[GITLAB] Project '${PROJECT_NAME}' already exists"
  fi
else
  echo "[WARN] GITLAB_TOKEN not set: skip project auto-creation."
  echo "[WARN] Expecting existing repo: ${GITLAB_REPO_URL}"
fi

# --- Build push URL with credentials embedded ---
PUSH_URL="http://${GITLAB_USERNAME}:${GITLAB_PASSWORD}@${GITLAB_BASE_URL#http://}/${GITLAB_PROJECT_PATH}.git"

if ! git ls-remote "${PUSH_URL}" >/dev/null 2>&1; then
  echo "[ERROR] Cannot reach target repo: ${GITLAB_REPO_URL}"
  echo "[HINT] Either set GITLAB_TOKEN to auto-create the project, or create '${GITLAB_PROJECT_PATH}' manually in GitLab."
  exit 1
fi

WORK_DIR="${MIRROR_WORKDIR}/push-funny"
SRC_APP_DIR="${REPO_ROOT}/bonus/funny-app"
SRC_MANIFEST_DIR="${SRC_APP_DIR}/manifests"
IMAGE_REF="${DOCKERHUB_IMAGE}:v1"

if [[ ! -d "${SRC_MANIFEST_DIR}" ]]; then
  echo "[ERROR] Missing manifests directory: ${SRC_MANIFEST_DIR}"
  exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/src" "${WORK_DIR}/manifests"

# Copy funny-app sources
cp -r "${SRC_APP_DIR}/." "${WORK_DIR}/src/"
cp -r "${SRC_MANIFEST_DIR}/." "${WORK_DIR}/manifests/"

# Render image tag in deployment manifest template.
sed -i "s|__IMAGE__|${IMAGE_REF}|g" "${WORK_DIR}/manifests/deployment.yaml"

# --- Initialize and push git repo ---
cd "${WORK_DIR}"
git init -b main
git config user.email "bonus@iot.local"
git config user.name "IoT Bonus"
git add .
git commit -m "feat: initial funny-app deployment (v1)"
git remote add origin "${PUSH_URL}"
git push --force origin main

echo "[GITLAB] funny-app pushed to ${GITLAB_REPO_URL} (branch main)"
echo "[INFO] To deploy v2: edit manifests/deployment.yaml, change image tag to v2, git push"
