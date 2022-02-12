SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
CURRENT_DIR=$(pwd)
cd $SCRIPTPATH
git stash push -m"local changes"
git pull
git stash pop
cd $CURRENT_DIR