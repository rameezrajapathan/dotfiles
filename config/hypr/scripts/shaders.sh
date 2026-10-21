#!/usr/bin/env bash
set -euo pipefail

qsb=$(command -v qsb || ls /usr/lib/qt6/bin/qsb /usr/lib64/qt6/bin/qsb 2>/dev/null | head -1 || true)
[[ -x $qsb ]] || { echo "qsb not found (install qt6-shadertools, or qt6-qtshadertools on Fedora)" >&2; exit 1; }
dir=$(dirname "$(realpath "$0")")/../../quickshell/shaders
for frag in "$dir"/*.frag; do
	"$qsb" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$frag.qsb" "$frag"
	echo "built ${frag##*/}.qsb"
done
