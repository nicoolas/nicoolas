#!/bin/bash

SLEEP=5
SLEEP2=2
RETRIES=3


tmpfile=$(mktemp)

mode=down
do_switch=yes
method=arping
once=no
alive_mode=no
CHECK_HOST_UP_QUIET=no

determine_notify_tool()
{
	[ "$CHECK_HOST_UP_QUIET" == "yes" ] && return 0
	if which notify-send >/dev/null
	then
		SHOUT="notify-send -t 0 $(basename $0) "
		return 0
	fi

	if which kdialog >/dev/null
	then
		SHOUT="kdialog --msgbox "
		return 0
	fi

	# Add your notifier here
	if which mynotifier >/dev/null
	then
		SHOUT="mynotifier "
		return 0
	fi

	return 1
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

     Mode (choose one)
     -m <up|down> : Alert when host gets in given mode first (default $mode)
     -o : Once Mode: Leaves after first state change (don't switch mode)
     -a : Alive mode: Wait for host to (re)boot and quits.

     Misc:
     -p : Use ping rather than arping
     -q : Quiet mode: Do not notify state changes (write on terminal only)
	 
     Time & tries :
     -s <seconds> : Sleep time between to checks (default ($SLEEP)
     -t <seconds> : Sleep time between to checks,
                    when host state has chanegd (default ($SLEEP2)
     -r <number>  : Number of retires before shouting state change
EOF
[ -n "$1" ] && exit $1
}

test_ping()
{
	if [ "$method" == "ping" ]
	then
		ping -c 1 $IP >$tmpfile 2>&1 
		ret=$?
	elif [ "$method" == "arping" ]
	then
		sudo arping -c 1 $IP >$tmpfile 2>&1 
		ret=$?
	fi
 	[ $ret -ne 0 ] && return 1

	time=$(grep time= $tmpfile | head -1 | sed 's/.*time=//')
	return 0
}

switch_mode()
{
	if [ "$once" == "yes" -a "$alive_mode" != "yes" ]
	then
		echo "Switching in Once mode: leaving."
		exit 0
	fi
	if [ "$mode" == "track_down" ]
	then
		mode=track_up
	else
		mode=track_down
	fi
	echo "    - > switching to mode: $mode"

}

output_result()
{
	#msg="$(date +"%A %T") : $name"
	msg="$(date +'%a %T') $name"
	do_echo=0
	do_shout=0
	echo_arg=""
	switch_now=dont

	if [ "$mode" == "track_up" -a "$1" == "noping" ]
	then
		do_echo=1
		msg2="is dead"
	elif [ "$mode" == "track_up" -a "$1" == "ping" -a "$alive_mode" == "yes" ]
	then
		do_echo=1
		do_shout=0
		msg2="is still alive, waiting for reboot"
	elif [ "$mode" == "track_up" -a "$1" == "ping" ]
	then
		do_echo=1
		do_shout=1
		msg2="is alive ! [$time]"
		[ "$do_switch" == "yes" ] && switch_now=yes
		[ "$exit_on_resurrection" == "yes" ] && exit_on_resurrection_now="yes"
	elif [ "$mode" == "track_down" -a "$1" == "noping" ]
	then
		do_echo=1
		echo_arg="-n"
		msg2="is dead "
	elif [ "$mode" == "track_down" -a "$1" == "ping" ]
	then
		do_echo=1
		msg2="is alive [$time]"
	elif [ "$mode" == "track_down" -a "$1" == "reallydead" ]
	then
		do_echo=1
		do_shout=1
		msg=""
		msg2="$name is dead !"
		[ "$do_switch" == "yes" ] && switch_now=yes
	fi
	[ "$CHECK_HOST_UP_QUIET" == "yes" ] && do_shout=0
	[ $do_echo -eq 1 ] && echo $echo_arg "$msg $msg2"
	[ $do_shout -eq 1 ] && $SHOUT "$(date +'%a %T:') $msg $msg2"
	[ "$switch_now" == "yes" ] && switch_mode
	[ "$exit_on_resurrection_now" == "yes" ] && exit 0
}

# -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

while getopts om:s:t:r:pqae o
do
	case "$o" in 
	m) mode=$OPTARG ;;
	a) alive_mode=yes ;;
	e) exit_on_resurrection=yes ;;
	s) SLEEP=$OPTARG ;;
	t) SLEEP2=$OPTARG ;;
	r) RETRIES=$OPTARG ;;
	p) method="ping" ;;
	o) once="yes" ;;
	q) CHECK_HOST_UP_QUIET="yes" ;;
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



[ -z "name" -o -z "$IP" ] && _usage 1
if [ "$alive_mode" = "yes" ]; then
	mode="track_up"
	once="yes"
	[ $SLEEP -gt 2 ] && SLEEP=2
fi
[ "$mode" != "down" ]  && mode=track_down
[ "$mode" != "up" ]  && mode=track_up
[ "$mode" != "track_down" -a "$mode" != "track_up" ]  && _usage 1
[ "$method" != "ping" -a "$method" != "arping" ]  && _usage 1

cat <<EOF

$(basename $0)

	Name: $name
	IP: $IP

	Track mode: $mode
	Alive mode: $alive_mode
	Once mode: $once

	Method: $method
	Quiet mode: $CHECK_HOST_UP_QUIET

	Sleep: $SLEEP / $SLEEP2
	Retries: $RETRIES

EOF

while :
do
	if test_ping
	then
		output_result ping
	else
		output_result noping
		# Now wait for appliance to (re)boot 
		[ "$alive_mode" = "yes" ] && alive_mode="nope"
		if [ "$mode" == "track_down" ]
		then
			i=$RETRIES
			while [ $i -gt 0 ]
			do
				if ! test_ping
				then
					echo -n "."
					sleep $SLEEP2
				else
					break
				fi
				i=$(($i-1))
			done
			if [ $i -eq 0 ]
			then
				output_result reallydead
			else
				echo " OK [$time]"
			fi
		fi
	fi
	sleep $SLEEP
done
