#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

ensure_layout

if [[ ! -x "${STEAMCMD_DIR}/steamcmd.sh" ]]; then
  echo "SteamCMD not found. Run native/install-steamcmd.sh first." >&2
  exit 1
fi

echo "Downloading Valheim dedicated server (~1 GB). This may take several minutes..."
"${STEAMCMD_DIR}/steamcmd.sh" \
  +force_install_dir "${SERVER_DIR}" \
  +login anonymous \
  +app_update 896660 validate \
  +quit

echo "Valheim server installed: ${SERVER_DIR}"
