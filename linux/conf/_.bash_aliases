## [ -n "$bashrc_aliases_sourced" ] && return
## export bashrc_aliases_sourced=yes

alias init_profile=". ${HOME}/.bashrc"
alias edit_profile="vi ${HOME}/.bashrc"
alias apt='sudo aptitude '
alias slogs='sudo tail -n 40 -f /var/log/syslog'
alias shout='notify-send "Youpi."'

alias gr='grep -nI --color=auto'
alias rgr='grep -rnI --color=auto'
alias apt='sudo aptitude'
alias grep='grep --color=auto'
alias psf='pgrep -fl '

alias sfind='find  -path *.svn -prune -o -print '

# TMUX
alias tmux-ls='tmux list-sessions'
alias tmux-copy=" tee /tmp/screen-exchange"
alias tmux-copy-n=' awk "//{printf \$1 }" | tee /tmp/screen-exchange'
alias tmux-copy-pwd=" pwd | tmux-copy-n"


function browse()
{
    local _dir="$1"
    for _b in "nautilus" "dolphin"
    do
        if which $_b &> /dev/null
        then
            [ -z "$_dir" ] && _dir="$(pwd)"
            echo $_b "$_dir"
            $_b "$_dir"  &>/dev/null &
            return 0
        fi
    done
    echo "No browser found"
    return 1
}

function tmux-go()
{
	if [ -z "$TMUX" ]; then
		tmux new-session -A -s 0
		if [ $? -ne 0 ] # new-session -A not supported on tmux versions < 1.9
		then
			DEFAULT_TMUX_SESSION_NAME=0
			if  tmux has-session -t $DEFAULT_TMUX_SESSION_NAME
			then tmux attach-session -t $DEFAULT_TMUX_SESSION_NAME
			else tmux new-session -s $DEFAULT_TMUX_SESSION_NAME
			fi
		fi
	else
		echo "Running in a Tmux session ($TMUX)"
	fi
}

function tmux-buffers()
{
	local buf=""
	for i in $(seq 0  9)
	do 
		buf=/opt/screen/scbuf.$i
		if [ -r $buf ]
		then
			echo "\033[1;31m=== Buffer #$i ===\033[0m"
			cat $buf
			echo
		fi
	done | less -R
}

# some more ls aliases
alias ls='ls --color=auto'
alias ll='ls -hl'
alias la='ls -hA'
alias lla='ls -hlA'
alias l='ls -hCF'

#alias kfr='setxkbmap fr'
#alias kgb='setxkbmap gb; xmodmap ~/.xmodmaprc'
#alias kus='setxkbmap us; xmodmap ~/.xmodmaprc'

function base() {
	while read in
	do
		in_upper=${in^^}
		for base in " 2" 10 16
			do
			echo -en "base $base: "
			echo "obase=$base; ibase=16; $in_upper" | bc
		done
	done
}

function base_bin() {
	echo  "obase=16; ibase=2; $1" | bc  | base
}

function base_dec() {
	echo  "obase=16; ibase=10; $1" | bc  | base
}

function base_hex() {
	echo  $1 | base
}

# -- GIT aliases

# GIT: get the diff of one commit
# git diff COMMIT^!
# or 
# git diff-tree -p COMMIT
alias git_diff_one="git show --color --pretty=format:%b "
alias git_status="git status --porcelain | grep -v '^??'"
alias git_status_all="git status --porcelain"

