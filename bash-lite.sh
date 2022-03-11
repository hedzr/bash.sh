# # /usr/bin/env bash
# -*- mode: bash; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: t-*-
# vi: set ft=bash noet ci pi sts=0 sw=2 ts=2:
# st:
#
#
# # /usr/bin/env bash
#
# bash.sh:
#   Standard Template for bash/zsh developing.
#   Version: v20220311
#   License: MIT
#   Site: https://github/hedzr/bash.sh
#

# Usages:
#  $ ./bash.sh cool
#  $ DEBUG=1 ./bash.sh
#
#  $ ./bash.sh debug-info
#
#  $ ./bash.sh 'is_root && echo Y'
#  $ sudo ./bash.sh 'is_root && echo Y'
#  $ sudo DEBUG=1 ./bash.sh 'is_root && echo y'
#
#  $ HAS_END=: ./bash.sh
#  $ HAS_END=false ./bash.sh
#
# Use installer:
#   $ curl -sSL https://hedzr.com/bash.sh/installer | sudo bash -s

#

#### write your functions here, and invoke them by: `./bash.sh <your-func-name>`
cool() { echo cool; }
sleeping() { echo sleeping; }

_my_main_do_sth() {
	local cmd=${1:-sleeping} && { [[ $# -ge 1 ]] && shift; } || :
	# for linux only:
	# local cmd=${1:-sleeping} && shift || :

	debug "$cmd - $@"
	eval "$cmd $@" || :
}

in_debug() { [[ $DEBUG -eq 1 ]]; }
is_root() { [ "$(id -u)" = "0" ]; }
is_bash() { is_bash_t1 || is_bush_t2; }
is_zsh() { [ -n "$ZSH_NAME" ]; }
is_darwin() { [[ $OSTYPE == *darwin* ]]; }
is_linux() { [[ $OSTYPE == *linux* ]]; }
in_sourcing() { is_zsh && [[ "$ZSH_EVAL_CONTEXT" == toplevel* ]] || [[ $(basename -- "$0") != $(basename -- "${BASH_SOURCE[0]}") ]]; }
is_git_dirty() { git diff --stat --quiet; }
headline() { printf "\e[0;1m$@\e[0m:\n"; }
debug() { in_debug && printf "\e[0;38;2;133;133;133m$@\e[0m\n" || :; }
dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
main_do_sth() {
	set -e
	trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
	trap '[ $? -ne 0 ] && echo FAILED COMMAND: $previous_command with exit code $?' EXIT
	MAIN_DEV=${MAIN_DEV:-eth0}
	MAIN_ENTRY=${MAIN_ENTRY:-_my_main_do_sth}
	# echo $MAIN_ENTRY - "$@"
	in_debug && { echo "$SHELL : $ZSH_NAME - $ZSH_VERSION | BASH_VERSION = $BASH_VERSION" && [ -n "$ZSH_NAME" ] && echo "x!"; }
	$MAIN_ENTRY "$@"
	trap - EXIT
	${HAS_END:-$(false)} && { debug 'Success!'; } || :
}
DEBUG=${DEBUG:-0}
trans_readlink() { DIR="${1%/*}" && (cd $DIR && pwd -P); }
is_darwin && realpathx() { [[ $1 == /* ]] && echo "$1" || { DIR="${1%/*}" && DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $1)"; }; } || realpathx() { readlink -f $*; }
in_sourcing && { CD=${CD} && debug ">> IN SOURCING, \$0=$0, \$_=$_"; } || { SCRIPT=$(realpathx "$0") && CD=$(dirname "$SCRIPT") && debug ">> '$SCRIPT' in '$CD', \$0='$0','$1'."; }
main_do_sth "$@"
#### HZ Tail END ####
