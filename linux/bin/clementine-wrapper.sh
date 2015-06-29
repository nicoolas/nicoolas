#!/bin/bash

__log() {
	echo "$(date +%Y-%m-%d_%H:%M:%S) $*"
}
prog=clementine
prog_lock=$prog-wrapper.lock
date_diff_minimum_sec=20
early_death_max=10
early_death_max_count=0

load_xauth_vars() {
	xauth_file=~/._current_xauth_var
	if [ -r "$xauth_file" ]
	then
	    export XAUTHORITY="$(cat $xauth_file)"
		export DISPLAY=":0.0"
	fi
}

# Check options
if [ "$1" = "start" ]
then
	__log "Option: Start"
	# If prog not alread running, start straight away
	start_prog="yes"
fi

__log "$prog: starting ($0 $*)"
prog_pid=$(pgrep "$prog$" | head -n 1)

# Check if prog already running
if [ -z "$prog_pid" ]
then
	__log "$prog: not yet running."
	if [ "$start_prog" = "yes" ]
	then
		__log "$prog: not yet running, start it now"
	else
		__log "$prog: not yet running, wait for its birth"
		# Wait for prog to be started from outside world
		while [ -z "$prog_pid" ]
		do
			sleep 3
			prog_pid=$(pgrep "$prog$" | head -n 1)
		done
	fi
fi

# Wait for prog to die
if [ -n "$prog_pid" ]
then
	__log "$prog: running (pid: $prog_pid)"
	while [ -d /proc/$prog_pid ]
	do
		sleep 3
	done
	__log "$prog: died"
fi

# Now (re)start and loop
while true
do
	date_s=$(date +"%s")
	log_root=/tmp/$prog-wrapper.$date_s
	log_file=$log_root.log
	log_meminfo=$log_root.meminfo
	__log "$prog: Starting, time:${date_s}s, logfile:'$log_file'"
	load_xauth_vars
	flock /tmp/$prog_lock $prog $prog_args >$log_file 2>&1 &
	sleep 1
	flock /tmp/$prog_lock touch /dev/null
	date_e=$(date +"%s")
	date_d=$((date_e-date_s))
	__log "$prog: Died, time:${date_e}s / diff:${date_d}s == $((date_d/60))m/ min:${date_diff_minimum_sec}s"
	cat /proc/meminfo > $log_meminfo
	__log "$prog: Meminfo logged in $log_meminfo"

	if [ $date_d -lt $date_diff_minimum_sec ]
	then
		early_death_max_count=$((early_death_max_count+1))
		__log "$prog: Died too young ! ($early_death_max_count/$early_death_max)"
		if [ $early_death_max_count -ge $early_death_max ]
		then
			__log "$prog: Died young too many times, aborting. ($early_death_max_count/$early_death_max)"
			cat
		fi
	else
		early_death_max_count=0
	fi
done

