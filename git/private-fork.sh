
declare -a arr=("jq" "git" "sed")

## now loop through the above array
for i in "${arr[@]}"; do
   command -v "$i" >/dev/null 2>&1 || { echo >&2 "I require $i but it's not installed.  Aborting."; exit 1; }
done

SRC_REPO=$1 #git@github.com:usi-systems/easytrace.git
DEST_REPO=$2 #git@github.com:<your_username>/${REPO_NAME}.git
REPO_NAME=$3 #easytrace
ACCESS_TOKEN=$4

if [ -z "$REPO_NAME" ]; then
  # get repo name from end of SRC_REPO
  REPO_NAME=$(echo $SRC_REPO | sed -e 's/.*\/\([^ ]*\)\.git/\1/')
  echo "Repo name not provided, using $REPO_NAME"
  exit 1
fi
echo "cloning $SRC_REPO to $DEST_REPO, using $REPO_NAME"

REPO_EXISTS=1
if [ -z "$ACCESS_TOKEN" ]; then
  echo "No access token provided, checking to see if private repo exists"
  REPO_EXISTS="$(git ls-remote -q "$DEST_REPO" &> /dev/null)";
  REPO_EXISTS="$?"
    if [[ ! $REPO_EXISTS -eq 0 ]]; then
      echo "repo $DEST_REPO does not exist"
    fi
fi


directory=$(pwd)
tmp=$(mktemp -d)

#1 See if repo exists otherwise Create a new private repository on Github
repo="$(git ls-remote -q "$DEST_REPO" &> /dev/null)";
if [[ ! "$?" -eq 0 ]]; then
  TYPE=$(curl -s https://api.github.com/repos/Microsoft/vscode | jq -r '.owner.type')
  if [[ "$TYPE" == "User" ]]; then
    TYPE='user'
  elif [[ "$TYPE" == "Organization" ]]; then
    TYPE='orgs'
  else
    echo 'Error determinging repo type'
    exit 1
  fi

  #Create private repo for user or orgs
  curl -H "Authorization: token $ACCESS_TOKEN" --data "{\"name\":\"${DEST_REPO}\"}" https://api.github.com/${TYPE}/repos
fi

#2 Create a bare clone of the repository. (This is temporary and will be removed so just do it wherever.)
cd $tmp
git clone --bare ${SRC_REPO} ${REPO_NAME}

#3 Mirror-push your bare clone to your new easytrace repository.
# Replace <your_username> with your actual Github username in the url below.
cd ${REPO_NAME}
git push --mirror ${DEST_REPO}

#4 Remove the temporary local repository you created in step 1.
cd ${directory}
rm -rf "$tmp"

#5 You can now clone your easytrace repository on your machine (in my case in the code folder).
git clone ${DEST_REPO}

#6 If you want, add the original repo as remote to fetch (potential) future changes. Make sure you also disable push on the remote (as you are not allowed to push to it anyway).
cd ${REPO_NAME}
git remote add upstream ${SRC_REPO}
git remote set-url --push upstream DISABLE
git remote -v
cd ${directory}
echo "Complete private fork"
# You can list all your remotes with git remote -v. You should see:
# origin	git@github.com:<your_username>/easytrace.git (fetch)
# origin	git@github.com:<your_username>/easytrace.git (push)
# upstream	git@github.com:usi-systems/easytrace.git (fetch)
# upstream	DISABLE (push)
# When you push, do so on origin with git push origin.

#When you want to pull changes from upstream you can just fetch the remote and rebase on top of your work.

#  git fetch upstream
#  git rebase upstream/master
#And solve the conflicts if any
