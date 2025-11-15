#
# You may add more commands/functions here.
#

ask_yesno() {
	while true; do
		read -p "Do you want to continue? (y/n): " yesno
		case $yesno in
		[Yy]*)
			echo "You chose Yes. Proceeding..."
			true
			;;
		[Nn]*)
			echo "You chose No. Exiting."
			false
			;;
		*) echo "Invalid input. Please answer 'y' or 'n'." ;;
		esac
	done
}

ask_yesno_timeout() {
	local timeout="${1:-10}"
	local msg="${2:-Do you want to continue? (Y/n): }"
	echo "Please enter Y or N within $timeout seconds:"
	read -t $timeout -p "$msg" yesno

	if [ $? -eq 0 ]; then
		# User entered input within the timeout
		case $yesno in
		[Yy]*)
			echo "You chose Yes. Proceeding..."
			true
			;;
		[Nn]*)
			echo "You chose No. Exiting."
			false
			;;
		*) echo "Invalid input. Please answer 'y' or 'n'." ;;
		esac
	else
		# Timeout occurred or read failed for another reason
		true
	fi
}
