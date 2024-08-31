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

Todo: make these analogous to the above path
info here
https://wiki.archlinux.org/title/XDG_Base_Directory
=== User directories ===

* {{ic|XDG_CONFIG_HOME}}
** Where user-specific configurations should be written (analogous to {{ic|/etc}}).
** Should default to {{ic|$HOME/.config}}.

* {{ic|XDG_CACHE_HOME}}
** Where user-specific non-essential (cached) data should be written (analogous to {{ic|/var/cache}}).
** Should default to {{ic|$HOME/.cache}}.

* {{ic|XDG_DATA_HOME}}
** Where user-specific data files should be written (analogous to {{ic|/usr/share}}).
** Should default to {{ic|$HOME/.local/share}}.

* {{ic|XDG_STATE_HOME}}
** Where user-specific state files should be written (analogous to {{ic|/var/lib}}).
** Should default to {{ic|$HOME/.local/state}}.

* {{ic|XDG_RUNTIME_DIR}}
** Used for non-essential, user-specific data files such as sockets, named pipes, etc.
** Not required to have a default value; warnings should be issued if not set or equivalents provided.
** Must be owned by the user with an access mode of {{ic|0700}}.
** Filesystem fully featured by standards of OS.
** Must be on the local filesystem.
** May be subject to periodic cleanup.
** Modified every 6 hours or set sticky bit if persistence is desired.
** Can only exist for the duration of the user's login.
** Should not store large files as it may be mounted as a tmpfs.
** pam_systemd sets this to {{ic|/run/user/$UID}}.

=== System directories ===

* {{ic|XDG_DATA_DIRS}}
** List of directories separated by {{ic|:}} (analogous to {{ic|PATH}}).
** Should default to {{ic|/usr/local/share:/usr/share}}.

* {{ic|XDG_CONFIG_DIRS}}
** List of directories separated by {{ic|:}} (analogous to {{ic|PATH}}).
** Should default to {{ic|/etc/xdg}}.


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
