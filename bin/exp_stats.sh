#!/bin/bash

DEBUG=0
FUNCTIONS_FILE=/home/jkstill/bin/functions.sh; export FUNCTIONS_FILE
. $FUNCTIONS_FILE

function usage {
	printf "
$0 

Data Dictionary, System and Schema statistics can be exported to
an EXP file using the Oracle EXP utility

-o ORACLE_SID  - used to set local oracle environment
-d database    - database where stats table resides
-u username    - database logon account
-n owner       - owner of stats table
-i statid      - optional parameter to specify statid
                 this may use SQL wildcards
-s schema      - schema for which to export stats
                 may use SQL wild cards - defaults to all
					  use 'system' to get system stats
-t table_name  - name of stats table

create an exp dump of an oracle stats table

"
}

while getopts d:u:i:n:t:o:s:h arg
do
	case $arg in
		u) USERNAME=$OPTARG;;
		d) DATABASE=$OPTARG;;
		n) OWNER=$OPTARG;;
		t) TABLE_NAME=$OPTARG;;
		i) STATID=$OPTARG;;
		s) SCHEMA=$OPTARG;;
		o) ORACLE_SID=$OPTARG;;
		h) usage;exit;;
		*) echo "invalid argument specified"; usage;exit 1;
	esac

done

# check for empty arguments - exit if none
# do not check for ORACLE_SID as it may already be set
chkForEmptyArgs ":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$STATID:$SCHEMA:"
[ "$?" -eq 0 ] && {
	usage
	exit
}

[ -z "$STATID" ] && STATID='%';
[ -z "$SCHEMA" ] && SCHEMA='%';
SCHEMA=$(upperCase $SCHEMA)

# argument validation section 
# concat all args together
ALLARGS=":$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$STATID:$SCHEMA:$ORACLE_SID:"
# upper case args
ALLARGS=$(upperCase $ALLARGS)

# components of RE 
export ALNUM1="[[:alnum:]]+"
export ALNUM3="[[:alnum:]]{3,}"
export USER_RE='[[:alnum:]_$]+'
export DATABASE_RE=$ALNUM3
export OWNER_RE='[[:alnum:]_$]+'
export TABLE_RE='[[:alnum:]_#$]+'
export STATID_RE='(%|[[:alnum:]_$%]+)'
export SCHEMA_RE='(%|[[:alnum:]_$%]+)'

# bash
# order of argument regexs
# username, database, owner, tablename, oracle_sid always required
# statid is optional , and may use wildcards
# schema is optional - defaulted to %'
# :$USERNAME:$DATABASE:$OWNER:$TABLE_NAME:$STATID:$SCHEMA:$ORACLE_SID:
VALID_ARGS=(
":$USER_RE:$DATABASE_RE:$OWNER_RE:$TABLE_RE:$STATID_RE:$SCHEMA_RE:$DATABASE_RE:" \
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

echo "ALLARGS: $ALLARGS"

# end of argument validation
# statid as created by export scripts is in upper case
STATID=$(upperCase $STATID)

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
EXP=$ORACLE_HOME/bin/exp

printf "export STATS_TABLE: %s\n" $TABLE_NAME
printf "  Database: %s \n  Schema: %s \n" $DATABASE $USERNAME

# get password from database

PASSWORD=$(getPassword $USERNAME $DATABASE)
PASSWORD='"'$PASSWORD'"' # quoted for special characters

set SQLPATH_OLD=$SQLPATH
unset SQLPATH

NLS_SCRIPT=$SQLDIR/get_nls.sql
[ -f "$NLS_SCRIPT" ] || {
	echo cannot read $NLS_SCRIPT
	exit 3
}

SQLPATH_OLD=$SQLPATH
unset SQLPATH

# get the nls setting
export NLS_LANG=$( \
$SQLPLUS -S /nolog <<-EOF
connect $USERNAME/$PASSWORD@$DATABASE
@$NLS_SCRIPT
EOF
)

echo NLS_LANG: $NLS_LANG

$EXP userid="${USERNAME}/${PASSWORD}@${DATABASE}" \
	file=${OWNER}_${DATABASE}_${STATID}_${SCHEMA}_stats.dmp \
	log=${OWNER}_${DATABASE}_stats_${STATID}_${SCHEMA}_exp.log \
	tables=\("$OWNER"."$TABLE_NAME"\) \
	query=\"where statid like \'${STATID}\'\ and decode\(c5,null,\'SYSTEM\',c5\) like \'${SCHEMA}\'\" \
	statistics=none triggers=n constraints=n grants=n indexes=n

SQLPATH=$SQLPATH_OLD

