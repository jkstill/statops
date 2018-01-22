#!/bin/bash

DEBUG=0
FUNCTIONS_FILE=/home/jkstill/bin/functions.sh; export FUNCTIONS_FILE
. $FUNCTIONS_FILE

function usage {
	printf "
$0 

List statistics that have been saved with export_stats.sh
or any utility that exports Data Dictionary Statistics to
a table created via DBMS_STATS.CREATE_STAT_TABLE

-o ORACLE_SID - ORACLE_SID used to set local oracle environment

-d database     - database where stats table is found
-u username     - username to logon with
-n owner        - owner of statistics table
-t table_name   - statistics table to list from
                  as created by dbms_stats.create_stat_table

-s schema       - schema name for which to list statistics - defaults to %s

-b              - object name to search for - table or index name - defaults to %s
                  SQL wild cards allowed 
                  quote wild cards if used
                  the only valid object name for levels 1 and 2 is %s

-l level        - level of detail to show - defaults to 2
                  MUST be 3 or greater if -s and/or -b are used
                  1=statid only
                  2=statid and owners only
                  3=statid, owners, type and name
                  4=statid, owners, type, name and partition
                  5=statid, owners, type, name and column

" '%' '%' '%'
}

while getopts d:u:n:b:l:t:s:o:h arg
do
	case $arg in
		u) USERNAME=$OPTARG;;
		d) DATABASE=$OPTARG;;
		n) OWNER=$OPTARG;;
		t) TABLE_NAME=$OPTARG;;
		l) DLEVEL=$OPTARG;;
		s) SCHEMA=$OPTARG;;
		b) OBJECT=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$DLEVEL:$SCHEMA:$OBJECT:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

# default dlevel
[ -z "$DLEVEL" ] && DLEVEL=2
# default object
[ -z "$OBJECT" ] && OBJECT='%'
# default schema
[ -z "$SCHEMA" ] && SCHEMA='%'

# argument validation section 
# concat all args together
ALLARGS=":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$DLEVEL:$SCHEMA:$OBJECT:$ORACLE_SID:"
# upper case args
ALLARGS=$(upperCase $ALLARGS)

# components of RE 
export ALNUM1="[[:alnum:]]+"
export ALNUM3="[[:alnum:]]{3,}"
export USER_RE='[[:alnum:]_$]+'
export DATABASE_RE=$ALNUM3
export OWNER_RE='[[:alnum:]_$]+'
export TABLE_RE='[[:alnum:]_#$]+'
export OBJECT_RE='[[:alnum:]_#$%]+'
export OBJECT_RE='*'
export DLEVEL_RE1='[1-5]{1}'
export DLEVEL_RE2='[3-5]{1}'
export SCHEMA_RE='[[:alnum:]_$%]+'
export SCHEMA_RE='*'


# bash
# order of argument regexs
# username,database,owner,table_name,oracle_sid always required
# dlevel must be 1-5 (defaulted to 2)
# object_name must be % or name + wild cards - defaults to %
# object_name other than % only valid with levels 3-5
# schema other than % only valid with levels 3-5

# :$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$DLEVEL:$SCHEMA:$OBJECT:$ORACLE_SID:
VALID_ARGS=(
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$DLEVEL_RE2:$SCHEMA_RE:$OBJECT_RE:$DATABASE_RE:" \
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$DLEVEL_RE1:%:%:$DATABASE_RE:" \
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

# setup environment for oracle_database
export ORACLE_SID
export ORAENV_ASK=NO
. $ORAENV_SH $ORACLE_SID

SQLPLUS=$ORACLE_HOME/bin/sqlplus

printf "Exporting Schema Stats for: %s\n" $SCHEMA
printf "  Database: %s \n  Table: %s \n\n" $DATABASE $TABLE_NAME 

# get password from database
PASSWORD=$(getPassword $USERNAME $DATABASE)

# get password on command line if blank
# returns if password already set
getPasswordInteractive 'PASSWORD'

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

SQL_SCRIPT=$SQLDIR/list_stats.sql

echo LIST: $SQL_SCRIPT $OWNER $TABLE_NAME $DLEVEL $OBJECT

$SQLPLUS /nolog <<-EOF
connect $USERNAME/"$PASSWORD"@$DATABASE
@$SQL_SCRIPT $OWNER $TABLE_NAME $DLEVEL $SCHEMA $OBJECT
EOF

set SQLPATH=$SQLPATH_OLD

