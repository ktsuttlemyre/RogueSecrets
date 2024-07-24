#!/bin/bash
#$FOLDER=${~/nginx-proxy-manager/data/nginx/*:-/npm_data/*}
#$FOLDER=${1:$FOLDER}
echo "<html><head>"
echo "<title>kqsfl</title>"
echo '<meta name="viewport" content="width=device-width">'
echo "</head><body><ul>"
list=$(grep -rni "server_name" /npm_data/* | tr -s ' ' | cut -d ' ' -f 3)

while IFS= read -r entry; do
    #there is a ; on the end of entry idk why so remove it
    echo "<li><a href='https://${entry%?}'>${entry%?}</a></li>"
done <<< "$list"

echo "</ul>"
echo '<iframe src="https://cab1restream.kqsfl.com/b92f26bb-d449-43ca-bbb7-e0ab57ed2025.html" width="640" height="360" frameborder="no" scrolling="no" allowfullscreen="true"></iframe>'
echo "</body></html>"
