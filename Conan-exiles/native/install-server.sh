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

if [[ -f "${CONAN_BINARY}" ]]; then
  echo "Conan server already installed: ${CONAN_BINARY}"
  exit 0
fi

avail_kb="$(df -Pk "${SERVER_DIR}" | awk 'NR==2 {print $4}')"
if [[ -n "${avail_kb}" && "${avail_kb}" -lt 6291456 ]]; then
  echo "Warning: less than 6 GB free disk (${avail_kb} KB). Conan needs ~5 GB installed." >&2
fi

run_steamcmd_update() {
  # Force Linux depot — default platform for 443030 is Windows ("Missing configuration").
  "${STEAMCMD_DIR}/steamcmd.sh" \
    +@sSteamCmdForcePlatformType linux \
    +force_install_dir "${SERVER_DIR}" \
    +login anonymous \
    +app_info_update 1 \
    +app_update "${CONAN_APP_ID}" validate \
    +quit
}

echo "Downloading Conan Exiles Enhanced dedicated server (~3–5 GB). This may take a while..."

max_attempts=5
attempt=1
while (( attempt <= max_attempts )); do
  echo "SteamCMD attempt ${attempt}/${max_attempts}..."

  set +e
  output="$(run_steamcmd_update 2>&1)"
  status=$?
  set -e
  printf '%s\n' "${output}"

  if [[ -f "${CONAN_BINARY}" ]]; then
    chmod +x "${CONAN_BINARY}"
    echo "Conan server installed: ${SERVER_DIR}"
    exit 0
  fi

  if grep -q "Missing configuration" <<<"${output}"; then
    echo "SteamCMD returned 'Missing configuration' (known flake for app 443030) — retrying..."
    rm -rf "${SERVER_DIR}/steamapps/downloading/${CONAN_APP_ID}"
    sleep 5
  elif (( status != 0 )); then
    echo "SteamCMD exited with code ${status}."
    rm -rf "${SERVER_DIR}/steamapps/downloading/${CONAN_APP_ID}"
    sleep 5
  else
    echo "SteamCMD exit 0 but Linux binary missing — retrying with platform force..."
    sleep 5
  fi

  ((attempt++))
done

echo ""
echo "Failed to install Conan after ${max_attempts} attempts." >&2
echo "Try manually:" >&2
echo "  ${STEAMCMD_DIR}/steamcmd.sh +@sSteamCmdForcePlatformType linux +force_install_dir ${SERVER_DIR} +login anonymous +app_info_update 1 +app_update ${CONAN_APP_ID} validate +quit" >&2
echo "Expect binary: ${CONAN_BINARY}" >&2
exit 1
