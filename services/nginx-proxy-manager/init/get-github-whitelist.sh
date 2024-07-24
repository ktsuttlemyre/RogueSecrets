#!/bin/bash

curl -sS 'https://api.github.com/meta' | jq -r '.actions[] | "allow "+ .' > $rogue_wdir/scripts/nginx-proxy-manager/configs/gitub_actions_whitelist.conf