#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

SERVICE_NAME="${VALHEIM_SERVICE_NAME:-valheim}"
RUN_USER="${SUDO_USER:-${USER}}"
RUN_GROUP="$(id -gn "${RUN_USER}")"
UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
TMP_UNIT="$(mktemp)"

as_root() {
  if [[ $EUID -ne 0 ]]; then
    sudo "$@"
  else
    "$@"
  fi
}

sed \
  -e "s|@RUN_USER@|${RUN_USER}|g" \
  -e "s|@RUN_GROUP@|${RUN_GROUP}|g" \
  -e "s|@SERVER_DIR@|${SERVER_DIR}|g" \
  -e "s|@ENV_FILE@|${ENV_FILE}|g" \
  -e "s|@START_SCRIPT@|${ROOT_DIR}/native/start-server.sh|g" \
  "${ROOT_DIR}/native/valheim.service.tpl" > "${TMP_UNIT}"

as_root cp "${TMP_UNIT}" "${UNIT_PATH}"
as_root systemctl daemon-reload
as_root systemctl enable "${SERVICE_NAME}"
echo "Installed systemd unit: ${UNIT_PATH}"
if [[ $EUID -ne 0 ]]; then
  echo "Start with: sudo systemctl start ${SERVICE_NAME}"
fi

rm -f "${TMP_UNIT}"

# Localhost status API for the public landing page (/api/status via nginx).
STATUS_API_SRC="${ROOT_DIR}/native/status-api.py"
STATUS_API_UNIT="/etc/systemd/system/valheim-status-api.service"
if [[ -f "${STATUS_API_SRC}" ]]; then
  as_root chmod +x "${STATUS_API_SRC}"
  TMP_STATUS="$(mktemp)"
  sed -e "s|@STATUS_API@|${STATUS_API_SRC}|g" \
    "${ROOT_DIR}/native/valheim-status-api.service.tpl" > "${TMP_STATUS}"
  as_root cp "${TMP_STATUS}" "${STATUS_API_UNIT}"
  rm -f "${TMP_STATUS}"
  as_root systemctl daemon-reload
  as_root systemctl enable --now valheim-status-api
  echo "Installed systemd unit: ${STATUS_API_UNIT}"
fi

install_cron_job() {
  local schedule="$1"
  local command="$2"
  local marker="# valheim-native:${command##*/}"

  if crontab -l 2>/dev/null | grep -Fq "${marker}"; then
    return 0
  fi

  (
    crontab -l 2>/dev/null || true
    echo "${schedule} ${command} ${marker}"
  ) | crontab -
  echo "Cron installed: ${schedule} ${command}"
}

load_env

if env_bool "${BACKUPS:-true}"; then
  install_cron_job "${BACKUPS_CRON:-0 */6 * * *}" "${ROOT_DIR}/native/backup-world.sh"
fi

if [[ -n "${UPDATE_CRON:-}" ]]; then
  install_cron_job "${UPDATE_CRON}" "${ROOT_DIR}/native/update-server.sh"
fi
