#!/bin/sh
conf=$(dirname $0)/$(basename $0 .sh).conf
echo "Conf: $conf"
[ -r $conf ] || exit 1
. $conf

timestamp_file=/tmp/$(basename $0).timestamp

f_K2G() {
	echo "scale=2; $1/1024/1024" | bc 
}

f_log() {
	logger --stderr "$*"
	echo "$(date) - $*" >> $log_file
}

f_check_timestamp() {
	[ -s $timestamp_file ] || echo 0 > $timestamp_file
	head -n 1 $timestamp_file | grep -q '^[0-9][0-9]*$' || echo 0 > $timestamp_file
	local ts=$(head -n 1 $timestamp_file)
	local now=$(date "+%s")

	[ $((now - ts)) -lt $dont_alert_for_sec ] && return 1
	echo $now>$timestamp_file
	return 0
}

total_kb=$(df  $mount_point | sed -n '2p' | tr '%' ' ' | awk '{ print $2 }')
free_kb=$(df $mount_point | sed -n '2p' | tr '%' ' ' | awk '{ print $4 }')

alert_gb="$(f_K2G $alert_kb)GB"
total_gb="$(f_K2G $total_kb)GB"
free_gb="$(f_K2G $free_kb)GB"

msg_subject="[$(hostname)] Disk space alert: $free_gb"
msg_contents=$(cat <<-EOS

 Server: $(hostname)
 Date: $(date)
 Disk space available: $free_gb/$total_gb
 Alert below: $alert_gb

EOS
)

printf "$msg_contents\n\n"
extra_msg=""
if [ $free_kb -lt $alert_kb ]
then
	if f_check_timestamp
	then
		extra_msg=" -> raise alert"
		[ -n "$email" ] && echo "$msg_contents" | mail -s "$msg_subject" $email
	else
		extra_msg=" -> inhibate alert"
	fi
fi
f_log "Disk space check: $free_gb/$alert_gb/$total_gb$extra_msg"

echo

