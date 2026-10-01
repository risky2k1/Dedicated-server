#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="${ROOT_DIR}/config/bepinex/plugins"

# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

# Hexium does not publish these. Gale installs the Thunderstore packages.
# Jotunn: ValheimModding/Jotunn. Better Wisps: Digitalroot/Better_Wisps.
VERSION="${BETTER_WISPS_VERSION:-1.0.44}"
JOTUNN_VERSION="${JOTUNN_VERSION:-2.30.2}"
WISPS_URL="https://thunderstore.io/package/download/Digitalroot/Better_Wisps/${VERSION}/"
JOTUNN_URL="https://thunderstore.io/package/download/ValheimModding/Jotunn/${JOTUNN_VERSION}/"

"${ROOT_DIR}/linux/ensure-permissions.sh"
mkdir -p "${PLUGINS_DIR}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

install_zip_dlls() {
  local label="$1"
  local url="$2"
  local archive="${tmp_dir}/${label}.zip"
  local extracted="${tmp_dir}/${label}"

  echo "Downloading ${label}..."
  curl -fsSL -A 'Valheim-native-setup' -L -o "${archive}" "${url}"
  mkdir -p "${extracted}"
  unzip -qo "${archive}" -d "${extracted}"

  local dll base count=0
  while IFS= read -r dll; do
    [[ -n "${dll}" ]] || continue
    base="$(basename "${dll}")"
    cp "${dll}" "${PLUGINS_DIR}/${base}"
    chmod 644 "${PLUGINS_DIR}/${base}"
    echo "Installed: ${PLUGINS_DIR}/${base}"
    count=$((count + 1))
  done < <(find "${extracted}" -type f -name '*.dll' | sort)

  if ((count == 0)); then
    echo "No DLL found in ${label} package." >&2
    exit 1
  fi
}

install_zip_dlls "Jotunn-${JOTUNN_VERSION}" "${JOTUNN_URL}"
install_zip_dlls "Better_Wisps-${VERSION}" "${WISPS_URL}"

echo ""
echo "Restart server:  sudo systemctl restart valheim"
echo "Clients:         Better Wisps ${VERSION} (Digitalroot) and Jotunn ${JOTUNN_VERSION} via Gale."
