# Troubleshooting

[← README](../README.md)

Start with `pikadots health`, then `pikadots repair`.

| Problem | Try |
|---|---|
| Hyprland config errors | `hyprctl reload && hyprctl configerrors` |
| Bar missing or stuck | `qs kill; setsid -f ~/.config/hypr/scripts/shell.sh` (starts it with your icon theme) |
| Bar errors | `qs log` |
| A display setting left a screen unusable | **reset** in the Displays tab, or `rm ~/.local/state/pikadots/monitors.lua && hyprctl reload` |
| Colors not updated | `~/.config/hypr/scripts/theme.sh` |
| Backup failed | `journalctl --user -u pikadots-backup` |
| Notifications look plain | Another daemon (mako, dunst, swaync) took over; `pikadots repair` masks it |
| New font not showing in the bar | Restart the bar (above); a reload isn't enough |
| Bar shows the old time after changing the time zone | Restart the bar (above), or "Restart shell" in Settings > Date & time |
| A new icon theme isn't listed | Install it into `~/.local/share/icons` (with an `index.theme`), then reopen Settings > Fonts & icons |
| Bar items overlap with a full-width bar | Too many items for the screen: remove some in Settings > Bar, or use islands |

Programs start from `hypr/.config/hypr/autostart.lua`, not systemd.
