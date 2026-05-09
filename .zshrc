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
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -z "${DOTFILES_SKIP_TMUX:-}" ]; then
    tmux || tmux new
fi
##############################################################

# Load modules
source "$DOTFILES/zsh/env.zsh"
source "$DOTFILES/zsh/path.zsh"
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
