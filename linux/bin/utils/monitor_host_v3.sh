#!/bin/bash

SLEEP=5
SLEEP2=2
RETRIES=3

tmpfile=$(mktemp)

mode=down
action=
do_switch=yes
method=arping
once=no
alive_mode=no
param_verbose=no
param_notify=no

_print_seconds() {
	local cap_sec=$1
    if [ "$cap_sec" -ne 0 ]
    then
        time_t=$cap_sec
        time_s=$((time_t%60))
        time_t=$(((cap_sec-time_s)/60))
        time_m=$((time_t%60))
        time_h=$(((time_t-time_m)/60))
        echo "${time_h}h ${time_m}m ${time_s}s"
    else
        echo "n/a"
    fi
}

determine_notify_tool()
{
	[ "$param_notify" != "yes" ] && return 0
	if which notify-send >/dev/null
	then
		CMD_NOTIFY="notify-send -t 0 $(basename $0) "
		return 0
	fi

	if which kdialog >/dev/null
	then
		CMD_NOTIFY="kdialog --msgbox "
		return 0
	fi

	# Add your notifier here
	if which mynotifier >/dev/null
	then
		CMD_NOTIFY="mynotifier "
		return 0
	fi

	return 1
}


_error()
{
cat <<EOS

*****************************************************************
*** Error: $*
*****************************************************************

EOS
}

_usage()
{
cat <<EOF

The tool monitors a distant machine, wating for either its death of its resurrection 
by pinging (or arpinging) it at regular intervals.

It allows you to be alerted when
 - a host goes down ("down" mode)
 - a host comes up ("up" mode)

Whenever a state change is detected, the script keeps on monitoring for the next change.

Usage: $(basename $0) [options] [Name] <IP>

     name : optional, for displ;ay purposes only (IP @ is used otherwise)

     -c <action_cmd> : Execute command upon state change
                       Arguments are: action_cmd <IP> <new_mode>

     Verbosity
     -n : Notification: Do notify state changes
     -v : Verbose mode: Print every ping return on the terminal

     Mode (choose one)
     -m <up|down> : Alert when host gets in given mode first (default $mode)
     -o : Once Mode: Leaves after first state change (don't switch mode)
     -a : Alive mode: Wait for host to (re)boot and quits.

     Method: how to poke host
        : command= arping (default)
     -p : command= ping
     -x <exec_cmd>: command= execute given command
	 
     Time & tries :
     -s <seconds> : Sleep time between to checks (default: $SLEEP)
     -t <seconds> : Sleep time between to checks,
                    when host state has changed (default: $SLEEP2)
     -r <number>  : Number of retries before shouting state change

EOF
[ -n "$1" ] && exit $1
}

test_ping()
{
	if [ "$method" = "ping" ]
	then
		ping -c 1 $IP >$tmpfile 2>&1 
		ret=$?
	elif [ "$method" = "arping" ]
	then
		sudo arping -c 1 $IP >$tmpfile 2>&1 
		ret=$?
	elif [ "$method" = "exec" ]
	then
		$method_exec $IP $mode >$tmpfile 2>&1
		ret=$?
	fi
 	[ $ret -ne 0 ] && return 1

	time=$(grep time= $tmpfile | head -1 | sed 's/.*time=//')
	[ -n "$time" ] && time="(ping time: $time)"

	return 0
}

switch_mode()
{
	if [ "$once" = "yes" -a "$alive_mode" != "yes" ]
	then
		echo "Switching in Once mode: leaving."
		exit 0
	fi
	if [ "$mode" = "track_down" ]
	then
		mode=track_up
	else
		mode=track_down
	fi
	if [ -n "$action" ]
	then
		echo "    - > running action '$action $IP $mode'"
		$action $IP $mode >/dev/null 2>&1
	fi

	local _time_now=$(date +"%s")
	if [ -n "$switch_timestamp" ]
	then
		local _time_elapsed_sec=$((_time_now-switch_timestamp))
		local _time_elapsed_msg=": Time elapsed: $(_print_seconds $_time_elapsed_sec)"
	fi
	switch_timestamp=$_time_now

	echo "    - > switching to mode: $mode $_time_elapsed_msg"
}

output_result()
{
	#msg="$(date +"%A %T") : $name"
	msg="$(date +'%a %T') $name"
	do_echo=0
	do_notify=0
	echo_arg=""
	switch_now=dont

	if [ "$mode" = "track_up" -a "$1" = "noping" ]
	then
		do_echo=1
		msg2="is dead"
	elif [ "$mode" = "track_up" -a "$1" = "ping" -a "$alive_mode" = "yes" ]
	then
		do_echo=1
		do_notify=0
		msg2="is still alive, waiting for reboot"
	elif [ "$mode" = "track_up" -a "$1" = "ping" ]
	then
		do_echo=1
		do_notify=1
		msg2="is alive ! $time"
		[ "$do_switch" = "yes" ] && switch_now=yes
		[ "$exit_on_resurrection" = "yes" ] && exit_on_resurrection_now="yes"
	elif [ "$mode" = "track_down" -a "$1" = "noping" ]
	then
		do_echo=1
		msg2="is dead ($2 tries left)"
	elif [ "$mode" = "track_down" -a "$1" = "ping" ]
	then
		do_echo=1
		msg2="is alive $time"
	elif [ "$mode" = "track_up" -a "$1" = "reallydead" ]
	then # Happens if (RETRIES == 0)
		do_echo=1
		msg2="is dead"
	elif [ "$mode" = "track_down" -a "$1" = "reallydead" ]
	then
		do_echo=1
		do_notify=1
		msg2="is dead !"
		[ "$do_switch" = "yes" ] && switch_now=yes
	elif [ "$1" = "notdeadafterall" ]
	then
		do_echo=1
		do_notify=0
		msg2=" OK $time"
	fi
	if [ "$param_verbose" = "yes" -o "$do_notify" -eq 1 -o "$verbose_first" = "yes" ]; then
		[ $do_echo -eq 1 ] && echo $echo_arg "$msg $msg2"
		verbose_first="no"
	fi
	#[ $do_notify -eq 1 ] && verbose_first="yes"
	[ "$param_notify" != "yes" ] && do_notify=0
	[ $do_notify -eq 1 ] && $CMD_NOTIFY "$(date +'%a %T:') $msg $msg2"
	[ "$switch_now" = "yes" ] && switch_mode
	[ "$exit_on_resurrection_now" = "yes" ] && exit 0
}

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

while getopts om:s:t:r:paex:c:nv o
do
	case "$o" in 
	m) mode=$OPTARG ;;
	c) action=$OPTARG ;;
	a) alive_mode=yes ;;
	e) exit_on_resurrection=yes ;;
	s) SLEEP=$OPTARG ;;
	t) SLEEP2=$OPTARG ;;
	r) RETRIES=$OPTARG ;;
	p) method="ping" ;;
	x) method="exec" ; method_exec=$OPTARG ;;
	o) once="yes" ;;
	n) param_notify="yes" ;;
	v) param_verbose="yes" ;;
	*) _usage; exit 1;;
	esac
done
shift $(($OPTIND-1))

if [ $# -gt 1 ] ; then
	name="$1"
	IP=$2
else
	name="$1"
	IP="$1"
fi

# determine notifying tool
if ! determine_notify_tool
then
	cat <<EOF
Could not find a supported notifier.
Edit the script to get a list of supported notifiers, or to add yours (real easy :) )

eg. aptitude install libnotify-bin
eg. aptitude install gtkdialog
EOF
	exit 1
fi



[ -z "$name" -o -z "$IP" ] && _usage 1
if [ "$alive_mode" = "yes" ]; then
	mode="track_up"
	once="yes"
	[ $SLEEP -gt 2 ] && SLEEP=2
else
	if [ "$mode" = "down" ] ; then mode=track_down
	elif [ "$mode" = "up" ] ; then mode=track_up
	else 
		_error "Bad mode: [$mode]."
		_usage 1
	fi
fi
[ "$method" != "ping" -a "$method" != "arping" -a "$method" != "exec" ] && _usage 1
[ "$method" = "exec" -a -z "$method_exec" ] && _usage 1

__get_method() {
	if [ "$method" = "exec" ]
	then
		echo "$method: <$method_exec>"
	else
		echo "$method"
	fi
}
__get_action() {
	if [ -n "$action" ]
	then
		echo "<$action>"
	else
		echo "<none>"
	fi
}

cat <<EOF

$(basename $0)

	Name: $name
	IP: $IP

	Track mode: $mode
	Alive mode: $alive_mode
	Once mode: $once

	Method: $(__get_method)
	Action: $(__get_action)

	Verbose: $param_verbose
	Notify: $param_notify

	Sleep: $SLEEP / $SLEEP2
	Retries: $RETRIES

EOF

verbose_first="yes" # force verbose once after state change
while :
do
	if test_ping
	then
		output_result ping
	elif [ $RETRIES -eq 0 ]
	then
			output_result reallydead
	else	
		output_result noping $RETRIES
		# Now wait for appliance to (re)boot 
		[ "$alive_mode" = "yes" ] && alive_mode="nope"
		if [ "$mode" = "track_down" ]
		then
			i=$RETRIES
			while [ $i -gt 0 ]
			do
				i=$(($i-1))
				if ! test_ping
				then
					output_result noping $i
					sleep $SLEEP2
				else
					break
				fi
			done
			if [ $i -eq 0 ]
			then
				output_result reallydead
			else
				output_result notdeadafterall
			fi
		fi
	fi
	sleep $SLEEP
done
