# .zshrc entry point

# Path to your dotfiles repo
export DOTFILES="$HOME/.dotfiles"

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
