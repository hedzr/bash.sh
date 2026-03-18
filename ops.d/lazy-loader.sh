# -*- mode: bash; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: t-*-
# vi: set ft=bash noet ci pi sts=0 sw=2 ts=2:
# st:
#
#

# for zsh
lazy_loaded=()
if ! command -v fn_exists >/dev/null; then
	cmd_exists() { command -v $1 >/dev/null; } # it detects any builtin or external commands, aliases, and any functions
	fn_exists() { LC_ALL=C type $1 2>/dev/null | grep -qE '(shell function)|(a function)'; }
fi
if ! command -v dbg >/dev/null; then
	dbg() { ((DEBUG)) && printf ">>> \e[0;38;2;133;133;133m$@\e[0m\n" || :; }
	tip() { printf "\e[0;38;2;133;133;133m>>> $@\e[0m\n"; }
	wrn() { printf "\e[0;38;2;172;172;22m... [WARN] \e[0;38;2;11;11;11m$@\e[0m\n"; }
	err() { printf "\e[0;33;1;133;133;133m>>> $@\e[0m\n" 1>&2; }
fi
if fn_exists command_not_found_handler; then
	dbg "  ..  unset command_not_found_handler and define a new one for bash.sh/ops"
	unset command_not_found_handler
else
	dbg "  ..  define command_not_found_handler for bash.sh/ops"
fi
command_not_found_handler() {
	local command_not_found_handler_cmd="$1" && shift # a args=()
	local command_not_found_handler_arg=("$@")
	local command_not_found_handler_processed=0

	if (($DEBUG)); then
		dbg "  ..[command_not_found_handler] $command_not_found_handler_cmd + "
		for it in "${command_not_found_handler_arg[@]}"; do dbg "  ..[command_not_found_handler] --cmd-not-found-handler-- $it"; done
	fi

	_bash_sh_lazy_try_source_in() {
		local dx="$1" f ff f1 f2
		if [ -d $dx ]; then
			f="$dx/$command_not_found_handler_cmd.sh"
			if not_in_array $f $lazy_loaded; then
				dbg "    try loading $f ..."
				f1="$dx/${command_not_found_handler_cmd//_/-}.sh"
				f2="$dx/${command_not_found_handler_cmd//-/_}.sh"
				for ff in "$f" "${f%.sh}-lazy.sh" "$f1" "${f1%.sh}-lazy.sh" "$f2" "${f2%.sh}_lazy.sh"; do
					if [[ "$command_not_found_handler_processed" != "1" ]]; then
						dbg "  ...: testing $ff ..."
						if [ -f "$ff" ]; then
							source $ff && dbg "  yes: $ff" && command_not_found_handler_processed=1
						fi
					fi
				done
				if (($command_not_found_handler_processed)); then
					lazy_loaded+=($f)
					"$command_not_found_handler_cmd" "${command_not_found_handler_arg[@]}"
				fi
			fi
		fi
	}

	local dir dx osid="$(osid)" pmid="$(pmid)" bashshdir="$(dirname $BASH_SH)"
	dbg "bashshdir = $bashshdir"
	# try loading the lazied version of a command from these standard locations
	for dir in $HOME/.local/bin $HOME/bin "$bashshdir" /opt/bin /opt/local/bin $HOME/hack/bin $HOME/.r2env/bin; do
		if ! (($command_not_found_handler_processed)); then
			for dx in "$dir/.zsh/lazy" "$dir/ops.d/lazy"; do
				if [ -d $dx ]; then
					dbg "lazy-loader [1st]: dir: $dx, cmd: $command_not_found_handler_cmd, args: ${command_not_found_handler_arg[@]}"
					_bash_sh_lazy_try_source_in "$dx"
				fi
			done
		fi
	done

	if ! (($command_not_found_handler_processed)); then
		dbg "CD/1: $CD"
		# and if not found, loading it from bash.sh/ops.d/.../lazy/ folders
		for dir in "$CD/ops.d" "$CD/ops.d/$osid" "$CD/opd.d/$pmid"; do
			if ! (($command_not_found_handler_processed)); then
				local dx="$dir/lazy"
				if [ -d $dx ]; then
					dbg "lazy-loader [2nd]: dir: $dx, cmd: $command_not_found_handler_cmd, args: ${command_not_found_handler_arg[@]}"
					_bash_sh_lazy_try_source_in "$dx"
				fi
			fi
		done
	fi

	# todo: ~/.oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh

	if (($command_not_found_handler_processed)); then
		return 0
	else
		err "COMMAND NOT FOUND: You tried to run '$command_not_found_handler_cmd' with args '${command_not_found_handler_arg[@]}'."
		if [ -x /usr/bin/python3 ]; then
			if [ -x /usr/bin/command-not-found ]; then
				/usr/bin/command-not-found "${command_not_found_handler_cmd}" $(pmid) || :
				return 128
			elif [ -x /usr/lib/command-not-found ]; then
				/usr/lib/command-not-found -- "${command_not_found_handler_cmd}" || :
				return 129
			fi
		fi
		return 127
	fi
}
# for bash
#    `declare -f -p command_not_found_handle` to show it
#    or: typeset -f command_not_found_handle
#    or: (shopt -s extdebug; declare -F command_not_found_handle)
command_not_found_handle() {
	command_not_found_handler "$@"
	# # if the command-not-found package is installed, use it
	# # if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	# # function command_not_found_handle {
	# # check because c-n-f could've been removed in the meantime
	# if [ -x /usr/lib/command-not-found ]; then
	# 	/usr/lib/command-not-found -- "$1"
	# 	return $?
	# elif [ -x /usr/share/command-not-found/command-not-found ]; then
	# 	/usr/share/command-not-found/command-not-found -- "$1"
	# 	return $?
	# elif [ -x /usr/bin/command-not-found ]; then
	# 	/usr/bin/command-not-found "${command_not_found_handler_cmd}" $(pmid) || :
	# 	return 128
	# elif [ -x /usr/lib/command-not-found ]; then
	# 	/usr/lib/command-not-found -- "${command_not_found_handler_cmd}" || :
	# 	return 129
	# else
	# 	printf "%s: command not found\n" "$1" >&2
	# 	return 127
	# fi
	# # }
	# # fi
}
