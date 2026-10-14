#!/usr/bin/env bash
# First-time setup on a new machine:
#   git clone https://github.com/rameezrajapathan/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
# Afterwards use the pikadots command (health, repair, update, uninstall, backup).
set -e
command -v stow >/dev/null || sudo pacman -S --needed --noconfirm stow
exec "$(dirname "$(readlink -f "$0")")/pikadots/.local/bin/pikadots" install
