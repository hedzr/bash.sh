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
#   Version: v20220513
#   License: MIT
#   Site: https://github.com/hedzr/bash.sh
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
# Use installer (Deprecated):
#   $ curl -sSL https://hedzr.com/bash.sh/installer | sudo bash -s

#### write your functions here, and invoke them by: `./bash.sh <your-func-name>`
cool() { echo cool; }
sleeping() { echo sleeping; }

# FN_PREFIX=boot_
_my_main_do_sth() {
	local cmd=${1:-sleeping} && { [[ $# -ge 1 ]] && shift; } || :
	# local FN_PREFIX=boot_
	# for linux only:
	# local cmd=${1:-sleeping} && shift || :

	load_import_files
	load_env_files

	in_debug && LC_ALL=C type $cmd
	fn_exists $cmd && {
		debug "$cmd - $@"
		eval "$cmd $@" || :
	} || {
		# echo "$cmd - $@"
		debug "$cmd - $@"
		eval "$FN_PREFIX$cmd $@" || :
	}
}

load_import_files() {
	[ -d $CD/ops.d ] && {
		if test -n "$(find $CD/ops.d -maxdepth 1 -name 'import-*.sh' -print -quit)"; then
			for f in $CD/ops.d/import-*.sh; do source $f; done
		fi
	} || {
		[ -d /vagrant/bin ] && {
			cmd=first_install # bootstrapping a vagrant VM
			CD=/vagrant/bin
			if test -n "$(find $CD/ops.d -maxdepth 1 -name 'import-*.sh' -print -quit)"; then
				for f in $CD/ops.d/import-*.sh; do source $f; done
			fi
		} || {
			in_debug && ps -auxf
			debug "--------"
			debug "CD=$CD"
			debug "SCRIPT=$SCRIPT"
			debug "[NOTE] ops.d/ folder NOT FOUND, no more script files loaded."
		}
	}
}

load_env_files() {
	local env=
	for rel in '.' '..'; do
		env="$CD/$rel/.env"
		[ -f $env ] && source $env
	done

	# env="$HOME/.priv/k8s-istio-in-vagrant-env" # optional
	#	[ -f $env ] && source $env

	env="$CD/.env.local"
	[ -f $env ] && source $env
}

#### HZ Tail BEGIN ####
in_debug() { [[ $DEBUG -eq 1 ]]; }
is_root() { [ "$(id -u)" = "0" ]; }
is_bash() { is_bash_t1 || is_bush_t2; }
is_bash_t1() { [ -n "$BASH_VERSION" ]; }
is_bash_t2() { [ ! -n "$BASH" ]; }
is_zsh() { [ -n "$ZSH_NAME" ]; }
is_zsh_t1() { [ "$SHELL" = */zsh ]; }
is_zsh_t2() { [ -n "$ZSH_NAME" ]; }
is_fish() { [ -n "$FISH_VERSION" ]; }
is_darwin() { [ "$OSTYPE" = *darwin* ]; }
is_linux() { [ "$OSTYPE" = *linux* ]; }
in_sourcing() { is_zsh && [ "$ZSH_EVAL_CONTEXT" = toplevel* ] || [ $(basename -- "$0") != $(basename -- "${BASH_SOURCE[0]}") ]; }
is_interactive_shell() { [ $- = *i* ]; }
is_not_interactive_shell() { [ $- != *i* ]; }
is_ps1() { [ -z "$PS1" ]; }
is_not_ps1() { [ ! -z "$PS1" ]; }
# The [ -t 1 ] check only works when the function is not called from
# a subshell (like in `$(...)` or `(...)`, so this hack redefines the
# function at the top level to always return false when stdout is not
# a tty.
if [ -t 1 ]; then
	is_stdin() { true; }
	is_not_stdin() { false; }
	is_tty() { true; }
else
	is_stdin() { false; }
	is_not_stdin() { true; }
	is_tty() { false; }
fi
fn_exists() { LC_ALL=C type $1 | grep -qE '(shell function)|(a function)'; }
fn_builtin_exists() { LC_ALL=C type $1 | grep -q 'shell builtin'; }
fn_aliased_exists() { LC_ALL=C type $1 | grep -qE '(alias for)|(aliased to)'; }
fn_name() {
	is_zsh && echo "${funcstack[2]}" || {
		is_bash && echo "${FUNCNAME[1]}"
	}
}
currentShell=
fn_name_dyn() {
	# local currentShell=$(ps -p $$ | awk "NR==2" | awk '{ print $4 }' | tr -d '-')
	currentShell=${currentShell:-$(find_shell_by_pidtree)}
	if [[ $currentShell == *'bash' ]]; then
		echo ${FUNCNAME[1]}
	elif [[ $currentShell == *'zsh' ]]; then
		echo ${funcstack[2]}
	else
		echo "unknown func name ($currentShell)"
	fi
}
ps_get_procname() { ps -hp ${1:-$$} | awk '{print $4}'; }
ps_get_fullprocname() { ps -fhp ${1:-$$} | awk '{ for (i=5;i<=NF-1;i++) { printf "%s ", $i }; printf "\n" }'; }
ps_get_procpath() { ps -hp ${1:-$$} | awk '{ if(NF>6) print $6; else print $5 }'; }
user_shell() { grep -E "^${1:-$USER}:" /etc/passwd | awk -F: '{print $7}'; }
top_level_parent_pid() {
	# Look up the parent of the given PID.
	local pid=${1:-$$}
	local ppid="$(awk '/^PPid:/ { print $2 }' </proc/"$pid"/status)"
	# /sbin/init always has a PID of 1, so if you reach that, the current PID is
	# the top-level parent. Otherwise, keep looking.
	if [[ ${ppid} -eq 1 ]]; then
		echo "${pid}"
	else
		top_level_parent_pid "${ppid}"
	fi
}
find_shell_by_pidtree() {
	local pid=${1:-$$}
	local ppid="$(awk '/^PPid:/ { print $2 }' </proc/"$pid"/status)"
	local ppath="$(ps_get_fullprocname ${pid})"
	local pbin="${ppath%% *}" # get first part by space separated
	[[ "$pbin" =~ ^- ]] && { echo bad >>/tmp/tmp_pids && local isshell=0; } || {
		grep -qE "${pbin}" /etc/shells
		[[ $? -eq 0 ]] && local isshell=1 || local isshell=0
	}
	echo "$pid - $ppid - $ppath - $pbin - $isshell" >>/tmp/tmp_pids
	if [[ $isshell -eq 1 || ${ppid} -eq 1 ]]; then
		echo "${pbin}"
	else
		find_shell_by_pidtree "${ppid}"
	fi
}
home_dir() { grep -E "^${1:-$USER}:" /etc/passwd | awk -F: '{print $6}'; }
homedir_s() {
	local name=${1:-$USER}
	local home=/home/$name
	[ "$name" = "root" ] && home=/root
	echo $home
}
if_zero_or_empty() {
	if [ ! -z "$1" ]; then
		[[ "$1" -eq 0 ]]
	fi
}
if_non_zero_and_empty() {
	if [ ! -z "$1" ]; then
		[[ "$1" -ne 0 ]]
	else
		false
	fi
}
#
#
#
if_nix() {
	case "$OSTYPE" in
	*linux* | *hurd* | *msys* | *cygwin* | *sua* | *interix*) sys="gnu" ;;
	*bsd* | *darwin*) sys="bsd" ;;
	*sunos* | *solaris* | *indiana* | *illumos* | *smartos*) sys="sun" ;;
	esac
	[[ "${sys}" == "$1" ]]
}
if_mac() { [[ $OSTYPE == *darwin* ]]; }
if_ubuntu() {
	if [[ $OSTYPE == *linux* ]]; then
		[ -f /etc/os-release ] && grep -qi 'ubuntu' /etc/os-release
	else
		false
	fi
}
if_vagrant() {
	[ -d /vagrant ]
}
if_centos() {
	if [[ $OSTYPE == *linux* ]]; then
		if [ -f /etc/centos-release ]; then
			:
		else
			[ -f /etc/issue ] && grep -qPi '(centos|(Amazon Linux AMI))' /etc/issue
		fi
	else
		false
	fi
}
#
#
#
osid() { # fedora / ubuntu
	[[ -f /etc/os-release ]] && {
		grep -Eo '^ID="?(.+)"?' /etc/os-release | sed -r -e 's/^ID="?(.+)"?/\1/'
	}
}
osidlike() { # fedora / ubuntu
	[[ -f /etc/os-release ]] && {
		grep -Eo '^ID_LIKE="?(.+)"?' /etc/os-release | sed -r -e 's/^ID_LIKE="?(.+)"?/\1/'
	}
}
oscodename() { # fedora / ubuntu
	[[ -f /etc/os-release ]] && {
		grep -Eo '^VERSION_CODENAME="?(.+)"?' /etc/os-release | sed -r -e 's/^VERSION_CODENAME="?(.+)"?/\1/'
	}
}
versionid() { # 33 / 20.04
	[[ -f /etc/os-release ]] && {
		grep -Eo '^VERSION_ID="?(.+)"?' /etc/os-release | sed -r -e 's/^VERSION_ID="?(.+)"?/\1/' | sed -r -e 's/"$//'
	}
}
variantid() { # server, desktop
	[[ -f /etc/os-release ]] && {
		grep -Eo '^VARIANT_ID="?(.+)"?' /etc/os-release | sed -r -e 's/^VARIANT_ID="?(.+)"?/\1/' | sed -r -e 's/"$//'
	}
}
#
is_fedora() { [[ "$(osid)" == fedora ]]; }
is_centos() { [[ "$(osid)" == centos ]]; }
is_redhat() { [[ "$(osid)" == redhat ]]; }
is_debian() { [[ "$(osid)" == debian ]]; }
is_ubuntu() { [[ "$(osid)" == ubuntu ]]; }
# is_debian_series() { [[ "$(osid)" == debian || "$(osid)" == ubuntu ]]; }
# is_redhat_series() { [[ "$(osid)" == redhat || "$(osid)" == centos || "$(osid)" == fedora ]]; }
is_yum() { which yum 1>/dev/null 2>&1; }
is_dnf() { which dnf 1>/dev/null 2>&1; }
is_apt() { which apt-get 1>/dev/null 2>&1; }
# is_redhat_series() { is_yum || is_dnf; }
# is_debian_series() { is_apt; }
is_redhat_series() { [[ "$(osidlike)" == redhat ]]; }
is_debian_series() { [[ "$(osidlike)" == debian ]]; }
#
#
#
uname_kernel() { uname -s; } # Linux
uname_cpu() { uname -p; }    # processor: x86_64
uname_mach() { uname -m; }   # machine:   x86_64, ...
uname_rev() { uname -r; }    # kernel-release: 5.8.15-301.fc33.x86_64
uname_ver() { uname -v; }    # kernel-version:
lscpu_call() { lscpu $*; }
lshw_cpu() { sudo lshw -c cpu; }
i386_amd64() {
	ar=""
	case $(uname -m) in
	i386 | i686) ar="386" ;;
	x86_64) ar="amd64" ;;
	armv7*) ar="arm" ;;
	arm)
		is_debian_series && {
			dpkg --print-architecture | grep -q "arm64" && ar="arm64" || ar="arm"
		} || { ar="arm64"; }
		;;
	esac
	echo $ar
}
x86_64() { uname -m; }
if_hosttype() {
	case "$HOSTTYPE" in
	*x86_64*) sys="x64" ;;
	*) sys="x86" ;;
	esac
	[[ "${sys}" == "$1" ]]
}
#
#
#
is_git_dirty() { git diff --stat --quiet; }
#
#
#
headline() { printf "\e[0;1m$@\e[0m:\n"; }
headline_begin() { printf "\e[0;1m"; } # for more color, see: shttps://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
headline_end() { printf "\e[0m:\n"; }  # https://misc.flogisoft.com/bash/tip_colors_and_formatting
printf_black() { printf "\e[0;30m$@\e[0m:\n"; }
printf_red() { printf "\e[0;31m$@\e[0m:\n"; }
printf_green() { printf "\e[0;32m$@\e[0m:\n"; }
printf_yellow() { printf "\e[0;33m$@\e[0m:\n"; }
printf_blue() { printf "\e[0;34m$@\e[0m:\n"; }
printf_purple() { printf "\e[0;35m$@\e[0m:\n"; }
printf_cyan() { printf "\e[0;36m$@\e[0m:\n"; }
printf_white() { printf "\e[0;37m$@\e[0m:\n"; }
debug() { in_debug && printf "\e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_begin() { printf "\e[0;38;2;133;133;133m"; }
debug_end() { printf "\e[0m\n"; }
dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_info() {
	debug_begin
	cat <<-EOF
		             in_debug: $(in_debug && echo Y || echo '-')
		              is_root: $(is_root && echo Y || echo '-')
		              is_bash: $(is_bash && echo Y || echo '-')
		               is_zsh: $(is_zsh && echo Y || echo '-')
		          in_sourcing: $(in_sourcing && echo Y || echo '-')   # ZSH_EVAL_CONTEXT = $ZSH_EVAL_CONTEXT
		 is_interactive_shell: $(is_interactive_shell && echo Y || echo '-')
	EOF
	debug_end
}
commander() {
	local self=$1
	shift
	local cmd=${1:-usage}
	[ $# -eq 0 ] || shift
	#local self=${FUNCNAME[0]}
	case $cmd in
	help | usage | --help | -h | -H) "${self}_usage" "$@" ;;
	funcs | --funcs | --functions | --fn | -fn) script_functions "^$self" ;;
	*)
		if [ "$(type -t ${self}_${cmd}_entry)" == "function" ]; then
			"${self}_${cmd}_entry" "$@"
		else
			"${self}_${cmd}" "$@"
		fi
		;;
	esac
}
script_functions() {
	# shellcheck disable=SC2155
	local fncs=$(declare -F -p | cut -d " " -f 3 | grep -vP "^[_-]" | grep -vP "\\." | grep -vP "^[A-Z]") # Get function list
	if [ $# -eq 0 ]; then
		echo "$fncs" # not quoted here to create shell "argument list" of funcs.
	else
		echo "$fncs" | grep -P "$@"
	fi
	#declare MyFuncs=($(script.functions));
}
list_all_env_variables() { declare -xp; }
list_all_variables() { declare -p; }
main_do_sth() {
	set -e
	trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
	trap '[ $? -ne 0 ] && echo FAILED COMMAND: $previous_command with exit code $?' EXIT
	MAIN_DEV=${MAIN_DEV:-eth0}
	MAIN_ENTRY=${MAIN_ENTRY:-_my_main_do_sth}
	# echo $MAIN_ENTRY - "$@"
	in_debug && { debug_info && echo "$SHELL : $ZSH_NAME - $ZSH_VERSION | BASH_VERSION = $BASH_VERSION" && [ -n "$ZSH_NAME" ] && echo "x!"; }
	$MAIN_ENTRY "$@"
	trap - EXIT
	${HAS_END:-$(false)} && { debug_begin && echo -n 'Success!' && debug_end; } || :
}
DEBUG=${DEBUG:-0}
trans_readlink() { DIR="${1%/*}" && (cd $DIR && pwd -P); }
is_darwin && realpathx() { [[ $1 == /* ]] && echo "$1" || { DIR="${1%/*}" && DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $1)"; }; } || realpathx() { readlink -f $*; }
in_sourcing && { CD=${CD} && debug ">> IN SOURCING, \$0=$0, \$_=$_"; } || { SCRIPT=$(realpathx "$0") && CD=$(dirname "$SCRIPT") && debug ">> '$SCRIPT' in '$CD', \$0='$0','$1'."; }
main_do_sth "$@"
#### HZ Tail END ####
