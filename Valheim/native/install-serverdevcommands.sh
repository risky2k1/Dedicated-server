#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="${ROOT_DIR}/config/bepinex/plugins"

# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

VERSION="${SERVER_DEVCOMMANDS_VERSION:-1.108.0}"
DOWNLOAD_URL="https://thunderstore.io/package/download/JereKuusela/Server_devcommands/${VERSION}/"

"${ROOT_DIR}/linux/ensure-permissions.sh"
mkdir -p "${PLUGINS_DIR}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "Downloading Server devcommands ${VERSION}..."
curl -fsSL -o "${tmp_dir}/Server_devcommands.zip" "${DOWNLOAD_URL}"
unzip -qo "${tmp_dir}/Server_devcommands.zip" ServerDevcommands.dll -d "${tmp_dir}"
cp "${tmp_dir}/ServerDevcommands.dll" "${PLUGINS_DIR}/ServerDevcommands.dll"
chmod 644 "${PLUGINS_DIR}/ServerDevcommands.dll"

echo ""
echo "Installed: ${PLUGINS_DIR}/ServerDevcommands.dll"
echo ""
echo "Restart server:  sudo systemctl restart valheim"
echo "Admin client:    cài mod Server devcommands (JereKuusela) cùng version ${VERSION} qua r2modman/Thunderstore."
echo "Other players:   không cần mod này."
