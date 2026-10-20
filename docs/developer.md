# Developer tools

[← README](../README.md)

- **Keyring and SSH**: gnome-keyring stores passwords (VS Code, git, browsers). It unlocks at
  login when your login manager's PAM setup includes `pam_gnome_keyring`; otherwise it asks for
  your password the first time it's needed. Its SSH agent is the `gcr-ssh-agent.socket` user
  service.
- **git** (`config/git/config`): delta for diffs in the wallpaper colors, `main` as default
  branch. HTTPS credentials for GitHub come from `gh auth git-credential` (run `gh auth login`
  once); other hosts use the keyring. Your name and email go in `~/.config/git/user`, which git
  ignores ([pikadots.md](pikadots.md#install)).
- **Projects**: Super + P lists folders you visit often (from zoxide) that are git repos or hold a
  `package.json`, `Cargo.toml`, `go.mod`, `pyproject.toml`, `*.sln` or `*.csproj`.
- **Tool versions**: mise switches .NET, Node, Python and others per project from `mise.toml` or
  `.tool-versions`.
- **Neovim**: pikadots ships no Neovim config, only a `pikadots` colorscheme that follows the
  wallpaper ([theming.md](theming.md#neovim)). The author's own config is a separate repo,
  [nvim-config](https://github.com/rameezrajapathan/nvim-config).
- **lazygit** uses delta and the wallpaper colors ([theming.md](theming.md#terminal-tools)).
- **Keybindings**: after editing `config/hypr/keybinds.lua`, run `pikadots docs-check` so
  [keybindings.md](keybindings.md) stays in step.

## Next meeting

The bar can show your next meeting next to the clock and join it in one click (Teams, Zoom,
Meet). It reads a published calendar link:

1. Outlook on the web → Settings → Calendar → Shared calendars → Publish a calendar → copy the
   **ICS** link.
2. Save it (it gives read access to your calendar, so it stays out of the repo):

   ```sh
   mkdir -p ~/.config/pikadots && echo '<ICS link>' > ~/.config/pikadots/calendar.url
   ```
