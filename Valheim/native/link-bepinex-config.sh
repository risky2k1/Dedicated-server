#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

ensure_layout

if [[ ! -d "${SERVER_DIR}/BepInEx" ]]; then
  echo "BepInEx not installed in ${SERVER_DIR}." >&2
  exit 1
fi

# Move legacy cfg files from config/bepinex/*.cfg into config/bepinex/config/
shopt -s nullglob
for cfg in "${CONFIG_DIR}/bepinex"/*.cfg; do
  mv -n "${cfg}" "${BEPINEX_CONFIG_DIR}/"
done
shopt -u nullglob

rm -rf "${SERVER_DIR}/BepInEx/plugins" "${SERVER_DIR}/BepInEx/config"
ln -sfn "${PLUGINS_DIR}" "${SERVER_DIR}/BepInEx/plugins"
ln -sfn "${BEPINEX_CONFIG_DIR}" "${SERVER_DIR}/BepInEx/config"

echo "Linked BepInEx:"
echo "  plugins -> ${PLUGINS_DIR}"
echo "  config  -> ${BEPINEX_CONFIG_DIR}"
