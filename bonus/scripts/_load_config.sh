#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${BONUS_CONF_FILE:-${SCRIPT_DIR}/../confs/bonus.env}"

if [[ ! -f "${CONF_FILE}" ]]; then
  echo "[ERROR] Missing config file: ${CONF_FILE}"
  echo "[HINT] Create it from bonus/confs/bonus.env"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${CONF_FILE}"
set +a

REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
