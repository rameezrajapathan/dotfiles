status is-interactive; or return

fish_add_path -g ~/.local/bin
set -g fish_greeting

test -f ~/.local/state/theme/starship.toml; and set -gx STARSHIP_CONFIG ~/.local/state/theme/starship.toml
type -q starship; and starship init fish | source

test -f ~/.local/state/theme/eza-colors; and set -gx EZA_COLORS (cat ~/.local/state/theme/eza-colors)
if type -q eza
    alias ls 'eza --icons=auto'
    alias ll 'eza -lah --icons=auto --git'
    alias la 'eza -a --icons=auto'
    alias lt 'eza --tree --icons=auto'
end

test -f ~/.local/state/theme/lazygit.yml; and set -gx LG_CONFIG_FILE ~/.config/lazygit/config.yml,$HOME/.local/state/theme/lazygit.yml

type -q zoxide; and zoxide init fish --cmd cd | source
type -q mise; and mise activate fish | source

if set -q FASTFETCH
    set -e FASTFETCH
    fastfetch
end
