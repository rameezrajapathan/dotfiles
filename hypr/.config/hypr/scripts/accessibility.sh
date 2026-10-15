#!/usr/bin/env bash
# Applies Settings > Accessibility outside the shell: text size and animations for GTK apps
# (gsettings), and for Qt/KDE apps through kde-theme.py (font size, AnimationDurationFactor).
set -euo pipefail

settings=~/.config/pikadots/settings.json
scale=$(jq -r '.accessibility.textScale // 1' "$settings" 2>/dev/null || echo 1)
reduce=$(jq -r '.accessibility.reduceMotion // false' "$settings" 2>/dev/null || echo false)

gsettings set org.gnome.desktop.interface text-scaling-factor "$scale"
gsettings set org.gnome.desktop.interface enable-animations "$([[ $reduce == true ]] && echo false || echo true)"
python3 -I ~/.config/hypr/scripts/kde-theme.py || true
