# Developer credential management on macOS alongside a dotfiles repo (2026)

**Research date:** 2026-09-24
**Method:** primary sources only: official docs, man pages installed on this Mac, upstream repos and source, GitHub release API. Community/forum posts appear only where no first-party doc covers the point, and are labelled **[lead, not primary]**.

**Environment verified on this machine (2026-09-24):**

| Component | Version / state | How verified |
|---|---|---|
| macOS | Darwin 27.2 (macOS 27) | environment |
| OpenSSH (Apple build) | `OpenSSH_10.5p1, LibreSSL 3.3.6` | `ssh -V` |
| mongosh | 2.11.1 (latest upstream: 2.12.0, 2026-09-18) | `mongosh --version`; [GitHub releases API](https://api.github.com/repos/mongodb-js/mongosh/releases/latest) |
| `security` CLI | present at `/usr/bin/security` | `which security` |
| op, bw, bws, sops, age, direnv, chezmoi, pass, gopass | **not installed** | `which` |
| Repo secrets pattern | `.zshrc` sources plaintext `~/.zshrc-secrets` (`export JIRA_API_TOKEN=…`, `export OPENAI_API_KEY=…`) and reads `~/.config/openai.token` | `.zshrc` lines 52–65, `.zshrc-secrets.example` |
| `~/.ssh/config` | exists, **not** managed by `links.conf` | `ls ~/.ssh`, `links.conf` |

---

## 1. Bottom line

**Keep secret *values* out of the repo entirely and commit only *references* (to a vault item, a Keychain entry, or an encrypted blob). Resolve them at the moment a command runs, not at shell startup.** Every tool below supports that pattern; they differ mainly in cost, offline behaviour, and whether team sharing matters.

Key findings:

1. **SSH keys belong in an agent that never exposes the private key file.** 1Password, Bitwarden and Secretive each ship an agent; point `IdentityAgent` at its socket in `~/.ssh/config` ([ssh_config(5)](https://man.openbsd.org/ssh_config); [1Password](https://www.1password.dev/ssh/get-started); [Secretive source](https://github.com/maxgoedjen/secretive/blob/main/Sources/Secretive/Views/Configuration/Instructions.swift)).
2. **Secretive keys cannot be backed up or moved**: by design, one key set per Mac ([Secretive README](https://github.com/maxgoedjen/secretive/blob/main/README.md)). Secretive 4.0.0 shipped 2026-09-21 with macOS 27 support ([release](https://github.com/maxgoedjen/secretive/releases/tag/v4.0.0)).
3. **Apple's built-in path (`UseKeychain yes` + `AddKeysToAgent yes`) still works** and costs nothing, but the private key stays as a file on disk, protected only by its passphrase ([TN2449](https://developer.apple.com/library/archive/technotes/tn2449/_index.html); [Apple ssh_config.5 source](https://github.com/apple-oss-distributions/OpenSSH/blob/main/openssh/ssh_config.5)).
4. **`Include` lets you commit a public `~/.ssh/config` and keep private hosts in an untracked file**; ordering matters because the first obtained value wins ([ssh_config(5)](https://man.openbsd.org/ssh_config)).
5. **Environment variables are not a secure channel.** 1Password, gopass and the ssh docs all warn that same-user processes can read another process's environment ([1Password `op run`](https://www.1password.dev/cli/secrets-environment-variables); [gopass `env`](https://github.com/gopasspw/gopass/blob/master/docs/commands/env.md)). The current repo exports tokens globally from `~/.zshrc-secrets`, so every child process of every shell inherits them.
6. **MongoDB: put the username in the URI and let mongosh prompt for the password**; mongosh detects a missing password and asks for it ([mongosh source, `isPasswordMissingURI`](https://github.com/mongodb-js/mongosh/blob/main/packages/cli-repl/src/cli-repl.ts)). mongosh redacts credentials in history and logs by default ([mongosh logs](https://www.mongodb.com/docs/mongodb-shell/logs/)).
7. **Compass stores saved-connection secrets in the macOS Keychain, but exports passwords in plaintext unless you pass `--passphrase`** ([Compass import/export](https://www.mongodb.com/docs/compass/current/connect/favorite-connections/import-export/); [Compass CLI options](https://www.mongodb.com/docs/compass/current/settings/command-line-options/)).
8. **1Password CLI does not work offline** per staff statements (no first-party doc settles it); **1Password Environments' mounted `.env` does** serve the last-synced values offline ([1Password Environments](https://www.1password.dev/environments/local-env-file)).
9. **sops + age is the only option that stores encrypted secrets *in* the git repo**; it keeps YAML/JSON keys in cleartext and encrypts values ([sops docs](https://github.com/getsops/docs/blob/main/content/en/docs/usage/common-operations/_index.md)). Its weak point is the age identity file, which is plaintext unless passphrase-protected or held by a plugin such as `age-plugin-se` (Secure Enclave).
10. **chezmoi's template model conflicts with this repo's symlink-farm design**: chezmoi renders real files (with secrets substituted) rather than symlinks ([chezmoi design FAQ](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/frequently-asked-questions/design.md)).

---

## 2. SSH keys and host configuration

### 2.1 OpenSSH building blocks (all options)

| Directive | What it does | Source |
|---|---|---|
| `IdentityAgent` | "Specifies the Unix-domain socket used to communicate with the authentication agent. This option overrides the SSH_AUTH_SOCK environment variable"; `none` disables the agent. | [ssh_config(5)](https://man.openbsd.org/ssh_config); local `man ssh_config` (OpenSSH_10.5p1) |
| `Include` | Includes other config files; globs allowed; relative paths resolve to `~/.ssh`; "may appear inside a Match or Host block to perform conditional inclusion." | [ssh_config(5)](https://man.openbsd.org/ssh_config) |
| Ordering rule | "Since the first obtained value for each directive is used, more host-specific declarations should be given near the beginning of the file, and general defaults at the end." | [ssh_config(5)](https://man.openbsd.org/ssh_config) |
| `AddKeysToAgent` | `yes` adds a key and passphrase to the running agent on first use; `confirm` requires confirmation on each use; also accepts a lifetime. | [ssh_config(5)](https://man.openbsd.org/ssh_config) |
| `UseKeychain` (Apple only) | "On macOS, specifies whether the system should search for passphrases in the user's keychain … The default is 'no'." | [Apple OpenSSH ssh_config.5 source](https://github.com/apple-oss-distributions/OpenSSH/blob/main/openssh/ssh_config.5); local man page |
| `IgnoreUnknown UseKeychain` | Keeps a shared config valid on non-Apple OpenSSH builds. | [Apple TN2449](https://developer.apple.com/library/archive/technotes/tn2449/_index.html) |

**Public/private split pattern.** Commit a `~/.ssh/config` with generic defaults and an `Include` line near the top, such as `Include ~/.ssh/config.d/*` or `Include ~/.ssh/config.local`. Keep hostnames, IPs, and jump hosts for work in the untracked included file. Because the first obtained value wins, put the `Include` **before** any `Host *` block ([ssh_config(5)](https://man.openbsd.org/ssh_config)). Host entries are not secrets, but they do reveal infrastructure. The ssh man page also says `~/.ssh/config` "must have strict permissions: read/write for the user, and not writable by others" (local `man ssh_config`, FILES), so a symlinked config needs a mode-600 target.

### 2.2 Apple ssh-agent + Keychain

- **History:** macOS 10.12.2 changed `UseKeychain` to off by default. Add `UseKeychain yes` to store passphrases. OpenSSH stopped auto-loading keys into the agent, so `AddKeysToAgent yes` brings that back ([TN2449, 2016-12-20](https://developer.apple.com/library/archive/technotes/tn2449/_index.html)).
- **CLI:** `ssh-add --apple-use-keychain` stores passphrases in the Keychain; `--apple-load-keychain` loads identities using stored passphrases. The old `-K`/`-A` flags still work unless `APPLE_SSH_ADD_BEHAVIOR=openssh` is set ([Apple ssh-add.1 source](https://github.com/apple-oss-distributions/OpenSSH/blob/main/openssh/ssh-add.1); local `man ssh-add`).
- **Keeps secrets out of git:** the private key lives in `~/.ssh/`, outside the repo. The passphrase lives in the login Keychain.
- **Risk:** the key file sits on disk, encrypted only by its passphrase. Anyone who gets both the file and the passphrase (from the unlocked Keychain) has the key. *(Inference from the above; no single Apple doc states it.)*
- **Cost / offline / team:** free, fully offline, no sharing.

### 2.3 1Password SSH agent

- **Socket (macOS):** `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`. The docs suggest symlinking it to `~/.1password/agent.sock` and using `Host *` / `IdentityAgent ~/.1password/agent.sock` ([Get started with 1Password for SSH](https://www.1password.dev/ssh/get-started)).
- **Key types:** Ed25519 or RSA ([1Password manage keys](https://www.1password.dev/ssh/manage-keys)).
- **`agent.toml`:** lives at `~/.config/1Password/ssh/agent.toml` (or under `$XDG_CONFIG_HOME`). It uses `[[ssh-keys]]` entries with optional `item`, `vault`, `account` fields. Keys are offered in the listed order, which helps avoid the server's "six-key authentication limit" (`MaxAuthTries`) ([agent config](https://www.1password.dev/ssh/agent/config)). The file holds item names, not secrets, so it is safe to commit if vault/item names are not sensitive.
- **Authorization:** 1Password asks for approval per application. By default the approval lasts "until 1Password locks". It can be set to per-request, until quit, or 4/12/24 hours. "Approve for all applications" widens it to every app in the OS user account ([authorization](https://www.1password.dev/ssh/agent/authorization)).
- **Cost:** needs a paid 1Password account. Individual lists at $3.99/month regular, $2.99 promotional, billed annually, with a 14-day trial ([pricing](https://1password.com/pricing/password-manager)). The desktop app must be running.
- **Team sharing:** keys live in vaults, so sharing a vault shares the key. *(Implied by the vault model; not verified against a sharing-specific doc.)*

### 2.4 Bitwarden SSH agent (desktop app)

- **Socket (macOS):** App Store build: `~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock`; .dmg build: `~/.bitwarden-ssh-agent.sock`. Set `SSH_AUTH_SOCK` to it ([Bitwarden SSH agent](https://bitwarden.com/help/ssh-agent/)).
- **Key types:** "Ed25519, RSA (SHA-256 and SHA-512)" ([About SSH](https://bitwarden.com/help/about-ssh/)).
- **Behaviour:** the agent does not run when logged out. When the vault is locked, it prompts to unlock and then to authorize. The desktop app is required; the CLI has no agent ([Bitwarden SSH agent](https://bitwarden.com/help/ssh-agent/)).
- **Status:** a Bitwarden staff post (2026-03-26) says v1 gets only security and regression fixes while development moves to a v2 rebuild with no new features at launch ([community notice](https://community.bitwarden.com/t/ssh-agent-whats-changing-and-what-to-expect/95308)) **[lead, not primary]**.

### 2.5 Secretive (Secure Enclave)

- **What it is:** stores SSH keys in the Secure Enclave, "impossible to export", with Touch ID/Apple Watch approval and access notifications. MIT licensed. `brew install secretive` ([README](https://github.com/maxgoedjen/secretive/blob/main/README.md); [LICENSE](https://github.com/maxgoedjen/secretive/blob/main/LICENSE)).
- **Hard limits:** "Because secrets in the Secure Enclave are not exportable, they are not able to be backed up, and you will not be able to transfer them to a new machine" ([README](https://github.com/maxgoedjen/secretive/blob/main/README.md)). "The Mac's Secure Enclave only supports 256-bit EC keys", so it cannot generate RSA keys ([FAQ](https://github.com/maxgoedjen/secretive/blob/main/FAQ.md)).
- **Config:** the app's generated instructions are `Host *` / `IdentityAgent <socketPath>` or `export SSH_AUTH_SOCK=<socketPath>` in `~/.zshrc` ([Instructions.swift](https://github.com/maxgoedjen/secretive/blob/main/Sources/Secretive/Views/Configuration/Instructions.swift)). The community config repo gives the path as `~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh` ([secretive-config-instructions](https://github.com/maxgoedjen/secretive-config-instructions/blob/main/shells/zsh.md)). Each key has a public-key file on disk (since 2.2), which you can reference with `IdentityFile` to pin a key per host ([FAQ](https://github.com/maxgoedjen/secretive/blob/main/FAQ.md)).
- **Version:** v4.0.0 (2026-09-21) adds macOS 27 support, SSH certificate UI, and host lookup from `known_hosts`, with a minimum of macOS 15 ([release notes](https://github.com/maxgoedjen/secretive/releases/tag/v4.0.0)).
- **Cost / offline / team:** free, fully offline, no sharing. Each machine and person gets its own key.

---

## 3. MongoDB connection strings

| Surface | Fact | Source |
|---|---|---|
| URI encoding | If the username or password includes `$ : / ? # [ ] @`, "those characters must be converted using percent encoding." | [Connection strings](https://www.mongodb.com/docs/manual/reference/connection-string/) |
| Password prompt | "To force the MongoDB Shell to prompt for a password, enter the `--password` option as the last option and leave out the argument." | [mongosh options](https://www.mongodb.com/docs/mongodb-shell/reference/options/) |
| Missing password in URI | mongosh checks `isPasswordMissingURI(cs)` and, for password-based mechanisms, prompts and `encodeURIComponent`s the result. | [cli-repl.ts](https://github.com/mongodb-js/mongosh/blob/main/packages/cli-repl/src/cli-repl.ts) |
| History file | `~/.mongodb/mongosh/mongosh_repl_history` | [command history](https://www.mongodb.com/docs/mongodb-shell/logs/command-history/) |
| Redaction | "The MongoDB Shell redacts credentials from the command history and the logs." `redactHistory` defaults to `remove` (drops `db.auth()`/`connect()` lines); `remove-redact` also redacts URLs, emails, and paths. | [logs](https://www.mongodb.com/docs/mongodb-shell/logs/); [config API](https://www.mongodb.com/docs/mongodb-shell/reference/configure-shell-settings-api/) |
| Global config | YAML at `/usr/local/etc/mongosh.conf`, `/opt/homebrew/etc/mongosh.conf`, or `/etc/mongosh.conf` (first found wins); holds display/history/log settings, not credentials. | [global config](https://www.mongodb.com/docs/mongodb-shell/reference/configure-shell-settings-global/) |
| `~/.mongoshrc.js` | Runs on startup; `--norc` skips it. | [mongoshrc](https://www.mongodb.com/docs/mongodb-shell/mongoshrc/) |
| Compass storage | On macOS, Compass ≥ 1.20 asks for Keychain access "for each saved connection in Recents and Favorites." | [Compass upgrade](https://www.mongodb.com/docs/compass/current/upgrade/) |
| Compass export | "By default, when you export saved connections, passwords are included in plaintext." `--exportConnections` / `--importConnections` with `--passphrase` encrypt and decrypt. | [import/export](https://www.mongodb.com/docs/compass/current/connect/favorite-connections/import-export/); [CLI options](https://www.mongodb.com/docs/compass/current/settings/command-line-options/) |
| Compass read-only strings | `--protectConnectionStrings` shows passwords as `*****` and disables editing. | [CLI options](https://www.mongodb.com/docs/compass/current/settings/command-line-options/) |

**Patterns that keep the URI out of git and shell history:**

- `mongosh "mongodb+srv://user@cluster.example.net/db"`: no password in the command, so mongosh prompts ([cli-repl.ts](https://github.com/mongodb-js/mongosh/blob/main/packages/cli-repl/src/cli-repl.ts)).
- `op run --env-file=.env.mongo -- sh -c 'mongosh "$MONGODB_URI"'`, where `.env.mongo` holds `MONGODB_URI=op://vault/item/uri`. The reference is safe to commit, and 1Password notes that "variables do not get replaced in values that are enclosed in single quotes" in env files ([op run](https://www.1password.dev/cli/secrets-environment-variables)).
- `mongosh "$(security find-generic-password -s mongo-dev -a "$USER" -w)"` reads from the Keychain at call time (see §4.3). Caveat: the full URI still appears in the process's argv. *(argv visibility via `ps` is standard Unix behaviour, not stated in MongoDB docs.)*

**Could not confirm from primary sources:** whether mongosh reads any environment variable for the URI natively (§7).

---

## 4. Generic secrets: tool by tool

### 4.1 1Password CLI (`op`), latest 2.39.0 ([product history](https://app-updates.agilebits.com/product_history/CLI2))

- **Keeping secrets out of git:** commit **secret references** `op://<vault>/<item>/[section/]<field>` instead of values ([secret references](https://www.1password.dev/cli/secret-references)).
  - `op read op://…` prints one value to stdout or `--out-file`.
  - `op inject -i tpl -o out` renders a template. The output file gets mode `0600` by default (`--file-mode`) ([inject reference](https://www.1password.dev/cli/reference/commands/inject)).
  - `op run [--env-file=…] -- cmd` resolves references and runs `cmd` "in a subprocess with the secrets made available as environment variables only for the duration of the process." "Secrets printed to stdout or stderr are concealed by default"; `--no-masking` turns that off ([op run reference](https://www.1password.dev/cli/reference/commands/run)).
- **zsh pattern:** app integration uses Touch ID. Authorization applies per terminal session and "extends to sub-shell processes in that window." It "expires after 10 minutes of inactivity … hard limit of 12 hours." On macOS the session credential is tied to the `tty` plus its start time ([app integration security](https://www.1password.dev/cli/app-integration-security)). Shell Plugins wrap third-party CLIs (gh, aws, etc.) so their tokens come from 1Password ([shell plugins](https://www.1password.dev/cli/shell-plugins)).
- **1Password Environments (newer):** you can mount a `.env` at a path. Contents reach readers "through a UNIX-named pipe", are "never stored on disk", and git cannot commit them. Mac/Linux only. Not built for concurrent readers. File watchers like Vite may misbehave. "When you're offline, you'll only be able to access the most recent contents synced to your device" ([local .env](https://www.1password.dev/environments/local-env-file)). `op run --environments` is beta-only from 2.33.0-beta.02 ([op run reference](https://www.1password.dev/cli/reference/commands/run)).
- **Offline:** staff forum answers (2022, 2023) say the CLI talks to the server directly and has no offline mode ([forum thread](https://www.1password.community/discussions/developers/cli-offline-mode/88158)) **[lead, not primary]**. See §7.
- **Main risks:** env-var exposure. "Processes on your computer can access the environment of other processes run by the same user" ([op run guide](https://www.1password.dev/cli/secrets-environment-variables)). Also, `--no-masking` or `op read` output can leak into terminal scrollback and logs.
- **macOS 27 gotcha:** after the macOS 27 update, `op` may report "No accounts configured" until you grant the terminal access to 1Password app data ([app integration](https://www.1password.dev/cli/app-integration)).

### 4.2 Bitwarden CLI (`bw`, cli-v2026.9.0) and Secrets Manager CLI (`bws`, v2.1.0)

Versions come from the [bitwarden/clients](https://github.com/bitwarden/clients/releases) and [bitwarden/sdk-sm](https://github.com/bitwarden/sdk-sm/releases) release lists.

- **`bw`:** `bw unlock` returns a **session key** that you export as `BW_SESSION`. It stays valid until `bw lock`/`bw logout` but does not carry into new terminal windows. `--passwordenv` and `--passwordfile` allow non-interactive unlock, with a warning to lock down the password file. Vault data is "cached locally"; `bw sync` pulls updates ([Bitwarden CLI](https://bitwarden.com/help/cli/)).
  - Risk: `BW_SESSION` in the environment decrypts the whole vault for any process that can read it.
- **`bws`:** authenticates with `BWS_ACCESS_TOKEN` (a machine-account token). `bws run -- 'cmd'` injects a project's secrets as env vars; `--no-inherit-env` strips most parent env. Config lives at `~/.config/bws/config` and state at `~/.config/bws/state` ([Secrets Manager CLI](https://bitwarden.com/help/secrets-manager-cli/)).
  - Risk: the access token itself is a bearer secret that must live somewhere, which creates a bootstrap problem.
- **Cost:** Password Manager Free is $0; Premium is $1.65/month billed annually ([pricing](https://bitwarden.com/pricing/)). Secrets Manager Free allows up to 2 users, 3 projects, and 3 machine accounts. Teams and Enterprise remove the limits and include 20 and 50 machine accounts ([SM plans](https://bitwarden.com/help/secrets-manager-plans/)).
- **Team sharing:** organizations and collections for `bw`; projects and machine accounts for `bws`.

### 4.3 macOS Keychain `security` CLI

- **Store:** `security add-generic-password -a "$USER" -s <service> -U -w`. With `-w` at the end, `security` prompts for the value. The man page says "Put at end of command to be prompted (recommended)". `-A` ("insecure, not recommended!") allows any app. `-T appPath` limits which apps can read without a prompt. By default, "the application which creates an item is trusted to access its data without warning" ([security.1 source](https://github.com/apple-oss-distributions/Security/blob/main/SecurityTool/macOS/security.1); local `man security`).
- **Read:** `security find-generic-password -s <service> -a <account> -w` prints only the password ([security.1](https://github.com/apple-oss-distributions/Security/blob/main/SecurityTool/macOS/security.1)).
- **zsh pattern:** `export TOKEN="$(security find-generic-password -s x -w)"` in `.zshrc` works but puts the value in every child's environment. A function or alias that sets the variable only for one command (`FOO=$(…) cmd`) narrows that exposure. *(Synthesis.)*
- **Risks:** passing `-w <value>` on the command line puts the secret in shell history and argv. Because `/usr/bin/security` created the item, it is in the trusted-app list, so any script running as you can call `security find-generic-password` and read the item without a prompt once the Keychain is unlocked. *(Inference from the default-trust sentence above; see §7.)*
- **Cost / offline / team:** free, offline, no team sharing (iCloud Keychain sync is for personal devices).

### 4.4 pass / gopass

- **pass:** "each password lives inside of a gpg encrypted file whose filename is the title of the website or resource". The store is `~/.password-store` and can be a git repo (`pass git push/pull`). Clipboard copies clear after 45 s. Licence is GPLv2+. Install with `brew install pass` ([passwordstore.org](https://www.passwordstore.org/)).
  - Risk: file and folder **names are not encrypted**, so entry names such as `work/prod-mongo` leak through the directory tree. *(Follows from the storage model on passwordstore.org.)*
- **gopass** (v1.17.3, 2026-09-22, MIT) is "a drop-in replacement for pass" built "for teams". It defaults to GPG + git and supports "fully offline on an air-gapped machine" ([README](https://github.com/gopasspw/gopass/blob/master/README.md)). Its age backend is still marked "experimental and the on-disk format likely to change" ([age backend](https://github.com/gopasspw/gopass/blob/master/docs/backends/age.md)).
  - `gopass env` carries an explicit warning: env injection "exposes those values to every process that can read `/proc/<pid>/environ` on Linux or `ps eww` on macOS". It offers `--stdin` or `--file` (ramdisk temp file) instead ([env command](https://github.com/gopasspw/gopass/blob/master/docs/commands/env.md)).
- **Team sharing:** multiple GPG recipients per store or sub-store (`gopass recipients`) ([README](https://github.com/gopasspw/gopass/blob/master/README.md)).

### 4.5 sops + age

- **sops** (v3.13.3, 2026-07-23; MPL-2.0; CNCF Sandbox since 2023) is "an editor of encrypted files that supports YAML, JSON, ENV, INI and BINARY formats" and works with KMS, age, and PGP ([README](https://github.com/getsops/sops/blob/main/README.rst)). By default it "encrypts all the values … and leaves the keys in cleartext", so git diffs stay readable ([common operations](https://github.com/getsops/docs/blob/main/content/en/docs/usage/common-operations/_index.md)).
- **Runtime use:** `sops exec-env file 'cmd'` passes values to a child's environment and never writes them to disk. `sops exec-file` passes them by FIFO by default; `--no-fifo` uses a temp file ([advanced usage](https://github.com/getsops/docs/blob/main/content/en/docs/usage/advanced/_index.md)).
- **age key location on macOS:** `$XDG_CONFIG_HOME/sops/age/keys.txt`, falling back to `~/Library/Application Support/sops/age/keys.txt`. It can be overridden with `SOPS_AGE_KEY_FILE`, `SOPS_AGE_KEY`, or `SOPS_AGE_KEY_CMD`. SSH `ssh-ed25519`/`ssh-rsa` keys also work as recipients and identities ([sops age](https://github.com/getsops/docs/blob/main/content/en/docs/usage/identities/age/_index.md)).
- **age** (v1.3.2, 2026-08-29; BSD-style licence) has post-quantum keys (`age-keygen -pq`) since v1.3.0 and supports passphrase-protected identity files. YubiKeys work through `age-plugin-yubikey` ([age README](https://github.com/FiloSottile/age/blob/main/README.md)). `age-plugin-se` stores the identity in the **Secure Enclave** behind Touch ID ([age-plugin-se](https://github.com/remko/age-plugin-se)).
- **Main risk:** `keys.txt` is a plaintext private key by default, and losing it means losing every secret. Also, encrypted files in git keep their history forever, so a compromised key exposes every past version.
- **Cost / offline / team:** free and fully offline. Teams share by listing multiple recipients in `.sops.yaml` `creation_rules`.

### 4.6 direnv + `.envrc` (v2.37.1)

- **Mechanism:** "Before each prompt it checks for the existence of an `.envrc` file … in the current and parent directories" and loads or unloads the environment. Hook it up by adding `eval "$(direnv hook zsh)"` at the end of `~/.zshrc` ([direnv man](https://github.com/direnv/direnv/blob/master/man/direnv.1.md); [hook docs](https://github.com/direnv/direnv/blob/master/docs/hook.md)).
- **Security model:** new or changed files are blocked until `direnv allow`. Without that, "any git repo that you pull … would be able to wipe your hard drive once you `cd` into it" ([direnv man](https://github.com/direnv/direnv/blob/master/man/direnv.1.md)). `source_env` targets are "not checked by the security framework" ([stdlib](https://direnv.net/man/direnv-stdlib.1.html)).
- **Secrets:** direnv is a *loader*, not a store. The recommended shape is an `.envrc` that holds no secrets and calls a store, such as `export X=$(op read op://…)` or `dotenv_if_exists .env.local` with a git-ignored file. *(Synthesis; direnv's docs give no guidance on secrets.)*
- **Risks:** values stay exported in the interactive shell for as long as you are in the directory, so every command you run there inherits them. A plaintext `.env` loaded by `dotenv` is plaintext on disk.

### 4.7 chezmoi templates (v2.72.2, MIT)

- **Mechanism:** "When chezmoi applies a template with a secret referenced from a password manager, it will automatically fetch the secret value and insert it into the generated destination file" ([password managers](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/password-managers/index.md)). Built-in functions cover 1Password (`onepasswordRead "op://…"`), Bitwarden (`bitwarden`, `bitwardenSecrets` for bws), Keychain (`keyring`), pass, gopass, and others ([1Password](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/password-managers/1password.md); [Bitwarden](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/password-managers/bitwarden.md); [Keychain](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/password-managers/keychain-and-windows-credentials-manager.md)). It also supports whole-file age encryption ([age](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/encryption/age.md)).
- **Fit with this repo:** chezmoi "generates the dotfile as a regular file in its final location" instead of symlinking. Its symlink mode "currently requires a bit of manual work" ([design FAQ](https://github.com/twpayne/chezmoi/blob/master/assets/chezmoi.io/docs/user-guide/frequently-asked-questions/design.md)). Adopting it would replace `links.conf` and `install`.
- **Main risk:** the rendered target file (for example `~/.gitconfig` with a token) is **plaintext on disk**.

---

## 5. Cross-cutting risks

| Risk | Mitigation | Source |
|---|---|---|
| Secret typed on the command line lands in `~/.zsh_history` | `setopt HIST_IGNORE_SPACE` + leading space; better, use prompt-style input (`security … -w` at end, `mongosh --password` with no argument) | [zsh options](https://zsh.sourceforge.io/Doc/Release/Options.html); [security.1](https://github.com/apple-oss-distributions/Security/blob/main/SecurityTool/macOS/security.1); [mongosh options](https://www.mongodb.com/docs/mongodb-shell/reference/options/) |
| Env vars inherited by all children and readable by same-user processes | Scope per command (`op run`, `sops exec-env`, `bws run --no-inherit-env`, `gopass env --stdin/--file`) instead of global `export` in `.zshrc` | [op run](https://www.1password.dev/cli/secrets-environment-variables); [gopass env](https://github.com/gopasspw/gopass/blob/master/docs/commands/env.md); [bws](https://bitwarden.com/help/secrets-manager-cli/) |
| Plaintext on disk | Prefer FIFO or no-disk paths (1Password mounted `.env`, `sops exec-file` default FIFO); if a file is unavoidable, use mode 0600 (`op inject` default) | [1P local .env](https://www.1password.dev/environments/local-env-file); [sops advanced](https://github.com/getsops/docs/blob/main/content/en/docs/usage/advanced/_index.md); [op inject](https://www.1password.dev/cli/reference/commands/inject) |
| Secret in argv (`ps`) | Pass secrets via env, stdin, or file rather than flags | [gopass env](https://github.com/gopasspw/gopass/blob/master/docs/commands/env.md) (describes the stdin/file alternatives) |
| Plaintext on-disk secret detection | 1Password Developer Watchtower flags unencrypted SSH keys and `.env` files with plaintext secrets | [1Password llms index → Watchtower](https://www.1password.dev/watchtower) |

---

## 6. Comparison table

| Tool | Keeps secrets out of git by… | zsh integration | Cost / licence | Offline | Team sharing | Main risks |
|---|---|---|---|---|---|---|
| Apple ssh-agent + Keychain | key file outside repo; passphrase in Keychain | `UseKeychain yes`, `AddKeysToAgent yes` in `~/.ssh/config` | Free, built in | Yes | No | Key file on disk; protected only by passphrase |
| 1Password SSH agent | key in vault; `agent.toml` holds names only | `IdentityAgent ~/.1password/agent.sock` | Paid; Individual $3.99/mo regular | Not verified (§7) | Vaults | "Approve for all apps" widens access; app must run |
| Bitwarden SSH agent | key in vault | `export SSH_AUTH_SOCK=…/.bitwarden-ssh-agent.sock` | Free tier exists; plan gating not verified | Not verified | Orgs/collections | v1 in maintenance-only mode (staff post) |
| Secretive | key never leaves Secure Enclave | `IdentityAgent <socket>` or `SSH_AUTH_SOCK` | Free, MIT | Yes | No | No backup/migration; ECDSA P-256 only |
| 1Password CLI | commit `op://` references | `op run --env-file`, `op inject`, shell plugins; Touch ID per tty | Paid | CLI: no (staff, forum); mounted `.env`: last-synced values | Vaults | Env inheritance; `--no-masking` output |
| Bitwarden `bw` | values stay in vault | `export BW_SESSION=$(bw unlock --raw)` | Free / Premium $1.65/mo | Local encrypted cache (limits unverified) | Orgs | `BW_SESSION` decrypts everything |
| Bitwarden `bws` | values in Secrets Manager | `bws run --no-inherit-env -- 'cmd'` | Free: 2 users, 3 projects, 3 machine accts | Not verified | Projects | Bootstrap `BWS_ACCESS_TOKEN` |
| Keychain `security` | values in login Keychain | `$(security find-generic-password -s x -w)` | Free | Yes | No | Scripts running as you can read without a prompt; `-w value` in history |
| pass / gopass | GPG/age-encrypted files, own git repo | `pass show x`, `gopass env --stdin` | Free, GPLv2+ / MIT | Yes | GPG recipients | Entry names unencrypted; GPG key management |
| sops + age | encrypted values committed **in** repo | `sops exec-env f.yaml 'cmd'` | Free, MPL-2.0 / BSD | Yes | Multiple recipients | Plaintext `keys.txt`; git history keeps old secrets forever |
| direnv | loader only; pair with a store | `eval "$(direnv hook zsh)"`, `direnv allow` | Free, MIT | Yes | n/a | Exported for whole dir session; plaintext `.env` |
| chezmoi | templates call a store at apply time | `chezmoi apply` | Free, MIT | Depends on store | Depends on store | Rendered files are plaintext; replaces symlink model |

---

## 7. Open questions / could not settle

- **1Password CLI offline.** No first-party doc states it. The only statements are 2022/2023 staff forum posts saying no offline mode ([thread](https://www.1password.community/discussions/developers/cli-offline-mode/88158)). Whether 2.39.0 changed this is unknown. The same gap applies to the **SSH agent offline**: no doc found.
- **1Password Teams/Business pricing and plan gating for SSH agent and CLI.** Pricing pages only returned Individual and Families figures.
- **Bitwarden SSH agent plan tier** (Free vs Premium) and the first version that shipped it. A search hinted at desktop 2025.1.2, but no primary doc confirmed it.
- **`bw` and `bws` offline limits.** `bw` says vault data is "cached locally", but the docs do not say whether `bw get` works with no network after unlock. `bws` state stores authentication, not secrets, as far as the docs say.
- **direnv `require_allowed`.** The stdlib docs say it needs "direnv >= 2.38.0", but the newest tag and Homebrew version is 2.37.1 (2025-07-20). The docs appear ahead of the release.
- **Keychain ACL for `security`-created items.** The man page says the creating app is trusted by default. I did not find an Apple doc that confirms whether `security` counts as that app for every caller. It is inferred, not tested.
- **mongosh env-var URI.** No doc says mongosh reads a URI from an env var itself; the patterns above expand it in the shell.
- **Secretive socket path.** The path comes from the community config repo. The app's source uses a computed `URL.socketPath` that I did not trace to a literal string.

---

## 8. Fits for a solo dev dotfiles repo (synthesis, not sourced fact)

> This section is my judgment, built on the facts above.

- **Biggest win, lowest effort:** replace the global `export` lines in `~/.zshrc-secrets` with per-command resolution. With no paid tools, store each token in the Keychain (`security add-generic-password … -w`) and wrap tools in small zsh functions such as `jira() { JIRA_API_TOKEN=$(security find-generic-password -s jira -w) command jira "$@"; }`. That keeps the repo's current structure and removes the "every process inherits every token" exposure.
- **SSH:** if you already pay for 1Password, use its agent and commit a `~/.ssh/config` with `Include ~/.ssh/config.local` at the top plus `IdentityAgent ~/.1password/agent.sock`. If you don't, **Secretive** gives the strongest key protection for free; register one key per Mac with GitHub. Either way, add `~/.ssh/config` to `links.conf` and keep private hosts in the untracked include.
- **MongoDB:** save URIs **without** passwords, let mongosh prompt, set `redactHistory: remove-redact`, and never use Compass export without `--passphrase`.
- **sops + age** makes sense only if you want encrypted secrets to travel *with* the repo to new machines. Protect the identity with `age-plugin-se` or a passphrase. Otherwise the Keychain or a password manager is simpler.
- **Skip chezmoi** unless you plan to abandon the `links.conf` symlink model; it's a migration, not an add-on.
- **Add `setopt HIST_IGNORE_SPACE`** regardless of the tool you choose.
