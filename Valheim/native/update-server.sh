#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

SERVICE_NAME="${VALHEIM_SERVICE_NAME:-valheim}"

if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
  echo "Server is running. Stop it first: sudo systemctl stop ${SERVICE_NAME}"
  exit 1
fi

if pgrep -f "${SERVER_DIR}/valheim_server.x86_64" >/dev/null 2>&1; then
  echo "Valheim process is running. Stop it before updating."
  exit 1
fi

if [[ ! -x "${STEAMCMD_DIR}/steamcmd.sh" ]]; then
  echo "SteamCMD not found." >&2
  exit 1
fi

echo "Updating Valheim dedicated server..."
"${STEAMCMD_DIR}/steamcmd.sh" \
  +force_install_dir "${SERVER_DIR}" \
  +login anonymous \
  +app_update 896660 validate \
  +quit

load_env
if env_bool "${BEPINEX:-true}"; then
  "${ROOT_DIR}/native/link-bepinex-config.sh"
fi

echo "Update complete."
