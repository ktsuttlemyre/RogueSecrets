# RogueCLI
I need to run docker images a lot on different computers. This is a way to convert all my `functions` into `command line calls`

RogueCli examples
Get  secrets from bitwarden and inject them into the current session or save the files to disk (depending on how you have them saved in bitwarden
```bash
./rogue ./secrets/get.sh folder-name
```
```bash
RAMDISK="/mnt/RogueCLI_$$/ramdisk/"
rogue ./create/ramdisk.sh 250MB "$RAMDISK" -- local
```

### Inject from Repo
To use the bash scripts directly from the repo
```
#!/bin/bash

include () {
  d=/tmp/RogueCache/bash; mkdir -p $d; find $d -type f -mtime ${ROGUECASHE_TTL:-+7} -delete; f=${1##/*/}; ( ! [ -f $d$f ] && curl -s $1 > $d$f ) && env . $d$f
}
. include https://raw.githubusercontent.com/ktsuttlemyre/RogueScripts/master/bash/RogueArgs.sh;
```

### Install
```bash
repo="RogueScripts/";wdir="/opt/$repo";
mkdir -p ${wdir}; cd ${wdir}; curl -LkSs 'https://api.github.com/repos/${repo}tarball/' | tar xz --strip=1 -C $wdir;"
```


docker run -it --entrypoint ./secrets/get.sh ghcr.io/ktsuttlemyre/roguesecrets:main

# Logic
when running 
```bash
./rogue ./secrets/get.sh folder-name
```
.The wrapper `/rogue` will search backwards through the path to find docker-compose .yaml and .env files. if they are found then those containers are ran
If not found then the root of the repo has a catch all docker-compse yaml and env that will run and a temporary ramdisk is created for communicating back to the host.
when the container runs it sends the same command to the container but sets environment varialbe `IS_ROGUE_CONTEXT=true` which will run the roguerunner portion of the `./rogue` script
this will search through the path going from root to child looking for .env and .sh files that need to run in order to handle logins, env setup, etc till finally the .sh requested will run
The container has access to the host folders listed below See # Host Folders
anything left in the ramdisk location at /host/ramdisk will be available to the wrapper for a short time. This is currently used to transfer secrets from ./secrets/get.sh into the environment



# Working inside docker container
### Host folders
From in the docker image these paths map to host
 - /host/root is the root folder of the host
 - /host/home is the home of the current user
 - /host/cwd is the current working directory on the host
 - /host/parent is the parent folder of the current working directory

 - /host/session/.env will be exported into the current session as a .env file after the docker image closes

Useful conversions to use inside docker to map to host
```bash
#replace path with host locations
if [[ $f_path == ~* ]]; then
  f_path="${f_path/#\~\///host/home/}"
elif [[ $f_path == /* ]]; then
  f_path="${f_path/#\///host/root/}"
fi
```

Create a /host/session/.env for exporting variables
```bash
echo "$name=$data" >> /host/session/.env
```
