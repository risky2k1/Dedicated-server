#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

load_env
ensure_layout

VERSION="${BEPINEX_PACK_VERSION:-5.4.2202}"
DOWNLOAD_URL="https://thunderstore.io/package/download/denikson/BepInExPack_Valheim/${VERSION}/"

if [[ ! -f "${SERVER_DIR}/valheim_server.x86_64" ]]; then
  echo "Valheim server not found. Run native/install-server.sh first." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "Downloading BepInExPack ${VERSION}..."
curl -fsSL -o "${tmp_dir}/BepInExPack.zip" "${DOWNLOAD_URL}"
unzip -qo "${tmp_dir}/BepInExPack.zip" -d "${tmp_dir}"

cp -a "${tmp_dir}/BepInExPack_Valheim/." "${SERVER_DIR}/"
chmod +x "${SERVER_DIR}/start_server_bepinex.sh" 2>/dev/null || true

"${ROOT_DIR}/native/link-bepinex-config.sh"

echo "BepInEx installed: ${SERVER_DIR}/BepInEx"
