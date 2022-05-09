
#######################################
# ECHO_ARGS used in scripts to determine
# if args should be echod on error
#######################################
ECHO_ARGS='YES'

#######################################
# figure out where this is running
#######################################

[ -x '/bin/uname' ] && UNAME='/bin/uname'
[ -x '/usr/bin/uname' ] && UNAME='/usr/bin/uname'
[ -x '/bin/cut' ] && CUT='/bin/cut'
[ -x '/usr/bin/cut' ] && CUT='/usr/bin/cut'
export UNAME CUT

export FDOMAIN=$( $UNAME -n | $CUT -f2 -d'.' )

#######################################
# set the location of the script used
# to set the Oracle environment
# probably /usr/local/bin/oraenv for 
# most installations
#######################################
ORAENV_SH=/usr/local/bin/oraenv
ORAENV_ASK=NO
export ORAENV_SH ORAENV_ASK

#######################################
# set DEBUG to default of 0 if not already set
#######################################
: ${DEBUG:=0}

#######################################
# check to see if FUNCTIONS_FILE set
#######################################
[ -z "$FUNCTIONS_FILE" ] && {

	echo 
	echo error in $0
	echo PLEASE set the FUNCTIONS_FILE variable in $0 
	echo to the full path to functions.sh and try again.
	echo 
	echo eg.

	echo 'FUNCTIONS_FILE=$HOME/scripts/functions.sh; export FUNCTIONS_FILE'
	echo '. $FUNCTIONS_FILE'
	echo 

	exit 5
}

function debug {
	typeset LABEL=$1
	shift
	typeset OUT=$*
	if [ "$DEBUG" -gt 0 ]; then
		printf "$LABEL $OUT\n";
	fi
}

function hardpath {
	typeset ProgName ProgPath ProgVar
	ProgName=$1
	ProgVar=$2
	ProgVarName=$(echo $2)

	typeset idx=0
	typeset DIRS

	debug ====== $2 ==========================
	
	# setup search paths here
	for path in /etc /bin /sbin /usr/bin /usr/local/bin $HOME~/bin 
	do
		DIRS[$idx]=$path
		debug LOAD_PATHS $path
		(( idx = idx + 1))
	done

	idx=0
	typeset maxidx foundit
	foundit=0
	(( maxidx = ${#DIRS[*]} - 1 ))

	while (( foundit < 1 ))
	do
		debug FOUNDIT $foundit
		debug PATH_INDEX $idx
		debug SEARCH_PATH ${DIRS[$idx]}
		[ -x "${DIRS[$idx]}/$ProgName" ] && {
			ProgPath=${DIRS[$idx]}/$ProgName
			#echo "$ProgVarName - $ProgName: $ProgPath" 
			foundit=1
		}
		(( idx = idx+1 ))

		if [[ $idx -gt $maxidx ]]; then
			echo max idx reached setting hardpath for $ProgName:$ProgVar
			break
		fi
	done

	# just check to see if file executable
	[ -x "$ProgPath" ] || {
		echo "checking $ProgName"
		echo "ProgName: $ProgName"
		echo "ProgPath: $ProgPath"
		echo "$ProgName - $ProgPath is not executable"
		exit 1
	}

	eval "$ProgVar=$ProgPath"

}

# setup full qualified pathnames for external programs
# the 'continue' command is used to go to next iteration
# of loop to pick up second value in each pair
# do not set a variable of GZIP, as that is an env variable
# used by gzip.
i=0
for x in \
 find FIND \
 dirname DIRNAME \
 basename BASENAME \
 date DATE \
 xargs XARGS \
 cut CUT \
 head HEAD \
 grep GREP \
 mkdir MKDIR \
 rmdir RMDIR \
 gzip GZIPCMD \
 gunzip GUNZIP \
 cat CAT \
 tar TAR \
 ls LS \
 printf PRINTF \
 uname UNAME \
 file FILE \
 mknod MKNOD \
 rm RM \
 awk AWK \
 sed SED \
 stat STAT \
 tr TR \
 chown CHOWN \
 chmod CHMOD \
 who WHO \
 id ID \
 bash SHELL \
 ksh KSH \
 kill KILL \
 ps PS \
 touch TOUCH \
 seq SEQ \
 scp SCP \
 ssh SSH \
 sftp SFTP
do
	if [ $i -eq 1 ]; then
		typeset v=$x
		i=0
	else
		typeset p=$x
		i=1
		# go to top of loop and get 2nd value in pair
		continue
	fi
	hardpath $p $v
done

# get full pathname  to scrip
# resolve symlinks

function getScriptPath {
	typeset SCRIPT=$1
	#echo >&2 debug SCRIPT: $SCRIPT
	STAT_RESULT=$($STAT --format=%N $SCRIPT | $SED -e "s/[\`']//g")

	if [ -L "$SCRIPT" ]; then
		STAT_RESULT=$(echo $STAT_RESULT | $AWK '{ print $3 }')
	fi

	echo $STAT_RESULT
}

# getpath
# getfull path name - assuming a FQN script or exe name
function getPath {
	typeset PSCRIPT=$1
	$DIRNAME $PSCRIPT
}

# get the relative path
# if one path is rooted ( '/xx/xx/...') then use it
# otherwise concatenate 
# check path
# eg. determine where script was called from, then get
# the path to the location resolving symlinks if needed
# CALLED_SCRIPT=$0
# CALLED_DIRNAME=$(getPath $CALLED_SCRIPT);
# SCRIPT_FQN=$(getScriptPath $CALLED_SCRIPT)
# FQN_DIRNAME=$(getPath $SCRIPT_FQN)
# SCRIPT_HOME=$(getRelPath $CALLED_DIRNAME $FQN_DIRNAME)
# SQLDIR=$SCRIPT_HOME/../sql
#
# this is the real location of the script
# even if called via symlink

function getRelPath {
	typeset CALLED_PATH=$1
	typeset QUAL_PATH=$2
	typeset FULLPATH 

	if [ -d '/'"$QUAL_PATH" ]; then
		FULLPATH=$QUAL_PATH
	else
		FULLPATH=$CALLED_PATH/$QUAL_PATH
	fi

	if [ -d $FULLPATH ]; then
		echo $FULLPATH
	else
		echo "Error determining path"
		echo CALLED_PATH: $CALLED_PATH
		echo QUAL_PATH: $QUAL_PATH
		exit 1
	fi
}

# get the password interacticely
# pass the name of the password variable, not the variable itself
# password=''; password=$(getPasswordInteractive "$password")
# if the password already has a value, nothing will be done
# this allows calling the function without first testing 
# to see if the password variable has a value
function getPasswordInteractive {
	local password
	read -s -p 'Password: ' password

	echo $password
}

# just returns the password if already set
# otherwise calls getPasswordInteractive
function getPassword {
	local password="$*"
	if [ -n "$password" ]; then
		echo $password
	else
		## send password prompt to STDERR 
		## as the one in getPasswordInteractive will not display
		#echo Password: 1>&2
		#getPasswordInteractive 'ITC_PASSWORD' Y
		#echo $ITC_PASSWORD
		password=$(getPasswordInteractive "$password")
		echo $password
	fi
}

# returns the passed value in upper case
function uc {
	typeset input=$*
	input=$(echo $input | $TR '[a-z]' '[A-Z]')
	echo $input
}

# returns the passed value in lower case
function lc {
	typeset input=$*
	input=$(echo $input | $TR '[A-Z]' '[a-z]')
	echo $input
}

# returns the passed value in upper case
function upperCase {
	uc $*
}

# returns the passed value in lower case
function lowerCase {
	lc $*
}


function verifyStatsType {
	typeset input=$1
	input=$(uc $input)
	typeset -a statsTypes

	statsTypes[0]='DICTIONARY_STATS'
	statsTypes[1]='FIXED_OBJECTS_STATS'
	statsTypes[2]='SYSTEM_STATS'
	statsTypes[3]='SCHEMA'

	for chkstat in ${statsTypes[*]}
	do
		[ "$input" == "$chkstat" ] && {
			echo $input
			break
		}
	done

}

# determine what the shell is being used to run a script
function currshell {
	typeset myshell
	#echo CURRSHELL: "$BASENAME | $PS h -p $$ -o args| $CUT -f1 -d' ' "
	# jkstill - 02/15/2011 - added -- as some versions of basename 
	# were interpreting the later commands
	myshell=$($BASENAME -- $($PS h -p $$ -o args| $CUT -f1 -d' ' ))
	#myshell='ASHELL'
	echo $myshell
}

function usage {
	echo $0
	echo 
	echo
	echo This is the default usage\(\) function from $FUNCTIONS_FILE
	echo Your script needs to have its own usage\(\)
	echo go fix it!
	echo 
}

# check for empty argument list
# concat args into a : delimited string
# chkForEmptyArgs 
# check the return value
# returns 0 if args are empty
# returns 1 if args are not empty

function chkForEmptyArgs {
	typeset argsToChk=$1
	#echo argsToChk: $argsToChk
	[ -z "$argsToChk" ] && return 0
	[ $( echo "$argsToChk" | $GREP -E '^[:]+$' ) ] && return 0
	return 1
}

# validate_args is used to validate combinations of command line arguments
# see scripts validate_args_proto.sh, validate_args.sh and validate_args_unit_test.sh
#
# the method used is to create a bash array of regular expressions
# that describe valid command line expressions
# ( korn apparently cannot be prevented from stripping '{' and '}' from
#   arguments passed to a function.
#   as [[:alnum]]{3,} is a valid regular expression this is a problem )
# if the argument list passed can be grepped by one of the REs then 
# the argument list is valid and 0 is returned
# otherwise 1 is returned
# call the function and then check the return value
# ':' is used as a delimiter for text values
# VALID_ARGS=( ":[[:alnum]]{3,}:[[:alnum:]]{3,}:[[:alnum:]]{3,}" ":[[:alnum]]{3,}::[[:alnum:]]{3,}" )
# validate_args ':SCOTT:ORCL:MYTABLE' 
# RETVAL=$?



function validate_args {
	typeset arglist
	arglist="$1"
	
	while shift
	do
		# on tests that do not succeed before running
		# out of regular expressions to test, the last
		# shift will create $1 as an empty variable
		# this line would demonstrate that
		# [ -z "$1" ] && echo $1 | hexdump -C
		# 00000000  0a   |.|
		[ -z "$1" ] && break
		# grep does not work well with some regexes - I do not know why

		# was grep -E. changed to -P as some regexes did not work with -E 
		if [ $(echo "$arglist" | $GREP -P "$1" ) ]; then
			echo MATCHED
			return 0
		else 
			echo "NO MATCH"
			echo "arglist: $arglist"
			echo "  REGEX: $1"
		fi

		# tried a bash regex when grep -E did not work for some regular expressions
		# this also failed for some reason
		#echo "arglist: $arglist"
		#echo "  REGEX: $1"
		#if [[ "$arglist" =~ $1 ]]; then
			#echo "MATCHED"
		#else
			#echo "NO MATCH"
		#fi

		[[ $arglist =~ $1 ]] && { return 0; }
		
	done
	return 1

}

: << 'COMMENT'

cat > a
this is file a
^D

ln -s a b
ln -s b c
ln -s c d

find the original file, a

=== sample code ===

declare myFile=$1

# declare and assignment from a function cannot be done on 
# a single line if the exit code from the function is to be preserved
# otherwise the exit code seen is from 'declare'
declare fileLinkStatus
fileLinkStatus=$(isSoftLink $myFile)
declare rc=$?

if [[ $rc -ne 0 ]]; then
	echo
	echo rc: $rc
	echo err getting link status for $myFile
	echo 
	exit $rc
fi

if [[ $fileLinkStatus == 'Y' ]]; then
	echo -n 'source file: '
	getLinkSource $myFile
else
	echo not a link: $myFile
fi

COMMENT

isSoftLink () {

	local file2chk=$1

	[[ -z $file2chk ]] && {
		echo 
		echo isSoftLink: no file passed
		echo
		return 1
	}

	[[ -r $file2chk ]] || { 
		echo 
		echo 
		echo isSoftLink: file not found - $file2chk
		echo
		return 1
	}

	local deref=$(stat -c '%N' $file2chk)

	if [ "'$file2chk'" == "$deref" ]; then
		echo 'N'
	else
		echo 'Y'
	fi

	return 0

}

# find original file from softlink

getLinkSource () {

	local file2chk=$1

	[[ -z $file2chk ]] && {
		echo 
		echo getLinkSource: no file passed
		echo
		return 1
	}

	#echo file2chk: $file2chk

	local parentFile

	while :
	do
		parentFile=$(readlink $file2chk 2>/dev/null)
		[[ -z $parentFile ]] && { echo $file2chk; break; }
		file2chk=$parentFile
	done

	return 0
}


