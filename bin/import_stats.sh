#!/bin/bash

DEBUG=0

# must start in the statops directory
[ $(basename $(pwd)) == 'statops' ] || { echo "please start from the statops directory"; exit 1; }
source bin/bootstrap.sh || { echo "could not source bootstrap.sh"; exit 1; }

function usage {
	printf "
$0 

Data Dictionary, System and Schema statistics can be imported from
a stats table into the database using this script.

The statistics must already exist in a statistics table previously
created with DBMS_STATS.CREATE_STAT_TABLE.

The statistics in this table could have been previously created
via the exports_stats.sh script which would save a copy of current
database stats, or via create_stat_table.sh and a subsequent
import of statistics via imp_stats.sh


-o ORACLE_SID - ORACLE_SID used to set local oracle environment

-d database    - database to import statistics to

-u username    - user to logon as
                 this user also must own the table used to import
                 statistics as specified by the -t argument

-p password     - the user is prompted for password if not set on the command line

-n owner       - owner of stats table

-t table_name  - statistics table to import from 
                 as created by dbms_stats.create_stat_table

-s schema      - import oracle stats for schema when -T argument is 'schema'

-T stats_type  - type of statistics to import
                 valid values: SYSTEM_STATS SCHEMA DICTIONARY_STATS FIXED_OBJECTS_STATS
                 when the type is SCHEMA the -s argument must also be used
                 case is unimportant for stats_type

-i statid      - statid of stats to import

-v             - noinvalidate - yes or no
                 if NO then cursors will be invalidated to force use of new stats
                 defaults to YES

-f             - force import of stats even if stats are locked - yes or no
                 defaults to NO

"
}

declare PASSWORD=''  # must be defined

while getopts d:u:i:n:f:v:t:s:o:T:h arg
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
		f) FORCE_IMPORT=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		p) PASSWORD="$OPTARG";;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:$STATID:$NOINVALIDATE:$FORCE_IMPORT:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# convert stats_type to UC
if [ -n "$STATS_TYPE" ]; then
	STATS_TYPE=$(upperCase $STATS_TYPE)
fi

if [ -n "$STATID" ]; then
	STATID=$(upperCase $STATID)
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
case $FORCE_IMPORT in
	y|Y|yes|YES|Yes) FORCE_IMPORT='YES';;
	*) FORCE_IMPORT='NO';;
esac

#echo NOINVALIDATE: $NOINVALIDATE
# argument validation section 
# concat all args together
ALLARGS=":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:$STATID:$NOINVALIDATE:$FORCE_IMPORT:$ORACLE_SID:"
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
# import non-schema stats from stats table
# import schema stats from stats table
# :$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$SCHEMA:$STATS_TYPE:$STATID:$NOINVALIDATE:$FORCE_IMPORT:$ORACLE_SID:"
declare -a VALID_ARGS=(
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE::(DICTIONARY_STATS|SYSTEM_STATS|FIXED_OBJECTS_STATS):$STATID_RE:$NOINV_RE:$FORCE_RE:$DATABASE_RE:"
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$SCHEMA_RE:(SCHEMA):$STATID_RE:$NOINV_RE:$FORCE_RE:$DATABASE_RE:"
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

# determine which sql script to use
# import_stats.sql does system, fixed_objects and dictionary

if [ "$STATS_TYPE" == 'SCHEMA' ]; then
	IMPORT_STATS_SQL_SCRIPT=$SQLDIR/import_schema_stats.sql
else
	IMPORT_STATS_SQL_SCRIPT=$SQLDIR/import_stats.sql
fi

[ -f "$IMPORT_STATS_SQL_SCRIPT" ] || {
	cannot read $IMPORT_STATS_SQL_SCRIPT
	exit 3
}

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus

printf "Importing Schema Stats for: %s  statid: \n" $SCHEMA $STATID
printf "  Database: %s \n  Table: %s \n\n" $DATABASE $TABLE_NAME 

# get password from database
PASSWORD=$(getPassword $PASSWORD)

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

if [ "$STATS_TYPE" == 'SCHEMA' ]; then
	[ -z "$SCHEMA" ] && {
		usage
		exit 4
	}
	echo IMP: $IMPORT_STATS_SQL_SCRIPT $SCHEMA $TABLE_NAME $STATID
	$SQLPLUS /nolog <<-EOF
	connect $USERNAME/"$PASSWORD"@$DATABASE
	@$IMPORT_STATS_SQL_SCRIPT $OWNER $TABLE_NAME $SCHEMA $STATID $NOINVALIDATE $FORCE_IMPORT
	EOF
else
	echo IMP: $IMPORT_STATS_SQL_SCRIPT $USERNAME $TABLE_NAME $STATS_TYPE 
	$SQLPLUS /nolog <<-EOF
	connect $USERNAME/"$PASSWORD"@$DATABASE
	@$IMPORT_STATS_SQL_SCRIPT $OWNER $TABLE_NAME $STATID $STATS_TYPE $NOINVALIDATE $FORCE_IMPORT
	EOF
fi

set SQLPATH=$SQLPATH_OLD


