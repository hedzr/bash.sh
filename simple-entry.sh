#!/bin/bash

######### YOUR CODES HERE #########

set -e

# (($#)) && { cmd="$1" && shift; } || cmd="cmd"
# eval "mk-$cmd" "$@"

sleepx() { tip "sleeping..." && (($#)) && \sleep "$@"; }

######### SIMPLE BASH.SH FOOTER BEGIN #########

###
is_git_clean() { git diff-index --quiet "$@" HEAD -- 2>/dev/null; }
is_git_dirty() {
	if is_git_clean "$@"; then
		false
	else
		true
	fi
}

dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
wrn() { printf "\e[0;38;2;172;172;22m... [WARN] \e[0;38;2;11;11;11m$@\e[0m\n"; }
err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }
cmd_exists() { command -v $1 >/dev/null; } # it detects any builtin or external commands, aliases, and any functions
fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(shell function)|(a function)'; }
fn_builtin_exists() { LC_ALL=C type $1 2>/dev/null | grep -q 'shell builtin'; }
fn_defined() { LC_ALL=C type $1 2>/dev/null | grep -qE '( shell function)|( a function)|( shell builtin)'; }

###
is_xdg_ready() { [[ -n "${XDG_CONFIG_HOME-}" ]]; } # when xdg-config presents, prefer using XDG_xxx
is_darwin() { [[ $OSTYPE == darwin* ]]; }
is_darwin_sillicon() { is_darwin && [[ $(uname_mach) == arm64 ]]; }
is_linux() { [[ $OSTYPE == linux* ]]; }
is_freebsd() { [[ $OSTYPE == freebsd* ]]; }
is_win() { in_wsl; }
in_wsl() { [[ "$(uname -r)" == *windows_standard* ]]; }

###
if_nix_typ() {
	case "$OSTYPE" in
	*linux* | *hurd* | *msys* | *cygwin* | *sua* | *interix*) sys="gnu" ;;
	*bsd* | *darwin*) sys="bsd" ;;
	*sunos* | *solaris* | *indiana* | *illumos* | *smartos*) sys="sun" ;;
	esac
	echo "${sys}"
}
if_nix() { [[ "$(if_nix_typ)" == "$1" ]]; }
if_mac() { [[ $OSTYPE == darwin* ]]; }
if_ubuntu() {
	if [[ $OSTYPE == linux* ]]; then
		[ -f /etc/os-release ] && grep -qi 'ubuntu' /etc/os-release
	fi
}
if_vagrant() { [ -d /vagrant ]; }
in_vagrant() { [ -d /vagrant ]; }
in_orb() { [[ -d /mnt/mac ]]; }
path_in_orb_host() { [[ "$1" = /mnt/mac/* ]]; }
if_centos() {
	if [[ $OSTYPE == linux* ]]; then
		if [ -f /etc/centos-release ]; then
			:
		else
			[ -f /etc/issue ] && grep -qEi '(centos|(Amazon Linux AMI))' /etc/issue
		fi
	fi
}
in_vmware() {
	if cmd_exists hostnamectl; then
		$SUDO hostnamectl | grep -E 'Virtualization: ' | grep -qEi 'vmware'
	else
		false
	fi
}
in_vm() {
	if cmd_exists hostnamectl; then
		# dbg "checking hostnamectl"
		if $SUDO hostnamectl | grep -iE 'chassis: ' | grep -q ' vm'; then
			true
		elif $SUDO hostnamectl | grep -qE 'Virtualization: '; then
			true
		fi
	else
		# dbg "without hostnamectl"
		false
	fi
}
if_upstart() { [[ $(/sbin/init --version) =~ upstart ]]; }
if_systemd() { [[ $(systemctl) =~ -\.mount ]]; }
if_sysv() { [[ -f /etc/init.d/cron && ! -L /etc/init.d/cron ]]; }

# ###
# The better consice way to get baseDir, ie. $CD, is:
#       CD=$(cd `dirname "$0"`;pwd)
# It will open a sub-shell to print the folder name of the running shell-script.

# ###
# cmd="$1" && (($#)) && shift
# if fn_exists "$cmd"; then
# 	eval $cmd "$@"
# 	unset cmd
# else
# 	xcmd="cmake-$cmd"
# 	if fn_exists "$xcmd"; then eval $xcmd "$@"; else
# 		xcmd="build-$cmd"
# 		if fn_exists "$xcmd"; then eval $xcmd "$@"; else
# 			xcmd="build-c$cmd"
# 			if fn_exists "$xcmd"; then eval $xcmd "$@"; else
# 				echo "Error: No such command or function: '$cmd'" >&2
# 				exit 1
# 			fi
# 		fi
# 	fi
# 	unset cmd xcmd
# fi

###
CD="$(cd $(dirname "$0") && pwd)" && BASH_SH_VERSION=v20260103 && DEBUG=${DEBUG:-0} && PROVISIONING=${PROVISIONING:-0}
SUDO=sudo && { [ "$(id -u)" = "0" ] && SUDO= || :; }
LS_OPT="--color" && { is_darwin && LS_OPT="-G" || :; }
if (($#)); then
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
	check_entry "${FN_PREFIX:-boot}" "$@"
else
	dbg "empty: $# | CD = $CD | DEBUG = $DEBUG"
	if fn_exists boot_usages; then
		eval boot_usages "$@"
	else
		err "no default entry function 'boot_usages' found."
		exit 1
	fi
fi
######### SIMPLE BASH.SH FOOTER END #########
