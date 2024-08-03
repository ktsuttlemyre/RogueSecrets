#!/bin/bash
#
#
RogueArgs=("$@")
#simple debugger for this script only
console () {
 :;
}
if [[ " ${*} " =~ [[:space:]]--RogueArgs_debug[[:space:]] ]]; then
  console () {
    echo "$@"
  }
fi

console "Number of arguments received $#"
_sessionenv=$((set -o posix ; set)| cut -f1 -d= | tr '\0' '\n' | sort | egrep ^[[:alnum:]]) # IF=$'\n' or anythong else with a \n tends to fuck up filtering so the sort | egrep helps get it cleaner
sessionenv () {
  [ "$1" == 'all' ] && (set -o posix ; set) && return 0
  echo "$(set -o posix ; set | sort | uniq)" | grep "=" | egrep -ve "$(printf '^%s=*$|' $_sessionenv)g"
}
#fix file seperator
#IFS=$'\n\t'

parent_name="${script_name:-$(basename $(caller |  cut -d " " -f 2))}"
parent_dir="${script_dir:-$(realpath $(dirname $(caller | cut -d " " -f 2 )))}"
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
script_name=$(basename "$0")
if ! ( (return 0 2>/dev/null) && true || false); then
        echo "This script is expected to be sourced. Please use . or source commands to call $script_name from ${parent_name:-parent}"
        exit 1
fi

#prerequsite checks
[ -z "${version_tag}" ] && echo "Please add a version_tag variable to your $parent_name" && exit 0
[ -z "${help}" ] && [ ! -f "$parent_dir/README.md" ] && echo "Please add a help variable to your script or a $parent_dir/README.md" && exit 0

#varaibles
flags=( "h:help"
        "d:debug"
        "v:version"
        )
#"s":"silent" "strict"
#"q":"quiet"
        
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

#####################
#  Helper Functions
#####################
header () {
 echo -e "Rogue[${parent_name}]  $1"
}

# print private session variables 
sessionenv () { (set -o posix ; set) }

debugger () {
  set +x
  #state restore
  #TODO add shopt 
  # https://unix.stackexchange.com/questions/310957/how-to-restore-the-value-of-shell-options-like-set-x
  if [ ! -z "$RogueArgs_xtrace" ]; then
    setstate="$(set +o)"$'\nset -o xtrace'
  else
    setstate="$(set +o)" 
  fi
  set +euo pipefail
  
  #set variables to use
  caller=$(caller)
  
  #send output
  if [ "$#" -gt 0 ]; then #if [ ! -z "${@}" ]; then
    lines="$(echo "${@}" | wc -l)"
    if [ "$lines" -gt 5 ]; then 
            echo -e "RogueDebugger[$caller]>>> [ Start DocVar : $lines ] \n -----------------------------------" >> ${RogueArgs_debug_output:-/dev/stderr}
            echo "${@}" >> ${RogueArgs_debug_output:-/dev/stderr}
            echo -e " -----------------------------------\nRogueDebugger[$caller] [ End DocVar : $lines ]" >> ${RogueArgs_debug_output:-/dev/stderr}
    else
            echo "RogueDebugger[$caller]>>> ${@}" >> ${RogueArgs_debug_output:-/dev/stderr}
    fi
  fi
  # if it isn't interactive then reset bash set state flags and exit
  if [ ! -z "${RogueArgs_debug_output}" ]; then
    eval "$setstate"
    return 
  fi
  
  #interative debug
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
      :json:*)
        name="${response:6}"
        name="${name:@}"
        if[[ "$name" != [[:alpha:]]* ]]; then
          eval "printf '%s\n' \"\${${name}}\" | jq -R . | jq -s ."
        else
          #docker run --rm -i ghcr.io/jqlang/jq:latest < <(echo '{"version":5778}') '.version'
          eval "printf '%s\n' \"\${${name}[@]}\" | jq -R . | jq -s ."
          #eval "printf '%s\n' \${${name}[@]} | jq -R . | jq -s ."
          #Example
          #X=("hello world" "goodnight moon")
          #printf '%s\n' "${X[@]}" | jq -R . | jq -s .
        fi
        ;;
      ::*) # this will print the value bare
        name="${response:2}"
        if [[ "$(declare -p ${name})" =~ "declare -a" ]]; then
            echo -n "RogueDebugger[Type:Array]>>> "
            eval "echo \${${name}[@]}"
        else
            echo -n "RogueDebugger[Type:String]>>> "
            eval "echo \$${name}"
        fi
        ;;
      :*) # this will print the value
        name="${response:1}"
        if [[ "$(declare -p ${name})" =~ "declare -a" ]]; then
            echo -n "RogueDebugger[Type:Array]>>> "
            eval "echo \"\${${name}[@]}\""
        else
            echo -n "RogueDebugger[Type:String]>>> "
            eval "echo \"\$${name}\""
        fi
        ;;
      *)
        eval "$response"
        ;;
    esac 
  done
  eval "$setstate"
}

assign_keyvalue () {
    section="$1"; key="$2"; value="$3"
    #handle single variable assignements
    # (defaults to non existant variable or true means it flag exists and may have multiple values)
    if [ -z "$key" ];then #if it doesnt exist then make it
      console "declaring ${key}=${value}"
      delare -g ${key}="${value}"
    else  #if it exitsts then make it true and add values to args_${key} and args${section}_${key}
      console "declaring ${key}=true"
      declare -g ${key}=true
    fi
    if [ "$value" != true ]; then
      if [ -z "arg${section}_${key}" ]; then
        console "declaring arg${section}_${key}=${value}"
        declare -g arg${section}_${key}="${value}"
      else
        console "declaring arg${section}_${key}=true"
        declare -g arg${section}_${key}=true
      fi
      #handle multiple values and add to sections
      name=args_$key
      console "Handling argument arrays"
      console "declaring args_${key} && args${section}_${key}"
      [ -z "${!name+xxx}" ] && declare -ag args_${key} && declare -ag args${section}_${key}
      console "pushing key/value [$key] and [$value] to args_${key} and args${section}_${key}"
      eval "args_${key}+=('$value'); args${section}_${key}+=('$value')"
    fi
}

positional_args=()
while [[ $# -gt 0 ]]; do
  section="${#positional_args[@]}"
  console "parsing flag $1 in section args${section}"
  case $1 in
    --?*=*)
      IFS='=' read -r key value <<< "${1:2}"
      assign_keyvalue "$section" "$key" "$value"

      shift # past key=value
      ;;
    --?*)
      #if value doesn't start with - then assume true value
      key=${1:2}
      value=true
      shift # past key
      if [ ! -z "$2" ] || [[ ! ${2} == ^- ]]; then
        value="${2}"
        shift # past value
      fi
      assign_keyvalue "$section" "$key" "$value"
      ;;
    -?) #todo fix flags maybe
      found=false
      for entry in "${flags[@]}" ; do
          flag="${entry%%:*}"; arg="${entry##*:}"
          if [ "$1" = "$flag" ]; then
            assign_keyvalue "$section" "$arg" true; found=true
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
console "======== All arguments parsed ========"
console "number of arguments now $#"
console "values for arguments $@"
console "will now be set to ${positional_args[@]}"
set -- "${positional_args[@]}" # restore positional parameters
console "======== Arguments reset ========"
console "number of arguments now $#"
console "values for arguments $@"
console "moving on to standard flags"
[ ! -z "${version}" ] && echo "$version_tag" && exit 0
console "debug flag set to ${debug}"
set_flags=''
if [ ! -z "${debug}" ]; then
  header "Debug set to ${args_debug[@]}"
  for entry in "${args_debug[@]}"; do
          console "debug entry = $entry"
          [ -f "$entry" ] && RogueArgs_debug_output="$entry"
          [ "$entry" = "all" ] || [ "$entry" = 'verbose' ] || [ "$entry" = 'xtrace' ] && RogueArgs_xtrace=true && set_flags+=$'set -x\n'
          [ "$entry" = "all" ] || [ "$entry" = 'error' ] && set_flags+=$'set -e\n'
          [ "$entry" = "all" ] || [ "$entry" = 'trace' ] || [ "$entry" = 'history' ] && set_flags+=$'set -o history\n'
          [ "$entry" = "all" ] || [ "$entry" = 'break' ] || [ "$entry" = 'breakpoints' ] && echo "breakpoints on"
          [ "$entry" = 'stdout' ] && RogueArgs_debug_output=/dev/stdout && echo "logging debug to stdout"
          [ "$entry" = 'stderr' ] && RogueArgs_debug_output=/dev/stderr && echo "logging debug to stderr"
  done
else
  debugger () { :; } # disable debugger
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
set_flags=$(echo "$set_flags" | sort | uniq )
$set_flags
:;

