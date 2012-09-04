#!/bin/sh
# svn_commit

LOCAL_FILES=""
AGAIN=1

# Param 1: message
# Param 2: action
# Params:  file list
MESSAGE=$1
shift
ACTION=$1
shift

for a in $*
do
  [ -r "$a" ] && LOCAL_FILES="$LOCAL_FILES $a"
done

while [ $AGAIN -gt 0 ]
do

  echo
  echo "$MESSAGE"
  echo
  svn_status $LOCAL_FILES
  echo
  read R

  case $R in
  yes)
      AGAIN=0
      $ACTION $*
	  ;;
  no)
      AGAIN=0
	  echo "leaving..."
	  ;;
  e|edit)
      vi $LOCAL_FILES
	  ;;
  d|diff)
      svn_diff $LOCAL_FILES
	  ;;
  *)
      echo "Unknown answer: $R"
	  ;;
  esac
done




