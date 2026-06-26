#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

if [[ -z "${ROOT_DIR:-}" ]]; then
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

STEAMCMD_DIR="${ROOT_DIR}/native/steamcmd"
SERVER_DIR="${ROOT_DIR}/server"
CONFIG_DIR="${ROOT_DIR}/config"
BACKUP_DIR="${CONFIG_DIR}/backups"
PLUGINS_DIR="${CONFIG_DIR}/bepinex/plugins"
BEPINEX_CONFIG_DIR="${CONFIG_DIR}/bepinex/config"
ADMINLIST_FILE="${CONFIG_DIR}/adminlist.txt"
ENV_FILE="${ROOT_DIR}/.env"

load_env() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    return 0
  fi

  local line key value
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line}" || "${line}" =~ ^[[:space:]]*# ]] && continue

    if [[ ! "${line}" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      continue
    fi

    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"

    if [[ "${value}" =~ ^\"(.*)\"$ ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "${value}" =~ ^\'(.*)\'$ ]]; then
      value="${BASH_REMATCH[1]}"
    fi

    export "${key}=${value}"
  done < "${ENV_FILE}"
}

env_bool() {
  local value="${1:-}"
  case "${value,,}" in
    true | 1 | yes) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_layout() {
  mkdir -p \
    "${CONFIG_DIR}/worlds_local" \
    "${PLUGINS_DIR}" \
    "${BEPINEX_CONFIG_DIR}" \
    "${BACKUP_DIR}" \
    "${STEAMCMD_DIR}" \
    "${SERVER_DIR}"
}

write_adminlist() {
  load_env
  if [[ -n "${ADMINLIST_IDS:-}" ]]; then
  {
    for id in ${ADMINLIST_IDS}; do
      echo "${id}"
    done
  } > "${ADMINLIST_FILE}"
  else
    : > "${ADMINLIST_FILE}"
  fi
}

build_server_args() {
  load_env
  local args=(
    -name "${SERVER_NAME:?SERVER_NAME is required}"
    -port 2456
    -world "${WORLD_NAME:?WORLD_NAME is required}"
    -password "${SERVER_PASS:?SERVER_PASS is required}"
    -savedir "${CONFIG_DIR}/worlds_local"
  )

  if env_bool "${SERVER_PUBLIC:-false}"; then
    args+=(-public 1)
  else
    args+=(-public 0)
  fi

  if env_bool "${CROSSPLAY:-false}"; then
    args+=(-crossplay)
  fi

  if [[ -n "${SERVER_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    local extra=(${SERVER_ARGS})
    args+=("${extra[@]}")
  fi

  printf '%s\n' "${args[@]}"
}
