#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

load_env
ensure_layout

WORLDS_DIR="${CONFIG_DIR}/worlds_local"
if [[ ! -d "${WORLDS_DIR}" ]] || [[ -z "$(ls -A "${WORLDS_DIR}" 2>/dev/null)" ]]; then
  echo "No world data to backup in ${WORLDS_DIR}"
  exit 0
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
archive="${BACKUP_DIR}/worlds-${timestamp}.tar.gz"

tar -czf "${archive}" -C "${CONFIG_DIR}" worlds_local
echo "Backup created: ${archive}"

max_count="${BACKUPS_MAX_COUNT:-5}"
if [[ "${max_count}" =~ ^[0-9]+$ ]] && (( max_count > 0 )); then
  mapfile -t backups < <(ls -1t "${BACKUP_DIR}"/worlds-*.tar.gz 2>/dev/null || true)
  if ((${#backups[@]} > max_count)); then
    for old in "${backups[@]:max_count}"; do
      rm -f "${old}"
      echo "Removed old backup: ${old}"
    done
  fi
fi

max_age="${BACKUPS_MAX_AGE:-3}"
if [[ "${max_age}" =~ ^[0-9]+$ ]] && (( max_age > 0 )); then
  find "${BACKUP_DIR}" -name 'worlds-*.tar.gz' -mtime +"${max_age}" -delete
fi
