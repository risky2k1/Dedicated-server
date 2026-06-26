#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1" >&2
    exit 1
  fi
}

for cmd in curl unzip tar; do
  need_cmd "${cmd}"
done

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env — edit SERVER_PASS, SERVER_NAME, WORLD_NAME before playing."
fi

"${ROOT_DIR}/linux/sync-env-user.sh"
"${ROOT_DIR}/linux/ensure-permissions.sh"

# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

if ! dpkg -s lib32gcc-s1 >/dev/null 2>&1; then
  echo ""
  echo "Installing system packages (needs sudo once)..."
  "${ROOT_DIR}/native/install-deps.sh"
fi

"${ROOT_DIR}/native/install-steamcmd.sh"
"${ROOT_DIR}/native/install-server.sh"

if env_bool "${BEPINEX:-true}"; then
  "${ROOT_DIR}/native/install-bepinex.sh"
else
  echo "BEPINEX=false — skipping BepInEx."
fi

"${ROOT_DIR}/native/install-servercharacters.sh"
"${ROOT_DIR}/native/install-systemd.sh"

echo ""
echo "Native setup complete."
echo ""
echo "Next steps:"
echo "  1. Edit .env (SERVER_PASS, WORLD_NAME, SERVER_ARGS, ...)"
echo "  2. Open firewall UDP 2456-2457 on VPS:"
echo "       sudo ufw allow 2456:2457/udp"
echo "  3. Start server:"
echo "       sudo systemctl start valheim"
echo "  4. Logs:"
echo "       journalctl -u valheim -f"
echo ""
echo "Manual start (without systemd): ./native/start-server.sh"
