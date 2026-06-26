#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UID_VAL="$(id -u)"
GID_VAL="$(id -g)"

mkdir -p "${ROOT_DIR}/config/bepinex/plugins" \
         "${ROOT_DIR}/config/bepinex/config" \
         "${ROOT_DIR}/config/worlds_local" \
         "${ROOT_DIR}/config/backups" \
         "${ROOT_DIR}/data"

needs_sudo=false
for path in \
  "${ROOT_DIR}/config" \
  "${ROOT_DIR}/data" \
  "${ROOT_DIR}/config/bepinex/plugins"; do
  if [[ -e "$path" ]] && [[ ! -w "$path" ]]; then
    needs_sudo=true
    break
  fi
done

if [[ -f "${ROOT_DIR}/config/bepinex/plugins/ServerCharacters.dll" ]] \
  && [[ ! -w "${ROOT_DIR}/config/bepinex/plugins/ServerCharacters.dll" ]]; then
  needs_sudo=true
fi

if $needs_sudo; then
  echo "Fixing ownership (config/data owned by root from Docker)..."
  if ! chown -R "${UID_VAL}:${GID_VAL}" "${ROOT_DIR}/config" "${ROOT_DIR}/data" 2>/dev/null; then
    echo ""
    echo "Need sudo once to fix permissions:"
    echo "  sudo chown -R ${UID_VAL}:${GID_VAL} config data"
    echo ""
    echo "Then run ./linux/setup.sh again."
    exit 1
  fi
fi

# Keep dirs owned by current user even when empty
chown -R "${UID_VAL}:${GID_VAL}" "${ROOT_DIR}/config" "${ROOT_DIR}/data" 2>/dev/null || true
