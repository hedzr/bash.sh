in_array() {
	local find="$1"
	shift
	local arr=("$@")
	[[ ${arr[*]} =~ (^|[[:space:]])"$find"($|[[:space:]]) ]]
}

not_in_array() {
	local find="$1"
	shift
	local arr=("$@")
	[[ ! ${arr[*]} =~ (^|[[:space:]])"$find"($|[[:space:]]) ]]
}
