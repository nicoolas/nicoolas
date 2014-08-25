## [ -n "$bashrc_aliases_sourced" ] && return
## export bashrc_aliases_sourced=yes

alias init_profile=". ${HOME}/.bashrc"
alias edit_profile="vi ${HOME}/.bashrc"
alias apt='sudo aptitude '
alias slogs='sudo tail -n 40 -f /var/log/syslog'
alias logs='sudo tail -n 40 -f /var/log/messages'
alias shout='notify-send "Youpi."'

alias gr='grep -nI --color=auto'
alias rgr='grep -rnI --color=auto'
alias apt='sudo aptitude'
alias grep='grep --color=auto'
alias psf='pgrep -fl '

alias svnpath="svn info | sed -n '/^URL/s/URL.: //p'"
alias sfind='find  -path *.svn -prune -o -print '

# TMUX
alias tmux-as='tmux attach-session -t '
alias tmux-ls='tmux list-sessions'
alias tmux-ns='tmux new-session -s '
alias tmux-copy=" tr '\012' ' ' | tee /tmp/screen-exchange"
alias tmux-pwd=" pwd | tmux-copy"

function browse()
{
	local _dir="$1"
	local _browser=""
	for _b in "nautilus" "dolphin" 
	do
		which $_b &> /dev/null && _browser=$_b
		[ -n "$_browser" ] && break
	done
	if [ -z "$_browser" ]; then
		echo "No browser found"
		return 1
	fi
	[ -z "$_dir" ] && _dir="$(pwd)"
	echo $_browser "$_dir" 
	$_browser "$_dir"  &>/dev/null & 
}

function tmux-go()
{
    DEFAULT_TMUX_SESSION_NAME=.
    if [ "$TERM" = "xterm" -o "$1" = "force" ] ; then
        if [ "$TERM" != "xterm" ] ; then
            echo "Forcing embedded tmux sessions (TERM=$TERM)"
            #unset TMUX
        fi
        if  tmux has-session -t $DEFAULT_TMUX_SESSION_NAME
        then tmux-as $DEFAULT_TMUX_SESSION_NAME
        else tmux-ns $DEFAULT_TMUX_SESSION_NAME
        fi
    fi
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

alias git_merge_remove="git status --porcelain | sed -n '/^ D/s/^ D //p' | while read f ; do git rm $f; done"

# GIT: get the diff of one commit
# git diff COMMIT^!
# or 
# git diff-tree -p COMMIT
alias git_diff_one="git show --color --pretty=format:%b "

