#!/bin/bash
#custom image name
image='rogueos/roguescrets'
tag='latest'

#cache to rebuild image evey week
created_date="$(docker inspect -f '{{ .Created }}' $image:$tag)"
created_week=$(date +'%V' -d +'%Y-%m-%dT%H:%M:%S' --date="$created_date")
current_week=$(date +'%V')
if [ "$created_week" -ne "$current_week" ]; then
  log="$(docker build . -t $image:$tag --no-cache=true)"
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
