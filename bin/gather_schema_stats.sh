#!/bin/bash

DEBUG=0
FUNCTIONS_FILE=/home/jkstill/bin/functions.sh; export FUNCTIONS_FILE
. $FUNCTIONS_FILE

function usage {
	printf "
$0

-o ORACLE_SID - used to set local oracle environment
-d database   - database of schema to be analyzed
-s schema     - schema to be analyzed
-u username   - username used to run dbms_stats
-t time       - analyzes stats when more than N days old
                this may be a decimal value eg. 0.0007 is 1 minute
                defaults to 14 days
-p            - parallel processes - defaults to 1

The procedure dbms_stats.gather_schema_stats is NOT used.

See the gather_schema_stats.sql script for details.

"

}

while getopts d:u:t:s:o:t:p:h arg
do
	case $arg in
		u) USERNAME=$OPTARG;;
		d) DATABASE=$OPTARG;;
		p) DEGREE=$OPTARG;;
		s) SCHEMA=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		t) DAYS_OLD=$OPTARG;;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$DEGREE:$SCHEMA:$DAYS_OLD:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# default to 2 weeks
[ -z "$DAYS_OLD" ] && {
	DAYS_OLD=14
}

# default to 1
[ -z "$DEGREE" ] && {
	DEGREE=1
}

# argument validation section 
# concat all args together

ALLARGS=":$USERNAME:$DATABASE:$DEGREE:$SCHEMA:$DAYS_OLD:$ORACLE_SID:"
ALLARGS=$(upperCase $ALLARGS)

# components of RE 
export ALNUM1="[[:alnum:]]+"
export ALNUM3="[[:alnum:]]{3,}"
export USER_RE='[[:alnum:]_$]+'
export DATABASE_RE='[[:punct:][:alnum:]]{3,}'
export OWNER_RE='[[:alnum:]_$]+'
export STATID_RE='[[:alnum:]_$]+'
export TIME_RE="[[:digit:].]+"
export DEGREE_RE='[[:digit:]]+'

# bash
# order of argument regexs
# required args: 
# delete non-schema stats from stats table
# delete schema stats from dictionary
# delete schema stats from stats table
# delete schema stats from dictionary
# :$USERNAME:$DATABASE:$DEGREE:$SCHEMA:$DAYS_OLD:$ORACLE_SID:
declare -a VALID_ARGS=(
":$USER_RE:$DATABASE_RE:$DEGREE_RE:$USER_RE:$TIME_RE:$DATABASE_RE:"
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
STATS_SQL_SCRIPT=$SQLDIR/gather_schema_stats.sql
STATS_ERR_RPT=$SQLDIR/stats_err_rpt.sql

[ -f "$STATS_SQL_SCRIPT" ] || {
	cannot read $STATS_SQL_SCRIPT
	exit 3
}

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus

printf "Gathering Statistics for Schema: %s\n" $SCHEMA
printf "  Database: %s \n" $DATABASE 
printf "  Parallel: %s \n\n" $DEGREE 

# get password from database
PASSWORD=$(getPassword $USERNAME $DATABASE)

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

echo STATS: $STATS_SQL_SCRIPT $SCHEMA $DAYS_OLD $DEGREE

$SQLPLUS /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$DATABASE
@$STATS_SQL_SCRIPT $SCHEMA $DAYS_OLD $DEGREE
@$STATS_ERR_RPT
EOF

set SQLPATH=$SQLPATH_OLD



