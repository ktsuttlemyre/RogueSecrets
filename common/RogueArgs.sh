#!/bin/bash
#
#
#

version_tag="1.0"
debug=false
flags=( "h:help"
        "d:debug"
        "v:version"
        )

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
script_name=$(basename "$0")
# https://stackoverflow.com/questions/65349069/testing-whether-stdin-is-a-file-vs-a-pipe-vs-a-tty
is_interactive () { [[ $- == *i* ]]; }
is_stdin_redirected () { [[ $- == *s* ]]; }
if [ -f /dev/stdin ] || [[ stat -f %HT == *"Regular"* ]] ; then
  is_stdin="file"
elif [ -p /dev/stdin ] || [[ stat -f %HT == *"Fifo"* ]]; then
  is_stdin="pipe"
else # stat -f %HT == Character Device
  is_stdin=false
fi

positional_args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --*=)
      IFS='=' read -r key value <<< "$1"; ${!key#??}="${value}"; shift ;;
    --*)
      #if value doesn't start with -
      if [[ ! ${2} =~ ^- ]]; then
        ${!1}="${2}"
        shift # past argument
        shift # past value
      else
        ${!1}=true
        shift # past argument
      fi
      ;;
    -[:alnum:])
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
[ "$version" = true ] echo "$version_tag"; exit 0
if ! [ -z "${debug}" ];then
  [ "$debug" = true ] set +x
  #other debug values parse here
fi
[ "$help" = true ]; tail -n +1 $script_dir/$script_name | sed '/^#/!q'; exit 0

echo "FILE EXTENSION  = ${EXTENSION}"
echo "SEARCH PATH     = ${SEARCHPATH}"
echo "DEFAULT         = ${DEFAULT}"
echo "Number files in SEARCH PATH with EXTENSION:" $(ls -1 "${SEARCHPATH}"/*."${EXTENSION}" | wc -l)

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
fi
EOF
