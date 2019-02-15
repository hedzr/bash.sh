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

_my_main_do_sth(){
  local cmd=${1:-sleeping} && { [ $# -ge 1 ] && shift; } || :
  # for linux only: 
  # local cmd=${1:-sleeping} && shift || :
  
  debug "$cmd - $@"
  eval "$cmd $@" || :
}
#### write your functions here, and invoke them by: `./bash.sh <your-func-name>`
cool(){ echo cool; }
sleeping(){ echo sleeping; }



#### HZ Tail BEGIN ####
in_debug()       { [[ $DEBUG -eq 1 ]]; }
is_root()        { [ "$(id -u)" = "0" ]; }
is_bash()        { [ -n "$BASH_VERSION" ]; }
is_bash_t2()     { [ ! -n "$BASH" ]; }
is_zsh()         { [[ $SHELL == */zsh ]]; }
is_zsh_t2()      { [ -n "$ZSH_NAME" ]; }
is_darwin()      { [[ $OSTYPE == *darwin* ]]; }
is_linux()       { [[ $OSTYPE == *linux* ]]; }
in_sourcing()    { is_zsh && [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] || [[ $(basename -- "$0") != $(basename -- "${BASH_SOURCE[0]}") ]]; }
headline()       { printf "\e[0;1m$@\e[0m:\n"; }
headline_begin() { printf "\e[0;1m"; }  # for more color, see: shttps://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
headline_end()   { printf "\e[0m:\n"; } # https://misc.flogisoft.com/bash/tip_colors_and_formatting
is_interactive_shell () { [[ $- == *i* ]]; }
is_not_interactive_shell () { [[ $- != *i* ]]; }
is_ps1 () { [ -z "$PS1" ]; }
is_not_ps1 () { [ ! -z "$PS1" ]; }
is_stdin () { [ -t 0 ]; }
is_not_stdin () { [ ! -t 0 ]; }
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
debug_info()     {
	debug_begin
	cat <<-EOF
	             in_debug: $(in_debug && echo Y || echo '-')
	              is_root: $(is_root && echo Y || echo '-')
	              is_bash: $(is_bash && echo Y || echo '-')
	           is_bash_t2: $(is_bash_t2 && echo Y || echo '-')
	               is_zsh: $(is_zsh && echo Y || echo '-')
	          in_sourcing: $(in_sourcing && echo Y || echo '-')
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
	${HAS_END:-$(false)} && debug_begin && echo -n 'Success!' && debug_end
}
DEBUG=${DEBUG:-0}
is_darwin && realpathx(){ [[ $1 == /* ]] && echo "$1" || echo "$PWD/${1#./}"; } || realpathx () { readlink -f $*; }
in_sourcing && { CD=${CD}; debug ">> IN SOURCING, \$0=$0, \$_=$_"; } || { SCRIPT=$(realpathx $0) && CD=$(dirname $SCRIPT) && debug ">> '$SCRIPT' in '$CD', \$0='$0','$1'."; }
main_do_sth "$@"
#### HZ Tail END ####
