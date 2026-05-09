# ✦ Dotfiles

<div align="center">

![macOS](https://img.shields.io/badge/os-macOS-black?style=flat-square&logo=apple)
![Zsh](https://img.shields.io/badge/shell-zsh-blue?style=flat-square&logo=zsh)
![Neovim](https://img.shields.io/badge/editor-neovim-green?style=flat-square&logo=neovim)
![Tmux](https://img.shields.io/badge/multiplexer-tmux-blueviolet?style=flat-square&logo=tmux)
![License](https://img.shields.io/badge/license-MIT-yellow?style=flat-square)

**A modern, minimalist development environment for macOS.**
*Tailored for efficiency, performance, and aesthetic consistency.*

[Installation](#-installation) • [Commands](#-commands) • [Dependencies](#-dependencies) • [Runtime](#-runtime-management) • [Secrets](#-secrets)

</div>

---

## 📸 Preview

<div align="center">
  <img src="./assets/screen_shot.png" width="48%" />
  <img src="./assets/screen-shot-homebrew.png" width="48%" />
</div>

---

## 🚀 Installation

Quickly bootstrap your environment with a single command:

```bash
git clone git@github.com:Canvas-xxx/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install
```

> [!IMPORTANT]
> After installation, run `make doctor` to verify your environment and `make deps` to install required tools.

The installer creates symlinks in your home directory. Existing files are safely moved to `~/.dotfiles-backup/<timestamp>`.

---

## 🛠 Commands

Manage your environment using the included `Makefile`:

| Command | Description |
| :--- | :--- |
| `make install` | Install or update all symlinks |
| `make dry-run` | Preview symlink changes without applying |
| `make doctor` | Run diagnostic check on tools and paths |
| `make deps` | Install Homebrew dependencies from `Brewfile` |
| `make cleanup` | Identify and remove orphaned runtime formulae |

---

## 📦 Dependencies

Managed via **Homebrew**. Core tools included in the bundle:

| Category | Tools |
| :--- | :--- |
| **Editor** | `Neovim` (Primary), `Vim` (Fallback) |
| **Shell** | `Zsh`, `Zoxide`, `Fzf`, `Bat`, `Eza` |
| **Terminal** | `Kitty`, `Tmux` |
| **Workflow** | `Lazygit`, `Fd`, `Ripgrep`, `Jq`, `Delta` |
| **Runtime** | `Fnm` (Node), `Uv` (Python), `Yarn` |

---

## ⚙️ Runtime Management

This setup prioritizes project-isolated runtimes over global system packages.

### 🟢 Node.js
We use `fnm` for lightning-fast version switching.
```bash
fnm install --lts
fnm default lts-latest
```

### 🔵 Python
We use `uv` for modern, fast Python package management. Avoid pinning global versions; prefer project-local virtualenvs.

---

## ⌨️ Neovim Setup

The editor environment is **Neovim-first**, powered by [lazy.nvim](https://github.com/folke/lazy.nvim).

1. Open Neovim: `nvim`
2. Sync plugins: `:Lazy sync`
3. Verify health: `:checkhealth`

---

## 🔒 Secrets

Security is handled via `~/.zshrc-secrets`, which is automatically created by the installer but **ignored by Git**.

```bash
# Example usage in ~/.zshrc-secrets
export JIRA_API_TOKEN="your-jira-api-token"
export OPENAI_API_KEY="sk-..."
```

---

<div align="center">
  <sub>Built with ❤️ for macOS.</sub>
</div>
