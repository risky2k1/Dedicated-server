#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

SERVICE_NAME="${CONAN_SERVICE_NAME:-conan}"

echo "=== Conan Exiles native uninstall ==="
echo "Project: ${ROOT_DIR}"
echo ""

if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
  echo "Stopping ${SERVICE_NAME}..."
  systemctl stop "${SERVICE_NAME}"
fi

if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
  systemctl disable "${SERVICE_NAME}"
fi

if [[ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]]; then
  rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
  systemctl daemon-reload
  echo "Removed systemd unit: ${SERVICE_NAME}.service"
fi

remove_conan_cron() {
  local user="$1"
  local existing=""

  [[ -z "${user}" ]] && return 0
  id "${user}" >/dev/null 2>&1 || return 0

  if [[ $EUID -eq 0 ]]; then
    existing="$(crontab -u "${user}" -l 2>/dev/null || true)"
    if [[ -n "${existing}" ]]; then
      grep -v 'conan-native' <<<"${existing}" | crontab -u "${user}" - || true
    fi
  elif [[ "$(id -un)" == "${user}" ]] && crontab -l >/dev/null 2>&1; then
    crontab -l | grep -v 'conan-native' | crontab - || true
  fi
}

for cron_user in "${CONAN_RUN_USER:-conan}" root "${SUDO_USER:-}"; do
  remove_conan_cron "${cron_user}"
done
echo "Removed conan cron jobs."

if pgrep -f "ConanSandboxServer-Linux-Shipping" >/dev/null 2>&1; then
  pkill -INT -f "ConanSandboxServer-Linux-Shipping" || true
  sleep 3
fi

echo ""
echo "Service/cron stopped. World data kept in: ${ROOT_DIR}/config/Saved"
echo ""
echo "To delete all files, run:"
echo "  rm -rf ${ROOT_DIR}"
echo "  rm -rf /root/Steam"
echo ""
echo "Or delete only game binaries (keep saves):"
echo "  rm -rf ${ROOT_DIR}/server ${ROOT_DIR}/native/steamcmd"
echo ""
echo "Then clone and setup again — see README native section."
