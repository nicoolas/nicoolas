#!/bin/sh

local_user=$(whoami)
local_owner="gid=$local_user,uid=$local_user"

remote_user=
remote_host=
remote_share_name=
local_mount_point=

_usage()
{
cat <<EOS

Usage: $(basename $0) <options>
	-u remote user
	-r remote host IP
	-s Windows share name
	-m local mount point (directory)
	-h this help

EOS
exit $1
}

while getopts ":u:r:m:s:h" opt; do
	case $opt in
	u)	remote_user=$OPTARG ;;
	r)	remote_host=$OPTARG ;;
	s)	remote_share_name=$OPTARG ;;
	m)	local_mount_point=$OPTARG ;;
	h)	_usage 0 ;;
	\?) _usage 1 ;;
  esac
done

[ -z "$remote_user" ] && _usage 1
[ -z "$remote_host" ] && _usage 1
[ -z "$remote_share_name" ] && _usage 1
[ -z "$local_mount_point" ] && _usage 1

remote_mount_point=//$remote_host/$remote_share_name

mount_options="rw"
mount_options="$mount_options,username=$remote_user"
mount_options="$mount_options,$local_owner"
mount_options="$mount_options,iocharset=utf8"

cat <<EOS
$0
local :
 user: $local_user
 mount dir: $local_mount_point
remote:
 user: $remote_user
 host: $remote_host
 mount dir: $remote_mount_point
 mount_options: $mount_options
EOS

mkdir -p $local_mount_point

if $(mount | grep -q "^$remote_mount_point" )
then
    echo "Directory [$local_mount_point] already mounted:"
else
    echo "Mounting [$remote_mount_point] on [$local_mount_point]"
    sudo mount -t cifs -o $mount_options $remote_mount_point $local_mount_point
fi

echo
mount | grep "^$remote_mount_point"
