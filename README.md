<div align="center">

# dotfiles

**A minimal, opinionated macOS development environment — clone, run, done.**

[![CI](https://github.com/ntwrcht/dotfiles/actions/workflows/ci.yml/badge.svg)](https://github.com/ntwrcht/dotfiles/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square)](#license)
[![macOS](https://img.shields.io/badge/macOS-000000?style=flat-square&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Zsh](https://img.shields.io/badge/zsh-F15A24?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.zsh.org/)
[![Neovim](https://img.shields.io/badge/neovim-57A143?style=flat-square&logo=neovim&logoColor=white)](https://neovim.io/)

</div>

---

## Introduction

Setting up a new Mac by hand takes days: installing tools one by one, hunting down configuration files, and rediscovering settings you tuned years ago. This repository removes that cost entirely.

**dotfiles** stores every configuration file for your shell, editor, terminal, and Git in a single version-controlled location. One command installs the full toolchain via Homebrew; a second command symlinks each config into place — with automatic backups, an idempotent installer you can re-run safely, and a dry-run mode that previews every change before it happens.

The result: a new machine goes from factory state to a fully configured development environment in minutes, and every future tweak is tracked, reviewable, and reversible.

## Table of Contents

- [Introduction](#introduction)
- [Key Features](#key-features)
- [Architecture Overview](#architecture-overview)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
  - [Day-to-Day Commands](#day-to-day-commands)
  - [Previewing Changes](#previewing-changes)
  - [Managing Secrets](#managing-secrets)
  - [Health Checks](#health-checks)
- [What Gets Configured](#what-gets-configured)
- [Contributing](#contributing)
- [License](#license)

## Key Features

- **One-command setup** — `make deps && make install` takes a fresh Mac to a complete environment.
- **Safe by design** — existing files are backed up to `~/.dotfiles-backup/<timestamp>` before anything is replaced, and `make dry-run` previews every change without touching your system.
- **Idempotent installer** — re-run it any time; links already in place are detected and skipped.
- **Declarative dependencies** — a single [`Brewfile`](./Brewfile) defines the entire toolchain, from Neovim to Nerd Fonts.
- **Built-in diagnostics** — `make doctor` verifies that every tool is installed and every symlink points where it should.
- **Clean removal** — `make uninstall` reverses everything the installer did.
- **Secrets stay local** — API keys live in `~/.zshrc-secrets`, created from a template and never committed.

## Architecture Overview

The system follows the classic **symlink farm** pattern: configuration files live in this repository, and the installer links them into their expected locations under `$HOME`. Editing a file here immediately affects the live config — no copy step, no drift.

```mermaid
flowchart LR
    subgraph repo["~/.dotfiles (this repo)"]
        M["links.conf<br/><i>single source of truth</i>"]
        C["configs<br/>.zshrc · nvim · kitty · git · tmux"]
    end

    subgraph scripts["Makefile entry points"]
        I["install"]
        D["doctor"]
        U["uninstall"]
    end

    subgraph home["$HOME"]
        T["~/.zshrc<br/>~/.config/nvim<br/>~/.tmux.conf<br/>..."]
    end

    M --> I & D & U
    C -.->|symlinked| T
    I -->|creates links| T
    D -->|verifies links| T
    U -->|removes links| T
    I -->|backs up first| B["~/.dotfiles-backup/&lt;timestamp&gt;"]
```

**`links.conf` is the single source of truth.** `install`, `uninstall`, and `doctor` all read it, so adding a managed config is a one-line change rather than three edits that can drift apart.

### Managed links

<!-- BEGIN LINKS -->

| Source in repo | Linked to |
| :--- | :--- |
| `.vimrc` | `~/.vimrc` |
| `.zshrc` | `~/.zshrc` |
| `.config/nvim` | `~/.config/nvim` |
| `.config/kitty` | `~/.config/kitty` |
| `.config/git` | `~/.config/git` |
| `.gitconfig` | `~/.gitconfig` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.editorconfig` | `~/.editorconfig` |

<!-- END LINKS -->

<sub>Generated from [`links.conf`](./links.conf) by `make docs` — do not edit by hand.</sub>

Three design decisions shape the installer:

1. **Non-destructive linking.** Before creating a symlink, `install` moves any existing file to a timestamped backup directory, so nothing is ever silently overwritten.
2. **Convergent state.** Every step checks the current state first — an existing link, an installed plugin, a ready Python provider — and acts only when needed. Running the installer twice produces the same result as running it once.
3. **A single command surface.** The [`Makefile`](./Makefile) wraps every script, so you never need to remember flags: `make install`, `make doctor`, `make uninstall`.

## Getting Started

### Prerequisites

You need exactly one thing installed manually — **[Homebrew](https://brew.sh)**, the package manager for macOS:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Everything else is handled automatically.

### Installation

**1. Clone the repository**

```bash
git clone git@github.com:ntwrcht/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

**2. Install the toolchain**

```bash
make deps
```

Reads the [`Brewfile`](./Brewfile) and installs every tool at once — editor, terminal, shell utilities, fonts, and Git tooling.

**3. Apply the configurations**

```bash
make install
```

This links all config files into place, installs [Oh My Zsh](https://ohmyz.sh) with the [Powerlevel10k](https://github.com/romkatv/powerlevel10k) theme and Zsh plugins, sets up the Neovim Python provider, and creates your local secrets file.

Open a new terminal window when it finishes — everything is active.

> **Tip:** Not sure what will happen? Run `make dry-run` first. It prints exactly what the installer would do without changing a single file.

## Usage

### Day-to-Day Commands

Run these from inside `~/.dotfiles`:

| Command | Description |
| :--- | :--- |
| `make install` | Install or update all managed symlinks |
| `make dry-run` | Preview what `install` would change, safely |
| `make uninstall` | Remove all configs applied by this repo |
| `make doctor` | Verify tools are installed and links are correct |
| `make deps` | Install or update all tools via Homebrew |
| `make docs` | Regenerate the generated sections of this README |
| `make cleanup` | Preview Homebrew packages that can be removed |
| `make cleanup-apply` | Remove the packages shown by `cleanup` |

### Previewing Changes

The installer supports a first-class dry-run mode. Every action — links, backups, downloads — is printed instead of executed:

```bash
$ make dry-run

⚠ Running in DRY-RUN mode. No changes will be made.

==> Installing Dotfiles
ℹ 🔗 Linking: ~/.zshrc -> ~/.dotfiles/.zshrc
ℹ 📦 Backing up: ~/.tmux.conf
```

### Managing Secrets

API keys and tokens belong in `~/.zshrc-secrets` — a file that exists only on your machine and is never committed. The installer creates it from the [example template](./.zshrc-secrets.example) with `600` permissions. Fill in your values:

```bash
# ~/.zshrc-secrets
export JIRA_API_TOKEN=""
export OPENAI_API_KEY=""
```

### Health Checks

If something breaks, the diagnostic tells you exactly what is missing or misconfigured:

```bash
make doctor
```

## What Gets Configured

| Tool | Role | What this config provides |
| :--- | :--- | :--- |
| **[Zsh](https://www.zsh.org)** | Shell | Aliases, smarter history, Powerlevel10k prompt, syntax highlighting, autosuggestions |
| **[Neovim](https://neovim.io)** | Editor | Full plugin setup, installed automatically on first launch |
| **[Kitty](https://sw.kovidgoyal.net/kitty)** | Terminal | Font, colors, and keyboard shortcuts |
| **[Tmux](https://github.com/tmux/tmux)** | Multiplexer | An owned ~90-line config — vi copy mode, mouse, seamless pane navigation with Neovim |
| **[Git](https://git-scm.com)** | Version control | Global ignore rules, commit template, [delta](https://github.com/dandavison/delta) diffs |

The Brewfile also installs modern CLI replacements — [eza](https://github.com/eza-community/eza) (`ls`), [bat](https://github.com/sharkdp/bat) (`cat`), [fd](https://github.com/sharkdp/fd) (`find`), [ripgrep](https://github.com/BurntSushi/ripgrep) (search), [fzf](https://github.com/junegunn/fzf) (fuzzy finding), [zoxide](https://github.com/ajeetdsouza/zoxide) (smarter `cd`) — plus [Lazygit](https://github.com/jesseduffield/lazygit), [jq](https://jqlang.github.io/jq), and the [fnm](https://github.com/Schniz/fnm) and [uv](https://github.com/astral-sh/uv) runtime managers.

## Contributing

Contributions are welcome — whether it is a bug fix, a new tool integration, or an improvement to the installer.

1. **Fork** the repository and create a feature branch: `git checkout -b feat/my-improvement`
2. **Make your change.** Keep scripts POSIX-friendly Bash with `set -euo pipefail`, and test with `make dry-run` before `make install`.
3. **Verify** with `make doctor` on a clean run. CI runs `shellcheck`, `zsh -n`, and a dry-run install on macOS.
4. **Open a pull request** with a clear description of the problem and your solution.

Found a bug or have an idea? [Open an issue](https://github.com/ntwrcht/dotfiles/issues) — clear reproduction steps make fixes fast.

## License

Distributed under the **MIT License**. See [`LICENSE`](./LICENSE) for full text.

You are free to fork this repository and adapt it into your own dotfiles — that is the whole point.

---

<div align="center">
  <sub>made for macOS · built to last · yours to fork</sub>
</div>
