#!/bin/bash
#set -x

if [ -z ${script_dir+x} ]; then
	export script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
	set -a      # turn on automatic exporting
	source "$(dirname $script_dir)/env"
	[ -f "$host_wd/env" ] && source "$host_wd/env"
	set +a      # turn off automatic exporting

	#add secrets?
	#TODO
fi



handle_file () {
	ACTION="$1"
	FILE="$2"
	iter_dir="$3"
	if [[ $FILE == -* ]]; then
		#this one is disabled
	 	return
	fi
	if [[ $FILE != [0-9]* ]]; then
		#handle all matches
		$script_dir/service.sh "ls" | grep "$FILE" | while read -r line ; do
		    handle_file "$ACTION" "$line" "$iter_dir"
		done
		return
	fi

	IFS='.' read -ra array <<< "$FILE"
	service="${array[1]}"
	file_type=$(printf %s\\n "${array[@]:(-1)}")
	#if isDisabled
	if [ "${array[2]}" = "disbled" ]; then
		return
	fi

	if [ "$file_type" = "yml" ]; then

		#if there is an env-file variable in the header then grab it
		env_file="$secrets/.env"
		line=$(head -n 1 "$iter_dir/$FILE")
		if [[ $line == \#env\-file\=* ]]; then
			env_file="${line/\#env\-file\=/}"
			echo "found env_file for yml $env_file"
		fi

		echo "starting service $service from file $FILE filetype=$file_type"
		if [ "$ACTION" = "init" ];then
			docker compose -f "$service_wd/$service/docker-compose.yml" --env-file "$env_file" build
			#if user doesnt exist
				#Create a new $service user
				#makes it a member of the $service group and rogueos
				#and assigns it a home directory of $rogue_wdir and disables log in to the account.
				#sudo groupadd rogueos
				#user_name=$service_rogueos
				#sudo groupadd $user_name
				#sudo useradd -s /bin/false -g $user_name -d $rogue_wdir $user_name
			#fi
		fi
		if [ -f "$iter_dir/$FILE" ]; then
			[ "$ACTION" = "plan" ] && docker compose -f "$iter_dir/$FILE"  -f "$service_wd/$service/docker-compose.yml" --env-file "$env_file"  --project-name "$service" config
			[ "$ACTION" = "startup" ] && docker compose -f "$iter_dir/$FILE"  -f "$service_wd/$service/docker-compose.yml" --env-file "$env_file"  --project-name "$service" up -d
			[ "$ACTION" = "stop" ] && docker compose -f "$iter_dir/$FILE"  -f "$service_wd/$service/docker-compose.yml" --env-file "$env_file"  --project-name "$service" down
			#todo add  -f $service_wd/rogue.labels.yml to above command
		fi

	elif [ "$file_type" = "sh" ]; then
		#only run  if the action matches the parent file 
		if [[ $iter_dir == *${ACTION} ]]; then
			echo "running bash script from file $FILE filetype=$file_type"
			$iter_dir/$FILE
		fi
	fi
}

list="${@:2}"
echo "RogueOS service engine is perfoming $1 on $list"
startup_list=$list
startup_list="${startup_list:-$(ls $host_wd/startup | sort -g)}"

shutdown_list=$list
shutdown_list="${shutdown_list:-$(ls $host_wd/shutdown | sort -g)}"

case "$1" in
	"ls")
		#run init.sh
	    #$host_wd/init.sh
	    echo "===Startup==="
		for FILE in $startup_list; do
			echo "$FILE"
		done

	    echo "===Shutdown==="
		for FILE in $shutdown_list; do
			echo "$FILE"
		done
	;;
	"plan"|"config")
		action='plan'
		for FILE in $startup_list; do
			handle_file $action $FILE $host_wd/startup
		done

		for FILE in $shutdown_list; do
			handle_file $action $FILE $host_wd/shutdown
		done
	;;
	"restart"|"refresh")
		if [ -z ${list+x} ]; then
			$script_dir/service.sh "stopall" 
		else
			$script_dir/service.sh "stop" $list
		fi
		$script_dir/service.sh "startup" $list
	;;
	"reconnect")
		#todo find commands to fix eth connection
		resetroute () {
		    echo "Flushing routes...";
		    for i in $(ifconfig | egrep -o "^[a-z].+\d{1}:" | sed 's/://');
		    do
		        sudo ifconfig "$i" down;
		    done;
		    sudo route -n flush;
		    for i in $(ifconfig | egrep -o "^[a-z].+\d{1}:" | sed 's/://');
		    do
		        sudo ifconfig "$i" up;
		    done
		}
		#resetroute
		for FILE in $startup_list; do
			case $FILE in
			    #*"cloudflare"* | *".yml")
			    *".yml")
				$script_dir/service.sh "stop" $FILE
				$script_dir/service.sh "startup" $FILE
				;;
			esac
		done
	;;
    "init")
		#run init.sh
	    $host_wd/init.sh
		for FILE in $startup_list; do
			handle_file $1 $FILE $host_wd/startup
		done

		for FILE in $shutdown_list; do
			handle_file $1 $FILE $host_wd/shutdown
		done
	;;

    "startup")
		for FILE in $startup_list; do
			handle_file $1 $FILE $host_wd/startup
		done
	;;

    "shutdown")
		for FILE in $shutdown_list; do
			handle_file $1 $FILE $host_wd/shutdown
		done
	;;
	"stop")
		#stop a processes
		if [ -z ${list+x} ]; then
			echo "must provide a service file to stop"
			exit 1
		fi
		for FILE in $list; do
			handle_file $1 $FILE $host_wd/startup
			handle_file $1 $FILE $host_wd/shutdown
		done
	;;
	"stopall")
		#TODO add rogueos label and only stop rogue containers
		#stop all processes
		docker stop $(docker ps -a -q)
	;;
	"kill")
		#TODO add rogueos label and only stop rogue containers
		#stop all processes
		docker stop $(docker ps -a -q)
		#Remove all the containers
		docker rm $(docker ps -a -q)
		#Remove networks
		docker rm $(docker network ls -q)
	;;
	"killall")
		#TODO add rogueos label and only stop rogue containers
		#stop all processes
		docker stop $(docker ps -a -q)
		#Remove all the containers
		docker rm $(docker ps -a -q)
		#Remove networks
		docker rm $(docker network ls -q)

		#todo kill all pids in rogeos group
		#/etc/passwd doesnt work correctly in mac
		#root:!:0:0::/:/usr/bin/ksh
		#pkill -U $(id -u kqsfl)
	;;
	*)
        echo "Unknown command: $command" 
        exit 1
    ;;
esac


echo "Rogue Service Engine completed $1"