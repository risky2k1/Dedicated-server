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

for cmd in curl tar; do
  need_cmd "${cmd}"
done

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env — edit ADMIN_PASSWORD, SERVER_NAME, SERVER_PASSWORD before playing."
fi

# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

if [[ -z "${ADMIN_PASSWORD:-}" || "${ADMIN_PASSWORD}" == "changeme-admin" ]]; then
  echo ""
  echo "WARNING: Set a real ADMIN_PASSWORD in .env before going live."
fi

if ! dpkg -s lib32gcc-s1 >/dev/null 2>&1; then
  echo ""
  echo "Installing system packages (needs sudo once)..."
  "${ROOT_DIR}/native/install-deps.sh"
fi

"${ROOT_DIR}/native/install-steamcmd.sh"
"${ROOT_DIR}/native/install-server.sh"
"${ROOT_DIR}/native/apply-config.sh"
"${ROOT_DIR}/native/install-systemd.sh"

echo ""
echo "Native setup complete."
echo ""
echo "IMPORTANT: Conan Exiles Enhanced needs ~9 GB RAM idle (16 GB recommended)."
echo "A 2 GB VPS will not run this game."
echo ""
echo "Next steps:"
echo "  1. Edit .env (ADMIN_PASSWORD, SERVER_NAME, SERVER_PASSWORD, ...)"
echo "  2. Re-apply config after edits: ./native/apply-config.sh"
echo "  3. Open firewall:"
echo "       sudo ufw allow 7777:7778/udp"
echo "       sudo ufw allow 27015/udp"
echo "       # optional RCON: sudo ufw allow 25575/tcp"
echo "  4. Start server:"
echo "       sudo systemctl start conan"
echo "  5. Logs:"
echo "       journalctl -u conan -f"
echo "       # or: tail -f config/Saved/Logs/ConanSandbox.log"
echo ""
echo "Manual start (without systemd): ./native/start-server.sh"
