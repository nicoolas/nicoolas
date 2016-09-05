#!/bin/sh

prefix="$1"
tag=$(date +%Y%m%d_%H%M%S)
cat <<EOS

Prefix: $prefix
Tag: $tag

Directory: $prefix$tag

EOS
mkdir -vp $prefix$tag

