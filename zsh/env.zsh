# Core ZSH and Oh My Zsh settings
export ZSH="$HOME/.oh-my-zsh"
UPDATE_ZSH_DAYS=13
ZSH_CUSTOM=$ZSH/custom
ZSH_THEME="powerlevel10k/powerlevel10k"
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

# Global Environment Variables
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"
export DEFAULT_USER="$USER"
export VISUAL='nvim'
export EDITOR='nvim'
export SSH_KEY_PATH="$HOME/.ssh/rsa_id"
