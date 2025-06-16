# -*- mode: bash; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: t-*-
# vi: set ft=bash noet ci pi sts=0 sw=2 ts=2:
# st:
#
#

# for zsh
lazy_loaded=()
if fn_exists command_not_found_handler; then
	dbg "  ..  unset command_not_found_handler and define a new one for ops.sh/ops"
	unset command_not_found_handler
else
	dbg "  ..  define command_not_found_handler for ops.sh/ops"
fi
command_not_found_handler() {
	local command_not_found_handler_cmd="$1" && shift # a args=()
	local command_not_found_handler_arg="$@"
	local command_not_found_handler_processed=0

	dbg "  ..[command_not_found_handler] $command_not_found_handler_cmd + $command_not_found_handler_arg"

	_bash_sh_lazy_try_source_in() {
		local dx="$1" f f1
		if [ -d $dx ]; then
			f="$dx/$command_not_found_handler_cmd.sh"
			if not_in_array $f $lazy_loaded; then
				dbg "    try loading $f ..."
				if [ -f "$f" ]; then
					source $f && dbg "  yes: $f" && command_not_found_handler_processed=1
				elif [ -f "${f}-lazy.sh" ]; then
					source "${f}-lazy.sh" && dbg "  yes: $f" && command_not_found_handler_processed=1
				else
					f1="$dx/${command_not_found_handler_cmd//_/-}.sh"
					if [ -f "$f1" ]; then
						source $f1 && dbg "  yes: $f ($f1 loaded)" && command_not_found_handler_processed=1
					elif [ -f "${f1}-lazy.sh" ]; then
						source "${f1}-lazy.sh" && dbg "  yes: $f (${f1}-lazy.sh loaded)" && command_not_found_handler_processed=1
					else
						f1="$dx/${command_not_found_handler_cmd//-/_}.sh"
						if [ -f "$f1" ]; then
							source $f1 && dbg "  yes: $f ($f1 loaded)" && command_not_found_handler_processed=1
						fi
					fi
				fi
				if (($command_not_found_handler_processed)); then
					lazy_loaded+=($f)
					eval $command_not_found_handler_cmd "$command_not_found_handler_arg"
				fi
			fi
		fi
	}

	local dir dx osid="$(osid)" pmid="$(pmid)"
	# try loading the lazied version of a command from these standard locations
	for dir in $HOME/.local/bin $HOME/bin /opt/bin /opt/local/bin $HOME/hack/bin $HOME/.r2env/bin; do
		if ! (($command_not_found_handler_processed)); then
			for dx in "$dir/.zsh/lazy" "$dir/ops.d/lazy"; do
				if [ -d $dx ]; then
					dbg "lazy-loader [1st]: dir: $dx, cmd: $command_not_found_handler_cmd, args: $command_not_found_handler_arg"
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
					dbg "lazy-loader [2nd]: dir: $dx, cmd: $command_not_found_handler_cmd, args: $command_not_found_handler_arg"
					_bash_sh_lazy_try_source_in "$dx"
				fi
			fi
		done
	fi

	# todo: ~/.oh-my-zsh/plugins/command-not-found/command-not-found.plugin.zsh

	if (($command_not_found_handler_processed)); then
		return 0
	else
		err "COMMAND NOT FOUND: You tried to run '$command_not_found_handler_cmd' with args '$command_not_found_handler_arg'"
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
command_not_found_handle() {
	command_not_found_handler "$@"
}
