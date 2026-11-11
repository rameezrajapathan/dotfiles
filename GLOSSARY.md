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

## Desktop

**Desktop Widget**:
A card placed on the desktop, behind windows, that shows live information or offers a small control, such as the weather, a clock or what's playing.
_Avoid_: Widget (on its own), desklet, applet, gadget

**Control Center Card**:
One of the cards stacked inside the Control Center, such as quick tiles, sliders or the calendar.
_Avoid_: Widget (on its own), module

**Quick Actions**:
The Control Center Card of one-click buttons for capturing the screen, changing the wallpaper and opening Settings.
_Avoid_: Shortcuts (a Shortcut is a tile in a Shortcuts widget), actions card

**Widget Kind**:
One sort of content, such as weather or a calendar, that can be shown as a Desktop Widget, a Control Center Card, or both.
_Avoid_: Widget type, applet

**Widget Size**:
How many grid cells a Desktop Widget covers, wide by tall, from the smallest its Widget Kind allows up to four by four; the widget rearranges its content to suit. Small (2×2), medium (4×2) and large (4×4) are only starting points offered when adding one.
_Avoid_: Scale, dimensions, fixed size

**Desktop Grid**:
The invisible cells a Desktop Widget snaps to, always an even number across and down so two-cell widgets tile without a gap.
_Avoid_: Snap grid, layout grid

**Desktop Layout**:
Which Desktop Widgets sit where on one monitor, shared by every workspace on that monitor.
_Avoid_: Widget arrangement, desktop config

**Edit Mode**:
The state in which Desktop Widgets can be added, moved, resized and removed; outside it they only show and respond.
_Avoid_: Jiggle mode, arrange mode

**Show Desktop**:
The gesture or key that brings the Desktop Widgets forward over open windows until it is dismissed.
_Avoid_: Peek, desktop mode

**Desktop Menu**:
The menu that opens on a right click on empty desktop, with actions such as changing the wallpaper or adding a Desktop Widget.
_Avoid_: Context menu (too generic), right-click menu

**Shortcut**:
One tile in a Shortcuts widget that opens one thing: an app, a folder or file, or an address, with web addresses opening in a chosen browser and browser profile.
_Avoid_: Bookmark, launcher, link, Pinned App (that's the Dock's)

**Browser Profile**:
One of a browser's separate identities, with its own sign-in, history and extensions, that a Shortcut can open its web address in.
_Avoid_: Account, user, browser identity

## Setup

**First-Run Setup**:
The welcome flow shown the first time someone logs in to a fresh install, where they choose their wallpaper, bar style, Dock and account picture.
_Avoid_: Onboarding, wizard

**Greeter**:
The login screen shown before anyone is signed in, styled to match the lock screen.
_Avoid_: Login manager, display manager (that's the program that runs it)

## Bar

**Bar Style**:
One of the ready-made looks for the Bar, such as Minimalist, Islands or Classic, each a set of layout, size and items; Custom is the user's own changes, kept so they can switch back to it.
_Avoid_: Bar theme, bar preset, bar layout (the layout is only the pill, islands or full-width shape)

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
