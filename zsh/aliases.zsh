# Aliases
alias lc="eza -la --icons --git --group-directories-first"
alias config='/usr/bin/git --git-dir=$HOME/.cfg/.git/ --work-tree=$HOME'
alias vim="nvim"
alias vi="nvim"
alias grep="rg"
alias search="ddgr"
alias nnn="nnn -dea"
alias lg="lazygit"
alias gf='git fetch --all --prune'
alias gb='git branch -a'
alias gbm='git branch --merged'
alias gbnm='git branch --no-merged'
alias gbd='git branch --merged | grep -v "\*" | grep -v "main\|master" | xargs -n 1 git branch -D'
alias gp="git pull"
alias gl="git log --pretty=oneline"

# Functions
git_rebase_dynamic() {
    git rebase -i HEAD~$1
}
alias grb="git_rebase_dynamic"

# Tool-specific initialization
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v ng >/dev/null 2>&1; then
  eval "$(ng completion script 2>/dev/null || true)"
fi
