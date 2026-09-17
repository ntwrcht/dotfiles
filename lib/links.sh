# shellcheck shell=bash
# Shared manifest reader for install / uninstall / doctor.
#
# Requires DOTFILES_DIR to be set by the calling script.

# for_each_link <callback>
#
# Invokes <callback> once per entry in links.conf with two arguments:
#   $1 — absolute source path inside the repo
#   $2 — absolute target path under $HOME
for_each_link() {
  local callback="$1"
  local src dst

  while read -r src dst _; do
    [[ -z "$src" || "$src" == \#* ]] && continue
    "$callback" "${DOTFILES_DIR}/${src}" "${HOME}/${dst}"
  done < "${DOTFILES_DIR}/links.conf"
}

# display_path <absolute path> — abbreviates $HOME to ~ for output.
display_path() {
  printf '%s' "${1/#$HOME/~}"
}
