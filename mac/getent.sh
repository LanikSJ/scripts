#!/usr/bin/env bash
# shellcheck disable=SC2003,SC2046,SC2059,SC2155,SC2220

# Icons
USER_ICON="👤"
GROUP_ICON="👥"
HOST_ICON="🌐"
INFO_ICON="ℹ️"
ERROR_ICON="❌"

export PRGNAME=$(basename "$0" .sh)

ShowSyntax ()
{
  printf "${INFO_ICON} $PRGNAME lists UNIX file databases\n" 
  printf "Syntax:\n"
  printf -- "  $PRGNAME passwd [ USERNAME ...  ] ${USER_ICON}\n"
  printf -- "  $PRGNAME group  [ GROUPNAME ... ] ${GROUP_ICON}\n"
  printf -- "  $PRGNAME hosts  [ HOSTNAME ... ] ${HOST_ICON}\n" 
  printf -- "  -h          -- Shows this help\n"
}

ListPasswd ()
{
  # Define the awk script once to avoid duplication
  local awk_script="
    /NFSHomeDirectory/ {h=\$2}
    /Password/ {p=\$2}
    /PrimaryGroupID/ {g=\$2}
    /RealName/ {n=\$2}
    /RecordName/ {u=\$2}
    /UniqueID/ {i=\$2}
    /UserShell/ {s=\$2}
    END {print u \":\" p \":\" i \":\" g \":\" n \":\" h \":\" s}
  "
  
  if [ -n "$1" ]; then
    # Process specific users
    for username in "$@"; do
      dscl . -read /Users/"$username" 2>/dev/null | awk "$awk_script" || \
        echo "${ERROR_ICON} User $username not found" >&2
    done
  else
    # Process all users
    for username in $(dscl . -list /Users); do
      dscl . -read /Users/"$username" 2>/dev/null | awk "$awk_script"
    done
  fi
}

ListGroup ()
{
  # Define the awk script once to avoid duplication
  local awk_script="
    /RecordName/ {n=\$2}
    /PrimaryGroupID/ {i=\$2}
    /Password/ {p=\$2}
    /RealName/ {n=\$2}
    /GroupMembership/ {
      \$1=\"\"; 
      u=\"\";
      for(j=1; j<=NF; j++) {
        if (\$j != \"\") {
          u = (u == \"\") ? \$j : u \",\" \$j;
        }
      }
    }
    END {print n \":\" p \":\" i \":\" u}
  "
  
  if [ -n "$1" ]; then
    # Process specific groups
    for groupname in "$@"; do
      dscl . -read /Groups/"$groupname" 2>/dev/null | awk "$awk_script" || \
        echo "${ERROR_ICON} Group $groupname not found" >&2
    done
  else
    # Process all groups
    for groupname in $(dscl . -list /Groups); do
      dscl . -read /Groups/"$groupname" 2>/dev/null | awk "$awk_script"
    done
  fi
}

ListHost ()
{
  if [ -n "$1" ]; then
    # Process specific hosts
    for hostname in "$@"; do
      grep -iw "$hostname" /etc/hosts || \
        echo "${ERROR_ICON} Host $hostname not found in /etc/hosts" >&2
    done
  else
    # Process all hosts - properly filter out comments and empty lines
    grep -v "^#" /etc/hosts | grep -v "^[[:space:]]*$"
  fi
}

if [ -n "$1" ]
then
  while getopts :h OPT "$@"
  do
    case "$OPT" in
    (h) ShowSyntax >&2
      exit 0
      ;;
    esac
  done
  shift $((OPTIND - 1))
  
  if [ -n "$1" ]
  then
    # Process lines
    case "$1" in
      (pa*) shift
        ListPasswd "$@"
        ;;
      (gr*) shift
        ListGroup "$@"
        ;;
      (ho*) shift
        ListHost "$@"
        ;;
    esac
  else
    printf "${ERROR_ICON} $PRGNAME: Too few arguments!\n" >&2
    exit 2
  fi
else
  printf "${ERROR_ICON} $PRGNAME: Too few arguments!\n" >&2
  exit 2
fi
