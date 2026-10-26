# Pikadots Desktop

The Hyprland + Quickshell desktop shell shipped by these dotfiles, and the surfaces people use on it every day.

## Dock

**Dock**:
A per-screen strip of app icons on one screen edge that is not the Bar's edge, used to launch apps and switch between them.
_Avoid_: Taskbar, launcher, panel

**Dock Item**:
One icon in the Dock, standing for one app (one app id), however many windows that app has open.
_Avoid_: Dock icon, tile, button

**Pinned App**:
An app the user has chosen to keep in the Dock in a fixed order, whether or not it is running.
_Avoid_: Favorite, shortcut

**Running App**:
An app with at least one open window on any workspace, special workspaces included.
_Avoid_: Open app, active app, working app

**Running Indicator**:
The mark on a Dock Item showing that the app is running; how it looks is up to the user.
_Avoid_: Dot (it isn't always a dot)

**Window Preview**:
The hover popup on a Dock Item that lists that app's open windows so the user can pick one.
_Avoid_: Thumbnail, tooltip

**Desktop Action**:
An extra launch option an app declares for itself, such as "New Private Window", offered from a Dock Item's menu.
_Avoid_: Shortcut, jump list, quick action

**Visibility Mode**:
How the Dock shows itself: always visible, auto-hide, or intellihide (hidden only while a window overlaps it).
_Avoid_: Hide mode, autohide setting

## Launcher

**Launcher**:
The search-and-launch overlay for apps, commands, emoji, projects and the clipboard.
_Avoid_: App menu, start menu, app drawer

**Launcher Style**:
Where and how the Launcher appears: attached to the Bar, attached to the Dock, centered, fullscreen, or Spotlight (a lone search field that grows a result list as you type).
_Avoid_: Launcher mode (a mode is what the search prefix selects, such as `=` for the calculator)

## Shell

**Tooltip**:
The short label that appears after hovering a control that shows only an icon, naming its action and keybinding.
_Avoid_: Hint, hover text, popover
