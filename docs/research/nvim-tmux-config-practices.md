# Neovim & tmux config practices, 2026 — and what they mean for this repo

**Research date:** 2026-09-17
**Method:** primary sources only — upstream docs, repo source, GitHub API repo/commit data, and the `tmux(1)` man page and Neovim `:help` files **installed on this machine**. Third-party write-ups are flagged inline where nothing first-party covers the point.

**Environment verified on this machine (2026-09-17):**

| Component | Version | How verified |
|---|---|---|
| Neovim | 0.12.2 | `nvim --version` |
| tmux | 3.6a | `tmux -V` |
| lazy.nvim | 11.17.5 | `:checkhealth lazy` |
| Outer terminal | `xterm-kitty`, reports `RGB` | `tmux display -p '#{client_termfeatures}'` |
| `TERM` inside tmux | `screen-256color` | `$TERM` |

---

## 1. Bottom line

**Your setup is in better shape than a "modernize it" instinct would suggest. Four of the six things worth doing are bug fixes, not migrations — and they total under an hour.**

The single most valuable finding: **your treesitter setup has been silently dead for some time.** Everything else is smaller.

The second most valuable finding: **coc.nvim is not abandoned. It received commits today.** A migration to native LSP is a legitimate choice, but frame it as a preference, not a rescue.

| Priority | Finding | Effort | Verdict |
|---|---|---|---|
| 1 | nvim-treesitter is installed but does nothing — zero parsers, highlighting off | 15 min | **Fix** |
| 2 | Three settings contradict themselves; `undofile` silently off | 10 min | **Fix** |
| 3 | `coc-python` archived since 2020; `coc-vetur` is Vue 2-only | 20 min | **Fix** |
| 4 | `.tmux.conf` is a copied blob; oh-my-tmux says symlink it | 30 min | **Fix** |
| 5 | tmux autostart guard misses IDE terminals; creates a new session per terminal | 15 min | **Fix** |
| 6 | Split `init.vim` into `init.lua` + `lua/` tree | 2–4 hrs | **Optional, real payoff** |
| 7 | coc.nvim → native LSP | 4–8 hrs | **Optional, no urgency** |
| 8 | `default-terminal screen-256color` → `tmux-256color` | 5 min | **Cheap win** |

---

## 2. Q1 — Neovim config structure

### 2.1 What the tooling documentation actually says

lazy.nvim documents a module tree as the recommended structure, not a single spec table:

> "The specs from the **module** and any top-level **sub-modules** will be merged together in the final spec."
> — [lazy.nvim docs, Structuring Your Plugins](https://lazy.folke.io/usage/structuring) (retrieved 2026-09-17)

`require("lazy").setup("plugins")` and `require("lazy").setup({{import = "plugins"}})` are documented as equivalent. Any Lua file under `~/.config/nvim/lua/plugins/*.lua` is merged automatically.

Merge semantics matter for maintainability, and the docs state them precisely:

> "`opts`, `dependencies`, `cmd`, `event`, `ft` and `keys` are always merged with the parent spec. Any other property will override the property from the parent spec."
> — same source

Lazy-loading triggers are declarative and co-located with the spec:

> Plugins are lazy-loaded when "The plugin only exists as a dependency in your spec", "It has an `event`, `cmd`, `ft` or `keys` key", or "`config.defaults.lazy == true`".
> — [lazy.nvim docs, Lazy Loading](https://lazy.folke.io/spec/lazy_loading) (retrieved 2026-09-17)

### 2.2 Three real configs, three different answers

| Config | Stars | Last push | Structure |
|---|---|---|---|
| [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) | 31,471 | 2026-09-14 | **Deliberately single-file** `init.lua` (1,039 lines) + opt-in `lua/kickstart/plugins/*.lua` |
| [LazyVim/starter](https://github.com/LazyVim/starter) | — | — | `init.lua` → `lua/config/{lazy,options,keymaps,autocmds}.lua` + `lua/plugins/*.lua` |
| [folke/dot](https://github.com/folke/dot) (`nvim/`) | 1,285 | 2026-04-17 | Same shape as starter; `lua/plugins/` grouped **by topic** (`ai.lua`, `coding.lua`, `lsp.lua`, `ui.lua`, `treesitter.lua`), not one file per plugin |

*(Repo metadata from the GitHub REST API, fetched 2026-09-17.)*

kickstart.nvim states its philosophy in its README: "Small / Single-file / Completely Documented". **So "single file" is a defensible position held by the most-starred starting-point config in the community.** The argument against your current file is not its file count — it is that a 437-line VimScript file with an embedded 190-line Lua heredoc gets neither VimScript nor Lua tooling to work on it.

Note the pattern folke uses: **grouped by topic, not one file per plugin.** One file per plugin produces 30 two-line files and a worse experience than one file. Topic grouping is what the working configs actually do.

### 2.3 What concretely makes a config easier to change in six months

Not "modularity". These specific mechanisms:

| Mechanism | What it buys you | Your config today |
|---|---|---|
| Lua file, not VimScript heredoc | LSP, treesitter, stylua, and `gd` all work on the config itself | ❌ — heredoc is an opaque string to every tool |
| Per-topic file under `lua/plugins/` | `git blame`/`git log` scope to one concern; merge conflicts shrink | ❌ — every change touches one file |
| `config`/`opts` co-located in the spec | You read "what plugin" and "how configured" in one place | ⚠️ partial — telescope is co-located, but lualine/gitsigns/treesitter configure ~50 lines below the spec |
| `event`/`ft`/`cmd`/`keys` declarations | Startup cost is visible in the spec; `:Lazy profile` attributes time | ❌ — only 2 of 30 plugins declare a trigger |
| `:checkhealth lazy` | Detects duplicate managers, stale `packer_compiled.lua`, git version | ✅ passes clean today |
| `lazy-lock.json` in git | `:Lazy restore` reproduces an exact working state | ✅ you already do this |
| One `pcall` per concern → **none** | A typo fails loudly instead of silently | ❌ — **this is how your treesitter config died** (see §3.1) |

**The `pcall` point is the load-bearing one.** Your `pcall(require, "nvim-treesitter.configs")` swallowed a real failure for months. In a module tree, that plugin's file would error visibly on startup.

### 2.4 A genuinely new option: `vim.pack`

Neovim 0.12 ships a built-in plugin manager. From the local `:help vim.pack` (`pack.txt`, Neovim 0.12.2):

> "Install, update, and delete external plugins. WARNING: It is still considered experimental, yet should be stable enough for daily use."

It keeps a lockfile at `$XDG_CONFIG_HOME/nvim/nvim-pack-lock.json`, and the docs say: "For a more robust config treat lockfile like its part: put under version control".

**kickstart.nvim has already migrated from lazy.nvim to `vim.pack`** (verified by reading `init.lua` on `master`, 2026-09-17 — it calls `vim.pack.add` throughout and its README documents `nvim-pack-lock.json`).

Meanwhile lazy.nvim's own pace has slowed: last release **v11.17.5 on 2025-11-06**, last commit on `main` **2025-12-17** (`chore(build): auto-generate rockspec mappings`). It is not abandoned and it is not broken — but it is no longer moving.

**Recommendation: stay on lazy.nvim.** It works, it is pinned, and `vim.pack` is self-described as experimental. Revisit in 2027. Do not take on two migrations at once.

### 2.5 Q1 recommendation

| | |
|---|---|
| **What to change** | Convert `init.vim` → `init.lua`; `lua/config/{options,keymaps,autocmds}.lua`; `lua/plugins/{ui,editor,lsp,lang,ai,tools}.lua`. Keep lazy.nvim. Delete every `pcall` wrapper. |
| **What it costs** | 2–4 hours, mechanical. Highest-risk part is translating the VimScript `GitCommitMessageFn()` function and the `\`-continued `g:vim_ai_*` dicts — those can stay in a `vim.cmd([[...]])` block verbatim if you prefer. |
| **What to leave alone** | lazy.nvim itself. `lazy-lock.json` committed. The leader choice. The plugin list. |
| **Honest counterpoint** | If you only touch this file twice a year, the restructure does not pay for itself. Do §3.1 and §5 first — those are bugs and they pay immediately. |

---

## 3. Bugs found in the current Neovim config

These were found by **running your config**, not by reading it.

### 3.1 nvim-treesitter is installed and does nothing — confirmed

`lazy-lock.json` pins `nvim-treesitter` to **`branch: main`**. Your spec does not pin a branch, so lazy.nvim follows the repo default — and nvim-treesitter's default branch is now `main`, a complete rewrite.

The rewrite's README is explicit:

> "**CAUTION** This is a full, incompatible, rewrite: Treat this as a different plugin you need to set up from scratch following the instructions below. If you can't or don't want to update, specify the [`master` branch] (which is locked but will remain available for backward compatibility with Nvim 0.11)."
> — [nvim-treesitter README](https://github.com/nvim-treesitter/nvim-treesitter) (retrieved 2026-09-17)

The `main` branch has **no `nvim-treesitter.configs` module** (verified: `lua/nvim-treesitter/` on `main` contains `config.lua`, `install.lua`, `parsers.lua`… but no `configs.lua`; `master` still has it). Your `pcall` swallows the error.

Verified by running your config:

```
$ nvim --headless -c 'lua print(pcall(require,"nvim-treesitter.configs"))' -c q
false   module 'nvim-treesitter.configs' not found

$ ls ~/.local/share/nvim/site/parser | wc -l
0
$ # treesitter highlighter active on a real buffer:
TS highlighter active: false
```

**Zero parsers installed. Highlighting is off.** Every colour you see comes from the legacy regex syntax plugins — which explains why you still need `vim-javascript`, `typescript-vim`, `vim-jsx-pretty`, `vim-jsx-typescript`, `vim-graphql`, `vim-vue-plugin`.

The fix, per the README's own instructions:

```lua
{ 'nvim-treesitter/nvim-treesitter', lazy = false, build = ':TSUpdate' }
```

then install parsers and turn highlighting on — which on `main` is Neovim's job, not the plugin's:

> "Treesitter highlighting is provided by Neovim, see `:h treesitter-highlight`. To enable it for a filetype, put `vim.treesitter.start()` in a `ftplugin/<filetype>.lua` in your config directory, or place the following in your `init.lua`: `vim.api.nvim_create_autocmd('FileType', { pattern = {...}, callback = function() vim.treesitter.start() end })`"

Note the `main` branch requires **Neovim 0.12.0+** (you have 0.12.2 ✅), plus `tree-sitter-cli` ≥ 0.26.1 installed **via package manager, not npm**, and `tar`/`curl`.

**Alternative, if you want zero risk:** pin `branch = "master"`. Your existing `nvim-treesitter.configs` block would then work as written. `master` is frozen but supported for Neovim 0.11 — on 0.12 it is unsupported territory. The `main` path is the correct one.

**Effort: 15 minutes. This is the highest-value change in this document.** Once treesitter works, six legacy syntax plugins become removable.

### 3.2 Settings that contradict themselves

| Lines | Conflict | Winner | Verified |
|---|---|---|---|
| 212 vs 218 | `set undofile` → `set noundofile` | `noundofile` | `undofile=0` at runtime — **persistent undo is off**, and `undolevels`/`undoreload` on lines 214–215 are wasted |
| 221 vs 231 | `set nocursorline` → `set cursorline` | `cursorline` | `cursorline=1` at runtime |
| 400 vs 429 | `<TAB>` mapped twice (`pumvisible()` then `coc#pum#visible()`) | line 429 | the `coc#pum` version — correct for modern coc |
| 415 vs 426 | `<CR>` mapped twice | line 426 | the `coc#pum#confirm()` version — correct for modern coc |
| 222 vs 365 | `set shortmess+=c` twice | harmless | — |

Lines 400/415 are **pre-`coc#pum` legacy mappings** (coc.nvim moved to its own popup menu in v0.0.82, 2022-07-31). They are dead weight that reads as if it were live. Delete them.

Decide what you want for `undofile`. If you want persistent undo, delete line 218. **Effort: 10 minutes.**

### 3.3 The `vim.treesitter.ft_to_lang` shim

Lines 38–42 define `vim.treesitter.ft_to_lang` if missing. Verified: it **does not** exist in a clean Neovim 0.12.2 (`nvim --clean` → `false`), so the shim is still doing something. It is harmless. Leave it until telescope no longer needs it, then delete with a comment noting why it existed.

---

## 4. Q2 — coc.nvim vs native LSP in 2026

### 4.1 coc.nvim's actual maintenance status

Measured via the GitHub REST API on 2026-09-17:

| Signal | Value |
|---|---|
| Last commit to `master` | **2026-09-17** (`fix(files): undo nested workspace edits`) |
| Last commit to `release` branch (what you track) | 2026-09-16 |
| Commits in the last 52 weeks | **470** |
| Open issues | **6** |
| Archived / disabled | No / No |
| Stars | 25,155 |
| Last tagged release | v0.0.82, 2022-07-31 |

Recent commit authors are overwhelmingly **Qiming Zhao (chemzqm)**, the original author, plus occasional outside PRs.

**Verdict: coc.nvim is actively, near-daily maintained by its original author.** Six open issues on a 25k-star project is an unusually tight triage record. The stale release tag is misleading — coc.nvim distributes through the `release` branch, which you already track.

I looked for a maintainer statement about the project's future and did **not** find a clear one. The discussion ["What's next for Coc.nvim?"](https://github.com/neoclide/coc.nvim/discussions/4593) contains only a one-line reply from chemzqm dated 2023-09-01 ("Yes, we need AI plugins for vim."). **See Open Questions.**

### 4.2 The state of native `vim.lsp`

From the Neovim 0.11 release notes (`runtime/doc/news.txt` at tag `v0.11.0`):

> "vim.lsp.config() has been added to define default configurations for servers. In addition, configurations can be specified in `lsp/<name>.lua`."
> "vim.lsp.enable() has been added to enable servers."

0.11 also added default keymaps unconditionally: `grn` rename, `gra` code action, `grr` references, `gri` implementation, `gO` document symbol, `CTRL-S` signature help.

From `:help lsp` on **your installed 0.12.2**, the quickstart is now four lines:

```lua
vim.lsp.config['lua_ls'] = {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
  settings = { Lua = { runtime = { version = 'LuaJIT' } } },
}
vim.lsp.enable('lua_ls')
```

0.12 added on top of that (from local `news.txt`): `grt` type definition, `grx` codelens, `:lsp` for interactive client management, `:checkhealth vim.lsp`, `textDocument/inlineCompletion`, `workspace/diagnostic`, document colour, linked editing, on-type formatting, and `vim.lsp.enable()` now "start/stops clients as necessary and detaches non-applicable LSP clients."

**Native LSP in 0.12 is feature-complete enough that nvim-lspconfig is now a config catalogue, not a framework.**

### 4.3 The completion engine question

Here is what actually happened — I could not find any archival or hand-off announcement, and the evidence does not support one.

| | nvim-cmp | blink.cmp |
|---|---|---|
| Repo | [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | [Saghen/blink.cmp](https://github.com/Saghen/blink.cmp) |
| Archived? | **No** | No |
| Last commit | 2026-07-09 | **2026-09-10** |
| Commits in 2026 (visible in first 10) | 7, sporadic — Jan, Mar, Jul | continuous |
| Open issues | **304** | 99 |
| Stars | 9,480 | 6,578 |
| Last release | — | v1.10.2, 2026-04-04 |
| Author's own last PR | hrsh7th, **2025-11-04** | active |

**What the "notable development" appears to be:** during a 2024 lull, a community fork appeared — [iguanacucumber/magazine.nvim](https://github.com/iguanacucumber/magazine.nvim), created 2024-10-04. Its README states plainly:

> "The goal of magazine.nvim is NOT to replace nvim-cmp, it's goal is to fix annoying bugs & implement new features early and more generaly to be like a 'beta' version of nvim-cmp relieving burden from hrsh7th"

**magazine.nvim is now archived** (archived: true, last push 2025-03-25). So: a fork formed, upstream resumed merging community PRs, the fork wound down. nvim-cmp today accepts fixes from contributors (wsdjeg, litoj, ErikReider and others), while hrsh7th's own attention has moved to [nvim-cmp-kit](https://github.com/hrsh7th/nvim-cmp-kit), "nvim's completion core module" — 36 stars, last push 2026-06-01, with "Rename repository" still on its TODO list. That is a research project, not a replacement.

**What the popular configs do:** [LazyVim](https://github.com/LazyVim/LazyVim) ships both as opt-in extras (`extras/coding/blink.lua`, `extras/coding/nvim-cmp.lua`), each of which sets `enabled = false` on the other. The nvim-cmp extra carries the comment `version = false, -- last release is way too old`. kickstart.nvim, however, ships **blink.cmp** as its only completion engine, pinned `version = vim.version.range '1.*'`.

**blink.cmp caveat, from its own README (retrieved 2026-09-17):**

> "**WARNING** V2 is under active development with many breaking changes. Consider staying on stable by using `branch = 'v1'` or `version = \"1.*\"` in your `lazy.nvim` config."

If you go blink, pin `version = "1.*"`.

**Third option, new in 0.12 and worth knowing about:** Neovim now has built-in autocompletion. From local `:help ins-autocompletion` and `:help 'autocomplete'`:

> `'autocomplete'` `'ac'` boolean (default off) — "When on, Vim shows a completion menu as you type, similar to using `i_CTRL-N`, but triggered automatically."

With `vim.lsp.completion.enable(..., { autotrigger = true })` plus `set autocomplete` and `set complete+=o`, you get LSP autocompletion **with no completion plugin at all**. This is new and not yet the community default, but for a config as light as yours it is a real option.

### 4.4 mason.nvim — organization change confirmed

Confirmed from the v2.0.0 release notes (published **2025-05-06**):

> "### Repository has been moved
> The repository has been transferred to the [`mason-org`](https://github.com/mason-org) organization. The new URL is https://github.com/mason-org/mason.nvim. The previous URL will continue to function as a redirect to the new URL but users are recommended to update to the new location."

The same release added three new maintainers (@mehalter, @Conarius, @chrisgrieser). Current release **v2.3.1, 2026-06-11**. `williamboman/mason.nvim` and `mason-org/mason.nvim` return identical API objects — confirming the redirect.

**Use `mason-org/mason.nvim`.** mason is the piece that makes native LSP comparable in convenience to coc: it installs the servers, which is the job coc's extension host does today.

### 4.5 Migration map — all 13 extensions, each verified

Every server name below was checked against the file list of `nvim-lspconfig`'s `lsp/` directory on `master` (416 configs, fetched 2026-09-17). Every formatter/linter name was checked against `conform.nvim`'s and `nvim-lint`'s source trees.

| Your coc extension | Upstream status | Native equivalent | Verified |
|---|---|---|---|
| `coc-tsserver` | active, pushed 2026-08-07 | `ts_ls`, or `vtsls`, or `tsc` (TypeScript-Go) | ✅ all three present |
| `coc-clangd` | active, pushed 2026-09-01 | `clangd` | ✅ |
| `coc-python` | **ARCHIVED 2020-12-23** | `basedpyright` or `pyright`, + `ruff` | ✅ all three present |
| `coc-go` | pushed 2024-10-22 | `gopls` | ✅ |
| `coc-emmet` | pushed 2023-01-07 | `emmet_language_server` (also `emmet_ls`) | ✅ both present |
| `coc-html` | active, pushed 2026-08-29 | `html` | ✅ |
| `coc-css` | active, pushed 2026-08-31 | `cssls` | ✅ |
| `coc-prettier` | pushed 2025-06-11 | `conform.nvim` → `prettier` or `prettierd` | ✅ both formatters exist |
| `coc-json` | active, pushed 2026-09-14 | `jsonls` | ✅ |
| `coc-docker` | pushed 2023-02-22 | `dockerls`, or the newer `docker_language_server` (Docker's own, handles Dockerfile **and** compose) | ✅ both present |
| `coc-markdownlint` | active, pushed 2026-09-01 | `marksman` (LSP) + `markdownlint-cli2` via conform/nvim-lint | ✅ all three present |
| `coc-sh` | pushed 2025-02-25 | `bashls` | ✅ |
| `coc-vetur` | **pushed 2021-08-02 — Vue 2 era** | `vue_ls` + `vtsls` — see below | ✅ |

**Your list has one dead entry.** `coc-python`'s own README says:

> "**WARNING**: it's recommended to use [coc-pyright] if you're using python3 or use [coc-jedi] if you're using jedi, the code of coc-python is too hard to maintain!"

**Replace `coc-python` with `coc-pyright`** (fannheyward/coc-pyright, 1,360 stars, pushed 2026-09-10 — healthy). That is a one-line change and does not require any migration.

### 4.6 coc-vetur → Vue 3, and the fiddly TypeScript plugin arrangement

Vetur is the Vue 2-era tool. `coc-vetur` wraps `vls` (vue-language-server) and has not been pushed since 2021-08-02. Vue's tooling moved to [vuejs/language-tools](https://github.com/vuejs/language-tools) (Volar), which is very much alive — pushed 2026-09-16, 6,718 stars.

The current arrangement, quoted verbatim from `nvim-lspconfig/lsp/vue_ls.lua` (`master`, 2026-09-17):

> "The language server only supports Vue 3 projects by default. For Vue 2 projects, additional configuration are required."
> "The Vue language server works in **'hybrid mode'** which exclusively manages the CSS/HTML sections. You need the `vtsls` server with the `@vue/typescript-plugin` plugin to support TypeScript in `.vue` files."
> "**NOTE**: Since v3.0.0, the Vue Language Server [no longer supports takeover mode]."

So the Vue 3 setup is **two cooperating servers**:

1. `vue_ls` (`vue-language-server --stdio`) — owns template/CSS.
2. `vtsls` (or `ts_ls`) loaded with the `@vue/typescript-plugin` — owns TypeScript, including inside `.vue` files.

`vue_ls.lua` ships an `on_init` handler that forwards `tsserver/request` messages to whichever TS client is attached, retrying up to 10 times with a 100ms delay because "there can sometimes be a short delay until `ts_ls`/`vtsls` are attached". **That retry loop in upstream's own code is the honest measure of how fiddly this is.** The old `volar` config name still exists but only as a deprecation shim that calls `vim.deprecate('volar', 'vue_ls', '3.0.0', ...)`.

**If you stay on coc:** [yaegassy/coc-volar](https://github.com/yaegassy/coc-volar) (292 stars, pushed 2025-03-02) is the coc-side replacement for `coc-vetur`. Less current than the native path, but a much smaller change.

### 4.7 Q2 verdict — honest

**coc.nvim still works fine. Migrating is optional. Do not do it because a blog post told you to.**

| | |
|---|---|
| **What to change now** | `coc-python` → `coc-pyright` (1 line). `coc-vetur` → `coc-volar` if you still write Vue (1 line). Delete the duplicate legacy `<TAB>`/`<CR>` mappings. |
| **Cost** | 20 minutes. |
| **What to leave alone** | coc.nvim itself. The `gd`/`gy`/`gi`/`gr`/`K`/`[g`/`]g` mappings — those are muscle memory and they work. |
| **If you migrate anyway** | Budget **4–8 hours of real work**, plus 2–4 weeks of paper cuts. Native LSP is genuinely better structured now, and you get one dependency chain (Go/Rust binaries via mason) instead of two (Node + coc extension host + npm). The honest reasons to do it: you dislike having Node in the loop, or you want the 0.12 features (`:lsp`, `:checkhealth vim.lsp`, inline completion). "coc is dying" is **not** a reason — it is not true. |
| **If you do migrate, the 2026 stack is** | `nvim-lspconfig` (catalogue) + `vim.lsp.enable()` + `mason-org/mason.nvim` + `mason-lspconfig` + `conform.nvim` (format) + `nvim-lint` (markdownlint) + `blink.cmp` pinned `version = "1.*"` — **or** no completion plugin at all, using 0.12's `'autocomplete'` + `vim.lsp.completion.enable({autotrigger=true})`. |

---

## 5. Q3 — tmux

### 5.1 oh-my-tmux maintenance status

| Signal | Value (2026-09-17) |
|---|---|
| Last commit | **2026-08-08** |
| Recent activity | Substantive — `refactored TPM plugins discovery`, `improved install.sh`, `warn when server and client versions do not match` (all Aug 2026) |
| Open issues | 24 |
| Stars | 25,385 |
| Tagged releases | **None** — the project ships no version tags at all |

**oh-my-tmux is actively maintained.** The absence of tags is the root of your provenance problem: there is no version number to record even if you wanted to.

### 5.2 Your copy violates oh-my-tmux's own installation instructions

From the [oh-my-tmux README](https://github.com/gpakosz/.tmux) (retrieved 2026-09-17), the documented install is a **clone plus a symlink**:

```sh
ln -s -f .tmux/.tmux.conf      # symlink the main file
cp .tmux/.tmux.conf.local .    # copy only the customization file
```

And the maintenance contract:

> "You should never alter the main .tmux.conf or tmux.conf file. If you do, you're on your own. Instead, every customization should happen in your .tmux.conf.local or tmux.conf.local customization file copy."

You honour the second half — all your settings live in `.tmux.conf.local`. But you copied the main file instead of symlinking it, and copied it on **2023-04-05** (file mtime). That is **~3.5 years and several hundred upstream commits behind**, with no recorded commit SHA. You have taken on maintenance of a 1,447-line file you did not write and cannot diff.

The README also states requirements: "tmux >= 2.6" and `TERM` set to `xterm-256color` outside tmux. **Your outer `TERM` is `screen-256color`** — because you are nested one level from a previous tmux, or because a parent process set it. Worth checking; it is not what oh-my-tmux expects.

### 5.3 Is vendoring still normal? What are the alternatives?

Three approaches, all live in 2026:

| Approach | Status | Trade-off |
|---|---|---|
| **oh-my-tmux as a git submodule + symlink** | Upstream's documented method; actively maintained | You get updates; you keep a 1,447-line black box you cannot read |
| **tpm + plugins** | [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm), 15,089 stars, pushed 2026-05-17. Requires "tmux version 1.9 (or higher), git, bash". Install is `set -g @plugin '...'` lines plus `run '~/.tmux/plugins/tpm/tpm'` — and the README is emphatic: "keep this line at the very bottom of tmux.conf" | Composable, per-plugin versions. But adds a bootstrap step and a plugins directory |
| **A hand-written ~60-line conf** | Always available | You own every line and can read it in 2 minutes. You lose the battery indicator, the pretty separators, and the `_maximize_pane`/`_urlview`/`_fpp` helpers |

Worth noting: oh-my-tmux **has built-in TPM support** (`<prefix> I` install, `<prefix> u` update), and you already enable it — `tmux_conf_update_plugins_on_launch=true` and `tmux_conf_update_plugins_on_reload=true` are set in your `.tmux.conf.local`. But you have **zero `set -g @plugin` lines**, so that machinery does nothing for you.

**Recommendation: pick one, and pick it on how much of oh-my-tmux you actually use.** Reading your `.tmux.conf.local`, you use: the Dracula theme colours, `status-position top`, a custom `status_left` (`🐶 | ♦️ #S`), an **empty** `status_right`, vi copy mode, mouse on, and the vim-tmux-navigator block. Everything else — battery bars, pairing indicators, synchronized-pane indicators, `tmux_conf_theme_*` for bells and activity — is unused decoration. That is a ~60-line hand-written conf's worth of behaviour sitting behind 87KB of config.

### 5.4 What tmux 3.6a's man page actually says about the old option names

I checked each against the **installed** `tmux(1)` man page (3.6a) and against the live server.

| Setting in your config | tmux 3.6a status | Action |
|---|---|---|
| `set -g default-terminal "screen-256color"` | Valid. Man page: "For tmux to work correctly, this must be set to 'screen', 'tmux' or a derivative of them." | **Change to `tmux-256color`** — see below |
| `setw -g xterm-keys on` | Option still **accepted** by tmux 3.6a (`show-options -g xterm-keys` → `on`), but **absent from the 3.6a man page**. Undocumented legacy. | Harmless; drop it if you rewrite |
| `set -q -g status-utf8 on` / `setw -q -g utf8 on` | **Unknown options** in 3.6a — confirmed, they error. The `-q` flag suppresses the error, which is why you never saw it. Comment in the file says "tmux < 2.2". | Dead lines; harmless |
| `set -ga terminal-overrides ...` (commented out in your `.local`) | Still valid. Man page: "The terminal entry value is passed through strunvis(3)…" | — |
| `terminal-features` | Introduced in **tmux 3.2**. Per the tmux CHANGES file: "terminal-features is intended for classes of functionality supported in a standard way but not reported by terminfo(5)… The terminal-overrides option remains both for backwards compatibility and to allow tweaks of individual capabilities." | Prefer this over `terminal-overrides` for new settings |

**The one change worth making: `screen-256color` → `tmux-256color`.** Verified with `infocmp` on this machine:

```
screen-256color    sitm=      (no italics)
tmux-256color      sitm=sitm  (italics)
xterm-kitty        sitm=sitm smxx=smxx Smulx=Smulx
```

The tmux FAQ (first-party, [tmux/tmux wiki](https://github.com/tmux/tmux/wiki/FAQ)) says the same:

> "Inside tmux TERM must be 'screen', 'tmux' or similar (such as 'tmux-256color'). Outside, it should match your terminal."

and notes that "the `tmux` and `tmux-256color` descriptions do have such capabilities" for modified function keys, whereas `screen`/`screen-256color` do not.

`tmux-256color` is already installed here (`infocmp tmux-256color` succeeds). **5-minute change, real gain: italics and correctly-reported modified keys.**

**Truecolor: leave it alone.** Your config sets `tmux_conf_24b_colour=false` and `default-terminal "screen-256color"`, which looks broken — but tmux 3.2+ autodetects. Verified on the live server:

```
$ tmux display -p '#{client_termfeatures}'
bpaste,ccolour,clipboard,cstyle,focus,RGB,title
```

**`RGB` is present.** Truecolor works. Do not add `terminal-overrides ",*:Tc"` — you would be fixing a non-problem.

### 5.5 A minimal, readable tmux.conf

Every line cited to `tmux(1)` (3.6a) unless noted. This reproduces the behaviour you actually use.

```tmux
# ─── Terminal ────────────────────────────────────────────────────────────────
# default-terminal: "must be set to 'screen', 'tmux' or a derivative of them"
# tmux-256color carries italics (sitm) and modified-function-key caps that
# screen-256color lacks.  [tmux(1) OPTIONS; tmux FAQ]
set  -g default-terminal "tmux-256color"

# terminal-features: "named sets of terminal features … intended for classes of
# functionality supported in a standard way but not reported by terminfo(5)"
# Only needed if your terminal does NOT advertise RGB. Kitty already does —
# check with:  tmux display -p '#{client_termfeatures}'
#set -as terminal-features ",xterm-256color:RGB"

# escape-time: "the time in milliseconds for which tmux waits after an escape
# is input to determine if it is part of a function or meta key". Low = no lag
# on <Esc> in vim.  [tmux(1) OPTIONS]
set  -s escape-time 10

# focus-events: lets tmux forward terminal focus events to programs inside —
# vim's FocusGained/FocusLost, and :checktime autoread.
set  -s focus-events on

# ─── Prefix ──────────────────────────────────────────────────────────────────
# prefix2: "Set a secondary key accepted as a prefix key."  [tmux(1) OPTIONS]
# Keeping C-b as primary avoids clobbering readline's C-a (start-of-line).
set  -g prefix2 C-a
bind C-a send-prefix -2

# ─── Indexing & history ──────────────────────────────────────────────────────
set  -g base-index 1
setw -g pane-base-index 1
set  -g renumber-windows on
set  -g history-limit 50000

# ─── Mouse ───────────────────────────────────────────────────────────────────
# mouse: "If on, tmux captures the mouse and allows mouse events to be bound
# as key bindings."  [tmux(1) OPTIONS]
set  -g mouse on

# ─── Copy mode (vi) ──────────────────────────────────────────────────────────
# mode-keys: "Use vi or emacs-style key bindings in copy mode."  [tmux(1)]
# With vi, copy-mode bindings live in the `copy-mode-vi` key table.  [tmux(1)
# WINDOWS AND PANES: "copy-mode for emacs, or copy-mode-vi for vi"]
setw -g mode-keys vi
set  -g status-keys vi
bind -T copy-mode-vi v     send -X begin-selection
bind -T copy-mode-vi C-v   send -X rectangle-toggle
bind -T copy-mode-vi y     send -X copy-pipe-and-cancel "pbcopy"   # macOS
bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel "pbcopy"

# ─── Splits that inherit the current directory ───────────────────────────────
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# ─── vim-tmux-navigator ──────────────────────────────────────────────────────
# Verbatim from christoomey/vim-tmux-navigator README (2026-09-17). The
# `is_vim` test inspects the pane's foreground process; if it is vim/nvim/fzf
# the key is forwarded, otherwise tmux moves the pane. `-n` binds in the root
# key table (no prefix).
vim_pattern='(\S+/)?g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?'
is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
    | grep -iqE '^[^TXZ ]+ +${vim_pattern}$'"
bind -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
# tmux >= 3.0 needs the doubled backslash (README documents both forms)
bind -n 'C-\' if-shell "$is_vim" 'send-keys C-\\' 'select-pane -l'
# Restore the shadowed keys behind the prefix:
bind C-l send-keys 'C-l'      # readline clear-screen
bind C-\\ send-keys 'C-\'     # SIGQUIT to foreground process

# ─── Status line ─────────────────────────────────────────────────────────────
set  -g status-position top
set  -g status-interval 10
set  -g status-style        "fg=#6272a4,bg=#282a36"
set  -g status-left         " 🐶 | ♦️ #S "
set  -g status-left-style   "fg=#282a36,bg=#50fa7b,bold"
set  -g status-left-length  40
set  -g status-right        ""
setw -g window-status-format         " #I #W "
setw -g window-status-current-format " #I #W "
setw -g window-status-current-style  "fg=#f8f8f2,bg=#6272a4,bold"
set  -g pane-border-style        "fg=#f8f8f2"
set  -g pane-active-border-style "fg=#6272a4"
set  -g message-style            "fg=#bd93f9,bg=#44475a,bold"

# ─── Reload ──────────────────────────────────────────────────────────────────
bind r source-file ~/.tmux.conf \; display "~/.tmux.conf sourced"
```

That is ~60 lines and reproduces everything you currently use, including your exact Dracula palette and status-left. Colours are taken from your `.tmux.conf.local`.

### 5.6 vim-tmux-navigator: verified working, one small drift

Good news: your `.tmux.conf.local` **does** contain the navigator bindings (lines 301–314), and they are live. Verified against the running server:

```
$ tmux list-keys -T root | grep C-l
bind-key -T root C-l  if-shell "ps -o state= …" "send-keys C-l" "select-pane -R"
```

The navigator binding **wins** over oh-my-tmux's `bind -n C-l ... clear-history` on line 74 of `.tmux.conf`, because `.tmux.conf.local` is sourced last. No conflict in practice.

One drift: your `is_vim` regex is `(g?(view|n?vim?x?)(diff)?|fzf)`, an older upstream revision. Current upstream is `(\S+/)?g?\.?(view|l?n?vim?x?|fzf)(diff)?(-wrapped)?` — it adds `-wrapped` (Nix), a leading `.` (wrapper scripts), and `lvim`. **None of those apply to you on macOS/Homebrew. Leave it.**

### 5.7 Q3 recommendation

| | |
|---|---|
| **What to change** | (a) `default-terminal` → `tmux-256color` — 5 min, real gain. (b) Fix the provenance: either replace the copied `.tmux.conf` with a git submodule + symlink as upstream documents, **or** replace both files with the ~60-line conf in §5.5 — 30 min either way. (c) Delete `tmux_conf_update_plugins_on_*` — you have no TPM plugins. |
| **Cost** | 35 min total. |
| **What to leave alone** | The truecolor setup — `RGB` is detected, it works. The vim-tmux-navigator block — it is correct and live. `mouse on` / `mode-keys vi` / `status-position top`. The Dracula palette. |
| **Which option to pick** | If you have never wanted a feature oh-my-tmux provides that you do not already use, take the 60-line conf. If you like having `<prefix>+` maximize-pane and `<prefix>U` urlview, submodule it properly. |

---

## 6. Q4 — Ergonomics

### 6.1 Tab-centric vs buffer-centric

The design intent is unambiguous in the docs. From `:help windows-intro` on your installed Neovim 0.12.2:

> ```
> Summary:
>    A buffer is the in-memory text of a file.
>    A window is a viewport on a buffer.
>    A tab page is a collection of windows.
> ```

And `:help tab-page-intro`:

> "A tab page holds one or more windows. You can easily switch between tab pages, so that you have several collections of windows to work on different things."
> "Tab pages are also a nice way to edit a buffer temporarily without changing the current window layout. Open a new tab page, do whatever you want to do and close the tab page."

**So yes: in Vim's design, tabs are window-layout containers, not file slots.** Your `telescope` override — `actions.select_default:replace(actions.select_tab)` — makes every file open create a new layout container holding exactly one window. That is not what the abstraction is for.

**But "against the grain" is not the same as "wrong", and the honest trade-offs are:**

| | Tab-centric (yours) | Buffer-centric |
|---|---|---|
| Spatial recall | **Strong** — `<leader>3` is always the same file this session | Weak — you search or cycle |
| Fixed-cost jump | **Yes** — one keystroke pair, no picker, no thinking | No — `<leader>b` then filter then Enter |
| Scales past ~9 files | **No** — `<leader>1-9` runs out and `:tablast` is the only escape | Yes — the picker does not care about count |
| Splits/diffs | Awkward — a tab already means "one file", so a split inside one is confusing | Natural — that is exactly what tabs are for |
| Plugin compatibility | Mixed — plugins assume buffers; you already had to override telescope, and `g:floaterm_opener = "tabe"` is a second workaround | Default path, no overrides |
| Memory/state | Each tab holds a window with its own options, folds, view | Buffers share state |

**Verdict: this is a legitimate workflow and I would not tell you to change it.** The tab number *is* real spatial memory, and a fixed one-keystroke jump genuinely beats a fuzzy picker for the 5–9 files you are actively editing. Plenty of people work this way productively.

The honest cost is not conceptual purity — it is **friction with plugins**. You have already paid it twice (the telescope override, the floaterm opener). Expect to pay it again each time you add a plugin that assumes buffers.

**If you ever want to try the other side** without giving up spatial recall, the usual bridge is a pinned-buffer jump list — one keystroke per slot, but backed by buffers so splits and plugins still behave. That is a preference change, not a fix. **Nothing here needs doing.**

### 6.2 Auto-starting tmux from `.zshrc`

**The pattern is common. Your specific implementation has two real problems.**

#### Problem 1: `tmux` creates a *new* session every time

From `tmux(1)` (3.6a), on the command argument:

> "If no commands are specified, the command in `default-client-command` is assumed, which defaults to `new-session`."

So `tmux` — with no arguments — means `tmux new-session`. It does **not** attach to an existing session. Every new terminal window starts another session, numbered `0`, `1`, `2`, … (confirmed: your live session is named `0`, the default numeric name that `new-session` assigns when `-s` is omitted).

The `|| tmux new` fallback in your `.zshrc` is therefore unreachable — the first command never fails for the reason it was written to catch.

The documented fix is `-A`:

> "The `-A` flag makes `new-session` behave like `attach-session` if `session-name` already exists; if `-A` is given, `-D` behaves like `-d` to `attach-session`"
> — `tmux(1)`, `new-session`

```sh
exec tmux new-session -A -D -s main
```

`-A` attaches if `main` exists, creates it otherwise. `-D` detaches any other client so you do not get two terminals fighting over one window size.

#### Problem 2: the guard is too narrow

Your guard:

```sh
if command -v tmux &> /dev/null && [ -z "$TMUX" ] && [ -z "${DOTFILES_SKIP_TMUX:-}" ]; then
```

`$TMUX` correctly prevents nesting. `DOTFILES_SKIP_TMUX` is a good escape hatch. But IDE and editor terminals are **interactive**, so zsh sources `.zshrc` for them, and none of them set `$TMUX`.

The most complete guard I found in first-party source code is [prezto's tmux module](https://github.com/sorin-ionescu/prezto/blob/master/modules/tmux/init.zsh) (read from source, 2026-09-17):

```zsh
if [[ -z "$TMUX" && -z "$EMACS" && -z "$VIM" && -z "$INSIDE_EMACS" \
   && -z "$VSCODE_RESOLVING_ENVIRONMENT" \
   && "$TERM_PROGRAM" != "vscode" \
   && "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" ]] && ( \
  ( [[ -n "$SSH_TTY" ]] && zstyle -t ':prezto:module:tmux:auto-start' remote ) ||
  ( [[ -z "$SSH_TTY" ]] && zstyle -t ':prezto:module:tmux:auto-start' local ) \
); then
  ...
  exec tmux attach-session -d
fi
```

Note what prezto guards that you do not, and why each one matters to you specifically:

| Guard | Failure mode it prevents | Applies to you? |
|---|---|---|
| `$TERM_PROGRAM != vscode`, `$VSCODE_RESOLVING_ENVIRONMENT` | VS Code / Cursor integrated terminal swallowed by tmux; task output and terminal-splitting break | **Yes** if you use VS Code or Cursor |
| `$TERMINAL_EMULATOR != JetBrains-JediTerm` | Same, for IntelliJ/WebStorm | Yes if you use JetBrains |
| `$VIM`, `$INSIDE_EMACS` | A shell opened *inside* an editor spawns tmux | **Yes** — `:terminal` and your `:FloatermNew nnn` / `:FloatermNew lazygit` both set `$VIM`. If you launch nvim outside tmux, floaterm spawns a tmux session inside a floating window |
| SSH split (`$SSH_TTY`) | Local and remote treated as one decision; nested local→remote tmux with duplicated prefix keys | **Yes** if you SSH |
| `exec` | Quitting tmux drops you to a bare shell instead of closing the terminal | Yes — you do not use `exec` |

Prezto also warns, for macOS specifically: launching tmux "can cause the error `launch_msg(...): Socket is not connected`" and "tmux is known to cause **kernel panics** on macOS". *(That warning is old and I could not date it or confirm it against a current macOS — treat it as unverified. See Open Questions.)*

#### Suggested replacement

```sh
if command -v tmux >/dev/null 2>&1 \
  && [ -z "$TMUX" ] \
  && [ -z "${DOTFILES_SKIP_TMUX:-}" ] \
  && [ -z "$VIM" ] && [ -z "$NVIM" ] && [ -z "$INSIDE_EMACS" ] \
  && [ "$TERM_PROGRAM" != "vscode" ] \
  && [ "$TERMINAL_EMULATOR" != "JetBrains-JediTerm" ] \
  && [ -z "$VSCODE_RESOLVING_ENVIRONMENT" ] \
  && [ -z "$SSH_CONNECTION" ]; then
    exec tmux new-session -A -D -s main
fi
```

**Effort: 15 minutes.** Test by opening a VS Code terminal and by running `:FloatermNew` from an nvim started outside tmux.

**Startup cost — not a real concern for you.** The guard runs before your p10k instant-prompt block does any heavy lifting, and `command -v tmux` is a builtin. The common complaint about slow shell startup from tmux autostart comes from configs that shell out to `tmux list-sessions` before deciding; yours does not.

---

## 7. Consolidated recommendation table

| # | What to change | Effort | Payoff | Risk |
|---|---|---|---|---|
| 1 | **Fix nvim-treesitter** — follow the `main` branch README: `lazy = false`, `build = ':TSUpdate'`, install parsers, enable highlighting via `vim.treesitter.start()` in a `FileType` autocmd | 15 min | **Large** — you currently have no treesitter at all | Low; needs `tree-sitter-cli` ≥ 0.26.1 from a package manager |
| 2 | Delete the duplicate legacy `<TAB>`/`<CR>` coc mappings (lines 400, 415); resolve `undofile` vs `noundofile`; resolve `cursorline` | 10 min | Medium — removes "which line wins?" from future edits | None |
| 3 | `coc-python` → `coc-pyright`; `coc-vetur` → `coc-volar` | 20 min | Medium — one of these is archived since 2020 | Low |
| 4 | tmux `default-terminal` → `tmux-256color` | 5 min | Small but free — italics, correct modified keys | None (already installed here) |
| 5 | Rewrite the tmux autostart guard: `exec tmux new-session -A -D -s main` + IDE/editor/SSH guards | 15 min | Medium — stops session sprawl and IDE terminal breakage | Low |
| 6 | Fix tmux provenance: submodule+symlink oh-my-tmux, **or** replace with the ~60-line conf in §5.5 | 30 min | Medium — removes an unversioned 74KB blob from the repo | Low; `<prefix>r` reload lets you test live |
| 7 | `init.vim` → `init.lua` + `lua/config/` + `lua/plugins/` | 2–4 hrs | Medium — pays off if you edit this more than twice a year | Medium; do it after #1 |
| 8 | After #1 and #7: drop the legacy syntax plugins treesitter replaces (`vim-javascript`, `typescript-vim`, `vim-jsx-pretty`, `vim-jsx-typescript`, `vim-graphql`) | 30 min | Small — 5 fewer plugins | Low; revert individually if a filetype regresses |
| 9 | coc.nvim → native LSP | 4–8 hrs | **Preference only** | Medium |

---

## 8. Explicitly: leave these alone

An honest list is as valuable as a change list.

| Thing | Why it is fine |
|---|---|
| **coc.nvim** | 470 commits in the last year, 6 open issues, a commit dated today. Actively maintained by its original author. There is no rescue to perform. |
| **Truecolor in tmux** | `client_termfeatures` includes `RGB`. It works. Adding `terminal-overrides ",*:Tc"` would fix nothing. |
| **vim-tmux-navigator bindings** | Verified live in the root key table. The oh-my-tmux `C-l` clear-history binding is correctly shadowed. |
| **The tab-centric workflow** | Against Vim's design intent, but genuinely productive and widely used. Costs you a plugin override now and then. Not a bug. |
| **lazy.nvim** | v11.17.5, slower but stable and working. `vim.pack` is self-described as experimental. Revisit in 2027. |
| **`lazy-lock.json` committed to git** | Exactly right. Keep doing it. |
| **leader = `,`** | Muscle memory beats convention. |
| **`g:VM_leader = '\'` and the visual-multi maps** | Working, and unrelated to everything above. |
| **`vim-ai` on `gpt-4.1-mini`** | Outside this research's scope. Working. |
| **The `is_vim` regex drift** | Upstream's additions (`-wrapped`, leading `.`, `lvim`) do not apply on macOS/Homebrew. |
| **`.zshrc` module split, p10k instant prompt, secrets fallback** | Clean. The only issue in `.zshrc` is the tmux block. |
| **`xterm-keys on`, `status-utf8`, `utf8` in the vendored conf** | Dead or undocumented, but harmless — the `-q` flag suppresses the errors. They disappear if you do #6. |

---

## 9. Open questions

Things I could not settle from primary sources. Named rather than guessed.

1. **coc.nvim's long-term plan.** I found no maintainer statement about the project's direction, successor, or bus factor. The only reply in ["What's next for Coc.nvim?"](https://github.com/neoclide/coc.nvim/discussions/4593) from chemzqm is a one-liner dated 2023-09-01. **Activity is high but it rests on one person.** I cannot tell you what happens if he stops.

2. **Whether nvim-cmp has a stated maintenance policy.** I checked the README, issue #231 (the pinned breaking-changes issue, last updated 2023-05-25), and hrsh7th's own issue/PR history. There is no announcement of archival, hand-off, or deprecation. The README says only "This is my hobby project." The magazine.nvim fork story is documented and verifiable; a formal policy is not.

3. **Whether `nvim-cmp-kit` is intended to succeed nvim-cmp.** Its README describes it as "nvim's completion core module" and has "Rename repository" as an open TODO. 36 stars. I found no statement of intent either way.

4. **LazyVim's default completion engine.** Both `blink.cmp` and `nvim-cmp` live in `extras/coding/` and each disables the other; neither appears in the base `coding.lua`. The default is set somewhere I did not locate. kickstart.nvim's choice (blink.cmp) is unambiguous; LazyVim's is not.

5. **Whether prezto's macOS kernel-panic warning still applies.** The text is in current prezto source but I could not date it or find a corresponding tmux issue. Likely stale. Treat as unverified.

6. **Whether auto-starting tmux from a shell rc is a "known annoyance."** The tmux FAQ and man page say nothing about it — this is genuinely outside first-party coverage. My §6.2 analysis derives the failure modes from the tmux man page (`new-session` semantics) and from prezto's actual guard code, which is primary source for *what experienced authors guard against*, but not for *how often it bites people*. The prevalence claim is unsupported.

7. **Why your outer `TERM` is `screen-256color`.** oh-my-tmux's README requires `xterm-256color` outside tmux. Yours is `screen-256color`, which suggests nesting or an inherited environment. I could not determine the cause from the repo alone — worth checking interactively.

8. **Whether `coc-volar` (yaegassy) is still current for Vue 3.4+.** Last push 2025-03-02 — 18 months old. Vue's language-tools moved to v3.0 with the takeover-mode removal. I did not verify that `coc-volar` tracks that change.

9. **Whether tsgo/`tsc` is production-ready.** Both kickstart.nvim (`tsc`) and folke's config (`lang.typescript.tsgo`) have adopted the TypeScript-Go server. It is in `nvim-lspconfig`. I did not evaluate its maturity — flagging only that the community is moving there.

---

## 10. Sources

**Primary — local (this machine, 2026-09-17)**
- `tmux(1)` man page, tmux 3.6a — `default-terminal`, `terminal-features`, `terminal-overrides`, `mouse`, `mode-keys`, `prefix2`, `extended-keys`, `allow-passthrough`, `new-session -A`, `default-client-command`
- Neovim 0.12.2 runtime docs: `windows.txt` (`windows-intro`), `tabpage.txt` (`tab-page-intro`), `lsp.txt` (`lsp-quickstart`, `lsp-defaults`, `lsp-completion`), `news.txt`, `options.txt` (`'autocomplete'`), `insert.txt` (`ins-autocompletion`), `pack.txt` (`vim.pack`)
- `infocmp` terminfo comparison; `tmux display -p '#{client_termfeatures}'`; `tmux list-keys -T root`; `nvim --headless` runtime probes

**Primary — upstream repos and docs**
- [lazy.nvim — Structuring Your Plugins](https://lazy.folke.io/usage/structuring), [Lazy Loading](https://lazy.folke.io/spec/lazy_loading), [Usage](https://lazy.folke.io/usage)
- [Neovim v0.11.0 `runtime/doc/news.txt`](https://raw.githubusercontent.com/neovim/neovim/v0.11.0/runtime/doc/news.txt)
- [nvim-treesitter README (`main`)](https://github.com/nvim-treesitter/nvim-treesitter)
- [nvim-lspconfig `lsp/` configs](https://github.com/neovim/nvim-lspconfig/tree/master/lsp) — incl. `vue_ls.lua`, `volar.lua`, `dockerls.lua`, `docker_language_server.lua`
- [mason.nvim v2.0.0 release notes](https://github.com/mason-org/mason.nvim/releases)
- [nvim-cmp README](https://github.com/hrsh7th/nvim-cmp) · [blink.cmp README](https://github.com/Saghen/blink.cmp) · [magazine.nvim README](https://github.com/iguanacucumber/magazine.nvim) · [nvim-cmp-kit](https://github.com/hrsh7th/nvim-cmp-kit)
- [coc-python README](https://github.com/neoclide/coc-python) (deprecation warning)
- [oh-my-tmux README](https://github.com/gpakosz/.tmux)
- [tmux CHANGES](https://raw.githubusercontent.com/tmux/tmux/master/CHANGES) (`terminal-features`, tmux 3.2)
- [tmux FAQ](https://github.com/tmux/tmux/wiki/FAQ) (TERM inside tmux, RGB via `terminal-features`)
- [tpm README](https://github.com/tmux-plugins/tpm)
- [vim-tmux-navigator README](https://github.com/christoomey/vim-tmux-navigator)
- [prezto `modules/tmux/init.zsh`](https://github.com/sorin-ionescu/prezto/blob/master/modules/tmux/init.zsh) (autostart guards, read from source)
- GitHub REST API — repo metadata, commit history, release history, branch state, and directory listings for every repo named above (all fetched 2026-09-17)

**Reference configs**
- [nvim-lua/kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) · [LazyVim/starter](https://github.com/LazyVim/starter) · [LazyVim/LazyVim](https://github.com/LazyVim/LazyVim) · [folke/dot](https://github.com/folke/dot)

**Second-hand — used only as leads, not cited for any claim**
- A search result headlined "Nvim-Treesitter Archived: 13K-Star Plugin Shut Down (2026)" (byteiota) led me to check the repo. **The headline is wrong** — nvim-treesitter is not archived (`archived: false`, pushed 2026-09-12). What actually happened is a branch rewrite: `master` is locked, `main` is a full incompatible rewrite. Verified from the repo's own README and directory tree.
