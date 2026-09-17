# Dotfiles Polish — Design

**Status:** Approved (grilling session, 2026-09-17)
**Scope:** One plan's worth of work across six workstreams.

## Goal

Make the dotfiles repo easier to change, harder to break, and visually coherent — in the README, at the terminal, and across kitty, tmux, and Neovim.

**Success signals:**

| Signal | Measured by |
|---|---|
| Adding a managed config is a one-line change | ✅ **Done** — verified: one `links.conf` line propagates to install, uninstall, and doctor |
| A broken change is caught before it reaches a machine | CI fails on shellcheck error or a dry-run install failure |
| Every surface shares one palette | kitty, tmux, nvim, fzf, delta, bat all render Catppuccin Mocha |
| The repo folder is its own size | ✅ **Done** — 851 MB → **3.8 MB** locally, beating the ~30 MB target. Fresh clones stay at 97 MB until the backup tag is deleted. |

## Non-Goals

- Rewriting the Neovim config or changing the plugin set.
- Migrating from coc.nvim to native LSP.
- Supporting Linux. This is a macOS repo.
- Changing the symlink-farm architecture. It works; only its bookkeeping changes.
- Touching `~/.p10k.zsh`. It is user-generated and not tracked.

## Context

The repo is a symlink farm: configs live here, `install` links them into `$HOME`. A May 2026 audit fixed ten correctness bugs. What remains is bookkeeping, presentation, and one large fossil.

**Current state, verified 2026-09-17:**

| Fact | Detail |
|---|---|
| Repo total on disk | **851 MB** |
| `.git` | **101 MB** — the coc blobs are in history, not just the working tree |
| Tracked files | 28 |
| Symlink list duplicated in | `install`, `uninstall`, `doctor` — three hardcoded copies |
| `.config/coc/` in repo | 749 MB, last modified **Apr 2023**, nothing points at it |
| `~/.config/coc/` | 739 MB, real directory — the live one. Dir mtime May 2026; its `extensions/` updated **Jun 2026** |
| `.gitignore` | 200+ lines, ~90% inherited home-directory rules that cannot match |
| `.tmux.conf` | 74 KB vendored oh-my-tmux, no provenance recorded |
| CI | None. README badge claims "build passing" against a non-existent workflow |
| kitty font | Requests `Mononoki Nerd Font Mono` — **not installed anywhere**; Brewfile ships Hack only |
| Palettes in use | kitty = Tango `#2E3436`, tmux = Dracula `#282a36`, nvim = xcode_dark |

**Audience:** primary user is the owner, cloning onto new Macs. Secondary: team members who may read or fork it. This justifies real CI and honest badges, but not contributor governance docs.

## Decisions

| # | Decision | Rejected alternative | Why |
|---|---|---|---|
| D1 | Delete the repo's `.config/coc/` fossil, via `~/.Trash` not `rm -rf` | Leave it; move it to `~/.config` | It is an Apr-2023 orphan. The live coc data is a separate directory already in the right place. Trash keeps it recoverable. |
| D2 | Introduce `links.conf` as the single source of truth for symlinks | Keep three hardcoded lists; adopt YAML | Kills the drift bug. Plain text keeps the scripts dependency-free. |
| D3 | Unify on **Catppuccin Mocha** | Dracula; align by hand to xcode_dark | Only palette with maintained first-party ports for every surface here, so consistency survives without hand-syncing hex. |
| D4 | Point `kitty.conf` at **Hack Nerd Font Mono** | Add `font-mononoki-nerd-font` cask | Hack is already installed and already in the Brewfile. One less cask on a fresh machine. |
| D5 | CI runs shellcheck + `zsh -n` + `./install --dry-run` on a macOS runner | Lint only; no CI | The dry-run is what protects the property that matters: a fresh Mac clone works. |
| D6 | Keep oh-my-tmux vendored, add a provenance header | Git submodule; hand-written tmux.conf | A submodule adds a clone step and a failure mode for a file that changes yearly. Rewriting risks losing familiar behaviour. |
| D7 | Prune `.gitignore` to rules that can actually match | Leave as-is | This repo is not `$HOME`. Dead rules obscure the live ones. |
| ~~D8~~ | **RETRACTED 2026-09-17.** Track `Brewfile.lock.json` | — | Not implementable: Homebrew 7.0.3 removed `Brewfile.lock.json`; `brew bundle --help` no longer mentions it. No replacement lock mechanism exists. Machine drift stays an accepted limitation. |
| **D9** | **TAKEN 2026-09-17.** Rewrote git history with `git filter-repo`, force-pushed `master` and the working branch | Accept a ~102 MB repo | User authorised explicitly. Local repo: 102 MB → **3.8 MB** (`.git` 101 MB → 3.4 MB); 0 coc objects remain. `pre-filter-repo-backup` was pushed to origin *before* the rewrite as an escape hatch — **the remote therefore still serves ~97 MB until that tag is deleted.** |

## The Manifest

`links.conf` at the repo root. Whitespace-separated `source target` pairs; `#` starts a comment; blank lines ignored. Source is relative to the repo root, target relative to `$HOME`.

```
# source                target
.zshrc                  .zshrc
.vimrc                  .vimrc
.gitconfig              .gitconfig
.tmux.conf              .tmux.conf
.tmux.conf.local        .tmux.conf.local
.editorconfig           .editorconfig
.config/nvim            .config/nvim
.config/kitty           .config/kitty
.config/git             .config/git
```

All three scripts read it through one shared helper in `lib/links.sh`:

```bash
# Calls a callback once per manifest entry with (absolute_source, absolute_target).
for_each_link() {
  local callback="$1" src dst
  while read -r src dst _; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    "$callback" "${DOTFILES_DIR}/${src}" "${HOME}/${dst}"
  done < "${DOTFILES_DIR}/links.conf"
}
```

All three callbacks take the same two arguments, `(absolute_source, absolute_target)`:

| Callback | Script | Asserts / does |
|---|---|---|
| `link_file` | `install` | Existing behaviour, unchanged |
| `unlink_file` | `uninstall` | **Re-signatured** — takes two args now, removes `target` only if it is a symlink resolving into `$DOTFILES_DIR` |
| `check_link` | `doctor` | **New** — reports OK only if `target` is a symlink **and** `readlink` resolves to `source`. Today `doctor` only tests `-L` and never checks where the link points. |

`doctor` has no `DOTFILES_DIR` variable today and `for_each_link` needs one under `set -u`; WS1 adds it.

**Expected behaviour change:** `doctor` currently checks only four targets (`~/.zshrc`, and the three `.config` dirs). The manifest gives it all nine, so an incompletely-installed machine will show more notices than before. This is the bug being fixed, not a regression.

Adding a config becomes one line in `links.conf`.

**Behaviour that must not change:** backup-before-replace, dry-run, idempotent re-link, and the "source not found" warning. The refactor moves *where the list lives*, nothing else.

## Workstreams

Ordered by dependency. **WS1 → WS4 → WS5** is a hard chain. WS2 and WS3 are independent of that chain and of each other.

### WS0 — Cleanup (no dependencies)

1. Move `~/.dotfiles/.config/coc/` to `~/.Trash/coc-dotfiles-fossil-<timestamp>/`.
2. Prune `.gitignore` from 200+ lines to ~30: keep the `.config/*` allowlist, the secrets block, the AI-agent block, macOS junk, and nvim/vim state. Drop every inherited home-directory rule (`/.adobe`, `/.belastingdienst.nl`, `/.bi_li3`, `/.ackrc`, and the rest of that lineage).
3. ~~Brewfile lock~~ — **dropped, see D8.** Separately noted while checking: `brew bundle check` reports 12 formulae/casks as outdated, so a future `brew bundle install` on this machine is an *upgrade*, not a no-op. That is a user decision, not part of this plan.

### WS1 — Manifest refactor (core)

1. Add `links.conf` with the nine current entries.
2. Add `lib/links.sh` with `for_each_link`.
3. Rewrite the link sections of `install`, `uninstall`, `doctor` to use it.
4. Non-link steps stay where they are: `ensure_secrets_file`, `ensure_nvim_python_provider`, `ensure_oh_my_zsh`, `ensure_zsh_custom_repo`.

### WS2 — Theming

1. `zsh/theme.zsh` — new module exporting the Mocha palette once as `CTP_*` variables; sourced from `.zshrc` before `fzf.zsh`.
2. `.config/kitty/` — add the official Catppuccin Mocha kitty theme as `themes/mocha.conf`, `include` it from `kitty.conf`, and delete the hand-written Tango color block. Change `font_family` to `Hack Nerd Font Mono`.
3. `.tmux.conf.local` — replace the twelve `tmux_conf_theme_colour_*` Dracula values with Mocha equivalents.
4. `.config/nvim/init.vim` — add `catppuccin/nvim` to the lazy spec, set `colorscheme catppuccin-mocha`, set lualine `theme = 'catppuccin'`, update the `install.colorscheme` fallback list. Keep `xcode_dark.vim` in the repo as a fallback.
5. `zsh/fzf.zsh` — set `FZF_DEFAULT_OPTS` colors from the `CTP_*` variables.
6. `.gitconfig` — set delta `syntax-theme` to a Mocha-compatible theme.
7. `zsh/env.zsh` — export `BAT_THEME`.

> **Implementation note:** take the exact hex values and theme file contents from the official Catppuccin ports for each tool at implementation time. Do not transcribe them from memory.

### WS3 — CLI output polish

1. `doctor` — group results into sections with a boxed summary; add a **font check** verifying the family named in `kitty.conf` resolves on this machine, so D4's bug class cannot return silently.
2. `install` — add a final summary line: counts of linked, already-linked, skipped, backed-up.
3. Both — degrade to plain text when `NO_COLOR` is set or stdout is not a TTY.
4. **Fix SC2059** while rewriting the logging helpers. Every helper is `printf "${CL_BLUE}...%b..." "$1"` — variables in the format string, dozens of occurrences. Move the color codes into arguments: `printf '%b%s%b\n' "$CL_BLUE" "$msg" "$CL_RESET"`.
5. Add `# shellcheck shell=bash` to `lib/colors.sh` and `lib/links.sh` — they have no shebang, which is SC2148 at *error* severity.

### WS4 — README visuals (depends on WS1)

1. **Add a `make docs` target** (it does not exist today) and a `scripts/gen-readme-links` script. Replace the hand-maintained tree with a block generated from `links.conf`, delimited by `<!-- BEGIN LINKS -->` / `<!-- END LINKS -->`.
2. Add a Mermaid architecture diagram showing repo → installer → `$HOME` targets.
3. Add a terminal recording (asciinema or GIF) of `make install` running.
4. Fix the badges: the build badge points at the real workflow from WS5; drop or correct the `v1.0.0` release badge.
5. Document the vendored oh-my-tmux provenance (D6) — upstream URL and pinned version, as a header comment in `.tmux.conf` and a line in the README.

### WS5 — CI (depends on WS1)

`.github/workflows/ci.yml`, on push and pull request:

| Job | Runner | Steps |
|---|---|---|
| `lint` | `ubuntu-latest` | `shellcheck --severity=error install uninstall doctor cleanup-deps lib/*.sh`; `zsh -n zsh/*.zsh` |
| `smoke` | `macos-latest` | checkout, install Homebrew deps needed to pass the brew guard, `./install --dry-run` |
| `docs` | `ubuntu-latest` | `make docs` then `git diff --exit-code README.md` — fails if the generated block is stale |

**Severity floor:** start at `--severity=error`, which the scripts pass once WS3 step 5 adds the `shell=bash` directives. Do **not** start at the default `style` floor — that fails immediately on dozens of pre-existing SC2059 findings. Once WS3 step 4 lands, lower the floor to `warning` in a follow-up commit.

**Ordering:** the `docs` job calls `make docs`, which WS4 introduces. **WS4 must land before WS5**, or CI is red on arrival.

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Manifest refactor changes link behaviour subtly | Medium | Capture `make dry-run` output before and after; the diff must be empty except for ordering. This is the gate for WS1. |
| Deleting the coc fossil breaks Neovim | Low | Verified the live data is a separate directory, modified Jun 2026. Trash, not `rm -rf`. Recoverable. |
| Catppuccin nvim port conflicts with coc highlight overrides | Medium | `init.vim` sets `CocSearch`/`CocMenuSel` colors by hand. Re-check these after the colorscheme change and move them to Mocha values. |
| `install --dry-run` fails on a clean CI runner for environment reasons, not real ones | Medium | The script already guards on `brew`. If CI proves noisy, narrow the smoke job to parse-and-resolve rather than full dry-run. |
| Pruning `.gitignore` un-ignores something that should stay ignored | Low | Run `git status` after the prune; nothing new should appear as untracked. |
| `doctor` reports more notices after WS1 than before, looking like a regression | High (expected) | Documented above as intended. Validation #2 measures notices *after* `./install` has run, not before. |
| CI lint job fails on first run from pre-existing findings | High without mitigation | `--severity=error` floor plus the WS3 step 5 directives. Raise the floor only after WS3 step 4. |

## Validation

| # | Check | Gates |
|---|---|---|
| 1 | `./install --dry-run` output identical before and after, **on an already-installed machine** (where no backup line with a timestamp is printed) | WS1 |
| 2 | `./uninstall --dry-run` output identical before and after | WS1 |
| 3 | `./doctor` output compared before and after; the only diff is the five additional link checks the manifest adds | WS1 |
| 4 | `make doctor` reports zero missing required tools and zero notices — measured *after* `./install` has run | WS1, WS2 |
| 5 | ✅ `du -sh ~/.dotfiles` = **3.8 MB**. Fresh-clone size is **97 MB** until `pre-filter-repo-backup` is deleted from origin | WS0, D9 |
| 6 | Fresh-clone rehearsal: clone to a temp directory, `./install --dry-run`, every target resolves | WS1 |
| 7 | Visual check: kitty, tmux, and nvim all render one palette; icons render in Hack Nerd Font | WS2 |
| 8 | CI green on push | WS5 |

## Rollback

Everything lands in git on a branch, so `git revert` covers all code changes. The coc fossil sits in `~/.Trash` for the system retention window. `install` continues to back up any replaced file to `~/.dotfiles-backup/<timestamp>`.

## Next Action

Implement WS0 and WS1 first, gated on the dry-run diff being empty. Then WS2, WS3 in either order, then WS4 and WS5.
