#!/bin/bash
#
# Takes a src directory and maps all the files in there to another drive using symlinks
# I use this for steamdeck to map my usb drive to a drive on the hdd
#set -xe
create_destinations=false
dry_run=false
# Check if env file is provided
config=${1:-../_hosts/steamdeck/RogueCLI/functions/src.json}
[ -z "$config" ] && echo "Usage: $0 path_to_env_file" && exit 1

# Source the env file
if [[ "$config" = *.env ]]; then
	[ ! -f "$config" ] && echo "Env file $config not found." && exit 1
	set -o allexport
	source "$config"
	set +o allexport
elif [[ "$config" == *.json ]]; then
	src_abs_path="$(jq -r '.src_abs_path' "$config")"
	dest_abs_path="$(jq -r '.dest_abs_path' "$config")"
else
 	echo "WHAT?!"
  	exit 1
fi

# Check required variables
[ -z "$src_abs_path" ] && echo "Variable src_abs_path has no value" && exit 1
[ ! -d "$src_abs_path" ] && echo "Source directory does not exist: $src_abs_path" && exit 1
[ -z "$dest_abs_path" ] && echo "Variable dest_abs_path has no value" && exit 1
[ ! -d "$dest_abs_path" ] && echo "Destination directory does not exist: $dest_abs_path" && exit 1

# Function to check if a file is a symbolic link
is_symlink() { [ -L "$1" ]; }

# Function to check if a file is a hard link
is_hardlink() { [ -e "$1" ] && [ "$(stat -c %h "$1")" -gt 1 ]; }

# Function to create symlinks
create_symlinks() {
  local source_dir=$1
  local dest_dir=$2

  [ ! -d "$source_dir" ] && echo "Source directory $source_dir does not exist. Nothing to do" && return 1
  if [ ! -d "$dest_dir" ]; then
	if [ ! -z "$create_destinations" ]; then
		mkdir -p "$dest_dir"
	else
		 echo "Destination directory $dest_dir does not exist. Not creating it"
		 return 1
	fi
  fi
  for src_file in "$source_dir"/*; do
    file_name=$(basename "$src_file")
    dest_file="$dest_dir/$file_name"

    #if file exists then
    if [ -e "$dest_file" ]; then
        if is_symlink "$dest_file"; then
            target_path=$(readlink "$dest_file")

            if [ -e "$target_path" ]; then
                echo "Found [Skipping]: Symlink $dest_file is valid and points to $target_path."
                continue
            fi
            #otherwise drop out of if statement and overwrite
        elif is_hardlink "$dest_file"; then
            echo "Found [Skipping]: Not sure what to do with hard links at the moment :-D"
            continue
        else
            echo "Found: [Skipping]: A file $dest_file that exists but is not a soft or hard link. Script will not overwrite a file with a link. Skipping"
            continue
        fi
    fi
    if [ "$dry_run" == true ]; then
        echo "this is a dry run"
        continue
     fi
     echo "creating softlink $src_file $dest_file"
     #ln -sf "$src_file" "$dest_file"
  done
}

scrub_destination=false
#if [ "$clean_destination" == true ]; then
#    for dest_folder in "$SOURCE_DIR"/*; do
#        src_name=$(basename "$src_folder")
#    fi
#fi

# Main loop
# Iterate over the files in the source directory using a glob pattern
# for src_folder in "$SOURCE_DIR"/*; do
#   src_name=$(basename "$src_folder")
#   # Check if it's a file (not a directory)
#   [ ! -d "$src_folder" ] && echo "Not a directory $src_folder skipping" && continue
#   echo "src is $src_name"
#   echo "folder is ${!src_name}"
#   dest_folder="${!src_name}"
#   [ -z "$dest_folder" ] && echo "Source directory $src_folder does not map to a destination" && continue

#   echo "Linking directory from $src_folder to $dest_folder"
#   create_symlinks "$src_folder" "$dest_folder"
# done

# https://stackoverflow.com/questions/34226370/jq-print-key-and-value-for-each-entry-in-an-object
cat "$config" | jq -r '.map | to_entries[][]' | while read -r src_rpath ; do
    read -r dest_rpath
    echo "src_rpath=$src_rpath and value=$dest_rpath"
    
    src_folder="$src_abs_path/$src_rpath"
    dest_folder="$dest_abs_path/$dest_rpath"

    # Check if it's a file (not a directory)
    [ -z "$src_folder" ] && echo "Source directory $src_folder does not map to a destination" && continue
    [ ! -d "$src_folder" ] && echo "Not a directory $src_folder skipping" && continue
    [ -z "$dest_folder" ] && echo "Source directory $dest_folder does not map to a destination" && continue
    [ ! -d "$dest_folder" ] && echo "Not a directory $dest_folder skipping" && continue

    echo "Linking directory from $src_folder to $dest_folder"
    create_symlinks "$src_folder" "$dest_folder"
done

echo "done"
