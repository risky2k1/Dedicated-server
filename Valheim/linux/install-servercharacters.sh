#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="${ROOT_DIR}/config/bepinex/plugins"
VERSION="${SERVERCHARACTERS_VERSION:-1.4.16}"
DOWNLOAD_URL="https://thunderstore.io/package/download/Smoothbrain/ServerCharacters/${VERSION}/"

"${ROOT_DIR}/linux/ensure-permissions.sh"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

echo "Downloading ServerCharacters ${VERSION}..."
curl -fsSL -o "${tmp_dir}/ServerCharacters.zip" "${DOWNLOAD_URL}"
unzip -qo "${tmp_dir}/ServerCharacters.zip" ServerCharacters.dll -d "${tmp_dir}"
cp "${tmp_dir}/ServerCharacters.dll" "${PLUGINS_DIR}/ServerCharacters.dll"
chmod 644 "${PLUGINS_DIR}/ServerCharacters.dll"

echo "Installed: ${PLUGINS_DIR}/ServerCharacters.dll"
