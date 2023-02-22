# for zsh
lazy_loaded=()
function command_not_found_handler() {
	local command_not_found_handler_cmd="$1" && shift # a args=()
	local command_not_found_handler_arg="$@"
	local command_not_found_handler_processed=0

	_bash_sh_lazy_try_source_in() {
		local dx="$1" f f1
		if [ -d $dx ]; then
			f="$dx/$command_not_found_handler_cmd.sh"
			if not_in_array $f $lazy_loaded; then
				if [ -f "$f" ]; then
					source $f && dbg "  yes: $f" && command_not_found_handler_processed=1
				else
					f1="${f//_/-}"
					if [ -f "$f1" ]; then
						source $f1 && dbg "  yes: $f ($f1 loaded)" && command_not_found_handler_processed=1
					fi
				fi
				if (($command_not_found_handler_processed)); then
					lazy_loaded+=($f)
					eval $command_not_found_handler_cmd "$command_not_found_handler_arg"
				fi
			fi
		fi
	}

	local dir osid="$(osid)" pmid="$(pmid)"
	# try loading the lazied version of a command from these standard locations
	for dir in $HOME/.local/bin $HOME/bin /opt/bin /opt/local/bin $HOME/hack/bin $HOME/.r2env/bin; do
		if ! (($command_not_found_handler_processed)); then
			local dx="$dir/.zsh/lazy"
			if [ -d $dx ]; then
				dbg "lazy-loader [1st]: dir: $dx, cmd: $command_not_found_handler_cmd, args: $command_not_found_handler_arg"
				_bash_sh_lazy_try_source_in "$dx"
			fi
		fi
	done

	dbg "CD: $CD"
	if ! (($command_not_found_handler_processed)); then
		# and if not found, loading it from bash.sh/ops.d/.../lazy/ folders
		for dir in "$CD/ops.d" "$CD/ops.d/$osid" "$CD/opd.d/$pmid"; do
			if ! (($command_not_found_handler_processed)); then
				local dx="$dir/lazy"
				if [ -d $dx ]; then
					dbg "lazy-loader [2nd]: dir: $dx, cmd: $command_not_found_handler_cmd, args: $command_not_found_handler_arg"
					_bash_sh_lazy_try_source_in "$dir/lazy"
				fi
			fi
		done
	fi

	if (($command_not_found_handler_processed)); then
		return 0
	else
		err "COMMAND NOT FOUND: You tried to run '$command_not_found_handler_cmd' with args '$command_not_found_handler_arg'"
		return 127
	fi
}
# for bash
command_not_found_handle() {
	command_not_found_handler "$@"
}
