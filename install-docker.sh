#!/bin/bash
script_name=$(basename "$0")
(return 0 2>/dev/null) && sourced=true || sourced=false
if ! $sourced; then
 script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
 source "$script_dir/env"
fi

function header () {
 echo -e "RogueSecrets[${script_name}]  $1"
}

header "Installing libs..."
if [ -f /etc/os-release ]; then
  source /etc/os-release
else
  header "Can't find /etc/os-release"
  exit 1
 fi
  
linux_distro=false
[ -z ${ID+x} ] && ID="$(uname -s)"

case "$ID" in
  raspbian) linux_distro="raspbian" ;;
  ubuntu) linux_distro="ubuntu" ;;
  arch) linux_distro="arch" ;;
  centos) linux_distro="centos" ;;
  Darwin*) linux_distro="mac" ;;
  steamos) linux_distro="steamos" ;;
  *) echo "This is an unknown distribution. Value observed is $ID";;
esac

if [ ! "$linux_distro" = "mac" ]; then
  processor_arch='arm'
  processor_bits='32'
  case $(uname -m) in
      i386)   processor_arch="x86"; processor_bits="32" ;;
      i686)   processor_arch="x86"; processor_bits="32" ;;
      x86_64) processor_arch="x86"; processor_bits="64" ;;
      arm)    dpkg --print-architecture | grep -q "arm64" && processor_arch="arm" && processor_bits="64" ;;
  esac
fi


header "Confirmed installing docker and compose on $linux_distro on processor type $processor_arch"


header "Remove docker and install official build'
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
#add repo
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo mkdir -p /etc/apt/keyrings
REPO="$linux_distro" #known values are rasbian and ubuntu others expected to work based on the $linux_distro var detemined from /etc/os-release #ID var
curl -fsSL https://download.docker.com/linux/$REPO/gpg | sudo gpg --dearmor --yes --output /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$REPO \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

header 'installing docker'
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo groupadd docker
#Add the connected user "$USER" to the docker group. Change the user name to match your preferred user if you do not want to use your current user:
sudo usermod -aG docker $USER
getent group docker || newgrp docker || true #continue if group exits

header 'docker emulation extentions'
if [ ${processor_arch} == 'arm' ]; then
  sudo apt-get install -y qemu-system-arm
else
  sudo apt-get install -y qemu qemu-user-static
fi
