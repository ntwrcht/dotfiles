# tgrid — one command for tmux pane layouts

## Goal

Arrange the panes of the current tmux window in one command: an even grid, a main pane with a stack beside it, or uneven splits at a ratio I choose (e.g. 1:3 instead of 50/50).

**Success signal:** I stop dragging pane borders or chaining `resize-pane` by hand.

## Decisions

| # | Decision | Choice |
|---|---|---|
| 1 | Modes | Grid, main, and ratio — all under one command |
| 2 | Scope | Current window only; never touches other windows |
| 3 | Delivery | Script `bin/tgrid` (on PATH via `zsh/path.zsh`, same pattern as `bin/md`) so both the shell and tmux bindings call the same code |
| 4 | Key bindings | `<prefix>G` → `tgrid`, `<prefix>M` → `tgrid main` |
| 5 | New panes | Open in the current pane's directory (`#{pane_current_path}`) |

## Command surface

| Command | Result |
|---|---|
| `tgrid` | Tile existing panes into an even grid (`select-layout tiled`) |
| `tgrid 4` | Add panes until there are 4, then tile |
| `tgrid main` | Current pane becomes main, left at 60% width; others stack on the right |
| `tgrid main 4` | Same, adding panes until there are 4 (1 main + 3 stacked) |
| `tgrid main-top` / `tgrid main-top 4` | Main pane on top at 60% height; others side by side below; count works as with `main` |
| `tgrid 1:3` | Resize panes to a 1:3 ratio (25% / 75%) |
| `tgrid 1:2:1` | Resize three panes to 25% / 50% / 25% |
| `tgrid -h` | Print usage |

## Behaviour rules

### Grid and main

- A count only adds panes; it never kills panes. If the window already has more panes than the count, tile what exists and print a note.
- `main` swaps the current pane into position 1 before applying `main-vertical` / `main-horizontal`, and sets the window's `main-pane-width` / `main-pane-height` to `60%`.
- Focus stays on the pane I was in (`swap-pane -d`, then re-select it).
- New panes always split from the currently largest pane, so small panes don't hit "pane too small" first.

### Ratio

- Direction comes from the layout, not a flag:
  - All panes in one row (side by side) → ratio sets widths, left to right.
  - All panes in one column (stacked) → ratio sets heights, top to bottom.
  - Mixed rows and columns → exit with `tgrid: ratio needs panes in a single row or column`.
- One pane + ratio of N parts → split horizontally (side by side) N−1 times, then apply.
- Fewer panes than parts (already in a single row/column) → add panes along that same axis, then apply.
- More panes than parts → exit with an error naming both counts.
- Missing panes split from the last pane in the row/column, along that axis.
- Sizes are computed in cells from the window size minus pane borders; the last pane takes the remainder so totals always add up.

### Current pane

- The script resolves the current pane with `tmux display -p '#{pane_id}'`, which honours `$TMUX_PANE`. The bindings set `TMUX_PANE=#{pane_id}` so the pane the key was pressed in is the target, the same as from the shell.

### Errors

- Outside tmux (`$TMUX` unset) → exit 1 with `tgrid: not inside tmux`.
- Unknown argument → usage, exit 2.
- Only one pane and no count (grid or main) → message `only one pane; split first or pass a count`, exit 0, so a key press never looks like it did nothing.
- tmux refuses a split because panes are too small → surface tmux's message, exit 1. Panes already created stay; there is no rollback. The "layout untouched" guarantee covers only argument and layout errors caught before any change.
- Output: when stdout is not a terminal (called from a binding), messages go through `tmux display-message` instead of stdout/stderr, so errors aren't lost and nothing covers the pane.

## Files touched

| File | Change |
|---|---|
| `bin/tgrid` | New executable bash script (matches `bin/md`'s `#!/usr/bin/env bash`) |
| `.tmux.conf` | Add `bind G run-shell "TMUX_PANE=#{pane_id} $HOME/.dotfiles/bin/tgrid"` and the same with `main` for `M` near the split bindings |

`<prefix>M` replaces tmux's default "clear marked pane"; `<prefix>m` still toggles the mark, so nothing is lost.

## Non-goals

- Exact rows × columns grids (`tgrid 2x3`) — tiled's automatic shape is close enough.
- Acting on other windows or merging windows into one.
- Saving or restoring named layouts.

## Risks

| Risk | Mitigation |
|---|---|
| `run-shell` from a tmux binding doesn't see `bin/` on PATH | Bindings call `$HOME/.dotfiles/bin/tgrid` by absolute path |
| Ratio rounding leaves a gap or overflow | Last pane absorbs the remainder |
| Tiny terminal can't fit the requested panes | Let tmux fail and report its error |

## Validation

Run manually in a scratch window:

1. `tgrid 4` from one pane → 2×2 grid, focus unchanged.
2. `tgrid main 4` → 1 large left pane at ~60%, 3 stacked right.
3. `tgrid 1:3` from one pane → two columns at ~25/75.
4. `tgrid 1:2:1` on 3 side-by-side panes → widths ~25/50/25.
5. `tgrid 1:3` on a 2×2 grid → clear error, layout untouched.
6. `<prefix>G` and `<prefix>M` from a pane running nvim → same results as the shell command.
7. `tgrid` outside tmux → error, exit 1.

## Rollback

Delete `bin/tgrid` and the two `bind` lines; `<prefix>r` reloads the config.
