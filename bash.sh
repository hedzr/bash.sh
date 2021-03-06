# # /usr/bin/env bash
#
# HZ: Standard Template for bash/zsh developing.
# Version: 20180215
# License: MIT
# Site: https://github/hedzr/bash.sh
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

#### write your functions here, and invoke them by: `./bash.sh <your-func-name>`
cool(){ echo cool; }
sleeping(){ echo sleeping; }



_my_main_do_sth(){
  local cmd=${1:-sleeping} && { [ $# -ge 1 ] && shift; } || :
  # for linux only: 
  # local cmd=${1:-sleeping} && shift || :
  
  debug "$cmd - $@"
  eval "$cmd $@" || :
}



#### HZ Tail BEGIN ####
in_debug()       { [[ $DEBUG -eq 1 ]]; }
is_root()        { [ "$(id -u)" = "0" ]; }
is_bash()        { is_bash_t1 && is_bush_t2; }
is_bash_t1()     { [ -n "$BASH_VERSION" ]; }
is_bash_t2()     { [ ! -n "$BASH" ]; }
is_zsh()         { [[ $SHELL == */zsh ]]; }
is_zsh_t2()      { [ -n "$ZSH_NAME" ]; }
is_darwin()      { [[ $OSTYPE == *darwin* ]]; }
is_linux()       { [[ $OSTYPE == *linux* ]]; }
in_sourcing()    { is_zsh && [[ "$ZSH_EVAL_CONTEXT" == toplevel* ]] || [[ $(basename -- "$0") != $(basename -- "${BASH_SOURCE[0]}") ]]; }
is_interactive_shell () { [[ $- == *i* ]]; }
is_not_interactive_shell () { [[ $- != *i* ]]; }
is_ps1 () { [ -z "$PS1" ]; }
is_not_ps1 () { [ ! -z "$PS1" ]; }
is_stdin () { [ -t 0 ]; }
is_not_stdin () { [ ! -t 0 ]; }
fn_exists()         { LC_ALL=C type $1 | grep -q 'shell function'; }
fn_builtin_exists() { LC_ALL=C type $1 | grep -q 'shell builtin'; }
fn_aliased_exists() { LC_ALL=C type $1 | grep -qE '(alias for)|(aliased to)'; }
if_nix () {
    case "$OSTYPE" in
        *linux*|*hurd*|*msys*|*cygwin*|*sua*|*interix*) sys="gnu";;
        *bsd*|*darwin*) sys="bsd";;
        *sunos*|*solaris*|*indiana*|*illumos*|*smartos*) sys="sun";;
    esac
    [[ "${sys}" == "$1" ]];
}
if_mac () { [[ $OSTYPE == *darwin* ]]; }
if_ubuntu () {
  if [[ $OSTYPE == *linux* ]]; then
    [ -f /etc/os-release ] && grep -qi 'ubuntu' /etc/os-release
  else
    false
  fi
}
if_vagrant () {
  [ -d /vagrant ];
}
if_centos () {
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
osid(){      # fedora / ubuntu
  [[ -f /etc/os-release ]] && {
    grep -Eo '^ID="?(.+)"?' /etc/os-release|sed -r -e 's/^ID="?(.+)"?/\1/'
  }
}
versionid(){ # 33 / 20.04
  [[ -f /etc/os-release ]] && {
    grep -Eo '^VERSION_ID="?(.+)"?' /etc/os-release|sed -r -e 's/^VERSION_ID="?(.+)"?/\1/'
  }
}
variantid(){ # server, desktop
  [[ -f /etc/os-release ]] && {
    grep -Eo '^VARIANT_ID="?(.+)"?' /etc/os-release|sed -r -e 's/^VARIANT_ID="?(.+)"?/\1/'
  }
}
#
is_fedora(){ [[ "$osid" == fedora ]]; }
is_centos(){ [[ "$osid" == centos ]]; }
is_redhat(){ [[ "$osid" == redhat ]]; }
is_debian(){ [[ "$osid" == debian ]]; }
is_ubuntu(){ [[ "$osid" == ubuntu ]]; }
is_debian(){ [[ "$osid" == debian ]]; }
is_yum   (){ which yum 2>/dev/null; }
is_dnf   (){ which dnf 2>/dev/null; }
is_apt   (){ which apt 2>/dev/null; }
is_redhat_series(){ is_yum || is_dnf; }
is_debian_series(){ is_apt; }
#
#
#
uname_kernel(){ uname -s; }   # Linux
uname_cpu(){ uname -p; }      # processor: x86_64
uname_mach(){ uname -m; }     # machine:   x86_64, ...
uname_rev(){ uname -r; }      # kernel-release: 5.8.15-301.fc33.x86_64
uname_ver(){ uname -v; }      # kernel-version: 
lscpu_call(){ lscpu $*; }
lshw_cpu(){ sudo lshw -c cpu; }
i386_amd64(){ dpkg --print-architecture; }
x86_64(){ uname -m; }
#
#
#
headline()       { printf "\e[0;1m$@\e[0m:\n"; }
headline_begin() { printf "\e[0;1m"; }  # for more color, see: shttps://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
headline_end()   { printf "\e[0m:\n"; } # https://misc.flogisoft.com/bash/tip_colors_and_formatting
printf_black()   { printf "\e[0;30m$@\e[0m:\n"; }
printf_red()     { printf "\e[0;31m$@\e[0m:\n"; }
printf_green()   { printf "\e[0;32m$@\e[0m:\n"; }
printf_yellow()  { printf "\e[0;33m$@\e[0m:\n"; }
printf_blue()    { printf "\e[0;34m$@\e[0m:\n"; }
printf_purple()  { printf "\e[0;35m$@\e[0m:\n"; }
printf_cyan()    { printf "\e[0;36m$@\e[0m:\n"; }
printf_white()   { printf "\e[0;37m$@\e[0m:\n"; }
debug()          { in_debug && printf "\e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_begin()    { printf "\e[0;38;2;133;133;133m"; }
debug_end()      { printf "\e[0m\n"; }
dbg()            { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
debug_info()     {
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
commander ()    {
  local self=$1; shift;
  local cmd=${1:-usage}; [ $# -eq 0 ] || shift;
  #local self=${FUNCNAME[0]}
  case $cmd in
	help|usage|--help|-h|-H) "${self}_usage" "$@"; ;;
	funcs|--funcs|--functions|--fn|-fn)  script_functions "^$self"; ;;
	*)
	  if [ "$(type -t ${self}_${cmd}_entry)" == "function" ]; then
		"${self}_${cmd}_entry" "$@"
	  else
		"${self}_${cmd}" "$@"
	  fi
	  ;;
  esac
}
script_functions () {
  # shellcheck disable=SC2155
  local fncs=$(declare -F -p | cut -d " " -f 3|grep -vP "^[_-]"|grep -vP "\\."|grep -vP "^[A-Z]"); # Get function list
  if [ $# -eq 0 ]; then
	echo "$fncs"; # not quoted here to create shell "argument list" of funcs.
  else
	echo "$fncs"|grep -P "$@"
  fi
  #declare MyFuncs=($(script.functions));
}
main_do_sth()    {
	set -e
	trap 'previous_command=$this_command; this_command=$BASH_COMMAND' DEBUG
	trap '[ $? -ne 0 ] && echo FAILED COMMAND: $previous_command with exit code $?' EXIT
	MAIN_DEV=${MAIN_DEV:-eth0}
	MAIN_ENTRY=${MAIN_ENTRY:-_my_main_do_sth}
	# echo $MAIN_ENTRY - "$@"
	in_debug && { debug_info; echo "$SHELL : $ZSH_NAME - $ZSH_VERSION | BASH_VERSION = $BASH_VERSION"; [ -n "$ZSH_NAME" ] && echo "x!"; }
	$MAIN_ENTRY "$@"
	trap - EXIT
	${HAS_END:-$(false)} && { debug_begin;echo -n 'Success!';debug_end; } || :
}
DEBUG=${DEBUG:-0}
trans_readlink(){ DIR="${1%/*}"; (cd $DIR && pwd -P); }
is_darwin && realpathx(){ [[ $1 == /* ]] && echo "$1" || { DIR="${1%/*}"; DIR=$(cd $DIR && pwd -P); echo "$DIR/$(basename $1)"; }; } || realpathx () { readlink -f $*; }
in_sourcing && { CD=${CD}; debug ">> IN SOURCING, \$0=$0, \$_=$_"; } || { SCRIPT=$(realpathx $0) && CD=$(dirname $SCRIPT) && debug ">> '$SCRIPT' in '$CD', \$0='$0','$1'."; }
main_do_sth "$@"
#### HZ Tail END ####