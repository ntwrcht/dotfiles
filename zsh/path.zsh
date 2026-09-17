# PATH configuration
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Commands shipped by this repo (bin/md, ...). Exported rather than
# symlinked so nvim and tmux inherit them without a links.conf entry.
export PATH="$DOTFILES/bin:$PATH"

# JAVA Home
export ANDROID_HOME=$HOME/Library/Android/sdk
if [[ -d "$ANDROID_HOME" ]]; then
  export PATH=$PATH:$ANDROID_HOME/tools
  export PATH=$PATH:$ANDROID_HOME/tools/bin
  export PATH=$PATH:$ANDROID_HOME/platform-tools
fi

# Python 
path=("${(@)path:#/opt/homebrew/opt/python@3.12/libexec/bin}")
if command -v uv >/dev/null 2>&1; then
  export UV_LINK_MODE=copy
fi

# Node 
path=("${(@)path:#$HOME/.nodebrew/current/bin}")
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --shell zsh)"
elif ! command -v node >/dev/null 2>&1 && [[ -d "$HOME/.nodebrew/current/bin" ]]; then
  export PATH="$HOME/.nodebrew/current/bin:$PATH"
fi
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Go path 
export GOPATH=$HOME/go
export GOBIN=$HOME/go/bin
export GOCACHE=$HOME/.cache
export GO111MODULE=on
export PATH=$PATH:$GOPATH/bin

# CLAUDE PATH
export PATH="$HOME/.local/bin:$PATH"
