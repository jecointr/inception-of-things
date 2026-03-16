#!/bin/bash
set -euo pipefail

USER_NAME="vagrant"
HOME_DIR="/home/${USER_NAME}"
SSH_DIR="${HOME_DIR}/.ssh"
AUTHORIZED_KEYS="${SSH_DIR}/authorized_keys"
TMP_KEYS="/tmp/ssh_authorized_keys"

mkdir -p "${SSH_DIR}"
chmod 700 "${SSH_DIR}"
touch "${AUTHORIZED_KEYS}"

if [ -f "${TMP_KEYS}" ]; then
  while IFS= read -r key; do
    if [[ -n "${key}" && ! "${key}" =~ ^[[:space:]]*# ]] && ! grep -Fxq "${key}" "${AUTHORIZED_KEYS}"; then
      echo "${key}" >> "${AUTHORIZED_KEYS}"
    fi
  done < "${TMP_KEYS}"
fi

chmod 600 "${AUTHORIZED_KEYS}"
chown -R "${USER_NAME}:${USER_NAME}" "${SSH_DIR}"

systemctl enable ssh >/dev/null 2>&1 || true
systemctl restart ssh >/dev/null 2>&1 || true

echo "[INFO] SSH authorized_keys configured for ${USER_NAME}"
