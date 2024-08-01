#!/bin/bash
# more info https://github.com/jqlang/jq

if command -v apt &> /dev/null; then
  sudo apt install -y jq
elif command -v dnf &> /dev/null; then
  sudo dnf install jq
elif command -v zypper &> /dev/null; then
  sudo zypper install jq
elif command -v pacman &> /dev/null; then
  sudo pacman -S jq
elif command -v brew &> /dev/null; then
  brew install jq
elif command -v port &> /dev/null; then
  port install jq
elif command -v fink &> /dev/null; then
  fink install jq
elif command -v pkgutil &> /dev/null; then
  pkgutil -i jq
elif command -v winget &> /dev/null; then
  winget install jqlang.jq
elif command -v scoop &> /dev/null; then
  scoop install jq
elif command -v choco &> /dev/null; then
  choco install jq
else
    pkg install jq as root installs a pre-built binary package.
    make -C /usr/ports/textproc/jq install clean
fi
