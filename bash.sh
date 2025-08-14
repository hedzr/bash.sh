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
#   Version: v20250815
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

# It's safe to delete 'bump'. By default it will be invoked under /bin/sh mode.
bump() {
	local VERSION="v$(date +%Y%m%d)"
	local YEAR="$(date +%Y)" f
	headline "bump version to: $VERSION ..."
	tip "  looking up at directory '$(safety $CD)'..."
	for f in $CD/bash* $CD/simple*; do
		echo "bumping for $(safety $f), YEAR = $YEAR ..."
		if [ -L "$f" ]; then
			:
		else
			sed -i '' -E -e "s/v$YEAR[0-9]+/$VERSION/g" $f
			sed -i '' -E "s/v$((YEAR - 1))[0-9]+/$VERSION/g" $f
		fi
	done
	# local src=bash.sh
	# for f in $CD/bash*; do
	# 	if [[ "$(basename $f)" != "$src" ]]; then
	# 	fi
	# done
}

bumpold() {
	local VERSION="v$(date +%Y%m%d)"
	local YEAR="$(date +%Y)" f
	echo bump version to: $VERSION
	for f in bash*; do
		echo bumping for $f ...
		sed -i '' -E -e "s/v$YEAR[0-9]+/$VERSION/g" $f
	done
}

bump1() {
	tip "  looking up at directory '$(safety $CD)'..."
	tip "  looking up at directory '$(echo "$CD" | safetypipe)'..."
}

help() {
	cat <<-EOF
		Who am I?

		I'm magicalembracer.

		D:
	EOF
	err "Here Am I."
	echo OK
	eval in-vscode && echo "in-VSCODE" || echo "_ $?"
	eval fn-exists in-vscode && echo "Y" || echo "N"
}

cool() { echo cool && ls -la | pad3 4 '-72' '' ' | desc here'; }
sleeping() { echo sleeping; }
sleepx() { tip "sleeping..." && (($#)) && \sleep "$@"; }

#### write your functions here, and invoke them by: `./bash.sh <your-func-name>`

# FN_PREFIX=boot_
_my_main_do_sth() {
	local cmd=${1:-help} && { [ $# -ge 1 ] && shift; } || :
	# local FN_PREFIX=boot_
	# for linux only:
	# local cmd=${1:-sleeping} && && shift || :

	local DBG_SAVE="$DEBUG"

	dbg "[importing files]: loading ..."
	_bash_sh_load_import_files
	dbg "[importing files]: shell.d/ops.d files"
	# _bash_sh_load_files '*'
	_bash_sh_load_env_files
	dbg "[importing files]: .env done"

	# in_provisioning ||
	[ "$cmd" = "first-install" ] || DEBUG="$DBG_SAVE" # && echo "DEBUG: $DEBUG"
	# echo "4. DEBUG: $DEBUG, cmd: $cmd"

	# in_debug && LC_ALL=C type $cmd || echo "$cmd not exists"
	dbg ": invoking cmd: $cmd"
	local xcmd="${cmd//-/_}"
	dbg ": trying cmd: $xcmd ..."
	if fn_exists "$xcmd"; then
		eval $xcmd "$@" #&& dbg ":DONE:$cmd"
	elif fn_exists "boot_$xcmd"; then
		eval boot_$xcmd "$@" #&& dbg ":DONE:$cmd"
	elif fn_aliased_exists "$xcmd"; then
		eval $xcmd "$@" #&& dbg ":DONE:$cmd"
	else
		xcmd="${cmd//_/-}"
		dbg ": trying cmd: $xcmd ..."
		if fn_exists "$xcmd"; then
			eval $xcmd "$@" #&& dbg ":DONE:$cmd"
		elif fn_exists "boot-$xcmd"; then
			eval boot-$xcmd "$@" #&& dbg ":DONE:$cmd"
		elif fn_aliased_exists "$xcmd"; then
			eval $xcmd "$@" #&& dbg ":DONE:$cmd"
		else
			local f="$CD/ops.d/run/$cmd.sh"
			# dbg "  ..finding $f"
			if [ -f "$f" ]; then
				dbg "  ..sourcing $(safety $f).." && source "$f" && dbg "  ..OK"
				if fn_exists "${cmd}_entry"; then
					# dbg "  ..eval '${cmd}_entry' $@"
					${cmd}_entry "$@"
				else
					eval $cmd "$@"
				fi
			else
				err "command '$cmd' has not been defined. (CD=$(safety $CD))"
				return
			fi
		fi
	fi
	# unset xcmd

	if in_provisioning; then
		if [ -f "$CD/after.sh" ]; then
			headline "Sourcing and Running after.sh ..."
			source "$CD/after.sh"
			if fn_exists "after_provision"; then
				eval "after_provision" "$@"
			else
				:
			fi
		fi
		if [ -f "$CD/user-customizations.sh" ]; then
			headline "Sourcing and Running user-customizations.sh ..."
			source "$CD/user-customizations.sh"
			if fn_exists "user_custom"; then
				eval "user_custom" "$@"
			else
				:
			fi
		fi
		dbg ":DONE:END:$(fn_name_dyn):$?"
	else
		HAS_END=0
	fi
}

_bash_sh_try_source_in() {
	local f
	for f in "$@"; do
		[ -f "$f" ] && shift && dbg "  ..sourcing $(safety $f)" && DEBUG=0 VERBOSE=0 source "$f"
	done
}

_bash_sh_try_source_child_files() {
	local dir="$1"
	# processed=0
	if [ -d $dir ]; then
		if test -n "$(find $dir -maxdepth 1 -name '*.sh' -print -quit)"; then
			for f in $dir/*.sh; do dbg "  ..sourcing $(safety $f)" && source $f && processed=1; done
		else
			tip "    nothing for testing $(safety $dir)/*.sh, PWD: $(pwd)"
		fi
	else
		:
	fi
}

_bash_sh_load_import_files() {
	local dir processed=0
	local osid="$(osid)" pmid="$(pmid)"
	for dir in $CD; do
		if [ -d $dir/ops.d ]; then
			_bash_sh_try_source_child_files "$dir/ops.d" # && tip "processed = $processed"
			_bash_sh_try_source_child_files "$dir/ops.d/$osid"
			_bash_sh_try_source_child_files "$dir/ops.d/$pmid"
		else
			dbg "[DBUG] $(safety $dir)/ops.d/ folder NOT FOUND, no more script files loaded."
		fi
	done
	if [[ $processed -eq 0 ]]; then
		# in_debug && is_darwin && ps -a || ps -auxf
		dbg
		dbg "CD=$(safety $CD), SCRIPT=$(safety $SCRIPT)"
		dbg "[NOTE] ops.d/ folder NOT FOUND, no more script files loaded."
	else
		:
	fi
}

_bash_sh_load_files() {
	local f ff dir processed=0
	dbg "  > load_files $(safety $@) <"
	for dir in "$CD"; do
		if [ -d "$dir/ops.d" ]; then
			for f in "$@"; do
				local s="$dir/ops.d/$f.sh"
				dbg "  ..testing for $(safety $s) ..."
				if test -n "$(find $dir/ops.d -maxdepth 1 -name $f'.sh' -print -quit)"; then
					for ff in $dir/ops.d/$f.sh; do dbg "  ..sourcing $(safety $ff)" && source $ff && processed=1; done
				else
					:
				fi
				# if [ -f $s ]; then
				# 	dbg "  ..sourcing $(safety $s)" && source $s && processed=1
				# fi
			done
		else
			:
		fi
	done
	if [[ $processed -eq 0 ]]; then
		# in_debug && is_darwin && ps -a || ps -auxf
		dbg
		dbg "CD=$(safety $CD), SCRIPT=$(safety $SCRIPT)"
		dbg "[NOTE] ops.d/ folder NOT FOUND, no more script files loaded."
	else
		:
	fi
}

_bash_sh_load_env_files() {
	local rel env=
	for rel in '.' '..'; do
		env="$CD/$rel/.env"
		[ -f $env ] && { dbg "  ..sourcing $(safety $env)" && source $env; } || :
	done
	for env in "$CD/ops.d/.env" "$CD/.env.local" "$CD/ops.d/.env.local" "$HOME/.config/ops.sh/env"; do
		[ -f $env ] && { dbg "  ..sourcing $(safety $env)" && source $env; } || :
	done
	:
}

########################################################

#### HZ Tail BEGIN #### v20250815 ####
in_debug() { (($DEBUG)); }
in_provisioning() { (($PROVISIONING)); } ## return exit status as true if $PROVISIONING is not equal to 0
is_root() { [ "$(id -u)" = "0" ]; }
is_bash() { is_bash_t1 || is_bash_t2; }
is_bash_t1() { [ -n "$BASH_VERSION" ]; }
is_bash_t2() { [ ! -n "$BASH" ]; }
is_bash_strict() { if is_bash; then if is_zsh_strict; then false; else true; fi; else false; fi; }
is_zsh() { [[ -n "$ZSH_NAME" || "$SHELL" = */zsh ]]; }
is_zsh_strict() { [[ -n "$ZSH_NAME" && "$SHELL" = */zsh ]]; }
is_zsh_t1() { [[ "$SHELL" = */zsh ]]; }
is_zsh_t2() { [ -n "$ZSH_NAME" ]; }
is_fish() { [ -n "$FISH_VERSION" ]; }
is_darwin() { [[ $OSTYPE == darwin* ]]; }
is_darwin_sillicon() { is_darwin && [[ $(uname_mach) == arm64 ]]; }
is_linux() { [[ $OSTYPE == linux* ]]; }
is_freebsd() { [[ $OSTYPE == freebsd* ]]; }
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
in_vscode() { [[ "$TERM_PROGRAM" == "vscode" ]]; } # or VSCODE_INJECTION=1
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
	alias is_stdin=true
	alias is_not_stdin=false
	alias is_ttya=true
else
	alias is_stdin=false
	alias is_not_stdin=true
	alias is_ttya=false
fi
cmd_exists() { command -v $1 >/dev/null; } # it detects any builtin or external commands, aliases, and any functions
fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '( shell function)|( a function)'; }
fn_builtin_exists() { LC_ALL=C type $1 2>/dev/null | grep -q ' shell builtin'; }
if is_zsh_strict; then
	fn_aliased_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(alias for )|(aliased to )'; }
else
	fn_aliased_exists() { LC_ALL=C alias $1 1>/dev/null 2>&1; }
fi
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
ps_get_procname() { ps -hp ${1:-$$} | awk '{print $4}'; }
ps_get_fullprocname() { ps -fhp ${1:-$$} | awk '{ for (i=5;i<=NF-1;i++) { printf "%s ", $i }; printf "\n" }'; }
ps_get_procpath() { ps -hp ${1:-$$} | awk '{ if(NF>6) print $6; else print $5 }'; }
user_shell() { grep -E "^${1:-$USER}:" /etc/passwd | awk -F: '{print $7}'; }
top_level_parent_pid() { # cannot work under darwin
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
find_shell_by_pidtree() { # cannot work under darwin
	local pid=${1:-$$}
	local ppid="$(awk '/^PPid:/ { print $2 }' </proc/"$pid"/status)"
	local ppath="$(ps_get_fullprocname ${pid})"
	local pbin="${ppath%% *}" # get first part by space separated
	[ -f /tmp/tmp_pids ] && $SUDO chown $USER: /tmp/tmp_pids
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
	else
		false
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
in_vmware() { $SUDO hostnamectl | grep -E 'Virtualization: ' | grep -qEi 'vmware'; }
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
#
#
#
pmid() { # apt, yum, dnf, brew, ...
	is_apt && echo "apt" && return
	is_dnf && echo "dnf" && return
	is_yum && echo "yum" && return
	is_pacman && echo "pacman" && return
	is_zypp && echo "zypp" && return
	is_homebrew && echo "brew" && return
	# is_snap && echo "snap" && return
	# is_chocolatey && echo "choco" && return
	# is_scoop && echo "scoop" && return
	# is_cargo && echo "cargo" && return
	echo "???"
}
osid() { # fedora / ubuntu / debian / mageia / manjaro / arch ...
	[[ -f /etc/os-release ]] && {
		grep -Eo '^ID="?(.+)"?' /etc/os-release | sed -r -e 's/^ID="?([^"]+)"?/\1/'
	} || {
		is_darwin && echo "darwin" || {
			is_win && echo "windows" || echo "unknown-os"
		}
	}
}
osidlike() { # redhat / debian / centos / fedora / redhat / mandriva fedora / arch ...
	[[ -f /etc/os-release ]] && {
		grep -Eo '^ID_LIKE="?(.+)"?' /etc/os-release | sed -r -e 's/^ID_LIKE="?([^"]+)"?/\1/'
	} || {
		is_darwin && echo "darwin" || {
			is_win && echo "windows" || echo "unknown-os"
		}
	}
}
oscodename() { # focal / xenial / ...   # = `lsb_release -cs`
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
is_alpine() { [[ "$(osid)" == alpine ]]; }
is_fedora() { [[ "$(osid)" == fedora ]]; }
is_centos() { [[ "$(osid)" == centos ]]; }
is_rocky() { [[ "$(osid)" == rocky* ]]; }    # yet another centos
is_alma() { [[ "$(osid)" == almalinux* ]]; } # yet another centos
is_gento() { [[ "$(osid)" == gento ]]; }
is_void() { [[ "$(osid)" == void ]]; } # a special linux distro
is_redhat() { [[ "$(osid)" == redhat ]]; }
is_debian() { [[ "$(osid)" == debian ]]; }
is_ubuntu() { [[ "$(osid)" == ubuntu ]]; }
is_devuan() { [[ "$(osid)" == devuan* ]]; } # yet another debian
is_mageia() { [[ "$(osid)" == mageia ]]; }
is_manjaro() { [[ "$(osid)" == manjaro ]]; }
is_opensuse() { [[ "$(osid)" == opensuse* ]]; }
is_arch() { [[ "$(osid)" == arch* ]]; }
is_archlinux() { [[ "$(osid)" == arch* ]]; }
is_archlinux_arm() { [[ "$(osid)" == archarm* ]]; }
is_kalilinux() { [[ "$(osid)" == kali* ]]; }
is_kali() { [[ "$(osid)" == kali ]]; }
# is_debian_series() { [[ "$(osid)" == debian || "$(osid)" == ubuntu ]]; }
# is_redhat_series() { [[ "$(osid)" == redhat || "$(osid)" == centos || "$(osid)" == fedora ]]; }
is_yum() { which yum 1>/dev/null 2>&1; }
is_dnf() { which dnf 1>/dev/null 2>&1; }
is_apt() { which apt-get 1>/dev/null 2>&1; }
is_pacman() { which pacman 1>/dev/null 2>&1; }
is_zypp() { which zypper 1>/dev/null 2>&1; }
is_zypper() { which zypper 1>/dev/null 2>&1; }
is_homebrew() { which brew 1>/dev/null 2>&1; }
is_pkg() { which pkg 1>/dev/null 2>&1; }
# is_redhat_series() { is_yum || is_dnf; }
# is_debian_series() { is_apt; }
is_redhat_series() {
	local t="$(osidlike)"
	[[ $t == redhat ]] || [[ $t == 'rhel '* ]]
}
is_debian_series() { [[ "$(osidlike)" == debian ]]; }
is_mandriva_series() { [[ "$(osidlike)" == mandriva* ]]; } # mandriva, mageia, ...
is_arch_series() { [[ "$(osidlike)" == arch ]]; }
is_fedora_series() { [[ "$(osidlike)" == *fedora* ]]; }
is_suse_series() { [[ "$(osidlike)" == suse* ]]; }
is_opensuse_series() { [[ "$(osidlike)" == *opensuse* ]]; }
is_bsd_series() { [[ "$(osid)" == *bsd* ]]; }
#
#
#
lsb_release_cs() { which lsb_release 1>/dev/null 2>&1 && lsb_release -cs; } # focal, ... # = oscodename
uname_kernel() { uname -s; }                                                # Linux
uname_cpu() { uname -p; }                                                   # processor: x86_64
uname_mach() { uname -m; }                                                  # machine:   x86_64, ...
uname_rev() { uname -r; }                                                   # kernel-release: 5.8.15-301.fc33.x86_64
uname_ver() { uname -v; }                                                   # kernel-version:
lscpu_call() { lscpu $*; }
lshw_cpu() { $SUDO lshw -c cpu; }
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
if_hosttype() { # usage: if_hosttype x64 && echo x64 || echo x86 | BUT, it only fit for intel cpu
	case "$HOSTTYPE" in
	*x86_64*) sys="x64" ;;
	*) sys="x86" ;;
	esac
	[[ "${sys}" == "$1" ]]
}
#
#
#
# is_git_clean() { git diff-index --quiet --cached HEAD -- 2>/dev/null; }
is_git_clean() { git diff-index --quiet "$@" HEAD -- 2>/dev/null; }
is_git_dirty() {
	if is_git_clean "$@"; then
		false
	else
		true
	fi
}
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
alias git-clone-v='git_clone -v'
alias git-clone-deep='git_clone -d'
alias git-clone-deep-v='git_clone -d -v'
#
#
url_exists() { curl --head --silent -S --fail --output /dev/null "$@" 1>/dev/null 2>&1; }
#
#
#
# effects
clr_reset_all="\e[0m"
clr_bold="\e[1m"
clr_dim="\e[2m"
clr_italic="\e[3m"
clr_underline="\e[4m"
clr_blink="\e[5m"
clr_rapic_blink="\e[6m"
clr_invert="\e[7m"
clr_hide="\e[8m"
clr_strike="\e[9m"
# reset effects
clr_reset_bold="\e[21m"
clr_reset_dim="\e[22m"
clr_reset_italic="\e[23m"
clr_reset_underline="\e[24m"
clr_reset_blink="\e[25m"
clr_reset_spacing="\e[26m"
clr_reset_invert="\e[27m"
clr_reset_hide="\e[28m"
clr_reset_crossout="\e[29m"
# 16-color fg
black="\e[30m"
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
blue="\e[34m"
megenta="\e[35m"
cyan="\e[36m"
white="\e[37m"
# 16-color bright fg
bright_black="\e[90m"
bright_red="\e[91m"
bright_green="\e[92m"
bright_yellow="\e[93m"
bright_blue="\e[94m"
bright_megenta="\e[95m"
bright_cyan="\e[96m"
bright_white="\e[97m"
# 16-color bg
bg_black="\e[40m"
bg_red="\e[41m"
bg_green="\e[42m"
bg_yellow="\e[43m"
bg_blue="\e[44m"
bg_megenta="\e[45m"
bg_cyan="\e[46m"
bg_white="\e[47m"
# 16-color bright bg
bg_bright_black="\e[100m"
bg_bright_red="\e[101m"
bg_bright_green="\e[102m"
bg_bright_yellow="\e[103m"
bg_bright_blue="\e[104m"
bg_bright_megenta="\e[105m"
bg_bright_cyan="\e[106m"
bg_bright_white="\e[107m"
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
println16() { # eg: println16 31 "hello"
	local clr="${1:-31}" && (($#)) && shift
	printf "\e[${clr}m$@\e[0m\n"
}
println256() { # eg: println256 255 "hello"
	local byte="${1:-128}" && (($#)) && shift
	printf "\e[38;5;${byte}m$@\e[0m\n"
}
printlnrgb() { # eg: printlnrgb 133 133 133 "hello"
	local r="${1:-128}" && (($#)) && shift
	local g="${1:-128}" && (($#)) && shift
	local b="${1:-128}" && (($#)) && shift
	printf "\e[38;2;${r};${g};${b}m$@\e[0m\n"
}
printlnrgb_special() {
	local r="${1:-128}" && (($#)) && shift
	local g="${1:-128}" && (($#)) && shift
	local b="${1:-128}" && (($#)) && shift
	printf "\e[38;0;${r};${g};${b}m$@\e[0m\n"
}
printlnrgb_transparent() {
	local r="${1:-128}" && (($#)) && shift
	local g="${1:-128}" && (($#)) && shift
	local b="${1:-128}" && (($#)) && shift
	printf "\e[38;1;${r};${g};${b}m$@\e[0m\n"
}
printlnrgb_cmy() {
	local cs="${1:-128}" && (($#)) && shift
	local r="${1:-128}" && (($#)) && shift
	local g="${1:-128}" && (($#)) && shift
	local b="${1:-128}" && (($#)) && shift
	printf "\e[38;3;${r};${g};${b};${cs}m$@\e[0m\n"
}
printlnrgb_cmyb() {
	local cs="${1:-128}" && (($#)) && shift
	local r="${1:-128}" && (($#)) && shift
	local g="${1:-128}" && (($#)) && shift
	local b="${1:-128}" && (($#)) && shift
	printf "\e[38;4;${r};${g};${b};${cs}m$@\e[0m\n"
}
h1() { printf "\e[30;104;1m\e[2K\n\e[A%s\e[00m\n\e[2K" "$@"; } # style first header
h2() { printf "\e[30;104m\e[1K\n\e[A%s\e[00m\n\e[2K" "$@"; }   # style second header
debug() { in_debug && printf "\e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_begin() { printf "\e[0;38;2;133;133;133m"; }
debug_end() { printf "\e[0m\n"; }
dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
wrn() { printf "\e[0;38;2;172;172;22m... [WARN] \e[0;38;2;11;11;11m$@\e[0m\n"; }
err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }
mvif() {
	local src="$1" dstdir="$2"
	if [ -d "$dstdir" ]; then
		mv "$src" "$dstdir"
	fi
}
debug_info() {
	debug_begin
	cat <<-EOF
		               in_debug: $(in_debug && echo Y || echo '.')
		                is_root: $(is_root && echo Y || echo '.')
		                is_bash: $(is_bash && echo Y || echo '.')       # STRICTED = $(is_bash_strict && echo Y || echo N), SHELL = $SHELL, BASH_VERSION = $BASH_VERSION
		       is_zsh/is_zsh_t1: $(is_zsh && echo Y || echo '.') / $(is_zsh_t1 && echo Y || echo '.')   # $(is_zsh && echo "ZSH_EVAL_CONTEXT = $ZSH_EVAL_CONTEXT, ZSH_NAME/VERSION = $ZSH_NAME v$ZSH_VERSION" || :)
		                is_fish: $(is_fish && echo Y || echo '.')       # FISH_VERSION = $FISH_VERSION
		            in_sourcing: $(in_sourcing && echo Y || echo '.')
		              in_vscode: $(in_vscode && echo Y || echo '.')
		           in_jetbrains: $(in_jetbrains && echo Y || echo '.')
		          in_vim/neovim: $(in_vim && echo Y || echo '.') / $(in_neovim && echo Y || echo '.')
		  darwin/linux/win(wsl): $(is_darwin && echo Y || echo '.')$(is_darwin_sillicon && echo ' [Sillicon] ' || echo ' ')/ $(is_linux && echo Y || echo '.') / $(is_win && echo Y || echo '.')
		   is_interactive_shell: $(is_interactive_shell && echo Y || echo '.')
		  
		NOTE: bash.sh can only work in bash/zsh mode, even if running it in fish shell.

		  IP(s): 4 -> $(lanip | join_lines), 6 -> $(lanip6 | join_lines)
		$(lanipall | pad 9)
		  Gateway / Mask: $(gw) / $(netmask)
		   Subnet Prefix: $(subnet4)
	EOF
	fn_exists pmid || : && cat <<-EOF

		  VM tests: in_vm='$(in_vm && echo Y || echo .)' in_orb='$(in_orb && echo Y || echo .)' in_vagrant='$(in_vagrant && echo Y || echo .)' in_vmware='$(in_vmware && echo Y || echo .)'
		  OS tests: pmid='$(pmid)' osid='$(osid)' osidlike='$(osidlike)'
		            oscodename='$(oscodename)' versionid='$(versionid)' variantid='$(variantid)'
		            if_nix_typ='$(if_nix_typ)' (\$OSTYPE='$OSTYPE')
		            is_suse_series='$(is_suse_series && echo Y || echo .)'
	EOF
	is_linux || : && cat <<-EOF

		              lsb_release_cs = '$(lsb_release_cs)'
		            uname_kernel(-s) = '$(uname_kernel)'
		               uname_cpu(-p) = '$(uname_cpu)'
		              uname_mach(-m) = '$(uname_mach)'
		               uname_rev(-r) = '$(uname_rev)'
		               uname_ver(-v) = '$(uname_ver)'
		                  i386_amd64 = '$(i386_amd64)'
		                      x86_64 = '$(x86_64)'
		                 if_hosttype = '$(if_hosttype)'
	EOF
	debug_end
	# colortable256
	colortabletruecolor
	printf "## Welcome to bash.sh %s ##\n" "$BASH_SH_VERSION"
}
ii() {
	local c_green="\e[0;32m"
	local c_red="\e[0;31m"
	local c_lblue="\e[1;34m"
	local c_clear="\e[0m"
	printf_red "       You are logged on : ${c_green}$(hostname)"
	printf_red " Additionnal information : ${c_green}$NC"
	uname -a
	# printf    "${c_red}         Users logged on : ${c_clear}$NC " ; w -h | head -1
	printf_red "            Current date : ${c_green}$NC "
	date
	printf_red "           Machine stats : ${c_green}$NC"
	uptime
	# printf "\n${c_red}Current network location : ${c_clear}$NC " ; scselect
	# printf    "${c_red}Public facing IP Address : ${c_clear}$c_green$(ip-wan)$c_clear / $c_green$(find_gw $(ip-wan))$c_clear"
	printf_ref "        Local IP Address : ${c_clear}$c_green$(ip-local)$c_clear / $c_green$(find_gw $(ip-local))$c_clear"
	# printf "\nLocal IP Address  : ${c_red}$(mylocalip)$c_clear / $c_red$(mylocalgw)$c_clear / $c_red$(mylocalni)$c_clear"
	# printf "\nDNS Configurations:$NC " ; mylocaldns
	echo ""
	echo "[dot] use: 'ip-wan' to query the public ip address of mine."
	echo "[dot] use: 'curl -sSL https://hedzr.com/bash/dot/installer | sudo bash -s' to upgrade \`ops\` commands."
	echo "      avaliable commands: disc-info, ports, env_check, hostnames, ii, ip-wan, ip-lan, ip-gw, ip-mask, ip-subnet, ...."
	echo ""
}
colortable256() {
	local i o x=$(tput op) y=$(printf %76s)
	for i in {0..256}; do
		o=00$i
		echo -e ${o:${#o}-3:3} $(
			tput setaf $i
			tput setab $i
		)${y// /=}$x
	done
}
colortable256colors() {
	local i
	for ((i = 16; i < 256; i++)); do
		printf "\e[48;5;${i}m%03d" $i
		printf '\e[0m'
		[ ! $(((i - 15) % 6)) -eq 0 ] && printf ' ' || printf '\n'
	done
}
colortabletruecolor() {
	awk 'BEGIN{
    s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
        r = 255-(colnum*255/76);
        g = (colnum*510/76);
        b = (colnum*255/76);
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm", r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\033[0m", substr(s,colnum+1,1);
    }
    printf "\n";
}'
}
# colored_eval() {
#   local none="\[\033[0m\]"
#
#   local black="\[\033[0;30m\]"
#   local dark_gray="\[\033[1;30m\]"
#   local blue="\[\033[0;34m\]"
#   local light_blue="\[\033[1;34m\]"
#   local green="\[\033[0;32m\]"
#   local light_green="\[\033[1;32m\]"
#   local cyan="\[\033[0;36m\]"
#   local light_cyan="\[\033[1;36m\]"
#   local red="\[\033[0;31m\]"
#   local light_red="\[\033[1;31m\]"
#   local purple="\[\033[0;35m\]"
#   local light_purple="\[\033[1;35m\]"
#   local brown="\[\033[0;33m\]"
#   local yellow="\[\033[1;33m\]"
#   local light_gray="\[\033[0;37m\]"
#   local white="\[\033[1;37m\]"
#
#   local current_tty=`tty | sed -e "s/\/dev\/\(.*\)/\1/"`
#
#   eval "$@"
# }
join_lines() {
	local delim="${1:-,}" ix=0
	while read line; do
		(($ix)) && printf '%s' "$delim"
		let ix++
		printf '%s' "$line"
	done
}
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
rpad() {
	# sample: rpad 32 - 'Some file' && echo '723 bytes'
	# will got:
	#   Some file-----------------------723 bytes
	local cnt=$1
	local pad="$(char_repeat $2 $1)"
	(($#)) && shift && (($#)) && shift && local y="$@"
	# dbg "cnt: $cnt, pad: $pad, y: $y" 1>&2
	y="${y:0:$cnt}${pad:0:$((cnt - ${#y}))}"
	echo -n "$y"
}
char_repeat() {
	# repeat char n times: `char_repeat '-' 32`
	local pad=$1 && (($#)) && shift
	local n="$1" && (($#)) && shift
	printf '%*s' $n "" | tr ' ' "$pad"
}
safety() {
	# safety make the folder name more safety when output. It
	# replaces $HOME to '~' to prevent home user name leaked.
	# In additions, it refers zsh tlide folder name list and
	# do the replacements rely on it. That means, if you have
	# a zsh hashed folder definition /usr/local/bin -> ~ulbin,
	# then it can also be applied to the result of
	# $(safety $string).
	#
	# For example,
	#
	#    $ echo $(./bash.sh safety /home/$USER/Downloads)
	#    ~/Downloads
	#    $ echo $(./bash.sh safety $HOME/Downloads)
	#    ~/Downloads
	local input="${@//$HOME/~}" from to list
	# dbg "Got input: $input" 1>&2
	for list in $HOME/.safety.list; do
		if [ -f $list ]; then
			while read from to; do
				input="$(printf "$input" | sed -E "s,$from,$to,g")"
			done <$list
		fi
	done
	if is_zsh_strict; then
		# if running under zsh mode
		if command -v hash >/dev/null; then
			hash -d | while IFS=$'=' read to from; do
				from="$(echo $from | tr -d "\042")"
				input="$(printf "$input" | sed -E "s,$from,~$to,g")"
			done
		fi
	elif command -v zsh >/dev/null; then
		# in bash/sh mode
		[ -f /tmp/hash.list ] || zsh -c "hash -d|sed 's/=/:/'|tr -d \"'\"|IFS=\$':' sort -k2 -r" >/tmp/hash.list
		while IFS=$':' read to from; do
			from="$(eval printf '%s' $from)"
			to="$(eval printf '%s' $to)"
			# echo "  $from -> $to" 1>&2
			# echo "$input" | sed -E 's,'"$from"',~'"$to"',g' 1>&2
			input="$(printf "$input" | sed -E 's,'"$from"',~'"$to"',g')"
		done </tmp/hash.list
	fi
	# in="$(echo $in | sed -E -e "s,/Volumes/Vol,~vol,g")"
	printf "$input"
}
safetypipe() { while read line; do printf "$(safety $line)"; done; }
datename() {
	local i=${1:-7}
	if [[ $OSTYPE == darwin* ]]; then
		date -v-${i}d +%Y-%m-%d
	else
		date -d -${i}day +%Y-%m-%d
	fi
}
if is_freebsd; then
	:
else
	for_each_days() {
		# Sample:
		#
		# delete_log_file() {
		# 	local dtname="$1"
		# 	for PRE in .sizes db-bacup tool-updates; do
		# 		$SUDO find . -type f -iname "${PRE}.$dtname"'*'".log" -print -delete | pad 3 "" " deleted."
		# 	done
		# }
		#
		# delete_elder_logs() {
		# 	for_each_days delete_log_file 7   # delete the older logfiles more than 7 days
		# }
		local func="$1" && (($#)) && shift
		local DAYS1="${1:-30}" && (($#)) && shift
		local TILLDAYS=365
		dbg "func: $func, days: $DAYS1"
		# # local TILLDAYS=$((DAYS1 + 365))
		# for ((i = $DAYS1; i < $TILLDAYS; i++)); do
		# 	eval $func "$(datename $i)" "$@"
		# done
	}
fi
commander() {
	local commander_self="$1" && (($#)) && shift
	local commander_cmd="${1:-usage}" && (($#)) && shift
	case $commander_cmd in
	help | usage | --help | -h | -H) "${commander_self}_usage" "$@" ;;
	funcs | --funcs | --functions | --fn | -fn) script_functions "^$commander_self" ;;
	*)
		# if [ "$(type -t ${commander_self}_${commander_cmd}_entry)" == "function" ]; then
		if fn_exists ${commander_self}_${commander_cmd}_entry; then
			dbg "try invoking: ${commander_self}_${commander_cmd}_entry | $@"
			eval ${commander_self}_${commander_cmd}_entry "$@"
		elif fn_exists ${commander_self}-${commander_cmd}-entry; then
			eval ${commander_self}-${commander_cmd}-entry "$@"
		elif fn_exists ${commander_self}-${commander_cmd}; then
			eval ${commander_self}-${commander_cmd} "$@"
		elif fn_exists ${commander_self}-${commander_cmd//_/-}; then
			eval ${commander_self}-${commander_cmd//_/-} "$@"
		elif fn_exists ${commander_self}_${commander_cmd//-/_}; then
			eval ${commander_self}_${commander_cmd//-/_} "$@"
		else
			dbg "try invoking: ${commander_self}_${commander_cmd} | $@"
			eval ${commander_self}_${commander_cmd} "$@"
		fi
		;;
	esac
}
script_functions() {
	# shellcheck disable=SC2155
	local fncs=$(declare -F -p | cut -d " " -f 3 | grep -vE "^[_-]" | grep -vE "\\." | grep -vE "^[A-Z]") # Get function list
	if [ $# -eq 0 ]; then
		echo "$fncs" # not quoted here to create shell "argument list" of funcs.
	else
		echo "$fncs" | grep -E "$@"
	fi
	#declare MyFuncs=($(script.functions));
}
list_all_env_variables() { declare -xp; }
list_all_variables() { declare -p; }
hex2ip4() { local II="$1" && echo "$(((II >> 24) & 0xff)).$(((II >> 16) & 0xff)).$(((II >> 8) & 0xff)).$((II & 0xff))"; }
ip_hex() {
	tox() {
		local IP S A II
		while IFS='/' read IP S; do
			is_bash_strict && {
				# tip "ip: $IP, S: $S"
				II=$(awk -F. '{printf "0x%02x%02x%02x%02x",$1,$2,$3,$4}' <<<"$IP")
				echo $II
			} || bash <<-EOF
				II=\$(awk -F. '{printf "0x%02x%02x%02x%02x",\$1,\$2,\$3,\$4}' <<<"$IP")
				echo \$II
			EOF
		done
	}
	lanip | tox
}
netmask_hex() {
	tox() {
		local IP S M
		while IFS='/' read IP S; do
			M=$((0xffffffff ^ ((1 << (32 - S)) - 1)))
			printf '0x%08x' $M
		done
	}
	lanip | tox
}
subnet_hex() {
	local INC="$1"
	tox1() {
		local IP S M A I II
		while IFS='/' read IP S; do
			is_bash_strict && {
				# tip "x ip: $IP, S: $S"
				M=$((0xffffffff ^ ((1 << (32 - S)) - 1)))
				[ "$INC" != "" ] && M=$((M + INC)) || :
				# tip "M: $(printf '0x%08x' $M)"
				I=$(($(awk -F. '{printf "0x%02x%02x%02x%02x",$1,$2,$3,$4}' <<<"$IP")))
				II=$((M & I))
				# tip "I: $I, M: $M (S: $S), II: $II"
				printf '0x%08x' $II
			} || bash <<-EOF
				INC=$INC
				M=\$((0xffffffff ^ ((1 << (32 - $S)) - 1)))
				[ "\$INC" != "" ] && M=\$((M+INC)) || :
				I=\$((\$(awk -F. '{printf "0x%02x%02x%02x%02x",\$1,\$2,\$3,\$4}' <<<"$IP")))
				II=\$((M & I))
				printf '0x%08x' "\${II}"
			EOF
		done
	}
	# tip "lanip: '$(lanip)'"
	lanip | tox1
}
if fn_exists which; then
	:
elif fn_builtin_exists which; then
	:
elif is_darwin; then
	which() { whereis "$@"; }
fi
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
	hex2mask() {
		local hexmask=$(echo $1 | sed -e 's/^0x//')
		local i
		# printf "(%s)" $hexmask
		for ((i = 0; i < ${#hexmask}; i += 2)); do
			if (($i > 1)); then
				# use a . to separate octets
				# but don't print a leading .
				printf "%s" "."
			fi
			printf "%d" "0x${hexmask:$i:2}"
		done
		printf "\n"
	}
	# default_dev() { route get default | awk '/interface:/{print $2}'; }
	# gw() { route get default | awk '/gateway:/{print $2}'; }
	default_dev() { netstat -rn | awk '/default/ {print $4}' | head -1; }
	gw() { netstat -rn | awk '/default/ {print $2}' | head -1; }
	lanip() { ifconfig | grep 'inet ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	lanip6_flat() { ifconfig | grep 'inet6 ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	lanipall() { ifconfig | grep -E 'inet6? ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	netmask_hex() { ifconfig $(default_dev) | awk '/netmask /{print $4}'; }
	subnet_hex() {
		local R="$(ifconfig $(default_dev) | grep 'inet ' | grep -vE '127.0.0.1|::1|%lo|fe80::')"
		# tip "$R"
		while read line; do
			# tip "line: $line, $(awk '{print $2}' <<<$line), $(awk '{print $4}' <<<$line)"
			local IP="$(awk '{print $2}' <<<$line)"
			local M="$(awk '{print $4}' <<<$line)"
			I=$(($(awk -F. '{printf "0x%02x%02x%02x%02x",$1,$2,$3,$4}' <<<"$IP")))
			II=$((M & I))
			# tip "IP: $IP, I: $I, M: $M, II: $II"
			printf '0x%08x' $II
			printf "\n"
		done <<<"$R"
	}
	subnet4() { hex2ip4 $(subnet_hex | head -1); }
else
	ipcmd="$(which ip 1>/dev/null 2>&1 && echo 'sudo ip' || echo ifconfig)"
	realpathx() { readlink -f "$@"; }
	default_dev() { eval $ipcmd route show default | grep -oE 'dev \w+' | awk '{print $2}'; }
	if is_suse_series; then
		gw() { which netstat 1>/dev/null 2>&1 && netstat -r -n | grep -P '^0.0.0.0' | awk '{print $2}' || {
			if eval "$ipcmd route show" | grep -qP '^default'; then
				eval "$ipcmd route show default" | awk '{print $3}'
			else
				local xx=$(eval "$ipcmd route show" | awk '{print $1}')
				if [[ "$xx" = */* ]]; then
					cut -d'/' -f1 <<<"$xx" | sed 's/.0$/.1/'
				else
					echo $xx
				fi
			fi
		}; }
	else
		gw() { eval "$ipcmd route show default" | awk '{print $3}'; }
	fi
	lanip() { eval $ipcmd a | grep -E 'inet ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	lanip6_flat() { eval $ipcmd a | grep 'inet6 ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	lanipall() { eval $ipcmd a | grep -E 'inet6? ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	subnet4() { hex2ip4 $(subnet_hex); }
fi
gw1() { hex2ip4 $(subnet_hex ${1:-1}); }
netmask() { hex2ip4 $(netmask_hex); }
# alias wanip='dig +short myip.opendns.com @resolver1.opendns.com'
# alias ip-wan=wanip
lanip6() {
	if is_darwin; then
		local ipinf=$(ifconfig | grep 'inet6 ' | grep -vE '127.0.0.1|::1|%lo|fe80::')
	else
		local ipinf=$(eval $ipcmd a | grep 'inet6 ' | grep -vE '127.0.0.1|::1|%lo|fe80::')
	fi
	ipinf=$(grep -v ' deprecated ' <<<"$ipinf")
	local dyn=$(grep ' dynamic' <<<"$ipinf" | awk '{print $2}')
	local secured=$(grep ' secured' <<<"$ipinf" | awk '{print $2}')
	local pub=$(grep ' temporary' <<<"$ipinf" | awk '{print $2}')
	cat <<-EOT
		IPv6(s) for this machine (locally):
		                 dyn: ${dyn}
		             secured: ${secured}
		    public(*wan-ip*): ${pub}

	EOT
}
wanip() { host myip.opendns.com 208.67.220.222 | tail -1 | awk '{print $4}'; }
wanip6() {
	if is_darwin; then
		local ipinf=$(ifconfig | grep 'inet6 ' | grep -vE '127.0.0.1|::1|%lo|fe80::')
	else
		local ipinf=$(eval $ipcmd a | grep 'inet6 ' | grep -vE '127.0.0.1|::1|%lo|fe80::')
	fi
	ipinf=$(grep -v ' deprecated ' <<<"$ipinf")
	local pub=$(grep ' temporary' <<<"$ipinf" | awk '{print $2}')
	if [ "$pub" == "" ]; then
		host -t AAAA myip.opendns.com resolver1.ipv6-sandbox.opendns.com | grep -oE "^myip\.opendns\.com.*" | awk '{print $5}'
	else
		echo "$pub"
	fi
}
# use a tool script 'externalip' is better choice.
# try more sources for yourself:
#  http://ipecho.net/plain
#  http://ifcfg.me/
#  ...
wanip_http() { curl -s http://whatismyip.akamai.com/; }
# the best and exact way is asking a dns server by dig/host:
wanip_exact() { dig @resolver4.opendns.com myip.opendns.com +short; }
wanip6_exact() { dig @resolver1.ipv6-sandbox.opendns.com AAAA myip.opendns.com +short -6; }
main_do_sth() {
	[[ ${VERBOSE:-0} -eq 1 ]] && set -x
	set -e
	# set -o errexit
	# set -o nounset
	# set -o pipefail
	MAIN_DEV=${MAIN_DEV:-$(default_dev)}
	MAIN_ENTRY=${MAIN_ENTRY:-_my_main_do_sth}
	in_debug && debug_info && dbg "$(safety "$MAIN_ENTRY - $@\n    [CD: $CD, SCRIPT: $SCRIPT]")"
	if in_sourcing; then
		$MAIN_ENTRY "$@"
		return $?
	else
		local result_code
		trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
		is_darwin || trap '[[ $? -ne 0 ]] && echo FAILED COMMAND: "$previous_command" with exit code $?' EXIT
		$MAIN_ENTRY "$@"
		result_code=$?
		trap - EXIT
	fi
	# Why use `{ [ $# -eq 0 ] && :; }`?
	#   While bash.sh/provision.sh/ops was been invoking with command-line args,
	#   we would assume that's normal status if `trap` caluse doesn't catch any errors.
	#   So, a failure test on HAS_END shouldn't take bad effect onto the whole provisioning script exit status.
	# You might always change this logic or comment the following line, no obsezzing on it.
	# Or, if your provisioning script with bash.sh has not any entranance arguments,
	# disabling this logic is still simple by defining HAS_END=1.
	((${HAS_END:-0})) && { debug_begin && echo -n 'Success!' && debug_end; } || return $result_code # { [ $# -eq 0 ] && :; }
}
BASH_SH_VERSION=v20250815
DEBUG=${DEBUG:-0}
PROVISIONING=${PROVISIONING:-0}
SUDO=sudo && [ "$(id -u)" = "0" ] && SUDO= || :
LS_OPT="--color" && is_darwin && LS_OPT="-G" || :
# Instantly aliases cannot work in many cases such as conditional
# constructs, loops, even in statement block. So this won't work sometimes:
#     if [ true ]; then cmd-exist ls && echo 'ls exists' || echo 'ls not-exists'; fi
# To use the following kebab aliases, a safety way is by eval:
#     if [ true ]; then eval cmd-exist ls && echo 'ls exists' || echo 'ls not-exists'; fi
alias char-repeat=char_repeat
alias cmd-exists=cmd_exists fn-aliased-exists=fn_aliased_exists fn-builtin-exists=fn_builtin_exists fn-exists=fn_exists fn-name=fn_name fn-name-dyn=fn_name_dyn
alias for-each-days=for_each_days foreach-days=for_each_days home-dir=home_dir homedir=home_dir
alias if-centos=if_centos if-hosttype=if_hosttype if-mac=if_mac if-nix=if_nix if-nix-typ=if_nix_typ if-non-zero-and-empty=if_non_zero_and_empty if-ubuntu=if_ubuntu if-vagrant=if_vagrant if-zero-or-empty=if_zero_or_empty
alias in-debug=in_debug in-jetbrains=in_jetbrains in-provisioning=in_provisioning in-sourcing=in_sourcing in-vagrant=in_vagrant in-vm=in_vm in-vscode=in_vscode in-wsl=in_wsl
alias is-apt=is_apt is-arch-series=is_arch_series is-bash=is_bash is-bash-t1='is_bash_t1' is-bash-t2='is_bash_t2' is-centos=is_centos is-darwin=is_darwin is-debian=is_debian is-debian-series=is_debian_series is-dnf=is_dnf is-fedora=is_fedora is-fedora-series=is_fedora_series is-fish=is_fish is-git-clean=is_git_clean is-git-dirty=is_git_dirty is-homebrew=is_homebrew is-interactive-shell=is_interactive_shell is-linux=is_linux is-mageia=is_mageia is-mandriva-series=is_mandriva_series is-manjaro=is_manjaro is-not-interactive-shell=is_not_interactive_shell is-not-ps1='is_not_ps1' is-opensuse=is_opensuse is-opensuse-series=is_opensuse_series is-pacman=is_pacman is-ps1='is_ps1' is-redhat=is_redhat is-redhat-series=is_redhat_series is-root=is_root is-suse-series=is_suse_series is-ubuntu=is_ubuntu is-win=is_win is-yum=is_yum is-zsh=is_zsh is-zsh-strict=is_zsh_strict is-zsh-t1='is_zsh_t1' is-zsh-t2='is_zsh_t2' is-zypp=is_zypp is-zypper=is_zypper
alias list-all-env-variables=list_all_env_variables list-all-variables=list_all_variables safety-pipe=safetypipe safety_pipe=safetypipe strip-l=strip_l strip-r=strip_r url-exists=url_exists user-shell=user_shell
# trans_readlink() { DIR="${1%/*}" && (cd $DIR && pwd -P); }
# is_darwin && realpathx() { [[ $1 == /* ]] && echo "$1" || { DIR="${1%/*}" && DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $1)"; }; } || realpathx() { readlink -f $*; }
in_sourcing && {
	SCRIPT=$(realpathx $(is_zsh_strict && echo "$0" || { [ "$BASH_SOURCE" != "" ] && echo "$BASH_SOURCE" || echo "$0"; })) && CD=$(dirname "$SCRIPT") && debug "$(safety ">> IN SOURCING (DEBUG=$DEBUG), \$0=$0, \$_=$_")"
} || {
	path_in_orb_host "$0" && SCRIPT="$0" || SCRIPT=$(realpathx "$0")
	CD=$(dirname "$SCRIPT") && debug "$(safety ">> '$SCRIPT' in '$CD', \$0='$0','$1'.")"
} || CD="$(cd $(dirname "$0") && pwd)"
if_vagrant && [ "$SCRIPT" == "/tmp/vagrant-shell" ] && { [ -d "$CD/ops.d" ] || CD=/vagrant/bin; }
path_in_orb_host "$0" && : || { [ -L "$SCRIPT" ] && debug "$(safety "linked script found")" && SCRIPT="$(realpathx "$SCRIPT")" && CD="$(dirname "$SCRIPT")"; }
# The better consice way to get baseDir, ie. $CD, is:
#       CD=$(cd `dirname "$0"`;pwd)
# It will open a sub-shell to print the folder name of the running shell-script.
in_sourcing && _bash_sh_load_import_files || main_do_sth "$@"
#### HZ Tail END #### v20250815 ####
