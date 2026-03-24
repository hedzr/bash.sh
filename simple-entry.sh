#!/bin/bash

######### YOUR CODES HERE #########

set -e

# (($#)) && { cmd="$1" && shift; } || cmd="cmd"
# eval "mk-$cmd" "$@"

sleepx() { tip "sleeping..." && (($#)) && \sleep "$@"; }

#### SIMPLE BASH.SH FOOTER BEGIN #### HZ Tail BEGIN #### v20260321 ####

in_debug() { (($DEBUG)); }
is_root() { [ "$(id -u)" = "0" ]; }
is_bash() { is_bash_t1 || is_bash_t2; }
is_zsh() { [[ -n "$ZSH_NAME" || "$SHELL" = */zsh ]]; }
#
in_vscode() { [[ "$TERM_PROGRAM" == "vscode" ]]; } # or VSCODE_INJECTION=1
in_jetbrains() { [[ "$TERMINAL_EMULATOR" == *JetBrains* ]]; }
in_clion() { [[ ${__CFBundleIdentifier} == "com.jetbrains.CLion" ]]; }
#
is_win() { in_wsl; }
in_wsl() { [[ "$(uname -r)" == *windows_standard* ]]; }
osidlike() { # redhat / debian / centos / fedora / redhat / mandriva fedora / arch ...
	[[ -f /etc/os-release ]] && {
		grep -Eo '^ID_LIKE="?(.+)"?' /etc/os-release | sed -r -e 's/^ID_LIKE="?([^"]+)"?/\1/'
	} || {
		is_darwin && echo "darwin" || {
			is_win && echo "windows" || echo "unknown-os"
		}
	}
}
#
is_debian_series() { [[ "$(osidlike)" == debian ]]; }
is_mandriva_series() { [[ "$(osidlike)" == mandriva* ]]; } # mandriva, mageia, ...
is_arch_series() { [[ "$(osidlike)" == arch ]]; }
is_fedora_series() { [[ "$(osidlike)" == *fedora* ]]; }
is_suse_series() { [[ "$(osidlike)" == suse* ]]; }
is_opensuse_series() { [[ "$(osidlike)" == *opensuse* ]]; }
is_bsd_series() { [[ "$(osid)" == *bsd* ]]; }
#
headline() { printf "\e[0;1m$@\e[0m:\n"; }
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
currentShell=
fn_name_dyn() {
	if is_darwin; then
		is_zsh && local fn_="${funcstack[2]}"
		if [ "$fn_" = "" ]; then
			is_bash && echo "${FUNCNAME[1]}"
		else
			echo "$fn_"
		fi
		return
	fi
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

###
is_git_clean() { git diff-index --quiet "$@" HEAD -- 2>/dev/null; }
is_git_dirty() {
	if is_git_clean "$@"; then
		false
	else
		true
	fi
}

###
cmd_exists() { command -v $1 >/dev/null; } # it detects any builtin or external commands, aliases, and any functions
fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(shell function)|(a function)'; }
fn_builtin_exists() { LC_ALL=C type $1 2>/dev/null | grep -q 'shell builtin'; }
fn_defined() { LC_ALL=C type $1 2>/dev/null | grep -qE '( shell function)|( a function)|( shell builtin)'; }
# MODS=("a" "v" "z") && in_array 'z' MODS && echo Y || echo N
in_array() { local a=$2[@] && local b=("${!a}") && [[ " ${b[*]} " =~ " ${1} " ]]; }
array_is_empty() { local a=$1[@] && local b=("${!a}") && [ ${#b[@]} -eq 0 ]; }

###
h1() { printf "\e[30;104;1m\e[2K\n\e[A%s\e[00m\n\e[2K" "$@"; } # style first header
h2() { printf "\e[30;104m\e[1K\n\e[A%s\e[00m\n\e[2K" "$@"; }   # style second header
debug() { in_debug && printf "\e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_begin() { printf "\e[0;38;2;133;133;133m"; }
debug_end() { printf "\e[0m\n"; }
dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
wrn() { printf "\e[0;38;2;172;172;22m... [WARN] \e[0;38;2;11;11;11m$@\e[0m\n"; }
err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }

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
#
#
if_upstart() { [[ $(/sbin/init --version) =~ upstart ]]; }
if_systemd() { [[ $(systemctl) =~ -\.mount ]]; }
if_sysv() { [[ -f /etc/init.d/cron && ! -L /etc/init.d/cron ]]; }
#
#
mach_is() { # if mach_is arm64; then echo "under arm-64bit"; fi;
	local ar="$(uname -m | grep -qE 'aarch64|arm64' && ar="arm64" || cat)"
	case "$1" in
	arm64* | aarch64*)
		[[ "$ar" == "arm64" ]]
		;;
	arm32* | armv7* | armv8* | armhf* | aarch32*)
		[[ "$ar" == "$1"* ]]
		;;
	x86-64* | x86_64* | x64*)
		[[ "$ar" == "x86_64" ]]
		;;
	i386* | i686* | x86*)
		[[ "$ar" == "i386" || "$ar" == "i686" || "$ar" == "x86" ]]
		;;
	# riscv32|risc64|mips32|mips64|solaris)
	*)
		[[ "$ar"* == "$1" ]]
		;;
	esac
}
if_hosttype() { # usage:     if_hosttype x64 && echo x64 || echo x86 | BUT, it only fit for intel cpu
	case "$HOSTTYPE" in
	*x86_64*) sys="x64" ;;
	*) sys="x86" ;;
	esac
	[[ "${sys}" == "$1" ]]
}

# ### version 1
# The better consice way to get baseDir, ie. $CD, is:
#       CD=$(cd `dirname "$0"`;pwd)
# It will open a sub-shell to print the folder name of the running shell-script.

# ### version 2
# cmd="$1" && (($#)) && shift
# if fn_exists "$cmd"; then
# 	$cmd "$@"
# 	unset cmd
# else
# 	xcmd="cmake-$cmd"
# 	if fn_exists "$xcmd"; then $xcmd "$@"; else
# 		xcmd="build-$cmd"
# 		if fn_exists "$xcmd"; then $xcmd "$@"; else
# 			xcmd="build-c$cmd"
# 			if fn_exists "$xcmd"; then $xcmd "$@"; else
# 				echo "Error: No such command or function: '$cmd'" >&2
# 				exit 1
# 			fi
# 		fi
# 	fi
# 	unset cmd xcmd
# fi

sample_usages_help() {
	cat <<-EOF
		   Usage: $0 [clean|help] [[gcc|llvm] [debug|release] [shared|static|interface]]
	EOF
}
sample_first_entry() {
	local BUILDDIR=builddir/$DIR
	local INSTALLDIR=install/$DIR

	local BUILD_TYPE=Release
	local BUILD_SHARED_LIBS=OFF
	local BUILD_STATIC_LIBS=OFF
	local INSTALLDIR=install/$DIR/interface

	local GCC=1

	if ! (($#)); then
		tip "Using BUILDDIR=${BUILDDIR}, INSTALLDIR=${INSTALLDIR} ..."
		sleeping "$@"
		return
	fi

	local _RM_CNT=0
	select_switches() {
		_RM_CNT=0
		case $1 in
		m | module) if ! in_array "$2" MODS; then MODS=(${MODS[@]} $2) && _RM_CNT=1; fi ;;
		esac
	}

	local unk_args=()
	while (($#)); do
		case $1 in
		--*) local sw="${1#--}" && shift && select_switches "$sw" "$@" && for ((i = 0; i < $_RM_CNT; i++)); do shift; done ;;
		-*) local sw="${1#-}" && shift && select_switches "$sw" "$@" && for ((i = 0; i < $_RM_CNT; i++)); do shift; done ;;

		clean | cleanup | reset)
			[ -d ${BUILDDIR} ] && rm -rf ${BUILDDIR}
			;;

		"gcc") GCC=1 ;;
		"llvm") GCC=0 ;;

		"debug" | "dbg")
			BUILD_TYPE=Debug
			BUILD_SHARED_LIBS=OFF
			BUILD_STATIC_LIBS=OFF
			INSTALLDIR=install/$DIR/interface
			;;
		"release" | "rel")
			BUILD_TYPE=Release
			;;

		"shared")
			BUILD_TYPE=Release
			BUILD_SHARED_LIBS=ON
			BUILD_STATIC_LIBS=OFF
			INSTALLDIR=install/$DIR/shared
			;;
		"static")
			BUILD_TYPE=Release
			BUILD_SHARED_LIBS=OFF
			BUILD_STATIC_LIBS=ON
			INSTALLDIR=install/$DIR/static
			;;
		"interface")
			BUILD_TYPE=Release
			BUILD_SHARED_LIBS=OFF
			BUILD_STATIC_LIBS=OFF
			INSTALLDIR=install/$DIR/interface
			;;

		usage | info | help | h)
			sample_usages_help
			exit 0
			;;
		*)
			unk_args=("${unk_args[@]}" "$1")
			;;
		esac
		shift
	done

	if ((${#unk_args[@]} == 0)); then
		echo "$@"
	else
		wrn "UNKNOWN ARGS FOUND: ${unk_args[@]}"
		sample_usages_help
		false
	fi
}

### final version
CD="$(cd $(dirname "$0") && pwd)" && BASH_SH_VERSION=v20260321 && DEBUG=${DEBUG:-0} && PROVISIONING=${PROVISIONING:-0}
SUDO=sudo && { [ "$(id -u)" = "0" ] && SUDO= || :; }
LS_OPT="--color" && { is_darwin && LS_OPT="-G" || :; }
check_entry() {
	install_cmd_not_found_handler
	local prefix="${1:-boot}" cmd="${2:-first}" && shift && shift
	local cx cc="${prefix}_${cmd}_entry" cp="${prefix}_${cmd}" processed=0
	# checking /(<prefix>[_-])?<cmd>([_-]entry)?/ ...
	# so, for prefix='boot' and cmd='usages', both these function names are ok:
	#   boot[_-]usages[_-]entry, boot[_-]usages, usages, ...
	# and '-' and '_' also be alternatived, for a cmd='some-ok', these works:
	#   boot-some-ok, boot_some_ok, some-ok, some_ok, ...
	for cx in "$cc" "${cc//-/_}" "${cc//_/-}" "$cp" "${cp//_/-}" "${cp//-/_}" "$cmd" "${cmd//_/-}" "${cmd//-/_}" "first_entry"; do
		if ! (($processed)); then
			# dbg "  . checking '$cx' ..."
			if fn_exists "$cx"; then
				unset prefix cmd cc cp f && processed=1 && "$cx" "$@"
			fi
		fi
	done
}
install_cmd_not_found_handler() {
	# install command-not-found handler for lazy-loading commands (such as `include`)
	if [[ "$BASH_SH" != "" ]]; then
		local f="$(dirname $BASH_SH)/ops.d/lazy-loader.sh"
		if [ -f "$f" ]; then
			source "$f"
		fi
	fi
}
# if you wanna send all args into boot_first_entry(), uncomment
# the following line and remove the rest.
# check_entry "${FN_PREFIX:-boot}" "${FN_NAME:-first}" "$@"
if (($#)); then
	dbg "$# arg(s) | CD = $CD"
	check_entry "${FN_PREFIX:-boot}" "$@"
else
	dbg "args empty | CD = $CD | DEBUG = $DEBUG"
	# set -x
	if fn_exists boot_usages; then
		# boot_usages "$@"
		check_entry "${FN_PREFIX:-boot}" "${FN_NAME:-usages}" "$@"
	else
		err "no default entry function 'boot_usages' found."
		exit 1
	fi
fi
#### SIMPLE BASH.SH FOOTER END #### HZ Tail END #### v20260321 ####
