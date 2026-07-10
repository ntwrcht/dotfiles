# --- Navigation ---
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# --- Modern Replacements ---
alias cat="bat"
alias help="tldr"
alias vim="nvim"
alias vi="nvim"
alias grep="rg"
alias search="ddgr"
alias nnn="nnn -dea"
alias lg="lazygit"
alias l="eza -1 --icons --group-directories-first"
alias lc="eza -la --icons --git --group-directories-first"

# --- Git Productivity ---
alias g="git"
alias gs="git status -sb"
alias ga="git add"
alias gc="git commit -v"
alias gp="git pull"
alias gpush="git push"
alias gf='git fetch --all --prune'
alias gfp='gf && gp'
alias gb='git branch -a'
alias gbm='git branch --merged'
alias gbnm='git branch --no-merged'
alias gbd='git branch --merged | grep -v "\*" | grep -v "main\|master" | xargs -n 1 git branch -D'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias grb="git_rebase_dynamic"

# --- System & Utilities ---
alias reload="source ~/.zshrc"
alias myip="curl -4 -s ifconfig.me && echo"
alias myip6="curl -6 -s ifconfig.me && echo"
alias rm="rm -i" # Safety first
alias ports="sudo lsof -iTCP -sTCP:LISTEN -P -n"

# --- Containers ---
alias d="docker"
alias dc="docker-compose"

# --- Functions ---
git_rebase_dynamic() {
    git rebase -i HEAD~$1
}

# --- Tool Initialization ---
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if command -v ng >/dev/null 2>&1; then
  eval "$(ng completion script 2>/dev/null || true)"
fi
