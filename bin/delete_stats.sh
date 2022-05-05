#!/bin/bash

DEBUG=0
FUNCTIONS_FILE=/home/jkstill/bin/functions.sh; export FUNCTIONS_FILE
. $FUNCTIONS_FILE

function usage {
	printf "
$0  deletes statistics from the stats table or the dictionary.

-o ORACLE_SID - ORACLE_SID used to set local oracle environment

-d database    - database to delete statistics from

-u username    - user to logon as

-n owner       - owner of the stats table specified by -t

-t table_name  - statistics table to delete from
                 as created by dbms_stats.create_stat_table

-i statid      - statid of stats to delete

if both -t table_name and -i statid are NOT specified on the command
line, then statistics will be deleted from the data dictionary.

if both -t table_name and -i statid ARE specified on the command line,
then statistics will be deleted from the statistics table.

Make sure you are using these options correctly!

-s schema      - delete oracle stats for schema when -T argument is 'schema'

-T stats_type  - type of statistics to delete
                 valid values: SYSTEM_STATS SCHEMA DICTIONARY_STATS FIXED_OBJECTS_STATS
                 when the type is SCHEMA the -s argument must also be used
                 case is unimportant for stats_type

-v             - noinvalidate - yes or no
                 if NO then cursors will be invalidated to force use of new stats
                 defaults to YES

-f             - force delete of stats even if stats are locked - yes or no
                 defaults to NO

"
}

while getopts d:u:s:o:n:t:i:v:f:T:h arg
do
	case $arg in
		u) USERNAME=$OPTARG;;
		d) DATABASE=$OPTARG;;
		n) OWNER=$OPTARG;;
		t) TABLE_NAME=$OPTARG;;
		s) SCHEMA=$OPTARG;;
		T) STATS_TYPE=$OPTARG;;
		i) STATID=$OPTARG;;
		v) NOINVALIDATE=$OPTARG;;
		f) FORCE_DELETE=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:$STATID:$NOINVALIDATE:$FORCE_DELETE:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# convert stats_type to UC
if [ -n "$STATS_TYPE" ]; then
	STATS_TYPE=$(upperCase $STATS_TYPE)
fi

# convert noinvalidate to YES or NO as that is what sql scripts expect
# default is YES - I just love negative logic...
case $NOINVALIDATE in
	n|N|no|NO|No) NOINVALIDATE='NO';;
	*) NOINVALIDATE='YES';;
esac
#echo NOINVALIDATE: $NOINVALIDATE

# convert force delete to YES or NO as that is what sql scripts expect
# default is NO 
case $FORCE_DELETE in
	y|Y|yes|YES|Yes) FORCE_DELETE='YES';;
	*) FORCE_DELETE='NO';;
esac

#echo FORCE_DELETE: $FORCE_DELETE
# argument validation section 
# concat all args together
ALLARGS=":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:$STATID:$NOINVALIDATE:$FORCE_DELETE:$ORACLE_SID:"
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
export FORCE_RE='([YyNn]|YES|yes|NO|no)'
export STATID_RE='[[:alnum:]_$]+'


# bash
# order of argument regexs
# delete non-schema stats from dictionary
# delete non-schema stats from stats table
# delete schema stats from dictionary
# delete schema stats from stats table
# delete schema stats from dictionary
# :$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:$STATID:$NOINVALIDATE:$ORACLE_SID:"
declare -a VALID_ARGS=(
":$USER_RE:$DATABASE_RE::::(DICTIONARY_STATS|SYSTEM_STATS|FIXED_OBJECTS_STATS)::$NOINV_RE:$FORCE_RE:$DATABASE_RE:"
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE::(DICTIONARY_STATS|SYSTEM_STATS|FIXED_OBJECTS_STATS):$STATID_RE:$NOINV_RE:$FORCE_RE:$DATABASE_RE:"
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$SCHEMA_RE:(SCHEMA):$STATID_RE:$NOINV_RE:$FORCE_RE:$DATABASE_RE:"
":$USER_RE:$DATABASE_RE:::$SCHEMA_RE:(SCHEMA)::$NOINV_RE:$FORCE_RE:$DATABASE_RE:"
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

# convert empty arguments to literal NULL for SQL script
[ -z "$TABLE_NAME" -a -z "$STATID" ] && {
	TABLE_NAME='NULL'
	STATID='NULL'
	OWNER='NULL'
}


if [ -n "$STATID" ]; then
	STATID=$(upperCase $STATID)
fi

CALLED_SCRIPT=$0
CALLED_DIRNAME=$(getPath $CALLED_SCRIPT);
SCRIPT_FQN=$(getScriptPath $CALLED_SCRIPT)
FQN_DIRNAME=$(getPath $SCRIPT_FQN)

# this is the real location of the script
# even if called with symlink
SCRIPT_HOME=$(getRelPath $CALLED_DIRNAME $FQN_DIRNAME)
SQLDIR=$SCRIPT_HOME/../sql

# determine which sql script to use
# delete_stats.sql does system, fixed_objects and dictionary

if [ "$STATS_TYPE" == 'SCHEMA' ]; then
	DELETE_STATS_SQL_SCRIPT=$SQLDIR/delete_schema_stats.sql
else
	DELETE_STATS_SQL_SCRIPT=$SQLDIR/delete_stats.sql
fi

[ -f "$DELETE_STATS_SQL_SCRIPT" ] || {
	echo cannot read $DELETE_STATS_SQL_SCRIPT
	exit 3
}

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus

printf "Deleting Schema Stats for: %s  statid: \n" $SCHEMA $STATID
printf "  Database: %s \n  Table: %s \n\n" $DATABASE $TABLE_NAME 

# get password from database
PASSWORD=$(getPassword $USERNAME $DATABASE)

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

$PRINTF "DEL: 
SCRIPT:       $DELETE_STATS_SQL_SCRIPT 
USERNAME:     $USERNAME
DATABASE:     $DATABASE
SCHEMA:       $SCHEMA 
OWNER:        $OWNER
TABLE_NAME:   $TABLE_NAME 
STATS_TYPE:   $STATS_TYPE
STATID:       $STATID 
NOINVALIDATE: $NOINVALIDATE
"


if [ "$STATS_TYPE" == 'SCHEMA' ]; then
	$SQLPLUS /nolog <<-EOF
	connect $USERNAME/"$PASSWORD"@$DATABASE
	@$DELETE_STATS_SQL_SCRIPT $SCHEMA $TABLE_NAME $STATID $NOINVALIDATE $FORCE_DELETE
	EOF
else
	echo DEL: $DELETE_STATS_SQL_SCRIPT $USERNAME $TABLE_NAME $STATS_TYPE 
	$SQLPLUS /nolog <<-EOF
	connect $USERNAME/"$PASSWORD"@$DATABASE
	@$DELETE_STATS_SQL_SCRIPT $OWNER $TABLE_NAME $STATID $STATS_TYPE $NOINVALIDATE $FORCE_DELETE
	EOF
fi

set SQLPATH=$SQLPATH_OLD


