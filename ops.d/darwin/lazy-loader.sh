# for zsh
lazy_loaded=()
function command_not_found_handler() {
	local f f1 dir processed=0 cmd="$1" && shift # a args=()
	local osid="$(osid)" pmid="$(pmid)"

	try_source_in() {
		local dx="$1"
		if [ -d $dx ]; then
			f="$dx/$cmd.sh"
			if not_in_array $f $lazy_loaded; then
				if [ -f "$f" ]; then
					source $f && dbg "yes: $f" && processed=1
				else
					f1="${f//_/-}"
					if [ -f "$f1" ]; then
						source $f1 && dbg "yes: $f ($f1 loaded)" && processed=1
					fi
				fi
				if (($processed)); then
					lazy_loaded+=($f)
					eval $cmd "$@"
				fi
			fi
		fi
	}

	for dir in $HOME/.local/bin $HOME/bin /opt/bin /opt/local/bin $HOME/hack/bin $HOME/.r2env/bin; do
		if ! (($processed)); then
			local dx="$dir/.zsh/lazy"
			if [ -d $dx ]; then
				# dbg " dir: $dx, args: $*"
				try_source_in "$dx"
			fi
		fi
	done

	if ! (($processed)); then
		for dir in "$CD/ops.d" "$CD/ops.d/$osid" "$CD/opd.d/$pmid"; do
			if ! (($processed)); then
				if [ -d $dx ]; then
					try_source_in "$dir/lazy"
				fi
			fi
		done
	fi

	if (($processed)); then
		return 0
	else
		err "COMMAND NOT FOUND: You tried to run '$cmd' with args '$@'"
		return 127
	fi
}
# for bash
command_not_found_handle() {
	command_not_found_handler "$@"
}
