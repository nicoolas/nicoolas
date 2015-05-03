#!/bin/sh

secs=10
[ -n "$1" ] && secs=$1
_log() {
	echo "$*"
	logger "$*"
}
_log "Suspending <$(hostname)> in $secs seconds"
bash -c "(sleep $secs ; echo 'Suspending NOW!' ; sudo pm-suspend)" &

