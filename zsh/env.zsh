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

# Global Environment Variables
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8
export ARCHFLAGS="-arch x86_64"
export DEFAULT_USER="$USER"
export VISUAL='nvim'
export EDITOR='nvim'
export SSH_KEY_PATH="$HOME/.ssh/rsa_id"
