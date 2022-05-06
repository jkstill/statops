#!/bin/bash

DEBUG=0

# must start in the statops directory
[ $(basename $(pwd)) == 'statops' ] || { echo "please start from the statops directory"; exit 1; }
source bin/bootstrap.sh || { echo "could not source bootstrap.sh"; exit 1; }

function usage {
	printf "

Create a table via DBMS_STATS.CREATE_STAT_TABLE that Data Dictionary
System and Schema  statistics can be exported to.  

Statistics can also be imported from this table.

$0 
-o ORACLE_SID      - this is used to set the oracle environment
-d database        - database the stats table will be created in
-u username        - username to logon with
-p password        - the user is prompted for password if not set on the command line
-n owner           - owner of the stats table
-t table_name      - name of the stats table to create
-s tablespace_name - tablespace name in which to create the stats table
                     defaults to the default tablespace for the owner
"
}

declare PASSWORD=''  # must be defined

while getopts d:u:n:t:s:o:p:h arg
do
	case $arg in
		u) USERNAME=$OPTARG;;
		d) DATABASE=$OPTARG;;
		n) OWNER=$OPTARG;;
		t) TABLE_NAME=$OPTARG;;
		s) TBS_NAME=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		p) PASSWORD="$OPTARG";;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$TBS_NAME:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# tbs_name will be set to 'NULL' if empty and the sql script 
# will get the default tablespace for the user
[ -z "$TBS_NAME" ] && TBS_NAME='NULL'

# argument validation section 
# concat all args together
ALLARGS=":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$TBS_NAME:$ORACLE_SID:"
# upper case args
ALLARGS=$(upperCase $ALLARGS)

# components of RE 
export ALNUM1="[[:alnum:]]+"
export ALNUM3="[[:alnum:]]{3,}"
export USER_RE='[[:alnum:]_$]+'
export DATABASE_RE='[[:punct:][:alnum:]]{3,}'
export OWNER_RE='[[:alnum:]_$]+'
export TABLE_RE='[[:alnum:]_#$]+'
export TBS_RE='[[:alnum:]_$]*'

# bash
# order of argument regexs
# nearly all arguments are required
# :$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$TBS_NAME:
declare -a VALID_ARGS=(
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$TBS_RE:$DATABASE_RE:"
)

validate_args "$ALLARGS" "${VALID_ARGS[@]}"
ARG_RESULT=$?

if [ "$ARG_RESULT" != '0' ]; then
	usage
	[ "$ECHO_ARGS" == 'YES' ] && {
		echo "ARG_RESULT: $ARG_RESULT"
		echo "ALLARGS: $ALLARGS"
		echo "VALID_ARGS: ${VALID_ARGS[*]}"
	}
	exit 1
fi


# end of argument validation

CALLED_SCRIPT=$0
CALLED_DIRNAME=$(getPath $CALLED_SCRIPT);
SCRIPT_FQN=$(getScriptPath $CALLED_SCRIPT)
FQN_DIRNAME=$(getPath $SCRIPT_FQN)

# this is the real location of the script
# even if called with symlink
SCRIPT_HOME=$(getRelPath $CALLED_DIRNAME $FQN_DIRNAME)
SQLDIR=$SCRIPT_HOME/../sql
CREATE_STATS_SQL_SCRIPT=$SQLDIR/create_stat_table.sql

[ -f $CREATE_STATS_SQL_SCRIPT ] || {
	cannot read $CREATE_STATS_SQL_SCRIPT
	exit 3
}

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus

printf "Creating STATS_TABLE: %s\n" $TABLE_NAME
printf "  Database: %s \n  Schema: %s \n  Tablespace: %s\n" $DATABASE $USERNAME $TBS_NAME

# get password from database
PASSWORD=$(getPassword $PASSWORD)

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

$SQLPLUS /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$DATABASE
@$CREATE_STATS_SQL_SCRIPT $OWNER $TABLE_NAME $TBS_NAME
EOF


set SQLPATH=$SQLPATH_OLD

