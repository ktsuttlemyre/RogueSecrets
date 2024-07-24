#!/bin/bash

# https://superuser.com/questions/248389/list-open-ssh-tunnels

case $cmd;
  ssh )
    case $arg;
      outgoing )
      #list
      sudo lsof -i -n | egrep '\<ssh\>'
    ;;
      incoming )
      sudo lsof -i -n | egrep '\<sshd\>
    ;;
    esac
 ;;
esac
