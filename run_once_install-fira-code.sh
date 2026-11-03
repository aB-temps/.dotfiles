#!/bin/sh
set -e
dir="$HOME/.local/share/fonts/FiraCode"
[ -n "$(ls -A "$dir" 2>/dev/null)" ] && exit 0
mkdir -p "$dir"
curl -fL -o /tmp/FiraCode.tar.xz \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz
tar -xf /tmp/FiraCode.tar.xz -C "$dir"
fc-cache -f
