#!/bin/bash

SCRIPT_PID_FILE=/tmp/.$(basename $0).pid
SCRIPT_NAME=/tmp/system_data_reaper.sh
SCRIPT_NAME=$(pwd)/$(dirname $0)/system_data_reaper.sh

OUTPUT_BASE_FOLDER=/tmp/SDR/out

SCRIPT_OPTIONS="-d"

_usage()
{
cat <<EOF

Usage: `basename $0` <option> 

          -h : this help.
		  -d : daemonise loop script
		  -w : watch data output by daemonised loop script
		  -k : kill previouslt daemonised script
		  -p : pack log files in output foldert add 


EOF
    exit $1
}

INTERVAL=20

while getopts dwkp o
do
    case "$o" in
    d) daemonise=yes ;;
    w) watch=yes ;;
    k) do_kill=yes ;;
    p) do_pack=yes ;;
    h) _usage 0;;
    *) _usage 1;;
    esac
done
shift $(($OPTIND-1))

if [ "$do_kill" == "yes" ]; then
	if [ -r $SCRIPT_PID_FILE ]; then
		while read pid; do
			echo "Kiling pid: $pid"
			kill $pid
		done <$SCRIPT_PID_FILE
		rm $SCRIPT_PID_FILE
	fi
	exit 0
fi

_hour() {
	    hour=`date "+%Y-%m-%d_%H-%M-%S"`
		echo "$hour"
}

_date() {
	    date=`date "+%Y-%m-%d_%H_%M_%S"`
		echo "$date"
}

_main_loop()
{
	while true
	do
		TIMESTAMP=`_hour`
		$SCRIPT_NAME $SCRIPT_OPTIONS >> $OUTPUT_FOLDER/sdr-$TIMESTAMP
		sleep $INTERVAL
	done
}

_get_latest_dir()
{
    local OUTPUT_FOLDER=$(ls -t1d $OUTPUT_BASE_FOLDER/* | head -1)
    if [ -z "$OUTPUT_FOLDER" ]; then
        echo "Can't find any directory, leaving."
        exit 1
    fi
	echo $OUTPUT_FOLDER

}
_watch_output()
{
	tmpfile=$(mktemp)
	chmod +x $tmpfile
cat <<EOS >$tmpfile
watch -d cat '$1/\$(ls -t1 $1/ | head -1)'
EOS
	$tmpfile
}

if [ "$watch" == "yes" ]; then
	OUTPUT_FOLDER=$(_get_latest_dir)
	echo Wathcing directory $OUTPUT_FOLDER
	_watch_output $OUTPUT_FOLDER
	exit 0
fi

if [ "$do_pack" == "yes" ]; then
	OUTPUT_FOLDER=$(_get_latest_dir)
	OUTPUT_TGZ=$(basename $(_get_latest_dir)).tgz
	echo Packing directory $OUTPUT_FOLDER to $OUTPUT_TGZ
	cd $(dirname $OUTPUT_FOLDER)
	tar czf $OUTPUT_TGZ $(basename $OUTPUT_FOLDER)
	ls -l `pwd`/$OUTPUT_TGZ
	exit 0
fi

if [ ! -x $SCRIPT_NAME ]; then
	echo "Cannot find script: $SCRIPT_NAME"
	SCRIPT_NAME="$(pwd)/$(basename $SCRIPT_NAME)"
fi
if [ ! -x $SCRIPT_NAME ]; then
	echo "Cannot find script: $SCRIPT_NAME"
	echo "Aborting."
	exit 1
else
	echo "Using script $SCRIPT_NAME instead"
	echo
fi

DATESTAMP=`_date`
HOSTNAME_TAG=$(hostname | sed 's/\..*$//')
OUTPUT_FOLDER=${OUTPUT_BASE_FOLDER}/sdr_${HOSTNAME_TAG}_${DATESTAMP}_SDR

mkdir -p $OUTPUT_FOLDER


echo "Setting OUTPUT_FOLDER to $OUTPUT_FOLDER"
echo "Entering loop."


if [ "$daemonise" == "yes" ]; then
	_main_loop &
	echo "$!" >> $SCRIPT_PID_FILE
	_watch_output $OUTPUT_FOLDER
else
	_main_loop
fi
