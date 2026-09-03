#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

link_saved_dir
apply_env_to_ini

echo "Config applied under ${LINUX_CONFIG_DIR}"
echo "  Engine.ini / ServerSettings.ini / Game.ini"
