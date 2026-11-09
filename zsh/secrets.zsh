# Tools that need a credential get it from Keychain per call (bin/secret),
# so no token is exported into every shell. One line per tool; add with
# `secret add NAME`. These exist only in interactive zsh — anything launched
# from nvim, tmux bindings, or scripts must call `secret run` itself.
# jira needs no wrapper: jira-cli reads its token from Keychain itself
# (service "jira-cli", account = your Jira login), so it works everywhere.
codex() { secret run OPENAI_API_KEY -- codex "$@"; }

# `mdb <Tab>` and `mydb <Tab>` complete stored environments one path segment
# at a time (mongo/shop/prod → `shop/` then `prod`); later words use files.
_db_envs() {
  if (( CURRENT == 2 )); then
    local -a envs
    envs=(${(f)"$($words[1] 2>/dev/null)"})
    _multi_parts / envs
  else
    _default
  fi
}
compdef _db_envs mdb mydb

# `secret <Tab>` completes subcommands; get, has, rm and run then complete
# stored names from `secret ls`, and `run ... -- <Tab>` completes a command.
_secret() {
  if (( CURRENT == 2 )); then
    local -a subs=(
      'add:create or update a secret'
      'get:print a value'
      'has:exit 0 if a secret exists'
      'ls:list stored names'
      'rm:delete a secret'
      'run:run a command with secrets in its env'
    )
    _describe -t commands 'secret command' subs
    return
  fi
  # After `run NAME... --`, complete the command as if typed on its own.
  if [[ $words[2] == run ]]; then
    local sep=${words[(i)--]}
    if (( sep < CURRENT )); then
      words=("${(@)words[sep+1,-1]}")
      (( CURRENT -= sep ))
      _normal
      return
    fi
  fi
  # `ls -l` prints "NAME  DESC"; names have no spaces, so split at the first.
  # `run` skips names that aren't valid env vars or are already on the line.
  setopt localoptions extendedglob
  local line name desc
  local -a names
  for line in ${(f)"$(secret ls -l 2>/dev/null)"}; do
    name=${line%% *}
    if [[ $words[2] == run ]]; then
      [[ $name == [A-Za-z_][A-Za-z0-9_]# ]] || continue
      (( ${words[(Ie)$name]} )) && continue
    fi
    desc=${${line#$name}##[[:space:]]#}
    names+=("$name${desc:+:$desc}")
  done
  case $words[2] in
    get|has)
      (( CURRENT == 3 )) && _describe -t names 'secret' names ;;
    rm)
      if (( CURRENT == 3 )); then
        compadd -- -f
        _describe -t names 'secret' names
      elif (( CURRENT == 4 )) && [[ $words[3] == -f ]]; then
        _describe -t names 'secret' names
      fi ;;
    run)
      (( CURRENT > 3 )) && compadd -- --
      _describe -t names 'secret' names ;;
  esac
}
compdef _secret secret
