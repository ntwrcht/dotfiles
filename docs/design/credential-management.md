# secret — credentials in macOS Keychain

## Goal

Keep every credential (API tokens, MongoDB URIs, SSH key passphrases) in the macOS login Keychain, reach it from the terminal with one command, and pass it only to the command that needs it. Nothing secret ever lands in this public repo or in a plaintext file.

**Success signal:** a new shell has no tokens in `env`, `~/.zshrc-secrets` and `~/.config/openai.token` are gone, and `jira`, `mdb dev`, and `ssh <host>` still work without pasting anything.

**Research:** [docs/research/credential-management.md](../research/credential-management.md)

## Decisions

| # | Decision | Choice |
|---|---|---|
| 1 | Store | macOS login Keychain via `/usr/bin/security`. Free and offline, with nothing new to install |
| 2 | Scope | Solo use, on my Macs only. Servers never store secrets |
| 3 | Unlock | No per-use Touch ID. The login Keychain unlocks with the Mac |
| 4 | Delivery | Per command: secrets go into one command's environment, never exported globally |
| 5 | Interface | One script, `bin/secret` (on PATH via `zsh/path.zsh`, same pattern as `bin/md`) |
| 6 | MongoDB | One full URI per environment (`mongo/<env>`), opened by `bin/mdb <env>` |
| 7 | SSH | Tracked defaults file (`UseKeychain`, `AddKeysToAgent`) included from a local, untracked `~/.ssh/config`. Passphrases go on all keys. No Secretive |
| 8 | Migration | Move tokens into Keychain, delete `~/.zshrc-secrets` and `~/.config/openai.token`, keep non-secret settings in `~/.zshrc.local` |

## Naming

- Every item is a generic password with **service** `dotfiles/<NAME>`, **account** `$USER`, and **label** `dotfiles/<NAME>`. The prefix is what lets `secret ls` find only these items, and what you search for in Keychain Access.
- `<NAME>` matches `[A-Za-z0-9_./-]+`. Names that are valid env var names (`OPENAI_API_KEY`) can be used with `secret run`. Path-style names (`mongo/prod`) are for `secret get` only.

## Command surface — `bin/secret`

| Command | Result | Underlying call |
|---|---|---|
| `secret add NAME` | Prompts for the value twice with no echo (or reads one line from stdin when piped) and creates or updates the item | `add-generic-password … -U -w "VALUE"` sent to `security -i` on stdin, so the value never appears in argv or history. **Not** `security`'s own `-w` prompt: it silently truncates input to 128 characters, which cut a 192-character Atlassian token and broke Jira auth. `security -i` caps a line near 4 KB, so values over 3800 characters are refused |
| `secret get NAME` | Prints the value to stdout. Exits 1 with a message on stderr if missing | `security find-generic-password -a $USER -s dotfiles/NAME -w` |
| `secret has NAME` | Silent. Exits 0 if the item exists, 1 if not | same call without `-w` (security exits 44 when missing) |
| `secret ls` | Prints names only, sorted, one per line. Never prints values | `security dump-keychain` → filter `"svce"<blob>="dotfiles/…"` |
| `secret rm NAME` | Asks `Delete dotfiles/NAME? [y/N]`, then deletes. `-f` skips the question | `security delete-generic-password -a $USER -s dotfiles/NAME` |
| `secret run NAME... -- CMD [ARGS]` | Runs `CMD` with each `NAME=<value>` in its environment only, and exits with `CMD`'s status. Fails before running `CMD` if any name is missing or not a valid env var name | `export NAME="$value"` inside the script, then `exec "$@"`, so values never reach argv |
| `secret -h` | Prints usage | — |

I verified the add/get/has/ls/rm calls on this Mac (macOS 27.2) with a throwaway item. None of them raised a Keychain prompt.

## Command surface — `bin/mdb`

| Command | Result |
|---|---|
| `mdb ENV [MONGOSH_ARGS]` | `exec mongosh "$(secret get mongo/ENV)" "$@"` |
| `mdb` | Lists available environments (`secret ls` filtered to `mongo/`) |

`mdb` resolves `mongodb+srv://` URIs itself (dig SRV + TXT, `tls=true`, URI options win) and hands mongosh a plain `mongodb://` seed list: mongosh's bundled Node rejects SRV answers from some DNS servers (`querySrv EBADRESP` on an iPhone hotspot) that the macOS resolver reads fine. If the lookup fails, the stored URI is used unchanged.

MongoDB Compass needs nothing extra, because it already stores saved-connection passwords in Keychain.

## Shell wiring — `zsh/secrets.zsh`

This file is sourced from the "Local Secrets & Overrides" block in `.zshrc`. It defines one wrapper function per tool that needs a secret:

| Wrapper | Secrets injected |
|---|---|
| `codex` | `OPENAI_API_KEY` |

`jira` was dropped from this table after release: jira-cli reads its token from Keychain natively (service `jira-cli`, account = the Jira login), which also covers non-interactive callers. `secret add/rm JIRA_API_TOKEN` mirrors the value into that item (see `mirror_of` in `bin/secret`), so `secret` remains the one interface. Each wrapper is one line of the form `jira() { secret run JIRA_API_TOKEN -- jira "$@"; }`. `bin/secret` is an external process and cannot see zsh functions, so this doesn't recurse. Adding a tool means adding one line.

The wrappers exist only in interactive zsh. Tools launched from nvim, tmux bindings, launchd, or scripts no longer get these tokens unless they call `secret run` themselves. No such consumer exists today; the README says so.

`.zshrc` also gains `setopt HIST_IGNORE_SPACE`, so a command typed with a leading space stays out of history.

## SSH

`gcloud compute config-ssh` writes host blocks into `~/.ssh/config`. If that file were a symlink into this public repo, gcloud would write private hostnames into the repo. So:

- **`~/.ssh/config` stays a local, untracked file.** It holds host entries, which are private.
- **The repo tracks `.ssh/dotfiles.conf`**, linked to `~/.ssh/dotfiles.conf` via `links.conf`. It holds only non-conflicting defaults:
  ```
  Host *
    UseKeychain yes
    AddKeysToAgent yes
    ServerAliveInterval 60
  ```
- **Line 1 of `~/.ssh/config` is `Include ~/.ssh/dotfiles.conf`.** The Include has to come first: an `Include` placed after a `Host` block belongs to that block. ssh takes the first value it finds for each option, and because the defaults above set nothing a host entry sets (`User`, `HostName`, `IdentityFile`), host entries are unaffected.
- **Passphrases:** all three keys (`id_ed25519`, `id_rsa`, `google_compute_engine`) currently have **no passphrase**. For each one, run `ssh-keygen -p -f <key>` once, then `ssh-add --apple-use-keychain <key>` to store the passphrase in Keychain.

### Managing hosts — `bin/sshm`

Added after the first release. `sshm add/ls/show/rm/test/key` (and a bare `sshm` fzf picker) manage host entries in `~/.ssh/hosts`, a local file (600) that `.ssh/dotfiles.conf` includes **before** its `Host *` block, so each host's own settings win. `sshm` only writes `~/.ssh/hosts`; hosts in `~/.ssh/config` (gcloud's block) are listed and usable but `rm` refuses them. Each added host gets `IdentitiesOnly yes`, so ssh offers only that host's key. Completion lives in `zsh/ssh.zsh`.

## Changes to existing files

| File | Change |
|---|---|
| `.zshrc` | Replace the "Local Secrets & Overrides" block: drop the `~/.zshrc-secrets` source and the `openai.token` fallback, source `zsh/secrets.zsh`, keep the `~/.zshrc.local` source, add `setopt HIST_IGNORE_SPACE` |
| `.zshrc-secrets.example` | Rename to `.zshrc.local.example`, containing only `GOPRIVATE` and a comment pointing to `secret add` for anything secret |
| `install` | `ensure_secrets_file` becomes `ensure_local_file` (creates `~/.zshrc.local` from the example, chmod 600). New `ensure_ssh_include`, run before linking: `mkdir -m 700 ~/.ssh` if missing, create `~/.ssh/config` (600) if missing, and prepend the `Include` line if absent, after backing up the file |
| `doctor` | Replace the `~/.zshrc-secrets` check with: `-x "$DOTFILES_DIR/bin/secret"`; `~/.ssh/config` has the `Include` line; NOTE if `~/.zshrc-secrets` or `~/.config/openai.token` still exist; NOTE for each private key without a passphrase (files in `~/.ssh` that have a matching `.pub`, where `ssh-keygen -y -P '' -f <key>` succeeds) |
| `links.conf` | Add `.ssh/dotfiles.conf  .ssh/dotfiles.conf` |
| `uninstall` | Offer to remove `~/.zshrc.local` instead of `~/.zshrc-secrets` |
| `README.md` | Rewrite "Managing Secrets" around `secret`, `mdb`, and the SSH include. Update line 51 ("Secrets stay local") |

## One-time migration (done by hand, in order)

1. `secret add JIRA_API_TOKEN` and `secret add OPENAI_API_KEY`, pasting the current values.
2. `secret add mongo/dev` (and `mongo/staging`, `mongo/prod` as they apply), pasting the full URIs.
3. `secret ls` shows all the names, and `jira` / `mdb dev` work in a new shell.
4. Move `GOPRIVATE` into `~/.zshrc.local`.
5. Delete `~/.zshrc-secrets` and `~/.config/openai.token`.
6. Add passphrases to the SSH keys and store them in Keychain (see SSH).

## Risks

| Risk | Mitigation / acceptance |
|---|---|
| Any process running as me can call `security find-generic-password` without a prompt (seen in the test) | Accepted. This is no worse than today's plaintext files, and much better than exported env vars inherited by every process. Per-use Touch ID was ruled out in decision 3 |
| `mdb` passes the URI as a `mongosh` argument, visible in `ps` while mongosh runs | Accepted on a single-user Mac; it is the only place a value reaches argv. mongosh already redacts credentials from its history and logs |
| Pasting a value as `secret add NAME value` would put it in history | `add` takes no value argument. It always prompts |
| A secret is deleted before the migration is verified | The migration verifies in step 3 before deleting anything in step 5 |
| gcloud or other tools rewrite `~/.ssh/config` and drop the Include line | `doctor` checks for the Include line, and `install` restores it |

## Validation

- A round trip of `secret add/has/get/ls/rm` on a throwaway name behaves as the table says.
- `secret run MISSING_NAME -- true` and `secret run mongo/dev -- true` both exit non-zero without running the command.
- In a new shell, `env | grep -E 'JIRA_API_TOKEN|OPENAI_API_KEY'` prints nothing, while `jira me` and `mdb dev --eval 'db.runCommand({ping:1})'` succeed.
- `ssh -G <host> | grep -i usekeychain` shows `yes`, and `ssh <host>` connects without a passphrase prompt after a reboot.
- `make doctor` reports no NOTEs for secrets or SSH.
- `git grep -nE 'mongodb(\+srv)?://[^ ]*@|BEGIN OPENSSH'` returns nothing.

## Rollback

- The code changes are ordinary commits, so `git revert` undoes them.
- Keychain items stay put across a revert. To rebuild `~/.zshrc-secrets`, run `secret get NAME` for each name in `secret ls`.
- To undo the SSH change, remove the `Include` line from `~/.ssh/config`. The keys and their Keychain passphrases keep working.

## Out of scope

- `zsh/env.zsh` sets `SSH_KEY_PATH="$HOME/.ssh/rsa_id"`, which points to a file that doesn't exist. That's worth a separate cleanup.
- Retiring the legacy `id_rsa` key.
- Team sharing, Linux servers, per-use Touch ID.
