#!/bin/bash
#
#
#

version_tag="1.0"
version=''
help=''
debug=false
flags=( "h:help"
        "d:debug"
        "v:version"
        )
        
#set -euo pipefail
IFS=$'\n\t'
parent_name="$script_name"
parent_dir="$script_dir"
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
script_name=$(basename "$0")
(return 0 2>/dev/null) && sourced=true || sourced=false
if ! $sourced; then
        echo "This script is expected to be sourced. Please use . or source commands to call $script_name"
fi
# https://stackoverflow.com/questions/65349069/testing-whether-stdin-is-a-file-vs-a-pipe-vs-a-tty
is_interactive () { [[ $- == *i* ]]; }
is_stdin_redirected () { [[ $- == *s* ]]; }
#TODO figure how to use stat properly
if [ -f /dev/stdin ]; then
  is_stdin="file"
elif [ -p /dev/stdin ]; then
  is_stdin="pipe"
else # stat -f %HT == Character Device
  is_stdin=false
fi

#functions
header () {
 echo -e "Rogue[${parent_name}]  $1"
}

debugger () {
  #state restore
  #TODO add shopt 
  # https://unix.stackexchange.com/questions/310957/how-to-restore-the-value-of-shell-options-like-set-x
  if [ ! -z "$RogueArgs_xtrace" ]; then
    set +x
    setstate="$(set +o)"$'\nset -o xtrace'
  else
    setstate="$(set +o)" 
  fi
  set +euox pipefail
  if [ ! -z "${@}" ]; then
    echo "RogueDebugger[${parent_name}]:::${@}"
  fi
  while true; do
    read -r -p "RogueDebugger>>> " response
    case "$response" in
      [Dd][Oo][Nn][Ee]|[Cc][Oo][Nn][Tt][Ii][Nn][Uu][Ee]|'')
        eval "$setstate"
        return 0
        ;;
      [Ee][Xx][Ii][Tt])
        eval "$setstate"
        exit 1
        ;;
      [Bb][Rr][Aa][Kk][Ee])
        eval "$setstate"
        return 1
        ;;
      *)
        eval "$response"
        ;;
    esac 
  done
  eval "$setstate"
}

positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --*=)
      IFS='=' read -r key value <<< "${1:2}"; export ${key}="${value}"; shift ;;
    --*)
      #if value doesn't start with -
      if [ -z "$2" ] || [[ ${2} == ^- ]]; then
        export ${1:2}=true
        shift # past argument
      else
        export ${1:2}="${2}"
        shift # past argument
        shift # past value
      fi
      ;;
    -[:alnum:]) #todo fix flags maybe
      found=false
      for entry in "${flags[@]}" ; do
          flag="${entry%%:*}"; arg="${entry##*:}"
          if [ "$1" = "$flag" ]; then
            set -- "--$arg" "${@:1}"; found=true
            break
          fi
      done
      [ "$found" != true ] echo "flag [$1] is not a valid flag"; exit 1
      ;;
    *)
      positional_args+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done
set -- "${positional_args[@]}" # restore positional parameters
[ ! -z "${version}" ] && echo "$version_tag" && exit 0
if [ ! -z "${debug}" ];then
  [ "$debug" = true ] && header "Debug set to true" && RogueArgs_xtrace=true && set -xe
  #other debug values parse here
  [ "$debug" = 'strict' ] && header "Debug set to strict" && set -euo pipefail
fi
if [ ! -z "${help}"]; then
  #todo make readme case insensitive
  if [ -f $script_dir/README.md ]; then
    # if glow exists then use that
    if command -v glow &> /dev/null; then
      glow "$script_dir/README.md"
    else
      cat "$script_dir/README.md"
    fi
  else
    tail -n +1 $script_dir/$script_name | sed '/^#/!q'
  fi
exit 0;
fi
:;

# echo "FILE EXTENSION  = ${EXTENSION}"
# echo "SEARCH PATH     = ${SEARCHPATH}"
# echo "DEFAULT         = ${DEFAULT}"
# echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)

# if [[ -n $1 ]]; then
#     echo "Last line of file specified as non-opt/last argument:"
#     tail -1 "$1"
# fi
# EOF
