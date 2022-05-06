
: <<'BOOTSTRAP'

 # due to some functions used these script must be run from statops or statops/bin

 These lines are used at that top of scripts in bin

   # must start in the statops directory
   [ $(basename $(pwd)) == 'statops' ] || { echo "please start from the statops directory"; exit 1; }
   source bin/bootstrap.sh || { echo "could not source bootstrap.sh"; exit 1; }

BOOTSTRAP

[ -r ./bin/functions.sh ] || {
	echo
	echo please run $0 from the statops directory
	echo 
	exit 1
}

declare -x FUNCTIONS_FILE=$(pwd)/bin/functions.sh
source $FUNCTIONS_FILE || { echo "cannot source '$FUNCTIONS_FILE'"; exit 1; }


