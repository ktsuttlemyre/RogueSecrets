#get.sh

RogueCli examples
Get secrets from bitwarden and inject them into the current session or save the files to disk (depending on how you have them saved in bitwarden
```bash
./rogue ./secrets/get.sh folder-name
```


The ./rogue wrapper will handle mounting of locations via the docker-compose.yaml and will even load the env file from the ram disk into the currnet host session after the docker container closes
