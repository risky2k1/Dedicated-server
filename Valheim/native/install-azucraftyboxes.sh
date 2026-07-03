#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="${ROOT_DIR}/config/bepinex/plugins"

# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

VERSION="${AZUCRAFTYBOXES_VERSION:-1.8.14}"
DOWNLOAD_URL="https://thunderstore.io/package/download/Azumatt/AzuCraftyBoxes/${VERSION}/"

"${ROOT_DIR}/linux/ensure-permissions.sh"
mkdir -p "${PLUGINS_DIR}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "Downloading AzuCraftyBoxes ${VERSION}..."
curl -fsSL -o "${tmp_dir}/AzuCraftyBoxes.zip" "${DOWNLOAD_URL}"
unzip -qo "${tmp_dir}/AzuCraftyBoxes.zip" -d "${tmp_dir}/extracted"

shopt -s nullglob
dlls=("${tmp_dir}/extracted"/*.dll)
if ((${#dlls[@]} == 0)); then
  echo "No DLL found in AzuCraftyBoxes package." >&2
  exit 1
fi

for dll in "${dlls[@]}"; do
  cp "${dll}" "${PLUGINS_DIR}/$(basename "${dll}")"
  chmod 644 "${PLUGINS_DIR}/$(basename "${dll}")"
  echo "Installed: ${PLUGINS_DIR}/$(basename "${dll}")"
done

echo ""
echo "Restart server:  sudo systemctl restart valheim"
echo "All clients must install AzuCraftyBoxes ${VERSION} (Azumatt) via r2modman/Thunderstore."
