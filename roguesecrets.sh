#!/bin/bash
image='rogueos/roguescrets'
tag='latest'
docker build . -t $image:$tag
docker run \
  --interactive --tty --rm \
  --volume "${PWD}:/tmp/roguesecrets" \
  --workdir "/tmp/roguesecrets" \
  $image:$tag roguesecrets.sh "$@"
