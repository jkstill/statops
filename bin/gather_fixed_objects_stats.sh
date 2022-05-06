#!/bin/bash

DEBUG=0

# must start in the statops directory
[ $(basename $(pwd)) == 'statops' ] || { echo "please start from the statops directory"; exit 1; }
source bin/bootstrap.sh || { echo "could not source bootstrap.sh"; exit 1; }

function usage {
	printf "
$0 

-o ORACLE_SID - ORACLE_SID used to set local oracle environment

-d database    - database to gather fixed objects statistics on

-u username    - user to logon as

-p password     - the user is prompted for password if not set on the command line

-n owner       - owner of stats table

-r dryrun      - show VALID_ARGS and exit without running the job

-t table_name  - statistics table to import to 
                 as created by dbms_stats.create_stat_table

if both -t table_name and -n owner arguments are empty then stats
will be gathered directly to the data dictionary

-v             - noinvalidate - yes or no
                 if NO then cursors will be invalidated to force use of new stats
                 defaults to YES - any value other than y/Y/YES is change to NO

Note: gather_fixed_objects_stats gathers statistics to the statistics table.
      fixed object statistics are updated in the data dictionary as well 
"
}

declare PASSWORD=''  # must be defined
declare DRYRUN=N

while getopts d:u:t:n:v:o:p:T:hr arg
do
	case $arg in
		u) USERNAME=$OPTARG;;
		d) DATABASE=$OPTARG;;
		n) OWNER=$OPTARG;;
		t) TABLE_NAME=$OPTARG;;
		v) NOINVALIDATE=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		p) PASSWORD="$OPTARG";;
		r) DRYRUN=Y;;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$NOINVALIDATE:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# convert noinvalidate to YES or NO as that is what sql scripts expect
# default is YES - I just love negative logic...
case $NOINVALIDATE in
	n|N|no|NO|No) NOINVALIDATE='NO';;
	*) NOINVALIDATE='YES';;
esac

# argument validation section 
# concat all args together
ALLARGS=":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$NOINVALIDATE:$ORACLE_SID:"
# upper case args
ALLARGS=$(upperCase $ALLARGS)

# components of RE 
export ALNUM1="[[:alnum:]]+"
export ALNUM3="[[:alnum:]]{3,}"
export USER_RE='[[:alnum:]_$]+'
export DATABASE_RE='[[:punct:][:alnum:]]{3,}'
export OWNER_RE='[[:alnum:]_$]+'
export TABLE_RE='[[:alnum:]_#$]+'
export SCHEMA_RE='[[:alnum:]_$]+'
export NOINV_RE='([YyNn]|YES|yes|NO|no)'
export STATID_RE='[[:alnum:]_$]+'


# bash
# order of argument regexs
# required args: database, username, table_name, owner, oracle_sid
# noinvalidate will default to YES
# :$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$NOINVALIDATE:$ORACLE_SID:
declare -a VALID_ARGS=(
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$NOINV_RE:$DATABASE_RE:"
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
	exit
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

# determine which sql script to use
# import_stats.sql does system, fixed_objects and dictionary

GATHER_FIXED_SQL_SCRIPT=$SQLDIR/gather_fixed_objects_stats.sql

[ -f "$GATHER_FIXED_SQL_SCRIPT" ] || {
	cannot read $GATHER_FIXED_SQL_SCRIPT
	exit 3
}

[ \( -z "$TABLE_NAME" -a -n "$OWNER" \) -o \( -n "$TABLE_NAME" -a -z "$OWNER" \) ] && {
	usage 
	exit 4
}

STATID='FIXED'
[ -z "$TABLE_NAME" -a -z "$OWNER" ] && {
	TABLE_NAME='NULL'
	STATID='NULL'
	OWNER='NULL'
}

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus

printf "Gathering Fixed Objects Stats\n"
printf "  Database: %s \n  Table: %s \n\n" $DATABASE $TABLE_NAME 

[[ $DRYRUN == 'Y' ]] && {
	echo
	for re in "${VALID_ARGS[@]}}"
	do
		echo REGEX: $re
	done
	echo
	exit
}

# get password from database
PASSWORD=$(getPassword $PASSWORD)

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

#echo FIXED: $USERNAME $PASSWORD $DATABASE $GATHER_FIXED_SQL_SCRIPT $USERNAME $OWNER $TABLE_NAME $STATID $NOINVALIDATE
$SQLPLUS /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$DATABASE
@$GATHER_FIXED_SQL_SCRIPT $OWNER $TABLE_NAME 'FIXED' $NOINVALIDATE
EOF

set SQLPATH=$SQLPATH_OLD


