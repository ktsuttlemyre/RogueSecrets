#!/bin/bash
DOMAIN=$1
PORT=$2

timeout 22 sh -c 'until nc -z $0 $1; do sleep 1; done' $DOMAIN $PORT &> /dev/null && echo "online" || echo "offline"