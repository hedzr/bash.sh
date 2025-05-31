#!/bin/bash

######### YOUR CODES HERE #########

sleep() { tip "sleeping..."; }

######### SIMPLE BASH.SH FOOTER BEGIN #########

# The better consice way to get baseDir, ie. $CD, is:
#       CD=$(cd `dirname "$0"`;pwd)
# It will open a sub-shell to print the folder name of the running shell-script.

dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }
fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(shell function)|(a function)'; }
CD="$(cd $(dirname "$0") && pwd)" && BASH_SH_VERSION=v20250531 && DEBUG=${DEBUG:-0} && PROVISIONING=${PROVISIONING:-0}
(($#)) && {
	dbg "$# arg(s) | CD = $CD"
	check_entry() {
		local prefix="$1" cmd="$2" && shift && shift
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
