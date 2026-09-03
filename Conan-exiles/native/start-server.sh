#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"

load_env
link_saved_dir
apply_env_to_ini

if [[ ! -f "${CONAN_BINARY}" ]]; then
  echo "Conan server not installed. Run ./native/setup.sh first." >&2
  exit 1
fi

chmod +x "${CONAN_BINARY}"

cd "${SERVER_DIR}"

mapfile -t SERVER_LAUNCH_ARGS < <(build_server_args)

export LD_LIBRARY_PATH="${SERVER_DIR}/ConanSandbox/Binaries/Linux:${LD_LIBRARY_PATH:-}"

echo "Starting Conan Exiles Enhanced (native Linux)..."
echo "Name: ${SERVER_NAME:-My Conan Server} | Port: ${SERVER_PORT:-7777} | Query: ${QUERY_PORT:-27015}"
echo "Saves: ${SAVED_DIR}"

# CWD = install root (same as Windows ConanSandboxServer.exe layout)
exec "./${CONAN_BINARY_REL}" "${SERVER_LAUNCH_ARGS[@]}"
