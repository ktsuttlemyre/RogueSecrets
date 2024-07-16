#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_NAME=$(basename "$0")
: > ${SCRIPT_DIR}/${SCRIPT_NAME}.prompt.history
prompt() {
  unattended_mode='no'
  message="$1"
  key="$2"
  yn=''
  while true; do
    if [ "$unattended_mode" = 'yes' ]; then
    echo "unattended"
      yn="$3"
    elif [ -z "$yn" ]; then
      if ! [ -z "$2" ] && ! [ -z "${!2}" ]; then
        echo "secondary "
        yn="${!2}"
        unattended_mode='yes'
      else
        read -p "$message " yn
      fi
    fi
      case $yn in
          [Yy][Ee][Ss]* )
            _prompt_history "$key" "$yn"
            return ;;
          [Nn][Oo]* )
            _prompt_history "$key" "$yn"
            return 1 ;;
          [Cc][Aa][Nn][Cc][Ee][Ll]* )
            _prompt_history "$key" "$yn"
            return 2 ;;
          [Ee][Xx][Ii][Tt]* )
            echo "user exit"
            _prompt_history "$key" "$yn"
            exit 0 ;;
          '' )
            #if theres a default value then use it
            if ! [ -z "$3" ]; then
              unattended_mode='yes'
            fi
            ;;
          * )
          echo "Please answer yes, no, cancel or exit."
          #check if we got the answer from\tan env var
          yn=''
          unset yn
          if [ "$unattended_mode" = 'yes' ]; then
            echo "Invalid response."
            echo "    $2=${!2}"
            echo "Program exiting now"
            exit 1
          fi
          ;;  
      esac
  done
}
_prompt_history() {
  echo "$1=$2"$'\n' >> ${SCRIPT_DIR}/${SCRIPT_NAME}.prompt.history
}
