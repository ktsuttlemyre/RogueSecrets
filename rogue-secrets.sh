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

if ! command -v docker &> /dev/null; then
    header "Docker not found. Installing"
    set -euo pipefail
    $script_dir/install-docker.sh
    set +euo pipefail
elif [ -x "$(command -v docker-compose)" ]; then
    header "SUCCESS: docker-compose (v1) is installed."
    header " will attempt to use docker-compose but may have incompabitliby issues."
    header "to force docker compose (v2) install. Run $script_dir/install-docker.sh"
    d-compose=docker-compose
elif $(docker compose &>/dev/null) && [ $? -eq 0 ]; then
    header "SUCCESS: docker compose (v2) is installed."
    d-compose=docker compose
else
    header "Docker not found. Installing"
    set -euo pipefail
    $script_dir/install-docker.sh
    set +euo pipefail
fi


#custom image name
set -a      # turn on automatic exporting
source ./params.env
set +a      # turn off automatic exporting

if [ "$1" == "--" ]; then
  if [ "$2" == "reset" ]; then
    cd ..
    rm -rf RogueSecrets/
    docker rmi $(docker images --filter=reference="rogueos/*:*" -q) -f
    git clone https://github.com/ktsuttlemyre/RogueSecrets.git
    cd RogueSecrets/
    chmod +x ./index.sh ./reset.sh
    #./index.sh
  fi
fi

git_pull () {
  git stash
  git pull
  git stash pop
  git submodule update --init --recursive --remote
}

docker_build () {
  local log; log="$(docker build . -t $project/$image:$tag $1)"
  if [ $? -ne 0 ]; then
    echo "Error building image = $project/$image:$tag" > /dev/stderr
    echo "$log" > /dev/stderr
  fi
}

#if image not already here
if [ -z "$(docker images -q $project/$image:$tag 2> /dev/null)" ]; then
  docker_build
else
  #cache to rebuild image evey week hard rebuild every month
  created_date="$(docker inspect -f '{{ .Created }}' $project/$image:$tag)"
  created_week=$(date +'%V' -d +'%Y-%m-%dT%H:%M:%S' --date="$created_date")
  created_month=$(date +'%m' -d +'%Y-%m-%dT%H:%M:%S' --date="$created_date")
  current_week=$(date +'%V')
  current_month=$(date +'%m')
  if [ "$created_week" -ne "$current_week" ]; then
    git_pull
    [ "$created_month" -ne "$current_month" ] && cache='--no-cache'
    docker_build $cache
  fi
fi

#Run image
$d-compose -f <( envsubst < docker-compose.yaml ) --env-file <( env ) run --build roguesecrets /home/roguesecrets/main.sh
if ! [ -z "$is_service" ]; then
   $d-compose -f <( envsubst < docker-compose.yaml ) down
fi


rogue_envvars="${PWD}/.exported_envs.env"
if [ -f $rogue_envvars ]; then
  unamestr=$(uname)
  if [ "$unamestr" = 'Linux' ]; then
    export $(grep -v '^#' $rogue_envvars | xargs -d '\n')
  elif [ "$unamestr" = 'FreeBSD' ] || [ "$unamestr" = 'Darwin' ]; then
    export $(grep -v '^#' $rogue_envvars | xargs -0)
  fi
  rm $rogue_envvars
fi
