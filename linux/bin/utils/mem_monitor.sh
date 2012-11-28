#!/bin/bash

LOGFILE="/tmp/mem-monitor.log"
MEMINFO_FILE="/tmp/mem-meminfo.log"
POLLING_FREQUENCY=1

PROCESS_TO_MONITOR=$1
[ -n "$2" ]&& POLLING_FREQUENCY=$2

_datesec() {
    date=`date +"%s"`
    echo $date 2> /dev/null
}


_totaltime() {
    sec_per_hour=3600
    sec_per_min=60
    t1=$1 && t2=$2
    tt=$(($t2-$t1))
    hour=$(($tt/$sec_per_hour))
    min=$((($tt-$hour*$sec_per_hour)/$sec_per_min))
    sec=$(($tt-($hour*$sec_per_hour)-$min*$sec_per_min))
    echo "${hour}h ${min}m ${sec}s" 2> /dev/null
}


_gottrap() {
    signal=$?
    code=$((signal-128))
    [ $signal -lt 128 ] && code=$signal
	time2=`_datesec`
    echo "Killed by signal $code: end of script"
	totaltime=`_totaltime time1 time2`
	echo "Time passed: $totaltime"
    grep ' \-s' $LOGFILE | uniq
    exit 0
}


trap _gottrap SIGINT SIGTRAP SIGTERM SIGKILL

echo "Start of script..."

rm -f $LOGFILE $MEMINFO_FILE

time1=`_datesec`
echo "process monitored : $PROCESS_TO_MONITOR" >> $LOGFILE
echo "polling frequency : $POLLING_FREQUENCY" >> $LOGFILE

while :
do
	# monitored process section
	echo "------------------------------------" >> $LOGFILE
	CURRENT_DATE=`date +"%F %H:%M:%S"`	
	echo $CURRENT_DATE >> $LOGFILE
	ps auxf | grep $PROCESS_TO_MONITOR | grep -v grep | grep -v bash | grep -v find | grep -v SCAN | awk '{print $4, $5, $6}' >> $LOGFILE
	# global memory section
	echo "------------------------------------" >> $MEMINFO_FILE
	echo $CURRENT_DATE >> $MEMINFO_FILE
	cat /proc/meminfo >> $MEMINFO_FILE
	sleep $POLLING_FREQUENCY
done

exit 0
