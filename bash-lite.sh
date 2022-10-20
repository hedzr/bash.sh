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
#   Version: v20221021
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

# erase this function and start yours
debug_info() {
	debug_begin
	cat <<-EOF
		               in_debug: $(in_debug && echo Y || echo '.')
		                is_root: $(is_root && echo Y || echo '.')
		                is_bash: $(is_bash && echo Y || echo '.')       # SHELL = $SHELL, BASH_VERSION = $BASH_VERSION
		       is_zsh/is_zsh_t1: $(is_zsh && echo Y || echo '.') / $(is_zsh_t1 && echo Y || echo '.')   # $(is_zsh && echo "ZSH_EVAL_CONTEXT = $ZSH_EVAL_CONTEXT, ZSH_NAME = $ZSH_NAME, ZSH_VERSION = $ZSH_VERSION" || :)
		                is_fish: $(is_fish && echo Y || echo '.')       # FISH_VERSION = $FISH_VERSION
		            in_sourcing: $(in_sourcing && echo Y || echo '.')
		              in_vscode: $(in_vscode && echo Y || echo '.')
		            in_jetbrain: $(in_jetbrain && echo Y || echo '.')
		  darwin/linux/win(wsl): $(is_darwin && echo Y || echo '.') / $(is_linux && echo Y || echo '.') / $(is_win && echo Y || echo '.')
		   is_interactive_shell: $(is_interactive_shell && echo Y || echo '.')
		  
		NOTE: bash.sh can only work in bash/zsh mode, even if running it in fish shell.
	EOF
	debug_end
	:
}

#### write your functions here, and invoke them by: `./bash-lite.sh <your-func-name>`
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
is_bash() { is_bash_t1 || is_bash_t2; }
is_bash_t1() { [ -n "$BASH_VERSION" ]; }
is_bash_t2() { [ ! -n "$BASH" ]; }
is_zsh() { [[ -n "$ZSH_NAME" || "$SHELL" = */zsh ]]; }
is_zsh_t1() { [[ "$SHELL" = */zsh ]]; }
is_zsh_t2() { [ -n "$ZSH_NAME" ]; }
is_fish() { [ -n "$FISH_VERSION" ]; }
is_darwin() { [[ $OSTYPE == darwin* ]]; }
is_linux() { [[ $OSTYPE == linux* ]]; }
is_win() { in_wsl; }
in_wsl() { [[ "$(uname -r)" == *windows_standard* ]]; }
in_sourcing() {
	# https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced
	if is_zsh; then
		[[ "$ZSH_EVAL_CONTEXT" == *:file:* ]]
	else
		[[ $(basename -- "$0") != $(basename -- "${BASH_SOURCE[0]}") ]]
	fi
}
in_vscode() { [[ "$TERM_PROGRAM" == "vscode" ]]; }
in_jetbrain() { [[ "$TERMINAL_EMULATOR" == *JetBrains* ]]; }
is_interactive_shell() { [[ $- == *i* ]]; }
is_not_interactive_shell() { [[ $- != *i* ]]; }
is_ps1() { [ -z "$PS1" ]; }
is_not_ps1() { [ ! -z "$PS1" ]; }
#
is_git_clean() { git diff-index --quiet $* HEAD -- 2>/dev/null; }
is_git_dirty() { is_git_clean && return -1 || return 0; }
#
headline() { printf "\e[0;1m$@\e[0m:\n"; }
debug() { in_debug && printf "\e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_begin() { printf "\e[0;38;2;133;133;133m"; }
debug_end() { printf "\e[0m\n"; }
dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
if is_darwin; then
	realpathx() {
		if [[ $1 == /* ]]; then
			# dbg " .. case 1: '$1'"
			echo "$@"
		else
			local DIR="${1%/*}" d p
			if [ -d "$DIR" ]; then
				# dbg " .. case 2: '$1' / DIR = '$DIR' pwd=$(pwd -P)"
				DIR=$(cd $DIR && pwd -P)
				d="$DIR/$(basename $1)"
				p="$(readlink "$d")"
			else
				# dbg " .. case 3: '$1'"
				p="$(readlink "$@")"
			fi
			# dbg " p: '$p', d: '$d'"
			[[ $p == /* ]] && echo "$p" || { local DIR="${p%/*}" && DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $p)"; }
		fi
	}
	default_dev() { route get default | awk '/interface:/{print $2}'; }
else
	realpathx() { readlink -f "$@"; }
	default_dev() { ip route show default | grep -oE 'dev \w+' | awk '{print $2}'; }
fi
main_do_sth() {
	[ ${VERBOSE:-0} -eq 1 ] && set -x
	set -e
	# set -o errexit
	# set -o nounset
	# set -o pipefail
	MAIN_DEV=${MAIN_DEV:-$(default_dev)}
	MAIN_ENTRY=${MAIN_ENTRY:-_my_main_do_sth}
	# echo $MAIN_ENTRY - "$@"
	if in_debug; then
		debug_info && dbg "$MAIN_ENTRY - $@ [CD: $CD, SCRIPT: $SCRIPT]"
	fi
	#
	if in_sourcing; then
		$MAIN_ENTRY "$@"
	else
		trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
		trap '[ $? -ne 0 ] && echo FAILED COMMAND: "$previous_command" with exit code $?' EXIT
		$MAIN_ENTRY "$@"
		trap - EXIT
	fi
	${HAS_END:-$(false)} && { debug_begin && echo -n 'Success!' && debug_end; } || { [ $# -eq 0 ] && :; }
}
BASH_SH_VERSION=v20221021
DEBUG=${DEBUG:-0}
# trans_readlink() { DIR="${1%/*}" && (cd $DIR && pwd -P); }
# is_darwin && realpathx() { [[ $1 == /* ]] && echo "$1" || { DIR="${1%/*}" && DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $1)"; }; } || realpathx() { readlink -f $*; }
in_sourcing && { CD="${CD}" && debug ">> IN SOURCING, \$0=$0, \$_=$_"; } || { SCRIPT=$(realpathx "$0") && CD=$(dirname "$SCRIPT") && debug ">> '$SCRIPT' in '$CD', \$0='$0','$1'."; }
if_vagrant && [ "$SCRIPT" == "/tmp/vagrant-shell" ] && { [ -d $CD/ops.d ] || CD=/vagrant/bin; }
[ -L "$SCRIPT" ] && debug linked script found && SCRIPT=$(realpathx "$SCRIPT") && CD=$(dirname "$SCRIPT")
in_sourcing || main_do_sth "$@"
#### HZ Tail END ####
