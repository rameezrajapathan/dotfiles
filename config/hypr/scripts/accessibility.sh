#!/usr/bin/env bash
set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/lib.sh"

scale=$(setting .accessibility.textScale 1)
reduce=$(setting .accessibility.reduceMotion false)

gsettings set org.gnome.desktop.interface text-scaling-factor "$scale"
gsettings set org.gnome.desktop.interface enable-animations "$([[ $reduce == true ]] && echo false || echo true)"
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
