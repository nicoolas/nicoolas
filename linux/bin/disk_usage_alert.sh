#!/bin/sh
alert_level=3G
free_space=$(df -H | grep ' /$' | tr '%' ' ' | awk '{ print $4 }')
cat <<EOS

  Disk free space alert: $alert_level
  Disk free space available: $free_space

EOS

if echo -e "$free_space\n$alert_level\n" | sort --check=silent -h
then
  msg_subject="[$(hostname)] Disk space alert: $free_space"
  msg_contents="Server: $(hostname)\nDate: $(date)\nDisk space available: $free_space"
  echo "$msg_contents"
  echo "$msg_contents" | mail -s "$msg_subject" nicoolas.t+server@gmail.com
fi

