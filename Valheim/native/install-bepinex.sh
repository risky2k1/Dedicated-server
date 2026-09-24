#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

load_env
ensure_layout

VERSION="${BEPINEX_PACK_VERSION:-5.4.2351}"
DOWNLOAD_URL="$(hexium_resolve_download_url denikson BepInExPack_Valheim "${VERSION}")"

if [[ ! -f "${SERVER_DIR}/valheim_server.x86_64" ]]; then
  echo "Valheim server not found. Run native/install-server.sh first." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "Downloading BepInExPack ${VERSION} from Hexium..."
curl -fsSL -A 'Valheim-native-setup' -o "${tmp_dir}/BepInExPack.zip" "${DOWNLOAD_URL}"
unzip -qo "${tmp_dir}/BepInExPack.zip" -d "${tmp_dir}"

PACK_DIR="${tmp_dir}/BepInExPack_Valheim"
# Copy pack without clobbering BepInEx/config & plugins symlinks
cp -a "${PACK_DIR}/changelog.txt" "${PACK_DIR}/doorstop_config.ini"   "${PACK_DIR}/start_game_bepinex.sh" "${PACK_DIR}/start_server_bepinex.sh"   "${PACK_DIR}/winhttp.dll" "${SERVER_DIR}/"
[[ -f "${PACK_DIR}/.doorstop_version" ]] && cp -a "${PACK_DIR}/.doorstop_version" "${SERVER_DIR}/"
mkdir -p "${SERVER_DIR}/doorstop_libs"
cp -a "${PACK_DIR}/doorstop_libs/." "${SERVER_DIR}/doorstop_libs/"
mkdir -p "${SERVER_DIR}/BepInEx/core"
cp -a "${PACK_DIR}/BepInEx/core/." "${SERVER_DIR}/BepInEx/core/"
chmod +x "${SERVER_DIR}/start_server_bepinex.sh" "${SERVER_DIR}/start_game_bepinex.sh" 2>/dev/null || true

"${ROOT_DIR}/native/link-bepinex-config.sh"

echo "BepInEx installed: ${SERVER_DIR}/BepInEx"
