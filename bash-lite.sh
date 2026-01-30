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
#   Version: v20260115
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
		                is_bash: $(is_bash && echo Y || echo '.')       # STRICTED = $(is_bash_strict && echo Y || echo N), SHELL = $SHELL, BASH_VERSION = $BASH_VERSION
		       is_zsh/is_zsh_t1: $(is_zsh && echo Y || echo '.') / $(is_zsh_t1 && echo Y || echo '.')   # $(is_zsh && echo "ZSH_EVAL_CONTEXT = $ZSH_EVAL_CONTEXT, ZSH_NAME/VERSION = $ZSH_NAME v$ZSH_VERSION" || :)
		                is_fish: $(is_fish && echo Y || echo '.')       # FISH_VERSION = $FISH_VERSION
		            in_sourcing: $(in_sourcing && echo Y || echo '.')
		       if_vagrant/in_vm: $(if_vagrant && echo Y || echo '.') / $(in_vm && echo Y || echo '.')
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
	fn_exists pmid && cat <<-EOF

		  OS tests: pmid='$(pmid)' osid='$(osid)' osidlike='$(osidlike)'
		            oscodename='$(oscodename)' versionid='$(versionid)' variantid='$(variantid)'
		            if_nix_typ='$(if_nix_typ)' (\$OSTYPE='$OSTYPE')
		            is_suse_series='$(is_suse_series && echo Y || echo .)'
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

slepp() { :; }

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

#### HZ Tail BEGIN #### v20260115 ####
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
is_xdg_ready() { [[ -n "${XDG_CONFIG_HOME-}" ]]; } # when xdg-config presents, prefer using XDG_xxx
is_darwin() { [[ $OSTYPE == darwin* ]]; }
is_darwin_sillicon() { is_darwin && [[ $(uname_mach) == arm64 ]]; }
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
	alias is_ttya=true
else
	alias is_stdin=false
	alias is_not_stdin=true
	alias is_ttya=false
fi
cmd_exists() { command -v $1 >/dev/null; } # it detects any builtin or external commands, aliases, and any functions
fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(shell function)|(a function)'; }
fn_builtin_exists() { LC_ALL=C type $1 2>/dev/null | grep -q 'shell builtin'; }
fn_defined() { LC_ALL=C type $1 2>/dev/null | grep -qE '( shell function)|( a function)|( shell builtin)'; }
if is_zsh_strict; then
	fn_aliased_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(alias for)|(aliased to)'; }
else
	fn_aliased_exists() { LC_ALL=C alias $1 1>/dev/null 2>&1; }
fi
if fn_defined which; then
	: # dbg "'which' has been defined."
else
	which() { command -v "$@"; }
fi
which2() { [ "$(whereis -b $1 | awk '{print $2}')" != "" ]; }
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
		if hostnamectl | grep -iE 'chassis: ' | grep -q ' vm'; then
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
#
#
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
headline() { printf "\e[0;1m$@\e[0m:\n"; }
headline_begin() { printf "\e[0;1m"; } # for more color, see: shttps://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
headline_end() { printf "\e[0m:\n"; }  # https://misc.flogisoft.com/bash/tip_colors_and_formatting
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
#
#
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
#
#
hex2ip4() { local II="$1" && echo "$(((II >> 24) & 0xff)).$(((II >> 16) & 0xff)).$(((II >> 8) & 0xff)).$((II & 0xff))"; }
ip_hex() {
	tox() {
		local IP S A II
		while IFS='/' read IP S; do
			is_bash_strict && {
				IFS='.' read -ra A <<<"$IP"
				II=$(printf '0x%02X%02X%02X%02X' ${A[0]} ${A[1]} ${A[2]} ${A[3]})
				echo $II
			} || bash <<-EOF
				IFS='.' read -ra A <<<"$IP"
				II=\$(printf '0x%02X%02X%02X%02X' \${A[0]} \${A[1]} \${A[2]} \${A[3]})
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
	lanip() { ifconfig | grep 'inet ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	lanip6_flat() { ifconfig | grep 'inet6 ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	lanipall() { ifconfig | grep -P 'inet6? ' | grep -vE '127.0.0.1|::1|%lo|fe80::' | awk '{print $2}'; }
	netmask_hex() { ifconfig $(default_dev) | awk '/netmask /{print $4}'; }
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
fi
gw1() { hex2ip4 $(subnet_hex ${1:-1}); }
subnet4() { hex2ip4 $(subnet_hex); }
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
#
#
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
BASH_SH_VERSION=v20260115
DEBUG=${DEBUG:-0}
# trans_readlink() { DIR="${1%/*}" && (cd $DIR && pwd -P); }
# is_darwin && realpathx() { [[ $1 == /* ]] && echo "$1" || { DIR="${1%/*}" && DIR=$(cd $DIR && pwd -P) && echo "$DIR/$(basename $1)"; }; } || realpathx() { readlink -f $*; }
in_sourcing && {
	SCRIPT=$(realpathx $(is_zsh_strict && echo "$0" || echo "$BASH_SOURCE")) && CD=$(dirname "$SCRIPT") && debug "$(safety ">> IN SOURCING (DEBUG=$DEBUG), \$0=$0, \$_=$_")"
} || { SCRIPT=$(realpathx "$0") && CD=$(dirname "$SCRIPT") && debug "$(safety ">> '$SCRIPT' in '$CD', \$0='$0','$1'.")"; }
if_vagrant && [ "$SCRIPT" == "/tmp/vagrant-shell" ] && { [ -d $CD/ops.d ] || CD=/vagrant/bin; }
[ -L "$SCRIPT" ] && debug linked script found && SCRIPT=$(realpathx "$SCRIPT") && CD=$(dirname "$SCRIPT")
in_sourcing || main_do_sth "$@"
#### HZ Tail END #### v20260115 ####
