#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

load_env

SERVICE_NAME="${CONAN_SERVICE_NAME:-conan}"
DEFAULT_RUN_USER="conan"

# Conan refuses to run as root. When setup runs over SSH as root (no SUDO_USER),
# fall back to a dedicated system user instead of binding the unit to root.
resolve_run_user() {
  local run_user="${CONAN_RUN_USER:-}"

  if [[ -z "${run_user}" ]]; then
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
      run_user="${SUDO_USER}"
    elif [[ "$(id -un)" != "root" ]]; then
      run_user="$(id -un)"
    else
      run_user="${DEFAULT_RUN_USER}"
    fi
  fi

  if ! id "${run_user}" >/dev/null 2>&1; then
    if [[ $EUID -ne 0 ]]; then
      echo "User '${run_user}' does not exist. Create it or set CONAN_RUN_USER in .env." >&2
      exit 1
    fi
    useradd -r -d "${ROOT_DIR}" -s /usr/sbin/nologin "${run_user}"
    echo "Created system user: ${run_user}"
  fi

  if [[ $EUID -eq 0 ]]; then
    echo "Setting ownership: ${ROOT_DIR} → ${run_user}"
    chown -R "${run_user}:$(id -gn "${run_user}")" "${ROOT_DIR}"
  fi

  RUN_USER="${run_user}"
  RUN_GROUP="$(id -gn "${RUN_USER}")"
}

resolve_run_user

UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
TMP_UNIT="$(mktemp)"

sed \
  -e "s|@RUN_USER@|${RUN_USER}|g" \
  -e "s|@RUN_GROUP@|${RUN_GROUP}|g" \
  -e "s|@SERVER_DIR@|${SERVER_DIR}|g" \
  -e "s|@ENV_FILE@|${ENV_FILE}|g" \
  -e "s|@START_SCRIPT@|${ROOT_DIR}/native/start-server.sh|g" \
  "${ROOT_DIR}/native/conan.service.tpl" > "${TMP_UNIT}"

if [[ $EUID -ne 0 ]]; then
  sudo cp "${TMP_UNIT}" "${UNIT_PATH}"
  sudo systemctl daemon-reload
  sudo systemctl enable "${SERVICE_NAME}"
  echo "Installed systemd unit: ${UNIT_PATH} (User=${RUN_USER})"
  echo "Start with: sudo systemctl start ${SERVICE_NAME}"
else
  cp "${TMP_UNIT}" "${UNIT_PATH}"
  systemctl daemon-reload
  systemctl enable "${SERVICE_NAME}"
  echo "Installed systemd unit: ${UNIT_PATH} (User=${RUN_USER})"
fi

rm -f "${TMP_UNIT}"

install_cron_job() {
  local schedule="$1"
  local command="$2"
  local marker="# conan-native:${command##*/}"
  local existing=""

  if [[ $EUID -eq 0 ]]; then
    existing="$(crontab -u "${RUN_USER}" -l 2>/dev/null || true)"
  else
    existing="$(crontab -l 2>/dev/null || true)"
  fi

  if grep -Fq "${marker}" <<<"${existing}"; then
    return 0
  fi

  if [[ $EUID -eq 0 ]]; then
    (
      echo "${existing}"
      echo "${schedule} ${command} ${marker}"
    ) | crontab -u "${RUN_USER}" -
  else
    (
      echo "${existing}"
      echo "${schedule} ${command} ${marker}"
    ) | crontab -
  fi

  echo "Cron installed for ${RUN_USER}: ${schedule} ${command}"
}

if env_bool "${BACKUPS:-true}"; then
  install_cron_job "${BACKUPS_CRON:-0 */6 * * *}" "${ROOT_DIR}/native/backup-world.sh"
fi

if [[ -n "${UPDATE_CRON:-}" ]]; then
  install_cron_job "${UPDATE_CRON}" "${ROOT_DIR}/native/update-server.sh"
fi
