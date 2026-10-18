# The pikadots command

[← README](../README.md)

```
pikadots install      packages, links into $HOME, services, colors
pikadots uninstall    undo install, then optionally remove packages
pikadots health       check everything (alias: check, doctor)
pikadots repair       fix what health finds (alias: fix)
pikadots update       pull the repo, then repair if anything changed
pikadots backup       back up now
pikadots backup-init  set up encrypted daily backups
pikadots export       save your settings to one file
pikadots import FILE  apply an exported file on this machine
```

## install

1. Installs [`packages.txt`](../packages.txt) with pacman, [`aur.txt`](../aur.txt) with yay or paru
   when present, and `asusctl` on ASUS laptops.
2. Links the files in `config/` into `$HOME` (`config/hypr` → `~/.config/hypr`; the full list is the
   `links` table at the top of `config/pikadots/pikadots`). Files in the way are moved to
   `~/.local/state/pikadots/backups/<date>/`. `pikadots link` does only this step.
3. Asks for your git name and email (saved to `~/.config/git/user`, outside the repo).
4. Enables NetworkManager, Bluetooth, power-profiles-daemon and the SSH agent.
5. Copies the [wallpapers](../wallpapers/CREDITS.md) into `~/Pictures/Wallpapers` (existing files are
   left alone) and generates colors from the current one.

## health and repair

`health` prints a ✓ / ! / ✗ line for packages, links, services, Hyprland config errors, Quickshell,
colors, keyring, SSH agent, GitHub sign-in, the last backup and the battery limit. `repair`
reinstalls, relinks, re-enables, regenerates colors and restarts the bar. Safe to run any time.

## update

Pulls the repo (`git pull --rebase --autostash`) and shows the new commits. Only when something
new came in does it run repair (new packages, links and services); when it's already up to date it
stops there, and `pikadots repair` checks everything anyway.
Settings > Updates shows what's new before you update, checks in the background and runs this
for you in a terminal ([settings.md](settings.md#updates)).

## uninstall

Asks first. Removes the links and puts back the files that were there before install. Backups,
the keyring and your git identity stay.

It also puts Plasma's own colors, icons and fonts back into `~/.config/kdeglobals` (see
[Qt and KDE apps](theming.md#qt-and-kde-apps)).

Then it offers to remove the packages pikadots installed: **y** removes them, **e** opens the list
in `$EDITOR` to choose, anything else keeps them. Essentials (networking, audio, Bluetooth, zsh,
git, neovim, keyring, restic) are never offered, nor anything another installed package needs.

## export and import

`pikadots export [FILE]` saves what the Settings app changed into one file, by default
`~/pikadots-settings-DATE.tar.gz`. That covers `~/.config/pikadots/settings.json` and the Hyprland
files written from it (Windows, Effects and Input options, startup apps, window rules), plus the
current wallpaper and `~/.face`. Keep it in cloud storage or on a USB drive.

On a new machine, after `install.sh`: `pikadots import pikadots-settings-DATE.tar.gz`. It saves
the files it replaces to `~/.local/state/pikadots/backups/import-DATE/`, stops the shell so it
can't write its old settings back, and copies the files in. Then it recolors from the wallpaper
and applies fonts, icons, accessibility, clipboard and idle timers, and restarts the shell. A plain
`settings.json` works too. Monitor layouts, clipboard pins and backups stay per machine.

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

## Repo layout

```
config/       one folder per app with its files (config/kitty → ~/.config/kitty)
docs/         these pages and their screenshots
wallpapers/   copied to ~/Pictures/Wallpapers on install
install.sh    first-time setup (runs pikadots install)
packages.txt  pacman packages; aur.txt: AUR packages
```

The shell (`config/quickshell/`) is split by role: `bar/`, `controlcenter/`,
`panels/` (control center pages), `overlays/` (launcher, overview, switcher, OSD, popups),
`lock/`, `settings/` (the Settings app), `services/` (singletons: state and system access),
`widgets/` (shared controls) and `shaders/` (the glass shader and its compiled `.qsb`). Files import other folders as `import qs.<folder>`.
