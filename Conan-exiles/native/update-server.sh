#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

SERVICE_NAME="${CONAN_SERVICE_NAME:-conan}"

if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
  echo "Server is running. Stop it first: sudo systemctl stop ${SERVICE_NAME}"
  exit 1
fi

if pgrep -f "ConanSandboxServer-Linux-Shipping" >/dev/null 2>&1; then
  echo "Conan process is running. Stop it before updating."
  exit 1
fi

if [[ ! -x "${STEAMCMD_DIR}/steamcmd.sh" ]]; then
  echo "SteamCMD not found." >&2
  exit 1
fi

echo "Updating Conan Exiles dedicated server (Linux depot)..."
"${STEAMCMD_DIR}/steamcmd.sh" \
  +@sSteamCmdForcePlatformType linux \
  +force_install_dir "${SERVER_DIR}" \
  +login anonymous \
  +app_info_update 1 \
  +app_update "${CONAN_APP_ID}" validate \
  +quit

if [[ ! -f "${CONAN_BINARY}" ]]; then
  echo "Update finished but binary missing: ${CONAN_BINARY}" >&2
  exit 1
fi

chmod +x "${CONAN_BINARY}"
link_saved_dir
"${ROOT_DIR}/native/apply-config.sh"

echo "Update complete."
