#!/bin/bash
cd ..
rm -rf RogueSecrets/
docker rmi $(docker images --filter=reference="rogueos/*:*" -q)
git clone https://github.com/ktsuttlemyre/RogueSecrets.git
cd RogueSecrets/
chmod +x ./index.sh ./reset.sh
#./index.sh 
