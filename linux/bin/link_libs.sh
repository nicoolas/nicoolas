#!/bin/sh


_make_links() {
	local _link=$1
	while echo $_link | grep -q '[0-9]$'
	do
		_link=$(echo $_link  | sed 's/\.[0-9]*$//')
		echo "     -> $_link"
		ln -fs $1 $_link
	done
}


for l in "$@"
do
	echo "Lib: $l"
	_make_links $l
done
