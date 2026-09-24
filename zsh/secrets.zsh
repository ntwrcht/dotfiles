# Tools that need a credential get it from Keychain per call (bin/secret),
# so no token is exported into every shell. One line per tool; add with
# `secret add NAME`. These exist only in interactive zsh — anything launched
# from nvim, tmux bindings, or scripts must call `secret run` itself.
jira()  { secret run JIRA_API_TOKEN -- jira "$@"; }
codex() { secret run OPENAI_API_KEY -- codex "$@"; }
