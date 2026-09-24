# Completion for bin/sshm: subcommands, then host names for the ones that
# take a host. `ssh <Tab>` already completes the same names from ~/.ssh.
_sshm() {
  if (( CURRENT == 2 )); then
    local -a cmds=(
      'ls:list hosts' 'add:add a host' 'show:print settings'
      'rm:remove a host' 'test:check key login' 'key:install public key'
    )
    _describe command cmds
  elif (( CURRENT == 3 )) && [[ $words[2] == (show|rm|test|key) ]]; then
    local -a hosts=(${(f)"$(sshm names 2>/dev/null)"})
    _describe host hosts
  else
    _default
  fi
}
compdef _sshm sshm
