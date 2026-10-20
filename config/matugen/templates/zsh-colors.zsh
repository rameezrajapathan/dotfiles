() {
  local text='38;2;{{colors.on_surface.default.red}};{{colors.on_surface.default.green}};{{colors.on_surface.default.blue}}'
  local soft='38;2;{{colors.on_surface_variant.default.red}};{{colors.on_surface_variant.default.green}};{{colors.on_surface_variant.default.blue}}'
  local dim='38;2;{{colors.outline.default.red}};{{colors.outline.default.green}};{{colors.outline.default.blue}}'
  local faint='38;2;{{colors.outline_variant.default.red}};{{colors.outline_variant.default.green}};{{colors.outline_variant.default.blue}}'
  local accent='38;2;{{colors.primary.default.red}};{{colors.primary.default.green}};{{colors.primary.default.blue}}'
  local error='38;2;{{colors.error.default.red}};{{colors.error.default.green}};{{colors.error.default.blue}}'

  export EZA_COLORS="uu=${dim}:gu=${dim}:da=${dim}:ur=${text}:uw=${dim}:ux=${text}:ue=${dim}:gr=${dim}:gw=${dim}:gx=${text}:tr=${dim}:tw=${dim}:tx=${text}:fi=${text}:di=1;${accent}:ln=${soft}:lp=${soft}:mp=1;${accent}:pi=${dim}:so=${dim}:bd=${dim}:cd=${dim}:or=${error}:mi=${error}:ex=${text}:sn=${soft}:sb=${dim}:hd=4;${soft}:xx=${faint}"

  zstyle ':completion:*' list-colors \
    "=(#b)*(=0)=${soft}" \
    "=(#b)*(=1)=${text}" \
    "=(#b)*(=2)=${dim}" \
    "=(#b)*(=3)=${faint}" \
    "di=1;${accent}" "ln=${soft}" "ex=${text}"

  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg={{colors.outline.default.hex}}'

  typeset -gA ZSH_HIGHLIGHT_STYLES
  ZSH_HIGHLIGHT_STYLES[command]='fg={{colors.primary.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[builtin]='fg={{colors.primary.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[function]='fg={{colors.primary.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[alias]='fg={{colors.primary.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[precommand]='fg={{colors.primary.default.hex}},underline'
  ZSH_HIGHLIGHT_STYLES[reserved-word]='fg={{colors.primary.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[path]='fg={{colors.on_surface_variant.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg={{colors.on_surface_variant.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg={{colors.on_surface_variant.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[comment]='fg={{colors.outline.default.hex}}'
  ZSH_HIGHLIGHT_STYLES[unknown-token]='fg={{colors.error.default.hex}}'
}
