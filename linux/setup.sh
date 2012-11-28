#!/bin/bash


# GIT Clone: git clone https://github.com/nicoolas/nicoolas .

_log() {
	echo "$*"
}

_log "Setting up configuration files"
cur_dir=$(pwd)
for file in conf/_.*
do
	link_file="$HOME/$(basename $file | sed s/^_//)"
	echo " - $(basename $link_file)"
	[ -f $link_file ] && mv $link_file $link_file.bkp
	ln -s $cur_dir/$file $link_file
done

_log "Appending sources to bashrc file"
cat >> $HOME/.bashrc << EOS 
[ -f ~/.bash_share ] && source ~/.bash_share
[ -f ~/.bash_aliases ] && source ~/.bash_aliases
EOS


