ls | jq -R '{(.):0}' | jq -sc 'add' | jq > ~/RogueCLI/function/src.json
