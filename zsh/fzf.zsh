# FZF Configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules,vendor}/*" 2> /dev/null'
# Colours come from $CTP_* (zsh/theme.zsh), so the palette lives in one place.
export FZF_DEFAULT_OPTS="\
--color=bg+:${CTP_SURFACE0},bg:${CTP_BASE},spinner:${CTP_ROSEWATER},hl:${CTP_RED} \
--color=fg:${CTP_TEXT},header:${CTP_RED},info:${CTP_MAUVE},pointer:${CTP_ROSEWATER} \
--color=marker:${CTP_LAVENDER},fg+:${CTP_TEXT},prompt:${CTP_MAUVE},hl+:${CTP_RED} \
--color=border:${CTP_SURFACE1} \
--height=40% --layout=reverse --border"
export FZF_COMPLETION_TRIGGER='~~'
export FZF_COMPLETION_OPTS='+c -x'
