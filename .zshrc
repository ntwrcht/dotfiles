##############################################################
# => ZSH Startup with Tmux
##############################################################
if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
    tmux || tmux new
fi
##############################################################

# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
UPDATE_ZSH_DAYS=13
ZSH_CUSTOM=$ZSH/custom
ZSH_THEME="powerlevel9k/powerlevel9k"
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"
DISABLE_AUTO_UPDATE="true"
DISABLE_LS_COLORS="true"
DISABLE_AUTO_TITLE="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"
NVM_LAZY_LOAD=true
NVM_COMPLETION=true

# Custom Powerlevel9k
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs time)
POWERLEVEL9K_TIME_BACKGROUND="060"
POWERLEVEL9K_TIME_FOREGROUND="015"

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

##############################################################
# => User configuration
##############################################################
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"

alias lc="colorls -lA --sd"
export DEFAULT_USER="$USER"

##############################################################
# => SSH
##############################################################
 export SSH_KEY_PATH="$HOME/.ssh/rsa_id"

##############################################################
# => Export Global Environments Variable
##############################################################
export VISUAL='nvim'
export EDITOR='nvim'

##############################################################
# => JAVA Home 
##############################################################
export JAVA_HOME=`/usr/libexec/java_home -v 1.8`
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools

##############################################################
# => Python 
##############################################################
export PATH="/usr/local/opt/python@3.7/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/python@3.7/lib"
##############################################################
# => Node 
##############################################################
export PATH=$PATH:$HOME/.nodebrew/current/bin
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

##############################################################
# => Go path 
##############################################################
export GOPATH=$HOME/go
export GOBIN=$HOME/go/bin
export GOCACHE=$HOME/.cache
export GO111MODULE=on
export GOPRIVATE="gitlab.com/botnoi-sme,bitbucket.org/botnoi-sme,github.com/botnoi-sme"
export PATH=$PATH:$GOPATH/bin
export PATH=$PATH:$GOROOT/bin
export GOROOT=/usr/local/Cellar/go/1.16.3/libexec

##############################################################
# => FZF Config 
##############################################################
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='rg --files --no-ignore --hidden --follow -g "!{.git,node_modules,vendor}/*" 2> /dev/null'
export FZF_DEFAULT_OPTS="--color hl:-1:underline,hl+:-1:underline:reverse"
export FZF_COMPLETION_TRIGGER='~~'
export FZF_COMPLETION_OPTS='+c -x'

##############################################################
# => Alias Bash Script
##############################################################
alias config='/usr/bin/git --git-dir=$HOME/.cfg/.git/ --work-tree=$HOME'
alias vim="nvim"
alias vi="nvim"
alias grep="rg"
alias python="python3"
alias pip="pip3"
alias nnn="nnn -dea"
alias lg="lazygit"
alias gf='git fetch --all --prune'
alias gb='git branch -a'
alias gm='git branch --merged'
