#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

load_env
ensure_layout

if [[ ! -d "${SAVED_DIR}" ]]; then
  echo "No save data to backup in ${SAVED_DIR}"
  exit 0
fi

# Prefer offline backup (server stopped). Live copy of SQLite can corrupt.
SERVICE_NAME="${CONAN_SERVICE_NAME:-conan}"
if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
  echo "Warning: server is running — SQLite backup may be inconsistent. Prefer: sudo systemctl stop ${SERVICE_NAME}" >&2
fi

timestamp="$(date +%Y%m%d-%H%M%S)"
archive="${BACKUP_DIR}/saved-${timestamp}.tar.gz"

# World DB + configs (skip huge log spam)
tar -czf "${archive}" \
  -C "${CONFIG_DIR}" \
  --exclude='Saved/Logs' \
  Saved

echo "Backup created: ${archive}"

max_count="${BACKUPS_MAX_COUNT:-5}"
if [[ "${max_count}" =~ ^[0-9]+$ ]] && (( max_count > 0 )); then
  mapfile -t backups < <(ls -1t "${BACKUP_DIR}"/saved-*.tar.gz 2>/dev/null || true)
  if ((${#backups[@]} > max_count)); then
    for old in "${backups[@]:max_count}"; do
      rm -f "${old}"
      echo "Removed old backup: ${old}"
    done
  fi
fi

max_age="${BACKUPS_MAX_AGE:-3}"
if [[ "${max_age}" =~ ^[0-9]+$ ]] && (( max_age > 0 )); then
  find "${BACKUP_DIR}" -name 'saved-*.tar.gz' -mtime +"${max_age}" -delete
fi
