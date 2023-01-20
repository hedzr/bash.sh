# echo '0.2. done'
try_prepend_path() {
	local dir
	for dir in "$@"; do [ -d "$dir" ] && [[ $PATH: != *$dir:* ]] && PATH="$dir:$PATH"; done
}
try_prepend_path_ex() {
	local dir
	for dir in "$@"; do
		[ -d "$dir" ] && {
			[[ $PATH: = *$dir:* ]] && PATH="${PATH//$dir/}" && PATH="${PATH//::/:}"
			PATH="$dir:$PATH"
		}
	done
}
try_append_path() {
	local dir
	for dir in "$@"; do [ -d "$dir" ] && [[ $PATH: != *$dir:* ]] && PATH="$PATH:$dir"; done
}
