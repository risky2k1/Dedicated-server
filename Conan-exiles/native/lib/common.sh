#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

if [[ -z "${ROOT_DIR:-}" ]]; then
  ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

STEAMCMD_DIR="${ROOT_DIR}/native/steamcmd"
SERVER_DIR="${ROOT_DIR}/server"
CONFIG_DIR="${ROOT_DIR}/config"
SAVED_DIR="${CONFIG_DIR}/Saved"
LINUX_CONFIG_DIR="${SAVED_DIR}/Config/LinuxServer"
BACKUP_DIR="${CONFIG_DIR}/backups"
ENV_FILE="${ROOT_DIR}/.env"

# Steam app / binary
CONAN_APP_ID=443030
CONAN_BINARY_REL="ConanSandbox/Binaries/Linux/ConanSandboxServer-Linux-Shipping"
CONAN_BINARY="${SERVER_DIR}/${CONAN_BINARY_REL}"
SERVER_SAVED_LINK="${SERVER_DIR}/ConanSandbox/Saved"

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
    "${LINUX_CONFIG_DIR}" \
    "${BACKUP_DIR}" \
    "${STEAMCMD_DIR}" \
    "${SERVER_DIR}" \
    "${SAVED_DIR}/Logs"
}

# Point game Saved/ at repo config/Saved (world + ini).
link_saved_dir() {
  ensure_layout
  mkdir -p "${SERVER_DIR}/ConanSandbox"

  if [[ -L "${SERVER_SAVED_LINK}" ]]; then
    local target
    target="$(readlink -f "${SERVER_SAVED_LINK}" 2>/dev/null || true)"
    if [[ "${target}" == "$(readlink -f "${SAVED_DIR}")" ]]; then
      return 0
    fi
    rm -f "${SERVER_SAVED_LINK}"
  elif [[ -d "${SERVER_SAVED_LINK}" && ! -L "${SERVER_SAVED_LINK}" ]]; then
    # First install created Saved under server/ — migrate once.
    if [[ -z "$(ls -A "${SAVED_DIR}" 2>/dev/null | grep -v Config || true)" ]] \
      && [[ ! -f "${SAVED_DIR}/game_0.db" ]]; then
      echo "Migrating server/ConanSandbox/Saved → config/Saved ..."
      shopt -s dotglob nullglob
      for item in "${SERVER_SAVED_LINK}"/*; do
        local base
        base="$(basename "${item}")"
        if [[ ! -e "${SAVED_DIR}/${base}" ]]; then
          mv "${item}" "${SAVED_DIR}/"
        fi
      done
      shopt -u dotglob nullglob
    fi
    rm -rf "${SERVER_SAVED_LINK}"
  fi

  ln -sfn "${SAVED_DIR}" "${SERVER_SAVED_LINK}"
}

# Upsert KEY=VALUE under [Section] in an INI file (creates section if missing).
ini_set() {
  local file="$1" section="$2" key="$3" value="$4"
  local tmp
  tmp="$(mktemp)"

  mkdir -p "$(dirname "${file}")"
  touch "${file}"

  awk -v section="${section}" -v key="${key}" -v value="${value}" '
    BEGIN {
      in_section = 0
      done_set = 0
      section_header = "[" section "]"
    }
    /^\[/ {
      if (in_section && !done_set) {
        print key "=" value
        done_set = 1
      }
      in_section = ($0 == section_header)
      print
      next
    }
    in_section && $0 ~ ("^" key "=") {
      print key "=" value
      done_set = 1
      next
    }
    { print }
    END {
      if (!done_set) {
        if (!in_section) {
          print ""
          print section_header
        }
        print key "=" value
      }
    }
  ' "${file}" > "${tmp}"

  mv "${tmp}" "${file}"
}

apply_env_to_ini() {
  load_env
  ensure_layout

  local engine="${LINUX_CONFIG_DIR}/Engine.ini"
  local settings="${LINUX_CONFIG_DIR}/ServerSettings.ini"
  local game="${LINUX_CONFIG_DIR}/Game.ini"

  touch "${engine}" "${settings}" "${game}"

  ini_set "${engine}" "OnlineSubsystemSteam" "ServerName" "${SERVER_NAME:-My Conan Server}"
  ini_set "${engine}" "URL" "Port" "${SERVER_PORT:-7777}"
  ini_set "${engine}" "OnlineSubsystemNull" "GameServerQueryPort" "${QUERY_PORT:-27015}"

  if [[ -n "${SERVER_PASSWORD:-}" ]]; then
    ini_set "${engine}" "OnlineSubsystemSteam" "ServerPassword" "${SERVER_PASSWORD}"
    ini_set "${settings}" "ServerSettings" "ServerPassword" "${SERVER_PASSWORD}"
  fi

  ini_set "${settings}" "ServerSettings" "AdminPassword" "${ADMIN_PASSWORD:?ADMIN_PASSWORD is required in .env}"
  ini_set "${settings}" "ServerSettings" "MaxPlayers" "${MAX_PLAYERS:-40}"
  ini_set "${settings}" "ServerSettings" "MaxNudity" "${MAX_NUDITY:-1}"
  ini_set "${settings}" "ServerSettings" "IsBattlEyeEnabled" "${BATTLEYE:-False}"

  if env_bool "${PVP_ENABLED:-false}"; then
    ini_set "${settings}" "ServerSettings" "PVPEnabled" "True"
  else
    ini_set "${settings}" "ServerSettings" "PVPEnabled" "False"
  fi

  ini_set "${game}" "/Script/Engine.GameSession" "MaxPlayers" "${MAX_PLAYERS:-40}"

  if env_bool "${RCON_ENABLED:-true}"; then
    ini_set "${game}" "RconPlugin" "RconEnabled" "True"
    ini_set "${game}" "RconPlugin" "RconPassword" "${RCON_PASSWORD:-${ADMIN_PASSWORD}}"
    ini_set "${game}" "RconPlugin" "RconPort" "${RCON_PORT:-25575}"
    ini_set "${game}" "RconPlugin" "RconMaxClients" "${RCON_MAX_CLIENTS:-5}"
  else
    ini_set "${game}" "RconPlugin" "RconEnabled" "False"
  fi
}

build_server_args() {
  load_env
  local args=(
    -log
    -Port="${SERVER_PORT:-7777}"
    -QueryPort="${QUERY_PORT:-27015}"
    -MaxPlayers="${MAX_PLAYERS:-40}"
    -ServerName="${SERVER_NAME:-My Conan Server}"
    -Multihome="${MULTIHOME:-0.0.0.0}"
  )

  if [[ -n "${SERVER_PASSWORD:-}" ]]; then
    args+=(-ServerPassword="${SERVER_PASSWORD}")
  fi

  if env_bool "${RCON_ENABLED:-true}"; then
    args+=(
      -RconEnabled=1
      -RconPassword="${RCON_PASSWORD:-${ADMIN_PASSWORD}}"
      -RconPort="${RCON_PORT:-25575}"
    )
  fi

  if [[ -n "${SERVER_ARGS:-}" ]]; then
    # shellcheck disable=SC2206
    local extra=(${SERVER_ARGS})
    args+=("${extra[@]}")
  fi

  printf '%s\n' "${args[@]}"
}
