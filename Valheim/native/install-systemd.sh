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

sed \
  -e "s|@RUN_USER@|${RUN_USER}|g" \
  -e "s|@RUN_GROUP@|${RUN_GROUP}|g" \
  -e "s|@SERVER_DIR@|${SERVER_DIR}|g" \
  -e "s|@ENV_FILE@|${ENV_FILE}|g" \
  -e "s|@START_SCRIPT@|${ROOT_DIR}/native/start-server.sh|g" \
  "${ROOT_DIR}/native/valheim.service.tpl" > "${TMP_UNIT}"

if [[ $EUID -ne 0 ]]; then
  sudo cp "${TMP_UNIT}" "${UNIT_PATH}"
  sudo systemctl daemon-reload
  sudo systemctl enable "${SERVICE_NAME}"
  echo "Installed systemd unit: ${UNIT_PATH}"
  echo "Start with: sudo systemctl start ${SERVICE_NAME}"
else
  cp "${TMP_UNIT}" "${UNIT_PATH}"
  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}"
  echo "Installed systemd unit: ${UNIT_PATH}"
fi

rm -f "${TMP_UNIT}"

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
