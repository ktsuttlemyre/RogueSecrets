domain="${1:-http://localhost}"

api_url="$domain/api"

#TODO figure out how to query for stream
stream_query="${2:-undefined currently because incomplete}"

username__FILE(<~/secrets/restreamer_username)
username="${3:-$username__FILE}"
password__FILE(<~/secrets/restreamer_password)
password="${4:-$password__FILE}"


restreamer_login=$(curl -s -X 'POST' \
  "$api_url/login" \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "username": "$username",
  "password": "$password"
}')

restreamer_jwt=$(echo "$restreamer_login" | jq -r '.access_token')
restreamer_refresh_token=$(echo "$restreamer_login" | jq -r '.refresh_token')

echo "current token $restreamer_jwt"

function refresh_jwt () {
	restreamer_jwt=$(curl -s -X 'GET' \
	  "$api_url/login/refresh" \ \
	  -H 'accept: application/json' \
	  -H "Authorization: Bearer $restreamer_refresh_token" | jq -r '.access_token'
	)
}

refresh_jwt

echo "refreshed token $restreamer_jwt"

restreamer_publish=$(curl -s -X 'GET' \
  "$api_url/api/v3/rtmp" \ \
  -H 'accept: application/json' \
  -H "Authorization: Bearer $restreamer_jwt"
)