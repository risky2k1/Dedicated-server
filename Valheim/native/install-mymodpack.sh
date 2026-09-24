#!/usr/bin/env bash
# Install TuanPM/MyModPack dependencies into config/bepinex/plugins/
# The Hexium modpack zip is only a manifest — this script resolves & installs each dep.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="${ROOT_DIR}/config/bepinex/plugins"

# shellcheck source=native/lib/common.sh
source "${ROOT_DIR}/native/lib/common.sh"
load_env

VERSION="${MYMODPACK_VERSION:-1.0.1}"
OWNER="TuanPM"
NAME="MyModPack"

"${ROOT_DIR}/linux/ensure-permissions.sh"
mkdir -p "${PLUGINS_DIR}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

api="https://valheim.hexium.gg/api/experimental/package/${OWNER}/${NAME}/"
echo "Resolving ${OWNER}-${NAME}-${VERSION} from Hexium..."
json="$(curl -fsSL -A 'Valheim-native-setup' "${api}")"

deps_json="$(
  printf '%s' "${json}" | python3 -c '
import json, sys
d = json.load(sys.stdin)
want = sys.argv[1]
latest = d["latest"]
deps = latest.get("dependencies") or []
if latest.get("version_number") != want:
    # Prefer deps from the requested version if listed; else keep latest deps.
    for v in d.get("versions") or []:
        if v.get("version_number") == want:
            deps = v.get("dependencies") or deps
            break
for dep in deps:
    print(dep)
' "${VERSION}"
)"

if [[ -z "${deps_json}" ]]; then
  echo "No dependencies listed for ${OWNER}/${NAME}@${VERSION}" >&2
  exit 1
fi

install_dep() {
  local dep="$1"
  local owner name ver url
  # Thunderstore/Hexium dependency string: Owner-Name-Version (Name may contain _)
  owner="${dep%%-*}"
  ver="${dep##*-}"
  name="${dep#"${owner}-"}"
  name="${name%-"${ver}"}"

  if [[ "${name}" == "BepInExPack_Valheim" ]]; then
    echo "Skip ${dep} (use native/install-bepinex.sh)"
    return 0
  fi

  echo ""
  echo "→ ${owner}/${name}@${ver}"
  url="$(hexium_resolve_download_url "${owner}" "${name}" "${ver}")"
  curl -fsSL -A 'Valheim-native-setup' -o "${tmp_dir}/${dep}.zip" "${url}"
  mkdir -p "${tmp_dir}/${dep}"
  unzip -qo "${tmp_dir}/${dep}.zip" -d "${tmp_dir}/${dep}"

  local dll base
  while IFS= read -r dll; do
    [[ -n "${dll}" ]] || continue
    base="$(basename "${dll}")"
    cp "${dll}" "${PLUGINS_DIR}/${base}"
    chmod 644 "${PLUGINS_DIR}/${base}"
    echo "Installed: ${PLUGINS_DIR}/${base}"
  done < <(find "${tmp_dir}/${dep}" -type f -name '*.dll' | sort)

  if ! find "${tmp_dir}/${dep}" -type f -name '*.dll' | grep -q .; then
    echo "No DLL found in ${dep}" >&2
    exit 1
  fi
}

while IFS= read -r dep; do
  [[ -n "${dep}" ]] || continue
  install_dep "${dep}"
done <<< "${deps_json}"

echo ""
echo "MyModPack ${VERSION} dependencies installed into ${PLUGINS_DIR}"
echo "Restart server:  sudo systemctl restart valheim"
echo "Clients: Gale → search TuanPM-MyModPack ${VERSION} (client + server)."
