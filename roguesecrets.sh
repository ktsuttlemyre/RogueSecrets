#!/bin/bash
#custom image name
image='rogueos/roguescrets'
tag='latest'

#if image not already here
if [ -z "$(docker images -q $image:$tag 2> /dev/null)" ]; then
  git pull
  git submodule update --init --recursive --remote
fi

#cache to rebuild image evey week hard rebuild every month
created_date="$(docker inspect -f '{{ .Created }}' $image:$tag)"
created_week=$(date +'%V' -d +'%Y-%m-%dT%H:%M:%S' --date="$created_date")
created_month=$(date +'%m' -d +'%Y-%m-%dT%H:%M:%S' --date="$created_date")
current_week=$(date +'%V')
current_month=$(date +'%m')
if [ "$created_week" -ne "$current_week" ]; then
  git pull
  git submodule update --init --recursive --remote
  if [ "$created_month" -ne "$current_month" ]; then
    log="$(docker build . -t $image:$tag --no-cache=true)"
  else
    log="$(docker build . -t $image:$tag)"
  fi
  if $? ; then
    echo "Error building image = $image:$tag" > /dev/stderr
    echo "$log" > /dev/stderr
  fi
fi

#actual run parameters
docker run \
  --interactive --tty --rm \
  --volume "${PWD}:/home/roguesecrets" \
  --workdir "/home/roguesecrets" \
  $image:$tag main.sh "$@"
