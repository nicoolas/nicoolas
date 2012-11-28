#!/bin/sh

action=
FORCE_ROOT=no
CMD_SSH_AUTOPWD='/opt/framework/bin/ssh -J '
PASSWD="arkoon69!"
TMPFILE=`mktemp`

usage ()
{
	#echo "Usage `basename $0`: (IP | MACHINE_NAME) ( files | @files )"
	echo "Usage: $(basename $0) ... "
}

debug()
{
	return 0;
	echo "debug: $*"
}

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Functions

fun_check_offending_key()
{
	# Offending key in /home/nico/.ssh/known_hosts:148
	cat $1 | grep "^Offending key" | sed 's/^Offending key in \(.*\):\([0-9]*\)\r$/\1 \2/' | (
	    read A B;
	    [ -n "$B" ] && {
			sed -i "${B}d" $A
			echo "Failure: Offending key removed, try again"
		}
	  )
}


fun_rex()
{
	debug "$*"
	echo
	EXEC="$CMD_SSH -p$P ${U}@${MACH} $*"
	echo "$EXEC"
	$EXEC 2>&1 | tee $TMPFILE
	fun_check_offending_key $TMPFILE

}

fun_ssh()
{
	EXEC="$CMD_SSH -p$P ${U}@${MACH}"
	echo
	echo "$EXEC"
	exec $EXEC 2>&1 | tee $TMPFILE
	fun_check_offending_key $TMPFILE
}

fun_scp()
{
	local ARGS=
	local DEST=
	local ORIG=

	for A in $*
	do
		if [ `expr "$A" : "@"` == 1 ]
		then
			A=`echo $A | sed s/^@//`
			ARGS=" ${ARGS} ${U}@${MACH}:$A "
			DEST=ok
		else
			ARGS=" ${ARGS} ${A} "
			ORIG=1
		fi
	done

	[ -z "$DEST" -a -z "$ORIG" ] && return 1

	[ -z "$DEST" ] && ARGS=" ${ARGS} ${U}@${MACH}:/tmp "
	[ -z "$ORIG" ] && ARGS=" ${ARGS} . "

	EXEC="$CMD_SCP  -P$P $ARGS"
	echo "$EXEC"
	$EXEC 2>&1 | tee $TMPFILE
	fun_check_offending_key $TMPFILE
}

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Options

debug "caller:$(basename $0)"

case $(basename $0) in
nk_send_cpt) action="send_cpt" ;;
nkssh)       action="ssh_cnx" ;;
nkrex)       action="rem_exe" ;;
*) usage; exit 1;;
esac

while getopts rnlp: o
do  case "$o" in
    r) FORCE_ROOT="yes" ;;
    n) CMD_SSH='ssh ' ;;
    p) PASSWD="$OPTARG" ;;
	l) _nkremote.sh list
		exit 0
		;;
    [?]) usage; exit 1;;
	esac
done
shift $(($OPTIND-1))
machine_id=$1
shift
remaining_args="$*"

[ -z "$CMD_SSH" ] && CMD_SSH="$CMD_SSH_AUTOPWD $PASSWD"

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Find Machine

debug "Machine: $machine_id"
set $(_nkremote.sh $machine_id)
[ $? -gt 0 ] && {
	echo "Cannot find: $machine_id"
	exit $RES
}

P=$1
U=$2
MACH=$3

[ "$FORCE_ROOT" == "yes" ] && U="root"

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
# Call functions

case $action in
ssh_cnx) fun_ssh;;
rem_exe) fun_rex "$remaining_args";;
send_cpt) fun_send_cpt;;
*) echo "BUG";;
esac

[ -r "$TMPFILE" ] && rm $TMPFILE

