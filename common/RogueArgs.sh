#!/bin/bash
#
#
#

version_tag="1.0"
version=''
help=''
#debug=false
flags=( "h:help"
        "d:debug"
        "v:version"
        )
#"s":"silent" "strict"
#"q":"quiet"
#set -euo pipefail
IFS=$'\n\t'
parent_name="${script_name:-$(basename $(caller))}"
parent_dir="${script_dir:-$(realpath dirname caller)}"
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
  if [ -z "${debug}" ] || [ "${debug}" = false ] && return
  caller=$(caller)
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
  if [ "$#" -gt 0 ]; then #if [ ! -z "${@}" ]; then
    echo "RogueDebugger[$caller]>>> ${@}"
  fi

  #TODO if you want a more advanced tab completion use this low level approach
  # https://stackoverflow.com/a/77567693
  while IFS="" read -r -e -d $'\n' -p "RogueDebugger[$caller]<<< " response; do 
    history -s "$response"
    case "$response" in
      [Dd][Oo][Nn][Ee]|[Cc][Oo][Nn][Tt][Ii][Nn][Uu][Ee]|[Nn][Ee][Xx][Tt]|[Ss][Tt][Ee][Pp]|'')
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
      ::*) # this will print the value bare
        eval "echo \$${response:2}"
        ;;
      :*) # this will print the value
        eval "echo \"\$${response:1}\""
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
    --*=*)
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
  header "Debug set to $debug"
  [ "$debug" = 'all' ] && debug=true
  [ "$debug" = true ] || [ "$debug" = 'verbose' ] && RogueArgs_xtrace=true && set -x
  [ "$debug" = true ] || [ "$debug" = 'error' ] && set -e
  [ "$debug" = true ] || [ "$debug" = 'trace' ] && set -o history
  [ "$debug" = true ] || [ "$debug" = 'break' ] || [ "$debug" = 'breakpoints' ] && echo "breakpoints on"
fi
if [ ! -z "$strict" ]; then
        [ "$strict" = true ] && header "Mode set to strict" && set -euo pipefail
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
