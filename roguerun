# RogueScripts


# ./BASH
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
