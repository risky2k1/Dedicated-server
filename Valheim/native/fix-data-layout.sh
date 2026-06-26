#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

ensure_layout

pick_newer_or_larger() {
  local src="$1" dest="$2"

  if [[ ! -e "${dest}" ]]; then
    mv "${src}" "${dest}"
    echo "Moved: $(basename "${src}")"
    return
  fi

  if [[ "${src}" == *.db ]]; then
    local src_size dest_size
    src_size="$(stat -c%s "${src}")"
    dest_size="$(stat -c%s "${dest}")"
    if (( src_size > dest_size )); then
      mv "${src}" "${dest}"
      echo "Replaced (larger .db): $(basename "${dest}")"
    else
      rm -f "${src}"
      echo "Kept existing (larger .db): $(basename "${dest}")"
    fi
    return
  fi

  if [[ "${src}" -nt "${dest}" ]]; then
    mv "${src}" "${dest}"
    echo "Replaced (newer): $(basename "${dest}")"
  else
    rm -f "${src}"
    echo "Kept existing: $(basename "${dest}")"
  fi
}

echo "=== Fix Valheim data layout ==="
echo "Save root: ${WORLD_SAVE_DIR}"
echo "Worlds:    ${WORLDS_DIR}"
echo "BepInEx:   ${BEPINEX_CONFIG_DIR}"
echo ""

nested="${WORLDS_DIR}/worlds_local"
if [[ -d "${nested}" ]]; then
  echo "Fixing nested worlds_local/worlds_local/ ..."
  shopt -s nullglob dotglob
  for item in "${nested}"/*; do
    [[ -e "${item}" ]] || continue
    if [[ -d "${item}" ]]; then
      echo "Skip directory: ${item}"
      continue
    fi
    pick_newer_or_larger "${item}" "${WORLDS_DIR}/$(basename "${item}")"
  done
  shopt -u nullglob dotglob
  rmdir "${nested}" 2>/dev/null || rm -rf "${nested}"
  echo "Removed nested folder: ${nested}"
  echo ""
fi

echo "Consolidating BepInEx config into config/bepinex/config/ ..."
shopt -s nullglob
for cfg in "${CONFIG_DIR}/bepinex"/*.cfg "${CONFIG_DIR}/bepinex"/*.cfg.default; do
  [[ -e "${cfg}" ]] || continue
  base="$(basename "${cfg}")"
  [[ "${base}" == *.default ]] && continue
  pick_newer_or_larger "${cfg}" "${BEPINEX_CONFIG_DIR}/${base}"
done
shopt -u nullglob

rm -f "${CONFIG_DIR}/bepinex/BepInEx.cfg.default" 2>/dev/null || true

if [[ -d "${SERVER_DIR}/BepInEx" ]]; then
  "${ROOT_DIR}/native/link-bepinex-config.sh"
fi

echo ""
echo "Done. Set WORLD_NAME=SuperSeed2 in .env, then:"
echo "  systemctl restart valheim"
echo ""
echo "World files should be at:"
echo "  ${WORLDS_DIR}/SuperSeed2.db"
echo "  ${WORLDS_DIR}/SuperSeed2.fwl"
