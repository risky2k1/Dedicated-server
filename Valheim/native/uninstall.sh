#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_NAME="${VALHEIM_SERVICE_NAME:-valheim}"
REPO_DIR="$(cd "${ROOT_DIR}/.." && pwd)"

echo "=== Valheim native uninstall ==="
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

if crontab -l >/dev/null 2>&1; then
  crontab -l | grep -v 'valheim-native' | crontab - || true
  echo "Removed valheim cron jobs."
fi

if pgrep -f "${ROOT_DIR}/server/valheim_server" >/dev/null 2>&1; then
  pkill -f "${ROOT_DIR}/server/valheim_server" || true
  sleep 2
fi

echo ""
echo "Service/cron stopped."
echo ""
echo "To delete all files, run:"
echo "  rm -rf ${REPO_DIR}"
echo "  rm -rf /root/Steam"
echo ""
echo "Then clone and setup again — see README native section."
