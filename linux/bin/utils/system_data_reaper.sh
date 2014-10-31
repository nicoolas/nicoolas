#!/bin/bash -e

_usage()
{
cat <<EOF

Usage: `basename $0` <option> [files]

      general options:
          -h : this help.
      dump options:
          -d : dumps current data
          -e : Extra info - such as detailed CPU usage.
          -f : output dumped data (-d option) to the given filename,
               to which is appended a 'date + time' tag.
	  analyze options:
          -b <directory> :
            compare the oldest and most recent files found in the directory
          -c <file1> <file2> :
            compare two data files
          -g <file1> [<file2> ...] :
            generate an CSV out of the given data files.

EOF
	exit $1
}

_check_files()
{
	for f in $*
	do
		if [ -z "$f" -o ! -r "$f" ]; then
			echo "Error: unreadable file [$f])"
			echo "Aborting."
			return 1
		fi
	done
}

get_extra_info()
{
#
# CPU usage: Needed this way for Classic distribs :
#
# Cpu(s):  0.9% us,  8.7% sy,  0.0% ni, 85.6% id,  4.1% wa,  0.5% hi,  0.1% si
#
	/usr/bin/top -b -n 1 | sed -n '/^Cpu/s/Cpu(s): *//p' | tr '%,' ' \n' |awk '
{printf "%-32s: % 20s\n", "CPU_usage_"$2, $1; }
'

}

get_info()
{

# Date
	printf "%-32s: % 20s\n" "date" $(date "+%Y/%m/%d_%H:%M:%S");

# Memory
	awk '
BEGIN {total=0; unused=0; low_total=0; low_free=0};
/^MemTotal:*/ { total=total+$2 };
/^LowTotal:*/ { low_total=low_total+$2 };
/^LowFree:*/ { low_free=low_free+$2 };
/^MemFree:*|^Cached:*|^Buffers:*/ { unused=unused+$2 };
END {
	printf "%-32s: % 20s\n", "memory_total", total;
	printf "%-32s: % 20s\n", "memory_unused", unused;
	printf "%-32s: % 20.*s\n", "memory_ratio", 4, 100*unused/total;
	printf "%-32s: % 20s\n", "memory_low_total", low_total;
	printf "%-32s: % 20s\n", "memory_low_free", low_free;
	printf "%-32s: % 20.*s\n", "memory_low_ratio", 4, 100*low_free/low_total;
}' /proc/meminfo

# Load average: last minute
	printf "%-32s: % 20s\n" "load_average" $(cat /proc/loadavg | cut -d" " -f1);

# Now get memory info (FULL mode only)
	[ "$memory_mode" == "yes" ] && get_memory_info

# Now get extra info (FULL mode only)
	[ "$extra_mode" == "yes" ] && get_extra_info
}

compare_csv()
{
	local nb=$(head -1 $1 | sed 's/,./\n/g' | wc -l)
	local i=1
	while [ $i -le $nb ]
	do
		sed -n '1,2p;$p' $1 | tr ' ' '_' |cut -d ',' -f$i | xargs -L 3 | \
			( read a b c; printf "%s : %s\n%s : %s\n" "$a" "$b" "$a" "$c"; )
		i=$(($i+1))
	done

}

compare_data()
{
	awk '
BEGIN {
	printf "\n%-32s: % 20s / % 20s   => % 20s\n\n", "Counter", "Start", "End", "Derive";
}
{
if ($1 != "date" && $1 != "cluster_virt_ifce" ) {
	if ($1 in array) {
		if (array[$1] == 0) ratio=0
		else {
			ratio = (($3-array[$1])*100/(array[$1]))
#			ratio = substr(ratio, 0, index(ratio, ".")+2)
		}
		printf "%-32s: % 20s / % 20s   => % 8.*s %%\n", $1, array[$1], $3, 8, ratio;
	}
	else {
		if ($3 != "") {
			array[$1] = $3
		}
	}
}
}'
}

_generate_csv()
{
	sep=","
	if [ "$1" == "head" ]; then
		while read label line
		do printf "%s%s" $label $sep
		done < $2
		echo
		return
	fi

	while read a b c
	do
		value="$(echo $c | tr '_' ' ')"
		printf "%s%s" "\"$value\"" $sep
	done <$1
	echo
}


generate_csv_dir()
{
	echo "Comming soon."
	return
}

generate_csv_files()
{
	_generate_csv head $1
	for f in $*; do
		_generate_csv $f
	done
}

###############################################

dowhat=
while getopts hedgbcf:o o
do  case "$o" in
    h) _usage 0 ;;
    d) dowhat="DUMP" ;;
    e) extra_mode="yes" ;;
    b) dowhat="COMPARE_DIR" ;;
    c) dowhat="COMPARE" ;;
    o) dowhat="COMPARE_CSV" ;;
    g) dowhat="GENERATE_CSV" ;;
    f) output_to_file="$OPTARG" ;;
    [?]) _usage 1;;
esac
done
shift $(($OPTIND-1))

case "$dowhat" in
DUMP)
	# TODO: CHECK output_to_file name is OK !
	if [ -n "$output_to_file" ]; then
		output_file=${output_to_file}_$(date "+%Y_%m_%d_%H_%M_%S").dat
		get_info | tee $output_file
	else
		get_info
	fi
	exit 0
	;;
COMPARE_DIR)
	[ -z "$1" ] && _usage 1
	[ ! -d "$1" ] && _usage 1
	last_file="$1/$(ls -1rt $1 | tail -n 1)"
	first_file="$1/$(ls -1rt $1 | head -n 1)"
	_check_files "$first_file" "$last_file" || exit 1
cat <<EOF
Comparing files:
File 1 : $first_file
File 2 : $last_file
EOF
	cat "$first_file" "$last_file" | compare_data
	;;
COMPARE)
	[ -z "$1" -o -z "$2" ] && _usage 1
	_check_files "$1" "$2" || exit 1
	cat $1 $2 | compare_data
	;;
COMPARE_CSV)
	[ -z "$1" ] && _usage 1
	_check_files "$1" || exit 1
	compare_csv $1 | compare_data
	;;
GENERATE_CSV)
	[ -z "$1" -o -z "$2" ] && _usage 1
	#	_check_files $* || exit 1
	generate_csv_files $*
	;;
*) _usage 1;;
esac

echo "end."
