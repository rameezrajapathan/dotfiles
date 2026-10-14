# Developer tools

[← README](../README.md)

- **Keyring and SSH**: gnome-keyring stores passwords (VS Code, git, browsers) and unlocks at
  login. Its SSH agent is the `gcr-ssh-agent.socket` user service.
- **git** (`git/.config/git/config`): delta for diffs in the wallpaper colors, HTTPS credentials
  in the keyring, `main` as default branch. Your name and email go in `~/.config/git/user`.
- **Projects**: Super + P lists git repos you visit often (from zoxide).
- **Tool versions**: mise switches .NET, Node, Python and others per project from `mise.toml` or
  `.tool-versions`.
- **Neovim**: its own repo, [nvim-config](https://github.com/rameezrajapathan/nvim-config). It reads
  the wallpaper colors and reloads when they change.

## Next meeting

The bar can show your next meeting next to the clock and join it in one click (Teams, Zoom,
Meet). It reads a published calendar link:

1. Outlook on the web → Settings → Calendar → Shared calendars → Publish a calendar → copy the
   **ICS** link.
2. Save it (it gives read access to your calendar, so it stays out of the repo):

   ```sh
   mkdir -p ~/.config/pikadots && echo '<ICS link>' > ~/.config/pikadots/calendar.url
   ```
