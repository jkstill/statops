#!/bin/bash

DEBUG=0
FUNCTIONS_FILE=/home/jkstill/bin/functions.sh; export FUNCTIONS_FILE
. $FUNCTIONS_FILE

function usage {
	printf "
$0 

Data Dictionary, System and Schema statistics can be imported from
an EXP file to a statistics table using the Oracle IMP utility.


-o ORACLE_SID   - used to set local oracle environment
-d database     - data where the import table resides
-u username     - account to login with
-f import_file  - file to import
-F fromuser     - fromuser argument for Oracle imp
-T touser       - touser argument for Oracle imp

"

}

while getopts d:u:f:o:s:F:T:h arg
do
	case $arg in
		d) DATABASE=$OPTARG;;
		u) USERNAME=$OPTARG;;
		f) IMPORT_FILE=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		F) FROMUSER=$OPTARG;;
		T) TOUSER=$OPTARG;;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$FROMUSER:$TOUSER:$IMPORT_FILE:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# argument validation section 
# concat all args together

ALLARGS=":$USERNAME:$DATABASE:$FROMUSER:$TOUSER:$IMPORT_FILE:$ORACLE_SID:"
# upper case args
ALLARGS=$(upperCase $ALLARGS)

# components of RE 
export ALNUM1="[[:alnum:]]+"
export ALNUM3="[[:alnum:]]{3,}"
export USER_RE='[[:alnum:]_$]+'
export DATABASE_RE=$ALNUM3
export TABLE_RE='[[:alnum:]_#$]+'
export FILE_RE="[[:alnum:]_$%-.]+"


# bash
# order of argument regexs
# all arguments are required
# :$USERNAME:$DATABASE:$IMPORT_FILE:$ORACLE_SID:
VALID_ARGS=(
":$USER_RE:$DATABASE_RE:$USER_RE:$USER_RE:$FILE_RE:$DATABASE_RE:" \
)

validate_args $ALLARGS ${VALID_ARGS[*]}
ARG_RESULT=$?

if [ "$ARG_RESULT" != '0' ]; then
	usage
	[ "$ECHO_ARGS" == 'YES' ] && {
		echo "ARG_RESULT: $ARG_RESULT"
		echo "ALLARGS: $ALLARGS"
		echo "VALID_ARGS: ${VALID_ARGS[*]}"
	}
	exit 9
fi

echo ARGS: $ALLARGS

[ -f "$IMPORT_FILE" ] || {
	echo cannot read "$IMPORT_FILE"
	exit 3
}
# end of argument validation

CALLED_SCRIPT=$0
CALLED_DIRNAME=$(getPath $CALLED_SCRIPT);
SCRIPT_FQN=$(getScriptPath $CALLED_SCRIPT)
FQN_DIRNAME=$(getPath $SCRIPT_FQN)

# this is the real location of the script
# even if called with symlink
SCRIPT_HOME=$(getRelPath $CALLED_DIRNAME $FQN_DIRNAME)

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus
IMP=$ORACLE_HOME/bin/imp

printf "export STATS_TABLE: %s\n" $TABLE_NAME
printf "  Database: %s \n  Schema: %s \n" $DATABASE $USERNAME

# get password from database

PASSWORD=$(getPassword $USERNAME $DATABASE)
PASSWORD='"'$PASSWORD'"' # quoted for special characters

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

LOG_FILE=$(echo $IMPORT_FILE | $CUT -f1 -d\.)'_imp.log'

$IMP userid="${USERNAME}/${PASSWORD}@${DATABASE}" \
	file=$IMPORT_FILE \
	log=$LOG_FILE \
	fromuser=$FROMUSER \
	touser=$TOUSER \
	ignore=y

