#!/usr/bin/env bash
set -euo pipefail

qsb=$(command -v qsb || echo /usr/lib/qt6/bin/qsb)
[[ -x $qsb ]] || { echo "qsb not found (install qt6-shadertools)" >&2; exit 1; }
dir=$(dirname "$(realpath "$0")")/../../quickshell/shaders
for frag in "$dir"/*.frag; do
	"$qsb" --glsl "100 es,120,150" --hlsl 50 --msl 12 -o "$frag.qsb" "$frag"
	echo "built ${frag##*/}.qsb"
done
