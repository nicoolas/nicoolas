#!/bin/sh

ldd $1 | while read a b c d;
 do
	 echo $b | grep -q '=>' || continue
	 [ $(expr "$c" : "(0x") -eq 3 ] && continue
	 echo $c
	 [ -n "$d" ] && $0 $c;
done

