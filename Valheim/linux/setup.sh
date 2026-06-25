#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Created .env — edit PLAYIT_SECRET_KEY and SERVER_PASS before playing."
fi

"${ROOT_DIR}/linux/sync-env-user.sh"
"${ROOT_DIR}/linux/ensure-permissions.sh"
"${ROOT_DIR}/linux/install-servercharacters.sh"

echo ""
echo "Starting server..."
docker compose up -d

echo ""
echo "Done. Logs: docker compose logs -f valheim"
