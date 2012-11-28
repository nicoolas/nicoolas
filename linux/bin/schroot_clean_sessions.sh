#!/bin/sh
schroot  -l --all-sessions | while read session ; do if [ $(ps au | grep  $session | grep -v grep | wc -l) -ne 0 ] ; then echo "Keeping session $session"; else echo "Ending chroot $session"; schroot -e -c $session; fi; done

