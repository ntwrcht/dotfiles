# Tools that need a credential get it from Keychain per call (bin/secret),
# so no token is exported into every shell. One line per tool; add with
# `secret add NAME`. These exist only in interactive zsh — anything launched
# from nvim, tmux bindings, or scripts must call `secret run` itself.
# jira needs no wrapper: jira-cli reads its token from Keychain itself
# (service "jira-cli", account = your Jira login), so it works everywhere.
codex() { secret run OPENAI_API_KEY -- codex "$@"; }

# `mdb <Tab>` completes stored environments one path segment at a time
# (mongo/shop/prod → `shop/` then `prod`); later words fall back to files.
_mdb() {
  if (( CURRENT == 2 )); then
    local -a envs
    envs=(${(f)"$(mdb 2>/dev/null)"})
    _multi_parts / envs
  else
    _default
  fi
}
compdef _mdb mdb
