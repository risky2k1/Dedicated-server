#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
  curl \
  unzip \
  tar \
  ca-certificates \
  lib32gcc-s1 \
  lib32stdc++6

echo "System dependencies installed."
