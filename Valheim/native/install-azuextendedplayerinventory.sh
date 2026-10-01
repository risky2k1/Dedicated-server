#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="${ROOT_DIR}/config/bepinex/plugins"

# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

VERSION="${AZUEXTENDEDPLAYERINVENTORY_VERSION:-2.6.1}"
DOWNLOAD_URL="$(hexium_resolve_download_url Azumatt AzuExtendedPlayerInventory "${VERSION}")"

"${ROOT_DIR}/linux/ensure-permissions.sh"
mkdir -p "${PLUGINS_DIR}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "Downloading AzuExtendedPlayerInventory ${VERSION} from Hexium..."
curl -fsSL -A 'Valheim-native-setup' -o "${tmp_dir}/AzuExtendedPlayerInventory.zip" "${DOWNLOAD_URL}"
unzip -qo "${tmp_dir}/AzuExtendedPlayerInventory.zip" -d "${tmp_dir}/extracted"

shopt -s nullglob
dlls=("${tmp_dir}/extracted"/*.dll)
if ((${#dlls[@]} == 0)); then
  echo "No DLL found in AzuExtendedPlayerInventory package." >&2
  exit 1
fi

for dll in "${dlls[@]}"; do
  cp "${dll}" "${PLUGINS_DIR}/$(basename "${dll}")"
  chmod 644 "${PLUGINS_DIR}/$(basename "${dll}")"
  echo "Installed: ${PLUGINS_DIR}/$(basename "${dll}")"
done

echo ""
echo "Restart server:  sudo systemctl restart valheim"
echo "All clients must install AzuExtendedPlayerInventory ${VERSION} (Azumatt) via Gale/Hexium."
