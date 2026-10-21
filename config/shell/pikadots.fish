status is-interactive; or return

fish_add_path -g ~/.local/bin
set -g fish_greeting

set -g __pikadots_starship (command -s starship)
set -g __pikadots_mise (command -s mise)
set -g __pikadots_zoxide (command -s zoxide)
function __pikadots_unhook --on-event fish_prompt
    if test -n "$__pikadots_starship"; and not test -x "$__pikadots_starship"
        set -g __pikadots_starship
        functions -e fish_right_prompt __starship_reset_transient
        function fish_prompt
            printf '%s@%s %s> ' $USER $hostname (prompt_pwd)
        end
    end
    if test -n "$__pikadots_mise"; and not test -x "$__pikadots_mise"
        set -g __pikadots_mise
        functions -e __mise_env_eval __mise_env_eval_on_prompt __mise_env_eval_2 __mise_cd_hook
    end
    if test -n "$__pikadots_zoxide"; and not test -x "$__pikadots_zoxide"
        set -g __pikadots_zoxide
        functions -e __zoxide_hook
        function __zoxide_z
            __zoxide_cd_internal $argv
        end
        function __zoxide_zi
            __zoxide_cd_internal $argv
        end
    end
end

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
