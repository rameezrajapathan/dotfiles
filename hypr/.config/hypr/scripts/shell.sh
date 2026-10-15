#!/usr/bin/env bash
# Starts Quickshell with the icon theme picked in Settings (icons.sh writes it).
theme=$(cat ~/.local/state/pikadots/icon-theme 2>/dev/null)
QS_ICON_THEME=${theme:-Papirus-Dark} exec qs "$@"
