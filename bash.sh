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
#   Version: v20230625
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
	for f in $CD/bash*; do
		echo "bumping for $(safety $f), YEAR = $YEAR ..."
		sed -i '' -E -e "s/v$YEAR[0-9]+/$VERSION/g" $f
		sed -i '' -E "s/v$((YEAR - 1))[0-9]+/$VERSION/g" $f
	done
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

#### write your functions here, and invoke them by: `./bash.sh <your-func-name>`

# FN_PREFIX=boot_
_my_main_do_sth() {
	local cmd=${1:-help} && { [ $# -ge 1 ] && shift; } || :
	# local FN_PREFIX=boot_
	# for linux only:
	# local cmd=${1:-sleeping} && && shift || :

	local DBG_SAVE="$DEBUG"

	dbg ": loading imports"
	_bash_sh_load_import_files
	dbg ": shell.d files imports"
	# _bash_sh_load_files '*'
	_bash_sh_load_env_files
	dbg ": env imports"

	# in_provisioning ||
	[ "$cmd" = "first-install" ] || DEBUG="$DBG_SAVE" # && echo "DEBUG: $DEBUG"
	# echo "4. DEBUG: $DEBUG, cmd: $cmd"

	# in_debug && LC_ALL=C type $cmd || echo "$cmd not exists"
	dbg ": invoking cmd: $cmd"
	if fn_exists "boot_$cmd"; then
		eval boot_$cmd "$@" #&& dbg ":DONE:boot_$cmd"
	elif fn_exists "$cmd"; then
		eval $cmd "$@" #&& dbg ":DONE:$cmd"
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

#### HZ Tail BEGIN ####
in_debug() { (($DEBUG)); }
in_provisioning() { (($PROVISIONING)); } ## return exit status as true if $PROVISIONING is not equal to 0
is_root() { [ "$(id -u)" = "0" ]; }
is_bash() { is_bash_t1 || is_bash_t2; }
is_bash_t1() { [ -n "$BASH_VERSION" ]; }
is_bash_t2() { [ ! -n "$BASH" ]; }
is_zsh() { [[ -n "$ZSH_NAME" || "$SHELL" = */zsh ]]; }
is_zsh_strict() { [[ -n "$ZSH_NAME" && "$SHELL" = */zsh ]]; }
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
	alias is_tty=true
else
	alias is_stdin=false
	alias is_not_stdin=true
	alias is_tty=false
fi
cmd_exists() { command -v $1 >/dev/null; } # it detects any builtin or external commands, aliases, and any functions
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
if_centos() {
	if [[ $OSTYPE == linux* ]]; then
		if [ -f /etc/centos-release ]; then
			:
		else
			[ -f /etc/issue ] && grep -qEi '(centos|(Amazon Linux AMI))' /etc/issue
		fi
	fi
}
in_vm() {
	if cmd_exists hostnamectl; then
		# dbg "checking hostnamectl"
		if hostnamectl | grep -E 'chassis: ' | grep -q ' vm'; then
			true
		elif hostnamectl | grep -qE 'Virtualization: '; then
			true
		fi
	else
		# dbg "without hostnamectl"
		false
	fi
}
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
is_fedora() { [[ "$(osid)" == fedora ]]; }
is_centos() { [[ "$(osid)" == centos ]]; }
is_redhat() { [[ "$(osid)" == redhat ]]; }
is_debian() { [[ "$(osid)" == debian ]]; }
is_ubuntu() { [[ "$(osid)" == ubuntu ]]; }
is_mageia() { [[ "$(osid)" == mageia ]]; }
is_manjaro() { [[ "$(osid)" == manjaro ]]; }
is_opensuse() { [[ "$(osid)" == opensuse* ]]; }
# is_debian_series() { [[ "$(osid)" == debian || "$(osid)" == ubuntu ]]; }
# is_redhat_series() { [[ "$(osid)" == redhat || "$(osid)" == centos || "$(osid)" == fedora ]]; }
is_yum() { which yum 1>/dev/null 2>&1; }
is_dnf() { which dnf 1>/dev/null 2>&1; }
is_apt() { which apt-get 1>/dev/null 2>&1; }
is_pacman() { which pacman 1>/dev/null 2>&1; }
is_zypp() { which zypper 1>/dev/null 2>&1; }
is_zypper() { which zypper 1>/dev/null 2>&1; }
is_homebrew() { which brew 1>/dev/null 2>&1; }
# is_redhat_series() { is_yum || is_dnf; }
# is_debian_series() { is_apt; }
is_redhat_series() { [[ "$(osidlike)" == redhat ]]; }
is_debian_series() { [[ "$(osidlike)" == debian ]]; }
is_mandriva_series() { [[ "$(osidlike)" == mandriva* ]]; } # mandriva, mageia, ...
is_arch_series() { [[ "$(osidlike)" == arch ]]; }
is_fedora_series() { [[ "$(osidlike)" == *fedora* ]]; }
is_suse_series() { [[ "$(osidlike)" == suse* ]]; }
is_opensuse_series() { [[ "$(osidlike)" == *opensuse* ]]; }
#
#
#
lsb_release_cs() { lsb_release -cs; } # focal, ... # = oscodename
uname_kernel() { uname -s; }          # Linux
uname_cpu() { uname -p; }             # processor: x86_64
uname_mach() { uname -m; }            # machine:   x86_64, ...
uname_rev() { uname -r; }             # kernel-release: 5.8.15-301.fc33.x86_64
uname_ver() { uname -v; }             # kernel-version:
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
is_git_clean() { git diff-index --quiet $* HEAD -- 2>/dev/null; }
is_git_dirty() { is_git_clean && return -1 || return 0; }
git_clone() {
	# git-clone will pull the repo into 'user.repo/', for example:
	#   git-clone git@github.com:hedzr/cmdr.git
	#   git-clone https://github.com/hedzr/cmdr.git
	#   will pull hedzr/cmdr into 'hedzr.cmdr/' directory.
	local Repo="${1:-hedzr/cmdr}"
	local Sep='/'
	local Prefix='${GIT_PREFIX:-https://}'
	local Host="${GIT_HOST:-github.com}"
	[[ $Repo =~ https://* ]] && Repo="${Repo//https:\/\//}" && Prefix='git@'
	[[ $Repo =~ github.com/* ]] && Repo="${Repo//github.com\//}" && Prefix='git@'
	[[ $Repo =~ github.com:* ]] && Repo="${Repo//github.com:/}" && Prefix='git@'
	Repo="${Repo#git@}"
	Repo="${Repo%.git}"
	Dir="${Repo//\//.}"
	# Repo="${Repo#https://github.com/}"
	# Repo="${Repo#git@github.com:}"
	# Repo="${Repo%.git}"
	[[ $Prefix == 'git@' ]] && Sep=':'
	local Url="${Prefix}${Host}${Sep}${Repo}.git"
	# tip "Url: $Url"
	dbg "cloning from $Url ..." && git clone --depth=1 -q "$Url" "$Dir" && dbg "git clone $Url DONE."
}
alias git-clone=git_clone
#
#
url_exists() { curl --head --silent -S --fail --output /dev/null "$@" 1>/dev/null 2>&1; }
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
tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }
debug_info() {
	debug_begin
	cat <<-EOF
		               in_debug: $(in_debug && echo Y || echo '.')
		                is_root: $(is_root && echo Y || echo '.')
		                is_bash: $(is_bash && echo Y || echo '.')       # SHELL = $SHELL, BASH_VERSION = $BASH_VERSION
		       is_zsh/is_zsh_t1: $(is_zsh && echo Y || echo '.') / $(is_zsh_t1 && echo Y || echo '.')   # $(is_zsh && echo "ZSH_EVAL_CONTEXT = $ZSH_EVAL_CONTEXT, ZSH_NAME = $ZSH_NAME, ZSH_VERSION = $ZSH_VERSION" || :)
		                is_fish: $(is_fish && echo Y || echo '.')       # FISH_VERSION = $FISH_VERSION
		            in_sourcing: $(in_sourcing && echo Y || echo '.')
		       if_vagrant/in_vm: $(if_vagrant && echo Y || echo '.') / $(in_vm && echo Y || echo '.')
		              in_vscode: $(in_vscode && echo Y || echo '.')
		           in_jetbrains: $(in_jetbrains && echo Y || echo '.')
		          in_vim/neovim: $(in_vim && echo Y || echo '.') / $(in_neovim && echo Y || echo '.')
		  darwin/linux/win(wsl): $(is_darwin && echo Y || echo '.') / $(is_linux && echo Y || echo '.') / $(is_win && echo Y || echo '.')
		   is_interactive_shell: $(is_interactive_shell && echo Y || echo '.')
		  
		NOTE: bash.sh can only work in bash/zsh mode, even if running it in fish shell.

		  IP(s):
		$(lanip | pad 9)
		  Gateway / Mask: $(gw) / $(netmask)

		  OS tests: pmid='$(pmid)' osid='$(osid)' osidlike='$(osidlike)'
		            oscodename='$(oscodename)' versionid='$(versionid)' variantid='$(variantid)'
		            if_nix_typ='$(if_nix_typ)' (\$OSTYPE='$OSTYPE')
	EOF
	is_linux && cat <<-EOF

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
	:
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
	# local TILLDAYS=$((DAYS1 + 365))
	for ((i = $DAYS1; i < $TILLDAYS; i++)); do
		eval $func "$(datename $i)" "$@"
	done
}
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
	default_dev() { route get default | awk '/interface:/{print $2}'; }
	gw() { route get default | awk '/gateway:/{print $2}'; }
	lanip() { ifconfig | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}'; }
	lanip6() { ifconfig | grep 'inet6 ' | grep -FvE '::1|%lo|fe80::' | awk '{print $2}'; }
	netmask_hex() { ifconfig $(default_dev) | awk '/netmask /{print $4}'; }
	netmask() { hex2mask $(netmask_hex); }
else
	ipcmd="$(which ip 2>/dev/null || echo 'sudo ip')"
	realpathx() { readlink -f "$@"; }
	default_dev() { $ipcmd route show default | grep -oE 'dev \w+' | awk '{print $2}'; }
	gw() { $ipcmd route show default | awk '{print $3}'; }
	lanip() { $ipcmd a | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}'; }
	lanip6() { $ipcmd a | grep 'inet6 ' | grep -FvE '::1|%lo|fe80::' | awk '{print $2}'; }
	netmask() {
		which ifconfig >/dev/null 2>&1 && { ifconfig $(default_dev) | awk '/netmask /{print $4}'; } || {
			tomask() {
				while IFS='/' read IP S; do
					M=$((0xffffffff ^ ((1 << (32 - S)) - 1)))
					echo "$(((M >> 24) & 0xff)).$(((M >> 16) & 0xff)).$(((M >> 8) & 0xff)).$((M & 0xff))"
				done
			}
			$ipcmd a | grep 'inet ' | grep -Fv 127.0.0.1 | awk '{print $2}' | tomask
		}
	}
fi
# alias wanip='dig +short myip.opendns.com @resolver1.opendns.com'
# alias ip-wan=wanip
wanip() { host myip.opendns.com 208.67.220.222 | tail -1 | awk '{print $4}'; }
wanip6() { host -t AAAA myip.opendns.com resolver1.ipv6-sandbox.opendns.com | grep -oE "^myip\.opendns\.com.*" | awk '{print $5}'; }
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
	# echo $MAIN_ENTRY - "$@"
	in_debug && debug_info && dbg "$(safety "$MAIN_ENTRY - $@\n    [CD: $CD, SCRIPT: $SCRIPT]")"
	if in_sourcing; then
		$MAIN_ENTRY "$@"
	else
		trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
		trap '[ $? -ne 0 ] && echo FAILED COMMAND: "$previous_command" with exit code $?' EXIT
		$MAIN_ENTRY "$@"
		trap - EXIT
	fi
	# Why use `{ [ $# -eq 0 ] && :; }`?
	#   While bash.sh/provision.sh/ops was been invoking with command-line args,
	#   we would assume that's normal status if `trap` caluse doesn't catch any errors.
	#   So, a failure test on HAS_END shouldn't take bad effect onto the whole provisioning script exit status.
	# You might always change this logic or comment the following line, no obsezzing on it.
	# Or, if your provisioning script with bash.sh has not any entranance arguments,
	# disabling this logic is still simple by defining HAS_END=1.
	((${HAS_END:-0})) && { debug_begin && echo -n 'Success!' && debug_end; } || { [ $# -eq 0 ] && :; }
}
BASH_SH_VERSION=v20230625
DEBUG=${DEBUG:-0}
PROVISIONING=${PROVISIONING:-0}
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
in_sourcing && { SCRIPT=$(realpathx "$0") && CD=$(dirname "$SCRIPT") && debug "$(safety ">> IN SOURCING (DEBUG=$DEBUG), \$0=$0, \$_=$_")"; } || { SCRIPT=$(realpathx "$0") && CD=$(dirname "$SCRIPT") && debug "$(safety ">> '$SCRIPT' in '$CD', \$0='$0','$1'.")"; }
if_vagrant && [ "$SCRIPT" == "/tmp/vagrant-shell" ] && { [ -d "$CD/ops.d" ] || CD=/vagrant/bin; }
[ -L "$SCRIPT" ] && debug "$(safety "linked script found")" && SCRIPT="$(realpathx "$SCRIPT")" && CD="$(dirname "$SCRIPT")"
in_sourcing && _bash_sh_load_import_files || main_do_sth "$@"
#### HZ Tail END ####
