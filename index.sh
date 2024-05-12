#!/bin/bash
#custom image name
image='rogueos/roguescrets'
tag='latest'

git_pull () {
  git stash
  git pull
  git stash pop
  git submodule update --init --recursive --remote
}

docker_build () {
  log="$(docker build . -t $image:$tag $1)"; exit_code=$?
  if $exit_code ; then
    echo "Error building image = $image:$tag" > /dev/stderr
    echo "$log" > /dev/stderr
  fi
}

#if image not already here
if [ -z "$(docker images -q $image:$tag 2> /dev/null)" ]; then
  docker_build
else
  #cache to rebuild image evey week hard rebuild every month
  created_date="$(docker inspect -f '{{ .Created }}' $image:$tag)"
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

#actual run parameters
docker run \
  --interactive --tty --rm \
  --volume "${PWD}:/tmp" \
  --workdir "/tmp" \
  $image:$tag /home/roguesecrets/main.sh "$@"
