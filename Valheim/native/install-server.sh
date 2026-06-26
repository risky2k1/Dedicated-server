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

if [[ -f "${SERVER_DIR}/valheim_server.x86_64" ]]; then
  echo "Valheim server already installed: ${SERVER_DIR}/valheim_server.x86_64"
  exit 0
fi

avail_kb="$(df -Pk "${SERVER_DIR}" | awk 'NR==2 {print $4}')"
if [[ -n "${avail_kb}" && "${avail_kb}" -lt 3145728 ]]; then
  echo "Warning: less than 3 GB free disk (${avail_kb} KB). Valheim needs ~2 GB to download." >&2
fi

run_steamcmd_update() {
  "${STEAMCMD_DIR}/steamcmd.sh" \
    +force_install_dir "${SERVER_DIR}" \
    +login anonymous \
    +app_update 896660 validate \
    +quit
}

echo "Downloading Valheim dedicated server (~1 GB). This may take several minutes..."

max_attempts=3
attempt=1
while (( attempt <= max_attempts )); do
  echo "SteamCMD attempt ${attempt}/${max_attempts}..."

  set +e
  output="$(run_steamcmd_update 2>&1)"
  status=$?
  set -e
  printf '%s\n' "${output}"

  if [[ -f "${SERVER_DIR}/valheim_server.x86_64" ]]; then
    echo "Valheim server installed: ${SERVER_DIR}"
    exit 0
  fi

  if grep -q "Missing configuration" <<<"${output}"; then
    echo "SteamCMD returned 'Missing configuration' (known transient bug) — retrying..."
    rm -rf "${SERVER_DIR}/steamapps/downloading/896660"
    sleep 5
  elif (( status != 0 )); then
    echo "SteamCMD exited with code ${status}."
    rm -rf "${SERVER_DIR}/steamapps/downloading/896660"
    sleep 5
  fi

  ((attempt++))
done

echo ""
echo "Failed to install Valheim after ${max_attempts} attempts." >&2
echo "Try manually on VPS:" >&2
echo "  rm -rf ${SERVER_DIR}/steamapps/downloading/896660" >&2
echo "  ${STEAMCMD_DIR}/steamcmd.sh +quit" >&2
echo "  ${STEAMCMD_DIR}/steamcmd.sh +force_install_dir ${SERVER_DIR} +login anonymous +app_update 896660 validate +quit" >&2
echo "Also check: df -h .  and  dpkg -l lib32gcc-s1" >&2
exit 1
