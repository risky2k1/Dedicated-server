#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

ensure_layout

if [[ ! -x "${STEAMCMD_DIR}/steamcmd.sh" ]]; then
  echo "Installing SteamCMD..."
  curl -fsSL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" \
    | tar -xzf - -C "${STEAMCMD_DIR}"
fi

if [[ ! -f "${STEAMCMD_DIR}/.bootstrapped" ]]; then
  echo "Bootstrapping SteamCMD (first run self-update)..."
  "${STEAMCMD_DIR}/steamcmd.sh" +quit
  touch "${STEAMCMD_DIR}/.bootstrapped"
fi

echo "SteamCMD ready: ${STEAMCMD_DIR}/steamcmd.sh"
