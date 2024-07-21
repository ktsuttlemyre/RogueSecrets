#!/bin/bash
source $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )/common/RogueArgs.sh "${@}"
#set -euo pipefail
IFS=$'\n\t'
#script metadata values
script_name=$(basename "$0")
script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#Detect if sourced
(return 0 2>/dev/null) && sourced=true || sourced=false

if ! $sourced; then
  #do not use set -a because it will cause all these secret values to be sent to terminal
  #set -a      # turn on automatic exporting
  [ -f ${script_dir}/env ] && source ${script_dir}/env
  [ -f "$host_wd/env" ] && source "$host_wd/env"
  #set +a      # turn off automatic exporting
fi

function header () {
 echo -e "RogueSecrets[${script_name}]  $1"
}
#reads all secrets from a bitwarden folder and loads them based on their path field
#notes is the value
#f_path is where to put the value (- is shell environment)
#f_base64 means it is base 64 encoded
#f_gzip means it is gzipped

debug=false

#add log4bash and debug flag
source /rogue/libs/log4bash/log4bash.sh
if $debug; then
	log_warning "THIS WILL SHOW SECRETS TO STDOUT TERMINAL"
	  log_debug "====      debug logging enabled      ===="
	log_warning "THIS WILL SHOW SECRETS TO STDOUT TERMINAL"
else
	log_debug()  { :; }
fi

secret_folder="${1:-rogue_secrets:$machine_name}"
if [[ $secret_folder != rogue_secrets:* ]]; then
	secret_folder="rogue_secrets:$secret_folder"
fi
echo "============================================="
echo "Downloaing secrets from folder $secret_folder" 
echo "============================================="
bw logout || true
unset BW_SESSION
while [ -z "$BW_SESSION" ]; do
	BW_SESSION=$(bw login --raw)
done
#get SecretsManager folder
folder_id=$(bw list folders  --session "$BW_SESSION" | jq -r ".[] | select(.name==\"$secret_folder\").id")

#parse bw item data
list=$(bw list items --folderid "$folder_id"  --session "$BW_SESSION")

log_debug "got this list of secrets from bitwarden: $list"

#iterate the secrets array
#source $rogue_wdir/scripts/json_to_env.sh <(echo "$list")

# secrets=$(jq -r '. as $root |
# 	path(..) | . as $path |
# 	$root | getpath($path) as $value |
# 	select($value | scalars) |
# 	([$path[]] | "json_"+join("_")) + "=" + ($value | @json)
# 	' <<< "$list")

# while IFS= read -r line || [[ -n $line ]]; do
#     export "$line"
# done < <(printf '%s' "$secrets")
# unset secrets

# # Use indirect referencing to echo the value
# variable_name="json_0_fields_0_name"
# echo "${!variable_name}"

# var="json_0_fields_0_value"
# echo "trying to get json_0_fields_0_value ${!var}"


#name is raw string
#notes is json
#fields is json
while read -r name; do
    read -r notes
    read -r fields
    log_info "found secret named: $name"
    log_debug "name=$name"
    log_debug "notes=$notes"
    log_debug "fields=$fields"

	f_path=''
	f_base64=false
	f_gzip=false
    if ! [[ "$fields" == 'null' ]]; then
	    while read -r f_name; do
		    read -r f_value
		    read -r f_type
		    log_debug "$f_name |type:$f_type| = $f_value"
		    declare "f_$f_name=$f_value"
		done < <( echo "$fields" | jq -cr '.[] | (.name, .value, .type)')
	fi #END handle field

	log_debug "f_path=$f_path"
    log_debug "f_base64=$f_base64"
    log_debug "f_gzip=$f_gzip"

    #string was originally json format
    # meaning it was surrounded with ""
    # and line breaks were endcoded as /n characters
    data=$(jq -cr '.' <<< "$notes")
	if $f_base64; then
		log_info "doing base64 decode"
		data=$(echo "$data" | base64 --decode)
	fi

	if $f_gzip; then
		log_error "Need to implement gzip"
		#get list of files from tar
		#structure=$(echo "$data" | tar tzf - | awk -F/ '{ if($NF != "") print $NF }')
		#untar and unzip to current directory
		#echo "$data" | tar -xzvf - -C .
	fi

	if [ -z "${f_path}" ]; then
		# load as envirnment variable
		log_info "exporting $name to shell environment"
		export "$name=$data"
  		echo "$name=$data" >> /host/session/.env
	else
		log_info "writing $name to $f_path"

		#replace path with host locations
		if [[ $f_path == ~* ]]; then
			f_path="${f_path/#\~\///host/home/}"
		elif [[ $f_path == /* ]]; then
			f_path="${f_path/#\///host/root/}"
		fi

		#get path to parent dir
		path_only="$(dirname "${f_path}")"

		log_debug "full path=$f_path"
		log_debug "path path_only=$path_only"

		#make the directory path
		mkdir -p $path_only
		#write file
		echo "$data" > "$f_path"
	fi
done < <( echo "$list" | jq -cr '.[] | (.name, (.notes | @json), (.fields | @json))')
bw logout
unset BW_SESSION




#example
# rogue_secrets 'Secrets:ShipDocker'

# #save session data
# save_data=$(tar -czvf - -T $structure | base64)
# echo "$save_data" | bw encode | bw edit item "$id"
# bw logout
