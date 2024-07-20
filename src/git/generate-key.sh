#!/bin/bash
# original https://gist.github.com/petersellars/c6fff3657d53d053a15e57862fc6f567
# Requirements
#   You will need to have created a GitHub Access Token with admin:public_key permissions

# Usage
#   chmod +x autokey-github.sh
#   ./autokey-github.sh <YOUR-GITHUB-ACCESS-TOKEN>

# Reference
#   https://nathanielhoag.com/blog/2014/05/26/automate-ssh-key-generation-and-deployment/
#   https://gist.github.com/nhoag/7043570bfe32003eb8a1
#   https://help.github.com/articles/testing-your-ssh-connection/
#   https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/
#   https://developer.github.com/v3/users/keys/

#set -e

prompt() {
  message="$1"
  while true; do
    if ! [ -z "$2" ]; then
      yn="$2"
    else
      read -p "$message " yn
    fi
      case $yn in
          [Yy][Ee][Ss]* )
            return ;;
          [Nn][Oo]* )
            return 1 ;;
          [Cc][Aa][Nn][Cc][Ee][Ll]* )
            return 2 ;;
          [Ee][Xx][Ii][Tt]* )
            echo "user exit"
            exit 0 ;;
          * )
          echo "Please answer yes,no,cancel or exit."
          if ! [ -z "$2" ]; then
            echo "Invalid response. Program exiting now"
            exit 1
          fi;;  
      esac
  done
}

if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
fi

if grep 'Host github.com' ~/.ssh/config; then
  if ! prompt "You might already have a github ssh key on this machine. Would you like to continue? " "$force_generate_github_ssh_key"; then
    exit 0
  fi
fi


# Generate SSH Key and Deploy to Github

TOKEN=$1 # must have admin:public_key for DELETE

ssh-keygen -q -b 4096 -t rsa -N "" -f ~/.ssh/github_rsa

PUBKEY=`cat ~/.ssh/github_rsa.pub`
TITLE=`hostname`

RESPONSE=`curl -s -H "Authorization: token ${TOKEN}" \
  -X POST --data-binary "{\"title\":\"${TITLE}\",\"key\":\"${PUBKEY}\"}" \
  https://api.github.com/user/keys`

if [[ $RESPONSE == *Error:* || $RESPONSE == *Bad* ]] ;then
  echo "an error occured!"
  rm  ~/.ssh/github_rsa
  echo $RESPONSE
  exit 1
fi

KEYID=`echo $RESPONSE \
  | grep -o '\"id.*' \
  | grep -o "[0-9]*" \
  | grep -m 1 "[0-9]*"`

echo "Public key deployed to remote service"

# Add SSH Key to the local ssh-agent"

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/github_rsa
echo "Added SSH key to the ssh-agent"

if ! grep -q "Host github.com" ~/.ssh/config > /dev/null; then
echo "Adding SSH key to the ~/.ssh/config"
cat > ~/.ssh/config <<EOF
Host github.com
    User git
    IdentityFile ~/.ssh/github_rsa
EOF
echo "Added SSH key to the ~/.ssh/config"
fi

# Test the SSH connection
ssh -T git@github.com || true

echo "continuing in"
for i in {5..1..1};do echo -n "$i." && sleep 1; done
