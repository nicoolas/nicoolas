#!/bin/sh

if ! which dig >/dev/null 2>&1
then
	echo 
	echo "Command dig missing."
	echo
	exit 1
fi
dig +short myip.opendns.com @resolver1.opendns.com
