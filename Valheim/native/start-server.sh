#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

load_env
ensure_layout
write_adminlist
cp "${ADMINLIST_FILE}" "${SERVER_DIR}/adminlist.txt"

if [[ ! -f "${SERVER_DIR}/valheim_server.x86_64" ]]; then
  echo "Valheim server not installed. Run ./native/setup.sh first." >&2
  exit 1
fi

cd "${SERVER_DIR}"

mapfile -t SERVER_LAUNCH_ARGS < <(build_server_args)

export LD_LIBRARY_PATH="./linux64:${LD_LIBRARY_PATH:-}"
export SteamAppId=892970

use_bepinex=false
if env_bool "${BEPINEX:-true}" && [[ -d "${SERVER_DIR}/BepInEx" ]]; then
  use_bepinex=true
fi

if $use_bepinex; then
  # Doorstop 4.x (BepInExPack Valheim 5.4.23xx+) — matches start_server_bepinex.sh
  export DOORSTOP_ENABLED=1
  export DOORSTOP_TARGET_ASSEMBLY=./BepInEx/core/BepInEx.Preloader.dll
  unset DOORSTOP_ENABLE DOORSTOP_INVOKE_DLL_PATH DOORSTOP_CORLIB_OVERRIDE_PATH || true
  export LD_LIBRARY_PATH="./doorstop_libs:${LD_LIBRARY_PATH}"
  export LD_PRELOAD="libdoorstop_x64.so:${LD_PRELOAD:-}"
fi

echo "Starting Valheim server (BepInEx: ${use_bepinex})..."
echo "World: ${WORLD_NAME} | Worlds: ${WORLDS_DIR}"
exec ./valheim_server.x86_64 "${SERVER_LAUNCH_ARGS[@]}"
