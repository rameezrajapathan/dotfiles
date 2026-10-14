# Troubleshooting

[← README](../README.md)

Start with `pikadots health`, then `pikadots repair`.

| Problem | Try |
|---|---|
| Hyprland config errors | `hyprctl reload && hyprctl configerrors` |
| Bar missing or stuck | `qs kill; hyprctl dispatch 'hl.dsp.exec_cmd("QS_ICON_THEME=Papirus-Dark qs")'` |
| Bar errors | `qs log` |
| A display setting left a screen unusable | **reset** in the display panel, or `rm ~/.local/state/pikadots/monitors.lua && hyprctl reload` |
| Colors not updated | `~/.config/hypr/scripts/theme.sh` |
| Backup failed | `journalctl --user -u pikadots-backup` |
| Notifications look plain | Another daemon (mako, dunst, swaync) took over; `pikadots repair` masks it |
| New font not showing in the bar | Restart the bar (above); a reload isn't enough |

Programs start from `hypr/.config/hypr/autostart.lua`, not systemd.
