#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2068,SC2317,SC2157

__SSH="/usr/local/bin/ssh"

on() {
  
  [[ -z "VTE_VERSION" ]] && return
  [[ -p /dev/stdout ]] && return
  echo "$1"

  host="$1"
  case "${host}" in
  *-*[0-9][0-9]*-dev*)
    echo -ne "\033]11;#4a4204\007"
    ;;
  *-*[0-9][0-9]*-*)
    echo -ne "\033]11;#3d0303\007"
    ;;
  *)
    echo -ne "\033]11;#033d08\007"
    ;;
  esac
}

if [ -n "VTE_VERSION" ]; then
  trap off EXIT ERR INT TERM
  while getopts ":1246AaCfgKkMNnqsTtVvXxYyb:c:D:E:e:F:I:i:J:L:l:m:O:o:p:Q:R:S:W:w:" Option; do
    :
  done
  server=$(eval echo "$"$OPTIND)
  OPTIND=1;
  server=$(echo "$server" | cut -d'@' -f2-)
  [[ -n "$server" ]] && on "$server"
fi

$__SSH $@
exit $?
