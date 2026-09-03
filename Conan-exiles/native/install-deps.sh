#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  exec sudo "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive

if ! dpkg --print-foreign-architectures | grep -q i386; then
  dpkg --add-architecture i386
fi

apt-get update
apt-get install -y \
  curl \
  unzip \
  tar \
  ca-certificates \
  lib32gcc-s1 \
  lib32stdc++6

echo "System dependencies installed."
