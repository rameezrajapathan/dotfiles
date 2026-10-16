#!/usr/bin/env bash
set -euo pipefail

settings=~/.config/pikadots/settings.json
scale=$(jq -r '.accessibility.textScale // 1' "$settings" 2>/dev/null || echo 1)
reduce=$(jq -r '.accessibility.reduceMotion // false' "$settings" 2>/dev/null || echo false)

gsettings set org.gnome.desktop.interface text-scaling-factor "$scale"
gsettings set org.gnome.desktop.interface enable-animations "$([[ $reduce == true ]] && echo false || echo true)"
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
