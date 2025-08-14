#!/bin/bash

######### YOUR CODES HERE #########

sleepx() { tip "sleeping..." && (($#)) && \sleep "$@"; }

######### SIMPLE BASH.SH FOOTER BEGIN #########

is_darwin() { [[ $OSTYPE == darwin* ]]; }
is_darwin_sillicon() { is_darwin && [[ $(uname_mach) == arm64 ]]; }
is_linux() { [[ $OSTYPE == linux* ]]; }
is_freebsd() { [[ $OSTYPE == freebsd* ]]; }
is_win() { in_wsl; }
in_wsl() { [[ "$(uname -r)" == *windows_standard* ]]; }

is_git_clean() { git diff-index --quiet "$@" HEAD -- 2>/dev/null; }
is_git_dirty() {
	if is_git_clean "$@"; then
		false
	else
		true
	fi
}

###
# The better consice way to get baseDir, ie. $CD, is:
#       CD=$(cd `dirname "$0"`;pwd)
# It will open a sub-shell to print the folder name of the running shell-script.

dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
wrn() { printf "\e[0;38;2;172;172;22m... [WARN] \e[0;38;2;11;11;11m$@\e[0m\n"; }
err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }
fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(shell function)|(a function)'; }
CD="$(cd $(dirname "$0") && pwd)" && BASH_SH_VERSION=v20250815 && DEBUG=${DEBUG:-0} && PROVISIONING=${PROVISIONING:-0}
SUDO=sudo && [ "$(id -u)" = "0" ] && SUDO=
LS_OPT="--color" && is_darwin && LS_OPT="-G"
(($#)) && {
	dbg "$# arg(s) | CD = $CD"
	check_entry() {
		local prefix="${1:-boot}" cmd="${2:-first}" && shift && shift
		if fn_exists "${prefix}_${cmd}_entry"; then
			eval "${prefix}_${cmd}_entry" "$@"
		elif fn_exists "${cmd}_entry"; then
			eval "${cmd}_entry" "$@"
		else
			prefix="${prefix}_${cmd}"
			if fn_exists $prefix; then
				eval $prefix "$@"
			elif fn_exists ${prefix//_/-}; then
				eval ${prefix//_/-} "$@"
			elif fn_exists $cmd; then
				eval $cmd "$@"
			elif fn_exists ${cmd//_/-}; then
				eval ${cmd//_/-} "$@"
			else
				err "command not found: $cmd $@"
				return 1
			fi
		fi
	}
	check_entry "boot" "$@"
} || { dbg "empty: $# | CD = $CD"; }
######### SIMPLE BASH.SH FOOTER END #########
