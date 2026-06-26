#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

ensure_layout

if [[ -x "${STEAMCMD_DIR}/steamcmd.sh" ]]; then
  echo "SteamCMD already installed: ${STEAMCMD_DIR}/steamcmd.sh"
  exit 0
fi

echo "Installing SteamCMD..."
curl -fsSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
  | tar -xzf - -C "${STEAMCMD_DIR}"

echo "Installed: ${STEAMCMD_DIR}/steamcmd.sh"
