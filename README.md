# RogueSecrets


# Working inside docker comtainer
### Paths
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
