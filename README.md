<div align="center">

```
 ·  · ✦ dotfiles ✦ ·  ·
```

[![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Zsh](https://img.shields.io/badge/zsh-F15A24?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![Neovim](https://img.shields.io/badge/neovim-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)
[![Kitty](https://img.shields.io/badge/kitty-terminal-8B5CF6?style=flat-square)](https://sw.kovidgoyal.net/kitty/)
[![Tmux](https://img.shields.io/badge/tmux-1BB91F?style=flat-square&logo=tmux&logoColor=white)](https://github.com/tmux/tmux)

*a minimal, opinionated macOS dev environment — clone, run, done.*

</div>

---

## what is this?

**Dotfiles** are the hidden configuration files that control how your terminal, editor, and tools look and behave. This repo stores all of them in one place so that setting up a new Mac takes minutes instead of days.

When you run the installer, it connects each config file here to the right place on your machine — no manual copying, no hunting for where things live.

---

## before you start

Make sure you have these two things installed:

**1. Homebrew** — the package manager for macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. Git** — to download this repo *(comes with macOS, but Homebrew's version is newer)*

```bash
brew install git
```

---

## setup

**Step 1 — download the repo**

```bash
git clone git@github.com:Canvas-xxx/dotfiles.git ~/.dotfiles
```

**Step 2 — install all tools**

```bash
cd ~/.dotfiles
make deps
```

This reads the [`Brewfile`](./Brewfile) and installs everything at once — editor, terminal, shell tools, fonts.

**Step 3 — apply the configs**

```bash
make install
```

This will:
- link all config files to the right places on your machine
- install [Oh My Zsh](https://ohmyz.sh) — a framework that powers the shell prompt and plugins
- install the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme and Zsh plugins
- set up the Neovim Python provider

Open a new terminal window when it finishes and everything should be active.

> **Not sure what will happen?** Run `make dry-run` first — it shows exactly what the installer would do without changing anything.

---

## what gets configured

| tool | what it is | what this config does |
| :--- | :--- | :--- |
| **Zsh** | your command-line shell | sets up aliases, smarter history, and a clean prompt |
| **Neovim** | a keyboard-driven code editor | installs plugins automatically on first launch |
| **Kitty** | a fast GPU-powered terminal | font, colors, and keyboard shortcuts |
| **Tmux** | splits one terminal into multiple panes/sessions | layout and keybinding config |
| **Git** | version control | global ignore rules + a structured commit message template |

---

## day-to-day commands

Run these from inside the `~/.dotfiles` folder.

| command | what it does |
| :--- | :--- |
| `make install` | apply configs to your machine |
| `make dry-run` | preview what `install` would change, safely |
| `make uninstall` | remove all configs applied by this repo |
| `make doctor` | check that all tools are installed and configs are linked correctly |
| `make deps` | install or update all tools via Homebrew |
| `make cleanup` | preview tools that can be safely removed |
| `make cleanup-apply` | remove the tools shown by `cleanup` |

---

## tools installed

| category | tools |
| :--- | :--- |
| **editor** | [Neovim](https://neovim.io) · [Vim](https://www.vim.org) |
| **shell** | [Zsh](https://www.zsh.org) · [fzf](https://github.com/junegunn/fzf) *(fuzzy search)* · [zoxide](https://github.com/ajeetdsouza/zoxide) *(smarter `cd`)* |
| **terminal** | [Kitty](https://sw.kovidgoyal.net/kitty) · [Tmux](https://github.com/tmux/tmux) · Hack Nerd Font |
| **files** | [eza](https://github.com/eza-community/eza) *(better `ls`)* · [fd](https://github.com/sharkdp/fd) *(faster `find`)* · [bat](https://github.com/sharkdp/bat) *(better `cat`)* · [ripgrep](https://github.com/BurntSushi/ripgrep) *(fast search)* |
| **git** | [Lazygit](https://github.com/jesseduffield/lazygit) *(visual git UI)* · [delta](https://github.com/dandavison/delta) *(prettier diffs)* |
| **utilities** | [jq](https://jqlang.github.io/jq) · [tldr](https://github.com/dbrgn/tealdeer) · [ddgr](https://github.com/jarun/ddgr) |
| **runtimes** | [fnm](https://github.com/Schniz/fnm) *(Node.js)* · [uv](https://github.com/astral-sh/uv) *(Python)* · [Yarn](https://yarnpkg.com) |

---

## keeping secrets safe

API keys and tokens go in `~/.zshrc-secrets` — a file that lives only on your machine and is never uploaded to Git.

The installer creates it automatically from the [example template](./.zshrc-secrets.example). Open it and fill in your values:

```bash
# ~/.zshrc-secrets
export JIRA_API_TOKEN=""
export OPENAI_API_KEY=""
```

---

## something broke?

Run the health check — it tells you exactly what's missing or misconfigured:

```bash
make doctor
```

---

<div align="center">
  <sub>made for macOS · built to last · yours to fork</sub>
</div>
