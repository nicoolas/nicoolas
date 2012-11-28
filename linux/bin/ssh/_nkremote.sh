#!/bin/bash

FILE=$NK_REMOTE_FILE
[ -n "$NK_REMOTE_FILE" ] || exit 1
[ -r "$NK_REMOTE_FILE" ] || exit 1

_N=
_IP=
_P=
_U=

P=
U=
MACH=
M=$1

[ ! -r $FILE ] && echo "Inexistant or unreadable file $FILE" && exit 1

if [ "$1" == "-h" -o "$1" == "--help" ] 
then
	echo "Usage `basename $0`: [IP | Machine_name | list | edit ]"
	exit 1
fi
[ "$1" == "list" ] && cat $FILE && exit 0
[ "$1" == "edit" ] && vi $FILE && exit 0

# arg is a number, then IP: 10.10.192.arg
#                       port= 822
#                       user= root
if [ $(expr "$M" : "[0-9]*$") -gt 0 ]; then
  M="10.86.1.$M"
  MACH=$M
  P="822"
  U="root"
# arg is an ip address, then IP: arg
#                       port= 822
#                       user= root
elif [ $(expr "$M" : "[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*$") -gt 0 ]; then
  MACH=$M
  P="822"
  U="root"

else
  while read _N _IP _P _U XX
  do
	[ -z "$_N" ] && continue
	if [ -z "$U" -a -z "$M" ]
	then
		P=$_P
		U=$_U
		M=$_IP # to use IP address rather than name
		MACH=$_N
		break
	fi
	
	if [ "$M" == "$_N" -o "$M" == "$_IP" ]
	then
		MACH=$_N
		P=$_P
		U=$_U
		M=$_IP
		break
	fi
  done < $FILE

  if [ -z "$U" -o -z "$MACH" ]
  then
	echo "couldn't find proper line for $M"
	echo "$FILE: "
	cat $FILE
	exit 1
  fi

fi

echo $P $U $M

