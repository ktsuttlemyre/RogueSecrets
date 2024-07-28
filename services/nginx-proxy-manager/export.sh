#!/bin/bash
source "$secrets/.env"
name="${1:-nginx-proxy-manager-db-1}"
id=$(docker ps -aqf "name=$name")
docker exec "$id" /usr/bin/mysqldump -u root --password="$nginx_proxy_manager_db_root_password" npm
