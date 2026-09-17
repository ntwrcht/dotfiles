# shellcheck shell=bash
# shellcheck disable=SC2034  # every CL_* is consumed by the scripts that source
                            # this file; shellcheck cannot see across `source`.
# Terminal colours, as real escape sequences ($'...' rather than literal
# backslashes) so callers can print them with %s instead of %b — which is what
# kept every log helper in this repo tripping shellcheck's SC2059.
#
# Colour is disabled, and every variable set to the empty string, when:
#   - NO_COLOR is set (https://no-color.org), or
#   - stdout is not a terminal (piped, redirected, or running in CI).
# Callers interpolate unconditionally; the values simply vanish.

if [[ -n "${NO_COLOR:-}" ]] || [[ ! -t 1 ]]; then
  CL_RED=''
  CL_GREEN=''
  CL_YELLOW=''
  CL_BLUE=''
  CL_MAGENTA=''
  CL_CYAN=''
  CL_BOLD=''
  CL_RESET=''
else
  CL_RED=$'\033[0;31m'
  CL_GREEN=$'\033[0;32m'
  CL_YELLOW=$'\033[0;33m'
  CL_BLUE=$'\033[0;34m'
  CL_MAGENTA=$'\033[0;35m'
  CL_CYAN=$'\033[0;36m'
  CL_BOLD=$'\033[1m'
  CL_RESET=$'\033[0m'
fi
