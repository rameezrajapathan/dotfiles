# The pikadots command

[← README](../README.md)

```
pikadots install      packages, links into $HOME, services, colors
pikadots uninstall    undo install, then optionally remove packages
pikadots health       check everything (alias: check, doctor)
pikadots repair       fix what health finds (alias: fix)
pikadots update       pull the repo, then repair
pikadots backup       back up now
pikadots backup-init  set up encrypted daily backups
```

## install

1. Installs [`packages.txt`](../packages.txt) with pacman, [`aur.txt`](../aur.txt) with yay or paru
   when present, and `asusctl` on ASUS laptops.
2. Links each top-level folder into `$HOME` with GNU Stow (`hypr/.config/hypr` →
   `~/.config/hypr`). Files in the way are moved to `~/.local/state/pikadots/backups/<date>/`.
3. Asks for your git name and email (saved to `~/.config/git/user`, outside the repo).
4. Enables NetworkManager, Bluetooth, power-profiles-daemon and the SSH agent.
5. Copies the [wallpapers](../wallpapers/CREDITS.md) into `~/Pictures/Wallpapers` (existing files are
   left alone) and generates colors from the current one.

## health and repair

`health` prints a ✓ / ! / ✗ line for packages, links, services, Hyprland config errors, Quickshell,
colors, keyring, SSH agent, GitHub sign-in, the last backup and the battery limit. `repair`
reinstalls, relinks, re-enables, regenerates colors and restarts the bar. Safe to run any time.

## update

Pulls the repo (`git pull --rebase --autostash`), shows the new commits, then runs repair.

## uninstall

Asks first. Removes the links and puts back the files that were there before install. Backups,
the keyring and your git identity stay.

Then it offers to remove the packages pikadots installed: **y** removes them, **e** opens the list
in `$EDITOR` to choose, anything else keeps them. Essentials (networking, audio, Bluetooth, zsh,
git, neovim, keyring, restic) are never offered, nor anything another installed package needs.

## Backups

`pikadots backup-init` creates an encrypted [restic](https://restic.net) repository and a daily
timer. It backs up `~/Projects`, `~/Documents`, `~/Pictures`, `~/dotfiles`, `~/.ssh` and the
keyring, skipping build folders, and keeps 7 daily, 4 weekly and 6 monthly snapshots.

- The location is in `~/.config/pikadots/backup-repo`. A OneDrive or Dropbox folder keeps a copy
  off the machine (it only sees encrypted data).
- **Save `~/.config/restic/password` somewhere else.** Without it the backups can't be read.
- The System tab shows the last backup; failures send a notification.

Restore:

```sh
export RESTIC_REPOSITORY=$(sed "s|^~|$HOME|" ~/.config/pikadots/backup-repo) RESTIC_PASSWORD_FILE=~/.config/restic/password
restic snapshots
restic restore latest --target ~/restored --include ~/Projects/myapp
```
