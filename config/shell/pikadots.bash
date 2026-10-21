[[ $- == *i* ]] || return 0
[[ :$PATH: == *":$HOME/.local/bin:"* ]] || PATH=$HOME/.local/bin:$PATH

[[ -f ~/.local/state/theme/starship.toml ]] && export STARSHIP_CONFIG=~/.local/state/theme/starship.toml
command -v starship >/dev/null && eval "$(starship init bash)"

[[ -f ~/.local/state/theme/eza-colors ]] && export EZA_COLORS=$(<~/.local/state/theme/eza-colors)
if command -v eza >/dev/null; then
	alias ls='eza --icons=auto'
	alias ll='eza -lah --icons=auto --git'
	alias la='eza -a --icons=auto'
	alias lt='eza --tree --icons=auto'
fi

HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

[[ -f ~/.local/state/theme/lazygit.yml ]] && export LG_CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/lazygit/config.yml,$HOME/.local/state/theme/lazygit.yml"

command -v zoxide >/dev/null && eval "$(zoxide init bash --cmd cd)"
command -v mise >/dev/null && eval "$(mise activate bash)"

if [[ -n $FASTFETCH ]]; then
	unset FASTFETCH
	fastfetch
fi
