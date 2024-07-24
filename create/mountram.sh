#!/bin/bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#set -a      # turn on automatic exporting
source "$(dirname $script_dir)/env"
[ -f "$host_wd/env" ] && source "$host_wd/env"
#set +a      # turn off automatic exporting

ramdisk="${1}"
if [ "$linux_distro" = "mac" ]; then
  #https://superuser.com/questions/1480144/creating-a-ram-disk-on-macos
  #brew install entr
  if [ ! -d $ramdisk ]; then
    diskutil apfs create $(hdiutil attach -nomount ram://8192) RogueOSRam && touch $ramdisk/.metadata_never_index
  fi
else
  if [ ! -d /Volumes/RogueOSRam ]; then
    mount tmpfs <mountpoint> -t tmpfs -o size=.25G
  fi
fi
