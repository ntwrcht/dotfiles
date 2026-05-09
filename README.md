# Dotfiles

![screenshot](./assets/screen_shot.png)
![screenshot](./assets/screen-shot-homebrew.png)

Personal macOS dotfiles for shell, Git, Vim, Neovim, tmux, and Kitty.

## Installation

```bash
git clone git@github.com:Canvas-xxx/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install
```

The installer creates symlinks into your home directory. Existing files are moved to:

```bash
~/.dotfiles-backup/<timestamp>
```

Preview changes without modifying files:

```bash
./install --dry-run
```

## Commands

```bash
make dry-run   # preview symlink changes
make install   # install dotfile symlinks
make doctor    # check required and optional tools
make deps      # install Homebrew dependencies from Brewfile
```

## Dependencies

Install Homebrew packages:

```bash
brew bundle
```

Useful tools included in the `Brewfile`:

- [bat](https://github.com/sharkdp/bat)
- [ddgr](https://github.com/jarun/ddgr)
- [eza](https://github.com/eza-community/eza)
- [fd](https://github.com/sharkdp/fd)
- [nnn](https://github.com/jarun/nnn)
- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [lazygit](https://github.com/jesseduffield/lazygit)
- [fzf](https://github.com/junegunn/fzf)
- [git-delta](https://github.com/dandavison/delta)
- [jq](https://github.com/jqlang/jq)
- [nerd-fonts](https://github.com/ryanoasis/nerd-fonts)
- [tealdeer](https://github.com/tealdeer-rs/tealdeer)
- [zoxide](https://github.com/ajeetdsouza/zoxide)

## Vim Plugins

The installer bootstraps [vim-plug](https://github.com/junegunn/vim-plug) when it is missing.

After installation, open Vim and run:

```vim
:PlugInstall
```

## Tmux

Follow this link for [tmux](https://github.com/tmux/tmux) and [oh-my-tmux](https://github.com/gpakosz/.tmux) pre-installation guide

## Secrets

Do not commit local credentials or tokens. Keep machine-specific secret files outside Git, or use example files with placeholder values.

For shell credentials, copy the example file and edit the local copy:

```bash
cp .zshrc-secrets.example ~/.zshrc-secrets
chmod 600 ~/.zshrc-secrets
```

The installer creates this file automatically when it is missing and never overwrites an existing one.

Then put real values in `~/.zshrc-secrets`:

```bash
export JIRA_API_TOKEN="..."
export OPENAI_API_KEY="..."
```
