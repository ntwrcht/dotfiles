# Claude Code + Neovim + tmux + kitty — what people actually do, and what this repo should adopt

**Research date:** 2026-09-17
**Method:** primary sources only — Anthropic's own docs at `code.claude.com/docs`, the `claude --help` output of the installed binary, plugin and tmux **source code**, the `tmux(1)` man page and Neovim `:help` files installed on this machine, and the GitHub REST API for maintenance data. Several claims are backed by **experiments run on this machine today**; each is marked *(tested)*. Third-party write-ups are used only as leads and are flagged where they appear.

**Environment verified on this machine (2026-09-17):**

| Component | Version | How verified |
|---|---|---|
| Claude Code CLI | 2.1.274 | `~/.local/bin/claude --version` |
| Neovim | 0.12.2 | `nvim --version` |
| tmux | 3.6a | `tmux -V` |
| kitty | 0.46.2 | `kitty --version` (current upstream: 0.48.2) |
| Client `TERM` | `xterm-kitty` | `tmux display -p '#{client_termname}'` |
| Client term features | `bpaste,ccolour,clipboard,cstyle,focus,RGB,title` | `tmux display -p '#{client_termfeatures}'` |
| `allow-passthrough` | **off** | `tmux show -gv allow-passthrough` |
| `extended-keys` | **off** | `tmux show -sv extended-keys` |
| `focus-events` | on | `tmux show -sv focus-events` |

---

## 1. Bottom line

**Your popup is a better design than you knew, your file-reload recipe is correct, and no Neovim plugin is worth installing today. The real gap is three missing lines of tmux config that Anthropic documents and you do not have.**

Three things surprised me and contradict the framing of the brief:

1. **Opening and closing a tmux popup *does* fire `FocusLost` / `FocusGained` in the neighbouring nvim pane** *(tested)*. Your `FocusGained → checktime` recipe therefore fires exactly when you come back from Claude. This is the case I expected to be the hole, and it is not.
2. **A tmux popup swallows the prefix key entirely.** While Claude runs in the popup, *every* key goes to Claude — including `C-b`, `C-j`, `C-k`, `C-l`. That is a **feature** here: those keys are stolen by your `vim-tmux-navigator` root bindings in a normal pane, which breaks Claude Code's documented `Ctrl+J` newline and `Ctrl+K` delete-to-end-of-line. The popup is immune.
3. **Claude Code now ships first-party parallelism**: `claude --worktree`, `claude --bg`, `claude attach`, `claude agents`, backed by a supervisor daemon. Every third-party "run N agents across tmux windows and worktrees" tool I found is now solving a solved problem.

| Rank | Finding | What to change | Effort | Payoff |
|---|---|---|---|---|
| 1 | tmux is missing the three lines Anthropic documents: notifications, progress bar and Shift+Enter are all swallowed | Add 3 lines to `.tmux.conf` | 2 min | **High** |
| 2 | Popup dismissal kills the session; the prefix key is unreachable while it is open | Know `claude --continue`; optionally wrap in `new-session -A` | 0–10 min | **High (knowledge)** |
| 3 | `C-h/j/k/l` root bindings break Claude Code keys in a *pane* (not in the popup) | Keep using the popup, or guard the bindings | 0–10 min | **Medium** |
| 4 | `claude --worktree` / `--bg` / `agents` replace all third-party orchestration | Learn the flags | 15 min | **Medium** |
| 5 | Your `autoread`/`checktime` recipe is right; `set autoread` is a no-op in Neovim | Optionally add 3 autocmd events | 2 min | **Low** |
| 6 | Neither Neovim Claude plugin is healthily maintained | **Change nothing** | 0 | — |
| 7 | kitty needs `macos_option_as_alt` and nothing else | Add 1 line | 1 min | **Low** |
| 8 | `exec tmux new-session -A -D` steals the session from a second kitty window | Drop `-D`, or use tmux windows | 5 min | **Low** |
| 9 | vim-ai (`gpt-4.1-mini`) duplicates Claude Code | Optional removal | 10 min | **Low** |

---

## 2. Q1 — Neovim plugins for Claude Code

### 2.1 Is the official IDE integration reachable from Neovim? Yes — and the mechanism is first-party documented

Anthropic documents the transport in the VS Code page, not as a Neovim feature, but the description is complete enough to reimplement:

> "The server binds to `127.0.0.1` on a random port in the range 10000–65535… The transport is unencrypted `ws://`… Each extension activation generates a fresh random auth token, writes it to a lock file at `~/.claude/ide/<port>.lock`, and the CLI must present it as the `X-Claude-Code-Ide-Authorization` header to connect. The lock file has `0600` permissions in a `0700` directory… If `CLAUDE_CONFIG_DIR` is set, the lock file is written to `$CLAUDE_CONFIG_DIR/ide/` instead."
> — [Use Claude Code in VS Code](https://code.claude.com/docs/en/ide-integrations), fetched 2026-09-17

What the connection buys, per the same page:

| Capability | Mechanism |
|---|---|
| Diff viewing | Internal RPC over the websocket; the CLI drives the editor's diff UI |
| Selection + open-file context | "While connected, the CLI includes your current editor selection and the path of the active file as context on each prompt you send." |
| Diagnostics | `mcp__ide__getDiagnostics` — the only read-only tool exposed to the model |
| Jupyter execution | `mcp__ide__executeCode` — irrelevant here |

Two first-party entry points exist in the CLI you have installed:

- `--ide` — "Automatically connect to IDE on startup if exactly one valid IDE is available" (`claude --help`, v2.1.274; also in the [CLI reference](https://code.claude.com/docs/en/cli-reference)).
- `/ide` — "If using an external terminal, run `/ide` inside Claude Code to connect it to VS Code." ([IDE integrations](https://code.claude.com/docs/en/ide-integrations)). The same command is what a Neovim-hosted lock file would be discovered through, since the CLI's discovery is lock-file based and editor-agnostic.

Anthropic ships no Neovim extension. Nothing on `code.claude.com/docs` mentions Neovim.

### 2.2 The plugins, measured

Data from the GitHub REST API, 2026-09-17.

| Plugin | Stars | Last commit (default branch) | Latest release | Open issues / PRs | What it actually does |
|---|---|---|---|---|---|
| [`coder/claudecode.nvim`](https://github.com/coder/claudecode.nvim) | 3,068 | **2026-06-25** | v0.3.0 (2025-09-16) | 94 / 40 | Full websocket-MCP server in pure Lua: lock file, auth token, selection tracking, native diff UI, `@`-mentions, terminal management |
| [`greggh/claude-code.nvim`](https://github.com/greggh/claude-code.nvim) | 2,098 | **2026-02-04** | v0.4.3 (2025-03-21) | 77 | Terminal wrapper only. Toggles a `:terminal` running `claude`, plus file-reload autocmds. No websocket, no diffs, no selection |
| [`carlos-algms/agentic.nvim`](https://github.com/carlos-algms/agentic.nvim) | 622 | 2026-08-23 | — | 16 | Chat UI over **ACP**, not Claude Code's own protocol. Needs a separate `@agentclientprotocol/claude-agent-acp` adapter binary |
| [`samir-roy/code-bridge.nvim`](https://github.com/samir-roy/code-bridge.nvim) | 67 | 2026-06-23 | — | 0 | Sends context to an existing Claude session; no IDE protocol |
| [`ldelossa/pi-ide.nvim`](https://github.com/ldelossa/pi-ide.nvim) | 11 | 2026-08-10 | — | 1 | Implements the same extension protocol; too small to depend on |
| [`HelpFreedom/claude-ide.nvim`](https://github.com/HelpFreedom/claude-ide.nvim) | 15 | 2026-07-18 (single day of commits) | — | 0 | Abandoned at birth |

**Maintenance verdict, stated plainly:**

- `greggh/claude-code.nvim` is **effectively unmaintained**. Two commits in 2026, both in February. Since then the issue tracker is weekly dependency bot noise plus unanswered bug reports. Its last release is 18 months old.
- `coder/claudecode.nvim` is **stalling**. Commit history on `main`: 4 in January, 1 in March, 2 in April, 38 in June, **nothing since 2026-06-25**. 40 open PRs, including community fixes for paths with spaces and peer-reset handling. Issue [#319](https://github.com/coder/claudecode.nvim/issues/319), opened 2026-09-09, is titled *"Is this plugin abondonned?"* and has **zero comments**. The `pushed_at` timestamp of 2026-09-13 is a Dependabot branch, not `main` — worth knowing, because a star-count-and-recent-push glance reads as healthy when it is not.

### 2.3 The one configuration that would fit this repo — if you want it at all

`coder/claudecode.nvim` reads its README as "we manage your terminal too", which conflicts with your popup. It does not have to. From `lua/claudecode/terminal.lua` and `lua/claudecode/terminal/none.lua` on `main`:

| `terminal.provider` | Behaviour |
|---|---|
| `"auto"` (default) | snacks.nvim if present, else the native `:terminal` |
| `"native"` | Neovim's built-in terminal — **snacks.nvim is not a hard dependency** |
| `"external"` | Runs a command you supply; takes a `function(cmd, env)` |
| `"none"` | *"Performs zero UI actions and never manages terminals inside Neovim."* |

With `provider = "none"` the plugin becomes **only the IDE server**: it writes `~/.claude/ide/<port>.lock`, tracks your selection, and renders diffs. You keep `<prefix>a` and `<leader>k` exactly as they are, and connect with `/ide` from inside the popup.

**My recommendation: do not install it yet.** The value it adds over a plain terminal is diff review and selection context. You already review diffs inside Claude Code's own TUI, and you can `@`-mention files. Against that: a stalled upstream, 94 open issues, a websocket server running inside your editor, and a lock file with an auth token in your home directory. Revisit if `main` moves again, or if selection-to-context becomes something you reach for daily.

---

## 3. Q2 — The file-reload problem

### 3.1 Your recipe is right. One line of it is a no-op.

```vim
set autoread
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI * silent! checktime
autocmd FileChangedShellPost * echohl WarningMsg | echo "…" | echohl None
```

**`set autoread` does nothing in Neovim — it is already on.**

> `'autoread'` `'ar'` boolean (default on)
> — `:help 'autoread'`, `options.txt:809`, Neovim 0.12.2

> - `'autoread'` is enabled (works in all UIs, including terminal)
> — `:help nvim-defaults`, `vim_diff.txt:41`

Harmless, and arguably good documentation-in-place. Not a bug.

The rest is the community standard. `greggh/claude-code.nvim`'s `file_refresh.lua` — the only plugin that treats this as its headline feature — does the same thing with a wider event list and a libuv timer:

```lua
vim.api.nvim_create_autocmd({
  'CursorHold', 'CursorHoldI', 'FocusGained', 'BufEnter',
  'InsertLeave', 'TextChanged', 'TermLeave', 'TermEnter', 'BufWinEnter',
}, { pattern = '*', callback = function() … vim.cmd 'checktime' end })
```

plus a `vim.loop.new_timer()` that fires `silent! checktime` on an interval **only while its Claude terminal buffer is visible**. That gating matters: an unconditional polling timer is what everyone regrets.

### 3.2 Can your recipe miss changes? Concretely:

| Situation | Does `checktime` fire? | Why |
|---|---|---|
| Claude runs in the **tmux popup**; you close it and return to nvim | **Yes** *(tested)* | Opening a popup sends `FocusLost` to the nvim pane and closing it sends `FocusGained`. Verified on tmux 3.6a with a logging autocmd |
| Claude runs in a **side-by-side tmux pane**; you switch panes | **Yes** *(tested)* | Pane selection fires `FocusLost`/`FocusGained` |
| Claude runs in a side-by-side pane; **you never leave the nvim pane** and sit still | **No** | `CursorHold` fires **once** per idle period and does not repeat until you press a key *(observed: one `CursorHold` in a 5 s idle window at `updatetime=200`)*. This is the one real hole |
| Claude runs in your **floaterm**, you close it | **Yes** | `BufEnter` on the file buffer |
| Claude runs in your floaterm and you are **typing in terminal mode** | **No** | `CursorHold` is Normal-mode only and `CursorHoldI` is Insert-mode only (`:help CursorHold`). Neither fires in Terminal mode. `TermLeave` would cover it |
| Buffer has **unsaved local edits** and the file also changed | Reload is refused, by design | *"When a file has been detected to have been changed outside of Vim **and it has not been changed inside of Vim**, automatically read it again"* — `:help 'autoread'` |
| You `:w` over Claude's change | You get a prompt, not silent loss | `WARNING: The file has been changed since reading it!!!  Do you really want to write to it (y/n)?` — `editing.txt:1584`; `W12` for the both-changed case — `message.txt:637` |

The only gap worth closing costs one keypress: any cursor movement re-arms `CursorHold`, which then fires 200 ms later. The practical exposure is "you returned to nvim, pressed nothing, and immediately typed `:w`" — and even that is caught by the `W12` prompt.

### 3.3 Is `FocusGained` reliable inside tmux? Yes, with your settings

`focus-events on` is set (`tmux show -sv focus-events` → `on`), and the client advertises the `focus` feature (`client_termfeatures` contains `focus`). tmux's own docs:

> `focus-events [on | off]` — When enabled, focus events are requested from the terminal if supported and passed through to applications running in tmux. **Attached clients should be detached and attached again after changing this option.**
> — `tmux(1)`, 3.6a

The detach-and-reattach caveat is the usual reason people think focus events are unreliable: they set the option in a running server and never reattach.

### 3.4 Should you use `vim.uv` filesystem watchers instead? No.

Two reasons, one of them measured here:

**Claude Code's `Edit` tool replaces the file rather than writing in place** *(tested)*. A file at inode `162260291` became inode `162260325` after a single `Edit` call by Claude Code 2.1.274. A `vim.uv.new_fs_event` watch on a *file path* is therefore the fragile design — you would have to watch the containing directory and filter, for every directory holding an open buffer. `luvref.txt` notes the same split: `uv_fs_event_t` uses OS notifications, `uv_fs_poll_t` uses `stat` — and `checktime` already *is* the `stat` approach, driven by events you actually care about.

No maintained Neovim plugin uses watchers for this. Every one I read uses `checktime`.

**A related finding for this repo specifically:** Claude Code 2.1.274 **refuses to write through a symlink** *(tested)* —

```
Refusing to write …/link.txt: it is a symbolic link. Write to the link's target path instead.
```

Your `links.conf`-driven symlinks from `$HOME` into `~/.dotfiles` are safe. Claude will edit the repo file, not replace your symlink with a regular file.

### 3.5 If you want the belt-and-braces version

```vim
autocmd FocusGained,BufEnter,CursorHold,CursorHoldI,TermLeave,InsertLeave,BufWinEnter * silent! checktime
```

`TermLeave` covers the floaterm case; `InsertLeave` and `BufWinEnter` are what greggh's plugin adds. **Effort: editing one line. Payoff: low.** Skip the polling timer.

---

## 4. Q3 — tmux patterns

### 4.1 The popup question, answered by experiment

**Does the agent session survive dismissing the popup? No. The process is killed.** *(tested)*

| Experiment (tmux 3.6a, isolated server) | Result |
|---|---|
| `display-popup -E` running `sh -c 'sleep 600'`; then `display-popup -C` | Child process **gone** |
| Same, but dismissed by detaching the client | Child process **gone** |
| Popup running `tmux new-session -A -s scratch '…'`; then `display-popup -C` | Session `scratch` **survives, detached**; the inner process keeps running |

The source explains the third row: the popup owns a `job`, and killing the popup kills that job. If the job is merely a *client attached to a separate session*, only the client dies.

**But there is a second half to this that changes the risk profile.** From `popup.c` in tmux 3.6a:

```c
if ((((pd->flags & (POPUP_CLOSEEXIT|POPUP_CLOSEEXITZERO)) == 0) ||
    pd->job == NULL) &&
    (event->key == '\033' || event->key == ('c'|KEYC_CTRL)))
        return (1);   /* close the popup */
```

With `-E` set (`POPUP_CLOSEEXIT`) **and** a job running, this branch is skipped — so **Escape and `Ctrl+C` are passed to Claude Code, not treated as "dismiss"**. Your binding uses `-E`. There is no accidental-Escape data-loss path.

And from `server-client.c`, `server_client_handle_key()` consults `c->overlay_key` **before** the key is ever queued for prefix/table lookup:

```c
if (c->overlay_key != NULL) {
        switch (c->overlay_key(c, c->overlay_data, event)) {
        case 0: return (0);
```

So while the popup is open, **the tmux prefix is unreachable**. You cannot detach, switch windows, or enter copy-mode without exiting Claude first. The realistic loss path is not Escape — it is closing the kitty window or detaching, which kills the client and takes the popup job with it *(tested)*.

**Mitigation that costs nothing:** Claude Code writes the transcript to disk continuously ("Claude Code saves every conversation locally" — [Common workflows](https://code.claude.com/docs/en/common-workflows)). `claude --continue` in the same directory resumes the conversation. What you lose is in-flight tool work, not the conversation.

### 4.2 Dedicated pane vs popup vs window vs session

| Shape | State on dismissal | Prefix reachable | Claude's `Ctrl+J`/`Ctrl+K` | Verdict for you |
|---|---|---|---|---|
| **`display-popup -E claude`** (yours) | **Lost** | **No** | **Works** (all keys reach the job) | Right default. Fast, scoped to `#{pane_current_path}`, no window clutter |
| Popup wrapping `new-session -A -s claude-…` | **Survives** | No | Works | The upgrade, if you want to walk away mid-task |
| Dedicated split pane | Survives | Yes | **Broken** by your `bind -n C-h/j/k/l` | Avoid, unless you guard the bindings |
| Dedicated window | Survives | Yes | Broken, same reason | Same |
| `claude --bg` + `claude agents` | Survives a reboot of the terminal entirely | n/a | n/a | The first-party answer (§6.4) |

If you want the survivable popup, this is the one-line change, and it keeps everything else you designed:

```tmux
bind a display-popup -E -w 85% -h 85% -d "#{pane_current_path}" \
  "zsh -c 'source $HOME/.dotfiles/zsh/path.zsh 2>/dev/null; exec tmux new-session -A -s claude-#{b:pane_current_path} -c \"#{pane_current_path}\" claude'"
```

**Effort: 10 minutes including testing. Payoff: medium.** The cost is one extra tmux session per project directory, which `list-sessions` will show. Judge whether that trade is worth it against `claude --continue`, which is free.

### 4.3 What published tooling actually does

These are leads I followed to source, not claims from write-ups.

| Project | Stars | Pattern, read from its source |
|---|---|---|
| [`smtg-ai/claude-squad`](https://github.com/smtg-ai/claude-squad) | 8,488 | `session/tmux/tmux.go`: `tmux new-session -d -s <name> -c <workDir> <program>`, then `tmux attach-session -t <name>` from a PTY. **Exactly the detached-session-plus-attach pattern verified above.** One git worktree per task |
| [`nielsgroen/claude-tmux`](https://github.com/nielsgroen/claude-tmux) | 206 | A Rust TUI installed as `bind-key C-c display-popup -E -w 80 -h 30 "~/.cargo/bin/claude-tmux"`. Lists sessions with per-session Claude status (working / idle / awaiting `[y/n]`). **It confirms your popup binding is the idiom** — it just puts a session picker in the popup instead of Claude itself |

Dozens of similar projects exist (`grove`, `switchyard`, `orchardist`, `wts`, …), nearly all under 50 stars and under a year old. They converge on the same two primitives: **a git worktree per task, and a detached tmux session per worktree**. Claude Code now does both natively, which is why I would not install any of them.

---

## 5. Q4 — kitty

**The honest answer is "almost nothing" — but not quite nothing.**

| Option | Current value | Recommendation |
|---|---|---|
| `macos_option_as_alt` | `no` (kitty default) | **Set to `yes`.** This is the one real gap |
| `allow_remote_control` | `no` (default) | **Leave it.** "other programs can control all aspects of kitty, including sending text to kitty windows… Note that this even works over SSH connections" — kitty docs. No Claude Code feature needs it |
| `listen_on` | `none` (default) | **Leave it.** Only meaningful with remote control on |
| `scrollback_pager` | `less --chop-long-lines --RAW-CONTROL-CHARS +INPUT_LINE_NUMBER` (default) | **Leave it.** You are inside tmux; tmux's copy-mode owns scrollback, and kitty's pager never sees it |
| `notify_on_cmd_finish` | `never` (default) | **Leave it.** Needs kitty shell integration, which tmux breaks, and Claude Code has its own notification channel (§6.2) |

### Why `macos_option_as_alt` is the exception

> "Some Claude Code shortcuts use the Option key, such as Option+Enter for a newline or Option+P to switch models. On macOS, most terminals do not send Option as a modifier by default, so these shortcuts do nothing until you enable it… For Ghostty, Kitty, and other terminals, look for an Option-as-Alt or Option-as-Meta setting in the terminal's configuration file."
> — [Configure your terminal](https://code.claude.com/docs/en/terminal-config)

kitty's own docs:

> `macos_option_as_alt no` — Use the Option key as an Alt key on macOS. With this set to `no`, kitty will use the macOS native Option + Key to enter Unicode character behavior. This will break any Alt + Key keyboard shortcuts in your terminal programs… You can use the values: `left`, `right` or `both`.

Shortcuts this unlocks in Claude Code, per [Interactive mode](https://code.claude.com/docs/en/interactive-mode): `Option+Enter` (newline), `Option+P` (model), `Alt+B` / `Alt+F` / `Alt+D` (word motions), `Alt+Y` (paste history). `Option+T` (thinking) and `Option+O` (fast mode) are documented to work without it.

```conf
# ─── macOS ───────────────────────────────────────────────────────────────────
# Send Option as Alt/Meta so Alt-key shortcuts reach programs in the terminal
# (Claude Code's Option+Enter, Option+P, Alt+B/F/D). Costs the macOS Unicode
# input behaviour, which nothing here uses.
macos_option_as_alt yes
```

**Effort: 1 minute. Payoff: low, but real.** Note the trade-off honestly: you lose macOS's Option-as-Unicode-composition input.

One thing kitty already gives you for free, which is why §6.1 matters: **Claude Code sends desktop notifications natively in kitty.** "By default Claude Code sends a desktop notification only in Ghostty, Kitty, and iTerm2… Ghostty and Kitty forward it to your OS notification center without further setup." Your tmux config is currently blocking it.

---

## 6. Q5 — Claude Code's terminal-side features, and what your config breaks

### 6.1 ⚠️ The three tmux lines you are missing — the highest-value finding in this document

Anthropic documents this verbatim:

> When Claude Code runs inside tmux, by default Shift+Enter submits instead of inserting a newline, and desktop notifications and the progress bar never reach the outer terminal. Add these lines to `~/.tmux.conf`…
> ```bash
> set -g allow-passthrough on
> set -s extended-keys on
> set -as terminal-features 'xterm*:extkeys'
> ```
> — [Configure your terminal § Configure tmux](https://code.claude.com/docs/en/terminal-config)

**Your config has none of them**, confirmed live: `allow-passthrough = off`, `extended-keys = off`, and `client_termfeatures` lacks `extkeys`.

Why the third line is genuinely required and not boilerplate: tmux 3.6a's `tty_default_features()` table in `tty-features.c` auto-detects features for **mintty, tmux, rxvt-unicode, iTerm2, foot and XTerm only**. kitty is not in that table, so tmux never learns that kitty supports extended keys. The `xterm*` glob matches your client `TERM` of `xterm-kitty`, so the line lands correctly.

Consequences today:
- Shift+Enter submits instead of inserting a newline, even though kitty supports it natively.
- Claude Code's desktop notification — free in kitty — is swallowed by tmux.
- The progress bar never reaches kitty.

```tmux
# ─── Claude Code ─────────────────────────────────────────────────────────────
# Documented at https://code.claude.com/docs/en/terminal-config#configure-tmux
# allow-passthrough: lets Claude Code's desktop notification and progress bar
#   escape sequences reach kitty instead of being swallowed by tmux. Use `all`
#   instead of `on` if you want notifications from a pane that is not visible.
# extended-keys + extkeys: lets tmux distinguish Shift+Enter from Enter. tmux
#   3.6a does not auto-detect kitty (see tty-features.c), so state it.
set -g  allow-passthrough on
set -s  extended-keys on
set -as terminal-features 'xterm*:extkeys'
```

**One judgement call to make:** `tmux(1)` says `allow-passthrough on` permits passthrough "only if the pane is visible"; `all` permits it "even if the pane is invisible". The notification is most useful precisely when you are not looking at that pane. Use `all` if you want notifications from a background window, and accept that any program in any pane can then write raw escape sequences to kitty.

**Effort: 2 minutes. Payoff: high.**

### 6.2 Notifications, and what you already have

With passthrough on, kitty gets OS notifications with no further config. If you want a sound as well, the documented hook goes in `~/.claude/settings.json`:

```json
{ "hooks": { "Notification": [ { "hooks": [
  { "type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff" } ] } ] } }
```

`preferredNotifChannel: "terminal_bell"` is the fallback for terminals without native support. You do not need it — and note your `.tmux.conf` does not set `visual-bell`/`bell-action`, so a bell would be silent anyway.

### 6.3 ⚠️ `Ctrl+J`, `Ctrl+K` and `Ctrl+L` — broken in a pane, fine in your popup

Claude Code's documented keys ([Interactive mode](https://code.claude.com/docs/en/interactive-mode)):

| Key | Claude Code action | Your tmux root binding |
|---|---|---|
| `Ctrl+J` | **Newline — "works in any terminal without configuration"** | `bind -n C-j` → `select-pane -D` |
| `Ctrl+K` | Delete to end of line | `bind -n C-k` → `select-pane -U` |
| `Ctrl+L` | (readline clear) | `bind -n C-l` → `select-pane -R` |
| `Ctrl+H` | — | `bind -n C-h` → `select-pane -L` |
| `Ctrl+B` | **Background running tasks** | tmux prefix |

Your `is_vim` guard matches `(view|l?n?vim?x?|fzf)`; `claude` does not match, so in a **pane** running Claude Code these four keys move the pane instead of reaching Claude. In the **popup** all keys go to the job (§4.1), so they all work.

`Ctrl+B` is the one case Anthropic already handles: *"Backgrounds Bash commands and agents. **Tmux users press twice.**"* Your config keeps tmux's default `bind C-b send-prefix`, so `C-b C-b` sends a literal `Ctrl+B` and works.

**Recommendation: no change, and keep using the popup.** If you ever want Claude in a pane, extend the `is_vim` pattern rather than dropping the bindings:

```tmux
vim_pattern='(\S+/)?g?\.?(view|l?n?vim?x?|fzf|claude)(diff)?(-wrapped)?'
```

That is a hack — it makes `C-j` *navigate panes* only when Claude is not focused, which is backwards from what you want. The honest framing: **the popup is the reason you have not hit this, and it is a good enough reason to keep it.**

### 6.4 First-party parallelism you may not know about

All from `claude --help` (v2.1.274) and [Worktrees](https://code.claude.com/docs/en/worktrees) / [Background agents](https://code.claude.com/docs/en/agent-view):

| Feature | Command | Notes |
|---|---|---|
| Worktree per session | `claude --worktree <name>` / `-w` | Creates `.claude/worktrees/<name>/` on branch `worktree-<name>`, branched from the repo's default branch. Prompts to keep or remove on exit |
| Worktree from a PR | `claude --worktree "#1234"` | Quote it so zsh does not eat the `#` |
| Carry gitignored files in | `.worktreeinclude` at the repo root | `.gitignore` syntax; only gitignored files are copied |
| Background session | `claude --bg "…"` | A supervisor daemon keeps it running after you close the terminal |
| Attach / list / stop | `claude attach <id>`, `claude agents`, `claude logs <id>`, `claude stop <id>` | Sessions live under `~/.claude/jobs/<id>/` |
| Background from a session | `Ctrl+B` on an empty prompt, or `/bg` | `Ctrl+B` twice inside tmux |
| Prompt in your editor | `Ctrl+G` or `Ctrl+X Ctrl+E` | Opens `$VISUAL`/`$EDITOR` — nvim, for you |

**`claude --worktree` plus `claude agents` replaces every third-party orchestrator in §4.3.** If you add `.claude/worktrees/` to `.gitignore`, you are done.

There is also an **undocumented** `--tmux` flag in your installed binary:

> `--tmux` — Create a tmux session for the worktree (requires `--worktree`). Uses iTerm2 native panes when available; use `--tmux=classic` for traditional tmux.

It appears in `claude --help` for 2.1.274 but **not** on the published CLI reference or worktrees pages. Treat it as unsupported surface area (see Open Questions).

### 6.5 Do not run `/terminal-setup`

> Run `/terminal-setup` directly in the host terminal rather than inside tmux or screen, since it needs to write to the host terminal's configuration.

And per the same page's table, kitty gets Shift+Enter **"without setup"**. `/terminal-setup` targets VS Code, Cursor, Devin Desktop, Alacritty < 0.16 and Zed. On macOS it also toggles Apple Terminal and iTerm2 profile settings — neither applies. **Nothing to do.**

### 6.6 ⚠️ `exec tmux new-session -A -D -s main` blocks the documented parallel workflow

Anthropic's worktree advice is *"Run the same command with a different name in a second terminal."* With your autostart you cannot: `tmux(1)` says that with `-A`, **"-D behaves like -d to attach-session"** — which detaches every other client. A second kitty window therefore **steals the session from the first**.

Two ways out:

| Option | Change | Trade-off |
|---|---|---|
| Use tmux windows, not kitty windows | None | Free. Just know that a second kitty window is not the move |
| Drop `-D` | `exec tmux new-session -A -s main` | Two kitty windows share one session and mirror each other's view — usually worse, and `-D` was presumably chosen deliberately |

**Recommendation: no code change. Know the constraint, and open parallel worktree sessions as tmux windows.**

### 6.7 Smaller notes

- **Flicker:** `client_termfeatures` lacks `sync`, so tmux does not know kitty supports synchronized output (kitty's changelog documents its synchronized-updates implementation). If the Claude Code TUI ever flickers, `CLAUDE_CODE_FORCE_SYNC_OUTPUT=1` is the documented fix, and `/tui fullscreen` is the heavier one. Not worth pre-emptive config.
- **Theme:** `/theme` has a documented custom-theme format (`~/.claude/themes/<slug>.json` with `base` and `overrides`). A Catppuccin Mocha theme would complete the "one palette across kitty, tmux, nvim, fzf, delta and bat" line in your configs. Cosmetic; entirely optional.
- **Vim mode:** `editorMode: "vim"` in `~/.claude/settings.json` gives the prompt vim motions. `Enter` still submits in INSERT mode.

---

## 7. vim-ai — the redundancy you suspected

| Fact | Source |
|---|---|
| `madox2/vim-ai`, 1,188 stars, last commit **2026-03-11**, 2 open issues | GitHub API, 2026-09-17 |
| Configured model: `gpt-4.1-mini` | `init.vim` |
| `<leader>c` = `:AIChat`, `<leader>re` = `:AIRedo`, `<leader>cm` = `GitCommitMessage` | `init.vim` |

The plugin is quiet but not dead, and it is not broken. The overlap is real: `GitCommitMessage` runs `git diff HEAD` through an OpenAI call to write a conventional commit message — which is a single sentence to Claude Code in the popup you already have bound. Keeping it also keeps `OPENAI_API_KEY` plumbing in `.zshrc` alive for one function.

**Recommendation: optional removal, not a finding.** If you drop it, delete the plugin spec, the two `g:vim_ai_*` blocks, the three mappings, the `GitCommitMessageFn` function, the three which-key entries, and the `OPENAI_API_KEY` fallback in `.zshrc`. **Effort: 10 minutes. Payoff: about 45 lines of `init.vim` and one API key.** Keep it if you value a second model's opinion in-buffer.

---

## 8. Recommended changes, consolidated

| # | Change | File | Effort | Payoff |
|---|---|---|---|---|
| 1 | Add `allow-passthrough`, `extended-keys`, `terminal-features …extkeys` | `.tmux.conf` | 2 min | **High** — notifications, progress bar, Shift+Enter |
| 2 | Add `macos_option_as_alt yes` | `.config/kitty/kitty.conf` | 1 min | Low — Option+Enter, Option+P, Alt word motions |
| 3 | Add `.claude/worktrees/` to `.gitignore` before first use of `claude -w` | `.gitignore` | 1 min | Low — prevents untracked noise |
| 4 | *(Optional)* add `TermLeave,InsertLeave,BufWinEnter` to the `checktime` autocmd | `init.vim` | 2 min | Low |
| 5 | *(Optional)* wrap the popup in `tmux new-session -A -s claude-…` | `.tmux.conf` | 10 min | Medium — survives dismissal; costs a session per project |
| 6 | *(Optional)* remove vim-ai | `init.vim`, `.zshrc` | 10 min | Low |

### Deliberately not recommended

| Not doing | Why |
|---|---|
| Installing `coder/claudecode.nvim` | Stalled since 2026-06-25; 40 unmerged PRs; an unanswered "is this abandoned?" issue. Revisit if `main` moves |
| Installing `greggh/claude-code.nvim` | Two commits in 2026; it is a terminal wrapper, and your floaterm binding already is one |
| Replacing `checktime` with `vim.uv` watchers | Claude Code replaces files rather than writing in place *(tested)*, so you would have to watch directories. No maintained plugin does this |
| Any third-party tmux/worktree orchestrator | `claude --worktree`, `--bg` and `claude agents` cover it first-party |
| `allow_remote_control` / `listen_on` in kitty | Nothing needs them; both widen the attack surface |
| `/terminal-setup` | Documented as a no-op for kitty, and it must not run inside tmux |
| Removing `set autoread` | A no-op in Neovim, but it documents intent next to the autocmd that depends on it |

---

## 9. Open Questions

1. **`claude --tmux` behaviour.** The flag exists in `claude --help` for 2.1.274 but appears nowhere on `code.claude.com/docs`. I could not exercise it: `claude -p --worktree ttest --tmux` in a fresh scratch repo returned *"Workspace trust not yet accepted. Run `claude` once in this directory and accept the trust dialog, then retry with --worktree"* — which **contradicts** the worktrees page's statement that *"Non-interactive runs with `-p` skip the trust check, so `claude -p --worktree` proceeds without it."* Whether `--tmux` forces an interactive path, or the docs are stale, is unresolved. Test it interactively in a throwaway repo before relying on it.
2. **Whether `/ide` lists a Neovim-hosted lock file.** The lock-file protocol is first-party documented and `coder/claudecode.nvim` implements it byte-for-byte, but I did not install the plugin, so I never watched `/ide` discover a Neovim entry. The failure mode would be a workspace-folder or `ideName` mismatch in the picker.
3. **Whether tmux's `allow-passthrough on` (visible-pane-only) is enough for Claude Code's notification.** The docs say "on"; the man page says "on" gates on pane visibility, and a popup is not a pane. Untested whether a notification fired *from inside a popup* reaches kitty under `on` versus `all`.
4. **Whether `coder/claudecode.nvim` is abandoned or merely paused.** Issue #319 has no maintainer reply as of 2026-09-17. No maintainer statement exists either way, so "stalled" is the strongest claim the evidence supports.
5. **kitty synchronized-output detection.** kitty implements synchronized updates and tmux does not list it in `client_termfeatures`, so `set -as terminal-features 'xterm*:sync'` looks correct — but Anthropic does not recommend it and I did not measure a flicker difference. Left out rather than guessed at.

---

## 10. Sources

**First-party — Anthropic** (all fetched 2026-09-17)
- [Configure your terminal](https://code.claude.com/docs/en/terminal-config) — the tmux block, Shift+Enter matrix, Option-as-Meta, notifications, themes, vim mode
- [Use Claude Code in VS Code / IDE integrations](https://code.claude.com/docs/en/ide-integrations) — lock file, `ws://`, auth header, `mcp__ide__*`, `/ide`
- [Interactive mode](https://code.claude.com/docs/en/interactive-mode) — shortcut tables, `Ctrl+B` "tmux users press twice", `Ctrl+J`, `Ctrl+G`
- [Common workflows](https://code.claude.com/docs/en/common-workflows) — `--continue`, parallel sessions
- [Worktrees](https://code.claude.com/docs/en/worktrees) — `--worktree`, `.worktreeinclude`, cleanup, isolation rules
- [Background agents](https://code.claude.com/docs/en/agent-view) — `--bg`, `attach`, `agents`, supervisor daemon
- [CLI reference](https://code.claude.com/docs/en/cli-reference) — `--ide`, `--bg`
- `~/.local/bin/claude --help`, v2.1.274 — `--tmux`, `--worktree`, subcommands

**First-party — projects**
- `tmux(1)` man page, tmux 3.6a, installed on this machine — `display-popup`, `allow-passthrough`, `extended-keys`, `terminal-features`, `focus-events`, `new-session -A -D`
- tmux 3.6a source: [`popup.c`](https://github.com/tmux/tmux/blob/3.6a/popup.c), [`server-client.c`](https://github.com/tmux/tmux/blob/3.6a/server-client.c), [`tty-features.c`](https://github.com/tmux/tmux/blob/3.6a/tty-features.c)
- Neovim 0.12.2 `:help` files at `/opt/homebrew/Cellar/neovim/0.12.2/share/nvim/runtime/doc/` — `options.txt` (`'autoread'`), `vim_diff.txt` (nvim-defaults), `editing.txt` (`timestamp`, `:checktime`), `autocmd.txt` (`FileChangedShell(Post)`, `CursorHold(I)`, `FocusGained`), `message.txt` (`W12`), `luvref.txt` (`uv_fs_event_t`)
- [kitty configuration docs](https://sw.kovidgoyal.net/kitty/conf/) — `macos_option_as_alt`, `allow_remote_control`, `listen_on`, `scrollback_pager`, `notify_on_cmd_finish`
- Plugin source read directly: `coder/claudecode.nvim` (`PROTOCOL.md`, `lua/claudecode/lockfile.lua`, `config.lua`, `terminal.lua`, `terminal/external.lua`, `terminal/none.lua`), `greggh/claude-code.nvim` (`lua/claude-code/file_refresh.lua`), `smtg-ai/claude-squad` (`session/tmux/tmux.go`), `nielsgroen/claude-tmux` (`README.md`)
- GitHub REST API via `gh api` — stars, commit dates, release tags, open issues and PRs for every repo named above

**Experiments run on this machine, 2026-09-17**
- tmux popup lifecycle: process survival across `display-popup -C` and across client detach; survival of a popup-wrapped `new-session -A`
- Focus-event propagation: `FocusLost`/`FocusGained` in a neighbouring nvim pane on popup open/close and on pane selection
- `CursorHold` firing once per idle period at `updatetime=200`
- Claude Code `Edit` tool: inode replacement (`162260291` → `162260325`) and refusal to write through a symlink
- Live tmux option and terminal-feature inspection in the running session

**No third-party write-ups, blog posts, Reddit threads or videos are cited in this document.** Community repositories appear only as measured artefacts — their source code and their GitHub API metadata — never as a source of claims about Claude Code's behaviour.
