# .zshrc entry point

# Path to your dotfiles repo
export DOTFILES="$HOME/.dotfiles"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

##############################################################
# => ZSH Startup with Tmux
##############################################################
# `tmux` with no arguments means `new-session` -- it never attaches. That made
# every terminal spawn ANOTHER session, and left the `|| tmux new` fallback
# unreachable. `new-session -A -D -s main` attaches if `main` exists, creates it
# otherwise, and detaches any other client.
#
# The guards below keep tmux out of editor and IDE terminals, which are
# interactive (so .zshrc runs) but do not set $TMUX. $VIM in particular matters
# here: :FloatermNew nnn / lazygit would otherwise start tmux inside a floating
# window when nvim is launched outside tmux.
if command -v tmux >/dev/null 2>&1 \
  && [ -z "$TMUX" ] \
  && [ -z "${DOTFILES_SKIP_TMUX:-}" ] \
  && [ -z "${VIM:-}" ] && [ -z "${NVIM:-}" ] && [ -z "${INSIDE_EMACS:-}" ] \
  && [ "${TERM_PROGRAM:-}" != "vscode" ] \
  && [ "${TERMINAL_EMULATOR:-}" != "JetBrains-JediTerm" ] \
  && [ -z "${VSCODE_RESOLVING_ENVIRONMENT:-}" ] \
  && [ -z "${SSH_CONNECTION:-}" ]; then
    exec tmux new-session -A -D -s main
fi
##############################################################

# Load modules
source "$DOTFILES/zsh/env.zsh"
source "$DOTFILES/zsh/path.zsh"
source "$DOTFILES/zsh/theme.zsh"   # must precede fzf.zsh — it reads $CTP_*
source "$DOTFILES/zsh/fzf.zsh"
source "$DOTFILES/zsh/plugins.zsh"
source "$DOTFILES/zsh/aliases.zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

##############################################################
# => Local Secrets & Overrides
##############################################################

# Load public secrets from repo-managed file
if [ -f "$HOME/.zshrc-secrets" ]; then
  source "$HOME/.zshrc-secrets"
fi

# Fallback for specific tokens
if [ -z "${OPENAI_API_KEY:-}" ] && [ -f "$HOME/.config/openai.token" ]; then
  export OPENAI_API_KEY="$(cat "$HOME/.config/openai.token")"
fi

# Load machine-specific local overrides (ignored by Git)
if [ -f "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi
