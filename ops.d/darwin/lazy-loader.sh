# for zsh
lazy_loaded=()
function command_not_found_handler() {
	local f dir processed=0 cmd=$1 && shift
	for dir in $HOME/.local/bin $HOME/bin /opt/bin /opt/local/bin $HOME/hack/bin $HOME/.r2env/bin; do
		local dx="$dir/.zsh/lazy"
		dbg "dx: $dx"
		if [ -d $dx ]; then
			f="$dx/$cmd.sh"
			if not_in_array $f $kazy_loaded; then
				if [ -f "$f" ]; then
					source $f && dbg "yes: $f" && processed=1
					lazy_loaded+=($f)
					eval $cmd $@
				fi
			fi
		fi
	done
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
