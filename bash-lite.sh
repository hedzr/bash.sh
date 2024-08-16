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
#   Version: v20240816
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
		          in_vim/neovim: $(in_vim && echo Y || echo '.') / $(in_neovim && echo Y || echo '.')
		  darwin/linux/win(wsl): $(is_darwin && echo Y || echo '.')$(is_darwin_sillicon && echo ' [Sillicon] ' || echo ' ')/ $(is_linux && echo Y || echo '.') / $(is_win && echo Y || echo '.')
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
	local xcmd cmd=${1:-sleeping} && { [[ $# -ge 1 ]] && shift; } || :
	# for linux only:
	# local cmd=${1:-sleeping} && shift || :

	# eval "$cmd $@" || :

	fn_exists "$cmd" && {
		debug "$cmd - $@"
		eval $cmd "$@"
	} || {
		xcmd="lite-$cmd" && fn_exists "$xcmd" && eval $xcmd "$@" || {
			xcmd="try-lite-$cmd" && fn_exists "$xcmd" && eval $xcmd "$@" || {
				xcmd="build-c$cmd" && fn_exists "$xcmd" && eval $xcmd "$@"
			}
		}
	}
	unset cmd xcmd
}

########################################################

#### HZ Tail BEGIN #### v20240816 ####
in_debug() { (($DEBUG)); }
in_provisioning() { (($PROVISIONING)); } ## return exit status as true if $PROVISIONING is not equal to 0
is_root() { [ "$(id -u)" = "0" ]; }
is_bash() { is_bash_t1 || is_bash_t2; }
is_bash_t1() { [ -n "$BASH_VERSION" ]; }
is_bash_t2() { [ ! -n "$BASH" ]; }
is_zsh() { [[ -n "$ZSH_NAME" || "$SHELL" = */zsh ]]; }
is_zsh_t1() { [[ "$SHELL" = */zsh ]]; }
is_zsh_t2() { [ -n "$ZSH_NAME" ]; }
is_fish() { [ -n "$FISH_VERSION" ]; }
is_darwin() { [[ $OSTYPE == darwin* ]]; }
is_darwin_sillicon() { is_darwin && [[ $(uname -m) == arm64 ]]; }
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
in_jetbrains() { [[ "$TERMINAL_EMULATOR" == *JetBrains* ]]; }
in_vim() { [[ "$VIM" != "" ]] && [[ "$VIMRUNTIME" != "" ]]; }
in_neovim() { [[ "$NVIM" != "" ]] || [[ "$NVIM_LOG_FILE" != "" ]] || [[ "$NVIM_LISTEN_ADDRESS" != "" ]]; }
is_interactive_shell() { [[ $- == *i* ]]; }
is_not_interactive_shell() { [[ $- != *i* ]]; }
is_ps1() { [ -z "$PS1" ]; }
is_not_ps1() { [ ! -z "$PS1" ]; }
# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
	is_stdin() { true; }
	is_not_stdin() { false; }
	is_ttya() { true; }
else
	is_stdin() { false; }
	is_not_stdin() { true; }
	is_ttya() { false; }
fi
fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(shell function)|(a function)'; }
fn_builtin_exists() { LC_ALL=C type $1 2>/dev/null | grep -q 'shell builtin'; }
fn_aliased_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(alias for)|(aliased to)'; }
fn_name() {
	is_zsh && local fn_="${funcstack[2]}"
	if [ "$fn_" = "" ]; then
		is_bash && echo "${FUNCNAME[1]}"
	else
		echo "$fn_"
	fi
	# is_zsh && echo "${funcstack[2]}" || {
	# 	is_bash && echo "${FUNCNAME[1]}"
	# }
}
#
is_git_clean() { git diff-index --quiet $* HEAD -- 2>/dev/null; }
is_git_dirty() { is_git_clean && return -1 || return 0; }
git_clone() {
	local Deep="--depth=1" Help Dryrun Https Dir arg i=1 Verbose=0
	while [[ $# -gt 0 ]]; do
		case $1 in
		-h | --help)
			shift && Help=1
			cat <<-EOT
				git-clone helps cloneing git repo simply from github/gitlab/bitbucket

				Usage: git-clone [-d|--deep] [-s|--https] [-o dir|--dir dir] repo

				Description:
				  git-clone will pull the repo into 'user.repo/', for example:
				    git-clone hedzr/cmdr
				    GIT_HOST=gitlab.com git-clone hedzr/cmdr
				    git-clone git@github.com:hedzr/cmdr.git
				    git-clone https://github.com/hedzr/cmdr.git
				  will pull hedzr/cmdr into 'hedzr.cmdr/' directory.

				Options and Args:

				  '--deep' enables full fetch, default is shallow pull only
				  '--https' enables https protocal, default is ssh protocol
				  '--dir' specifies the cloned target directory, default is 'user.repo'

				  'repo' can be these forms:
				    hedzr/cmdr
				    https://github.com/hedzr/cmdr
				    https://github.com/hedzr/cmdr.git
				    github.com:hedzr/cmdr.git
				    git@github.com:hedzr/cmdr.git
				    gitlab.com:hedzr/cmdr
				    bitbucket.com/hedzr/cmdr
				    git.sr.ht/hedzr/cmdr
				    gitee.com/hedzr/cmdr
				    coding.net/hedzr/cmdr

				EnvVars:
				  GIT_HOSTS    extras git hosts such as your own private host
				  GIT_HOST     specify git host explicitly if you're using user/repo form.

			EOT
			;;
		-d | --deep)
			# strength=$OPTARG
			shift && Deep=""
			;;
		-dr | --dry-run | --dryrun)
			shift && Dryrun=1
			;;
		-s | --https)
			shift && Https=1
			;;
		-o | --dir | --output)
			shift && Dir="$1" && shift
			;;
		-v | --verbose)
			Verbose=1 && shift
			;;
		*)
			case $i in
			1)
				local Repo="${1:-hedzr/cmdr}"
				shift
				;;
			esac
			;;
		esac
	done

	if [[ "$Help" != 1 ]]; then
		local Sep='/' Prefix="${GIT_PREFIX:-git@}" Host="${GIT_HOST:-github.com}" h
		[[ "$Https" -eq 1 ]] && Prefix="https://"
		[[ "$Repo" =~ https://* ]] && Repo="${Repo//https:\/\//}"
		for h in github.com gitlab.com bitbucket.com git.sr.ht gitee.com coding.net $GIT_HOSTS; do
			[[ "$Repo" =~ $h/* ]] && Host=$h && Repo="${Repo//$h\//}"
			[[ "$Repo" =~ $h:* ]] && Host=$h && Repo="${Repo//$h:/}"
		done
		Repo="${Repo%\#*}"
		Repo="${Repo%\?*}"
		Repo="${Repo#git@}"
		Repo="${Repo%.git}"
		Repo="${Repo%/blob/*}"
		[[ "$Dir" == "" ]] && Dir="${Repo//\//.}"
		[[ "$Prefix" == 'git@' ]] && Sep=':'
		local Url="${Prefix}${Host}${Sep}${Repo}.git" Opts=""
		(($Verbose)) && Opts="--verbose"
		if [[ "$Dryrun" -ne 0 ]]; then
			tip "Url: $Url | Deep?: '$Deep' | Opts: '$Opts'"
			tip "Result: git clone $Deep -q $Opts "$Url" "$Dir""
		else
			dbg "cloning from $Url ..." && git clone $Deep -q $Opts "$Url" "$Dir" && {
				(($Verbose)) && local DEBUG=1
				dbg "git clone $Url DONE."
				(($Verbose)) && du -sh "$Dir" || :
			}
		fi
	fi
}
alias git-clone=git_clone
alias git-clone-deep='git_clone -d'
alias git-clone-deep-v='git_clone -d -v'
#
headline() { printf "\e[0;1m$@\e[0m:\n"; }
headline_begin() { printf "\e[0;1m"; } # for more color, see: shttps://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
headline_end() { printf "\e[0m:\n"; }  # https://misc.flogisoft.com/bash/tip_colors_and_formatting
debug() { in_debug && printf "\e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_begin() { printf "\e[0;38;2;133;133;133m"; }
debug_end() { printf "\e[0m\n"; }
dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }
mvif() {
	local src="$1" dstdir="$2"
	if [ -d "$dstdir" ]; then
		mv "$src" "$dstdir"
	fi
}
#
strip_l() { echo ${1#"$2"}; }
strip_r() { echo ${1%"$2"}; }
pad() {
	# pad 'pre', 'line' and 'post' as 3-column.
	#   the 1st arg is the count of indent spaces
	#   the 2nd and 3rd args are 'pre'-text and 'post'-text
	#   NOTE that the 'line' itself will be read from stdin.
	# sample: cat 1.txt | pad 2
	#     or: find . -iname '*.log' -print -delete | pad 4 '' ' deleted.'
	local line p=$1 && (($#)) && shift
	local pre=$1 && (($#)) && shift
	local post=$1 && (($#)) && shift
	while read line; do printf '%-'$p"s%s%s%s\n" ' ' "$pre" "$line" "$post"; done # <<< "$@"
}
pad3() {
	# pad 'pre', 'line' and 'post' as 3-column.
	#   the 1st arg is the count of indent spaces
	#   the 2nd arg is the width of 'line'
	#   the 3rd and 4th args are 'pre'-text and 'post'-text
	#   NOTE that the 'line' itself will be read from stdin.
	# sample: ls -la | pad3 4 '-72' '' ' | desc here'
	local line
	local p=$1 && (($#)) && shift
	local linewidth="${1:--1}" && (($#)) && shift
	local pre=$1 && (($#)) && shift
	local post=$1 && (($#)) && shift
	while read line; do printf '%-'$p"s%s%${linewidth}s%s\n" ' ' "$pre" "$line" "$post"; done # <<< "$@"
}
commander() {
	local self=$1
	[[ $# -gt 0 ]] && shift
	local cmd=${1:-usage}
	[[ $# -gt 0 ]] && shift
	#local self=${FUNCNAME[0]}
	case $cmd in
	help | usage | --help | -h | -H) "${self}_usage" "$@" ;;
	funcs | --funcs | --functions | --fn | -fn) script_functions "^$self" ;;
	*)
		# if [ "$(type -t ${self}_${cmd}_entry)" == "function" ]; then
		if $(fn_exists ${self}_${cmd}_entry); then
			eval ${self}_${cmd}_entry "$@"
		elif $(fn_exists ${self}-${cmd}-entry); then
			eval ${self}-${cmd}-entry "$@"
		elif $(fn_exists ${self}-${cmd}); then
			eval ${self}-${cmd} "$@"
		else
			eval ${self}_${cmd} "$@"
		fi
		;;
	esac
}
#
if is_darwin; then
	readlinkx() {
		local p="$@"
		[ -L "$@" ] && p="$(readlink "$@")"
		echo "$p"
	}
	realpathx() {
		if [[ $1 == /* ]]; then
			# dbg " .. case 1: '$1'"
			echo "$@"
		else
			local DIR="${1%/*}" d p
			if [ -d "$DIR" ]; then
				# dbg " .. case 2: '$1' / DIR = '$DIR' pwd=$(pwd -P)"
				DIR="$(cd $DIR && pwd -P)"
				d="$DIR/$(basename "$1")"
				p="$(readlinkx "$d")"
			else
				# dbg " .. case 3: '$1'"
				p="$(readlinkx "$@")"
			fi
			# dbg " p: '$p', d: '$d'"
			[[ $p == /* ]] && echo "$p" || {
				[[ "$p" == "" ]] && echo || {
					local DIR="${p%/*}" && {
						[ -d "$DIR" ] && { DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $p)"; } || echo "$p"
					}
				}
			}
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
	local res_
	in_debug && debug_info && dbg "$(safety "$MAIN_ENTRY - $@\n    [CD: $CD, SCRIPT: $SCRIPT]")"
	if in_sourcing; then
		$MAIN_ENTRY "$@"
		res_=$?
	else
		trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
		trap '[ $? -ne 0 ] && echo FAILED COMMAND: "$previous_command" with exit code $?' EXIT
		$MAIN_ENTRY "$@"
		res_=$?
		trap - EXIT
	fi
	((${HAS_END:-0})) && { debug_begin && echo -n 'Success!' && debug_end; } || return $res_ # { [ $# -eq 0 ] && :; }
}
BASH_SH_VERSION=v20240816
DEBUG=${DEBUG:-0}
# trans_readlink() { DIR="${1%/*}" && (cd $DIR && pwd -P); }
# is_darwin && realpathx() { [[ $1 == /* ]] && echo "$1" || { DIR="${1%/*}" && DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $1)"; }; } || realpathx() { readlink -f $*; }
in_sourcing && { CD="${CD}" && debug ">> IN SOURCING, \$0=$0, \$_=$_"; } || { SCRIPT=$(realpathx "$0") && CD=$(dirname "$SCRIPT") && debug ">> '$SCRIPT' in '$CD', \$0='$0','$1'."; }
if_vagrant && [ "$SCRIPT" == "/tmp/vagrant-shell" ] && { [ -d $CD/ops.d ] || CD=/vagrant/bin; }
[ -L "$SCRIPT" ] && debug linked script found && SCRIPT=$(realpathx "$SCRIPT") && CD=$(dirname "$SCRIPT")
in_sourcing || main_do_sth "$@"
#### HZ Tail END #### v20240816 ####
