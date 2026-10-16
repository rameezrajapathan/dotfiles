#!/usr/bin/env bash
theme=$(cat ~/.local/state/pikadots/icon-theme 2>/dev/null)
QS_ICON_THEME=${theme:-Papirus-Dark} exec qs "$@"
