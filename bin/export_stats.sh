#!/bin/bash

DEBUG=0

# must start in the statops directory
[ $(basename $(pwd)) == 'statops' ] || { echo "please start from the statops directory"; exit 1; }
source bin/bootstrap.sh || { echo "could not source bootstrap.sh"; exit 1; }

function usage {
	printf "
$0 

Data Dictionary, System and Schema statistics can be exported to
to a table that has been previously created with database package
DBMS_STATS.CREATE_STAT_TABLE

This table can be created with the create_stat_table.sh script


-o ORACLE_SID - ORACLE_SID used to set local oracle environment

-d database     - database to export statistics from

-u username     - user to logon as
                  this user also must own the table used to export
                  statistics as specified by the -t argument

-p password     - the user is prompted for password if not set on the command line

-n owner        - owner of stats table in -t 

-r dryrun       - show VALID_ARGS and exit without running the job

-t table_name   - statistics table to export to 
                  as created by dbms_stats.create_stat_table

-s schema       - export oracle stats for schema when -T argument is 'schema'

-T stats_type  - type of statistics to export
                 valid values: SYSTEM_STATS SCHEMA DICTIONARY_STATS FIXED_OBJECTS_STATS
                 when the type is SCHEMA the -s argument must also be used
                 case is unimportant for stats_type

schema name will be the stat_id prefix for schema stats exports

stats_type will be the stat_id prefix for non-schema stats exports

sysdate will be the stat_id suffix

"
}

declare PASSWORD=''  # must be defined
declare DRYRUN=N

while getopts d:u:t:n:s:o:p:T:hr arg
do
	case $arg in
		u) USERNAME=$OPTARG;;
		d) DATABASE=$OPTARG;;
		n) OWNER=$OPTARG;;
		t) TABLE_NAME=$OPTARG;;
		s) SCHEMA=$OPTARG;;
		T) STATS_TYPE=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		p) PASSWORD="$OPTARG";;
		r) DRYRUN=Y;;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# some args need to be upper case
STATS_TYPE=$(upperCase $STATS_TYPE)

# argument validation section 
# concat all args together
# :USERNAME:DATABASE:OWNER:TABLE_NAME:SCHEMA:STATS_TYPE:ORACLE_SID:
ALLARGS=":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:$ORACLE_SID:"
# upper case args
ALLARGS=$(upperCase $ALLARGS)

# components of RE 
export ALNUM1="[[:alnum:]]+"
export ALNUM3="[[:alnum:]]{3,}"
export USER_RE=$ALNUM3
export DATABASE_RE='[[:punct:][:alnum:]]{3,}'
export OWNER_RE='[[:alnum:]_$]+'
export TABLE_RE='[[:alnum:]_#$]+'
export SCHEMA_RE='[[:alnum:]_$]+'

# bash
# order of argument regexs
# export non-schema stats to table
# delete schema stats to table
declare -a VALID_ARGS=(":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:(DICTIONARY_STATS|SYSTEM_STATS|FIXED_OBJECTS_STATS):$DATABASE_RE:"
	":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$SCHEMA_RE:(SCHEMA):$DATABASE_RE:")

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

# determine which sql script to use
# export_stats.sql does system, fixed_objects and dictionary

if [ "$STATS_TYPE" == 'SCHEMA' ]; then
	EXPORT_STATS_SQL_SCRIPT=$SQLDIR/export_schema_stats.sql
else
	EXPORT_STATS_SQL_SCRIPT=$SQLDIR/export_stats.sql
fi

[ -f "$EXPORT_STATS_SQL_SCRIPT" ] || {
	cannot read $EXPORT_STATS_SQL_SCRIPT
	exit 3
}

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus

printf "Exporting Schema Stats for: %s\n" $SCHEMA
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

if [ "$STATS_TYPE" == 'SCHEMA' ]; then
	echo EXP: $EXPORT_STATS_SQL_SCRIPT $SCHEMA $OWNER $TABLE_NAME
	$SQLPLUS /nolog <<-EOF
	connect $USERNAME/"$PASSWORD"@$DATABASE
	@$EXPORT_STATS_SQL_SCRIPT $SCHEMA $OWNER $TABLE_NAME
	EOF
else
	echo EXP: $EXPORT_STATS_SQL_SCRIPT $USERNAME $TABLE_NAME $STATS_TYPE 
	$SQLPLUS /nolog <<-EOF
	connect $USERNAME/"$PASSWORD"@$DATABASE
	@$EXPORT_STATS_SQL_SCRIPT $OWNER $TABLE_NAME $STATS_TYPE 
	EOF
fi

set SQLPATH=$SQLPATH_OLD


