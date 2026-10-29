#!/bin/bash
# Rebuild the shipped shader binaries (shaders/*.frag -> *.frag.qsb) and record
# each source's hash, so a .frag edited without a rebuild is caught.
#
#   tools/build-shaders.sh          rebuild every shader
#   tools/build-shaders.sh --check  fail if any .qsb is older than its .frag
#
# Needs qsb from qt6-shadertools (pacman -S qt6-shadertools), or QSB=/path/to/qsb.
set -euo pipefail

cd "$(dirname "$0")/../shaders"
mode="${1:-build}"
status=0

for frag in *.frag; do
  sum="$(sha256sum "$frag" | cut -d' ' -f1)"
  if [ "$mode" = "--check" ]; then
    if [ ! -f "$frag.qsb" ] || [ "$(cat "$frag.sha256" 2>/dev/null)" != "$sum" ]; then
      echo "stale: $frag.qsb (run tools/build-shaders.sh)" >&2
      status=1
    fi
    continue
  fi
  qsb="${QSB:-$(command -v qsb || echo /usr/lib/qt6/bin/qsb)}"
  [ -x "$qsb" ] || { echo "qsb not found; install qt6-shadertools or set QSB" >&2; exit 1; }
  "$qsb" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$frag.qsb" "$frag"
  echo "$sum" > "$frag.sha256"
  echo "built $frag.qsb"
done

[ "$mode" = "--check" ] && [ "$status" -eq 0 ] && echo "shaders up to date"
exit "$status"
