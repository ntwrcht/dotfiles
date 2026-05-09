# ✦ Dotfiles

<div align="center">

![macOS](https://img.shields.io/badge/os-macOS-black?style=flat-square&logo=apple)
![Zsh](https://img.shields.io/badge/shell-zsh-blue?style=flat-square&logo=zsh)
![Neovim](https://img.shields.io/badge/editor-neovim-green?style=flat-square&logo=neovim)
![Tmux](https://img.shields.io/badge/multiplexer-tmux-blueviolet?style=flat-square&logo=tmux)

**A modern, minimalist development environment for macOS.**

</div>

---

## 🚀 Installation

```bash
git clone git@github.com:Canvas-xxx/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install
```

---

## 🛠 Commands

| Command | Source | Description |
| :--- | :--- | :--- |
| `make install` | [`install`](./install) | Install or update all symlinks |
| `make doctor` | [`doctor`](./doctor) | Run diagnostic check on tools and paths |
| `make deps` | [`Brewfile`](./Brewfile) | Install dependencies via Homebrew |
| `make cleanup` | [`cleanup-deps`](./cleanup-deps) | Identify and remove orphaned runtimes |

---

## 🔒 Secrets

Managed via `~/.zshrc-secrets` (ignored by Git). See [`.zshrc-secrets.example`](./.zshrc-secrets.example) for configuration.

```bash
export JIRA_API_TOKEN="your-jira-api-token"
export OPENAI_API_KEY="sk-..."
```

---

<div align="center">
  <sub>Built with ❤️ for macOS.</sub>
</div>
