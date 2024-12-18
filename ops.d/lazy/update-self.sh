#!/bin/bash

function self_download() {
	if [ -z $# ]; then
		false
	elif [ $# -gt 1 ]; then
		echo "try"
		for file in $*; do
			self_download $file
		done
	else
		local context="$1"
		local cdir=$(dirname $context)
		local cname=$(basename $context)
		if [[ $context != */* ]]; then
			cdir="."
			cname=$context
		fi
		printf "#### Downloading %48s   todir: %s\n" "$context..." "$INSTALL_TARGET/$cdir"
		[ ! -d "$INSTALL_TARGET/$cdir" ] && mkdir -p "$INSTALL_TARGET/$cdir"
		#curl -sSL https://ops.hedzr.net/bash.sh/get/$context -o $INSTALL_TARGET/$cdir/$cname
		wget $Q -c --show-progress $URL_BASE/$context -O "$INSTALL_TARGET/$cdir/$cname"
		[ "$N" == "" ] && N="$INSTALL_TARGET/$cdir/$cname"
	fi
}

try_append_path() {
	local dir
	for dir in "$@"; do [ -d "$dir" ] && [[ $PATH: != *$dir:* ]] && PATH="$PATH:$dir" || :; done
}

funiqueappend() {
	local file="$1" && shift && local regex="$1" && shift && local text="$@"
	while read line; do
		text="$text"$'\n'"$line"
	done
	echo "checking '$regex' in file '$file'..."
	grep -qE "$regex" $file || {
		echo "$text" | $SUDO tee -a $file 1>/dev/null
	}
}

download_others() {
	local f tgt="${1:-$INSTALL_TARGET}"
	if ((SHORT)); then
		true
	else
		for f in import-array-cmds.sh \
			import-try-append-path.sh \
			import-ver-cmds.sh \
			lazied-functions.sh \
			lazy-loader.sh \
			more.sh; do
			self_download "ops.d/$f"
		done

		for f in apt-only.sh; do
			self_download "ops.d/apt/$f"
		done

		for f in darwin-only.sh more-darwin-only.sh; do
			self_download "ops.d/darwin/$f"
		done

		for f in debian-only.sh; do
			self_download "ops.d/debian/$f"
		done

		for f in dns-lazy.sh status-lazy.sh update-self.sh; do
			self_download "ops.d/lazy/$f"
		done

		for f in suse-only.sh; do
			self_download "ops.d/opensuse-leap/$f"
		done

		for f in ubuntu-only.sh; do
			self_download "ops.d/unubtu/$f"
		done

		for f in zypper-only.sh; do
			self_download "ops.d/zypp/$f"
		done

		for f in after.sh.sample; do
			self_download "$f"
		done
		mv "$tgt/after.sh.sample" "$tgt/after.sh"
	fi
}

install_myself() {
	#
	# install now:
	#
	echo "Install....$0 $@"
	local OPS_NAME="${OPS_NAME:-bash.sh}"
	local URL_BASE="${OPS_URL_BASE:-https://github.com/hedzr/$OPS_NAME/raw/refs/heads/master}"
	local INSTALL_PREFIX="${INSTALL_TARGET:-$HOME/.local/bin}"
	local INSTALL_TARGET="$INSTALL_PREFIX/bash.sh"
	local N=""
	local VERBOSE="${VERBOSE:-0}"
	local Q="-q" # for wget
	((VERBOSE)) && Q=""
	local SHORT="${SHORT:-0}" # just download main file

	self_download "bash.config" && {
		try_append_path "$INSTALL_PREFIX"
		chmod +x "$INSTALL_TARGET/bash.config"
		ln -sf "$INSTALL_TARGET/bash.config" "$INSTALL_PREFIX/ops" && chmod +x "$INSTALL_PREFIX/ops"

		download_others "$INSTALL_TARGET"

		local f=
		case $SHELL in
		*zsh)
			f="$HOME/.zshenv"
			;;
		*bash)
			f="$HOME/.bashrc"
			;;
		esac
		[ "$f" != "" ] && funiqueappend "$f" "### BASH.SH/.CONFIG END" <<-EOF

			### BASH.SH/.CONFIG ####################################
			{
				f="$INSTALL_TARGET/bash.config"
				[ -f "\$f" ] && DEBUG=1 VERBOSE=0 source "\$f" >>/tmp/sourced.list
				unset cool sleeping _my_main_do_sth main_do_sth dir f DEBUG VERBOSE currentShell
			}
			### BASH.SH/.CONFIG END ################################

		EOF
		unset f
	} && cat <<EOF

====================================================================
'$OPS_NAME' was installed as '$N'.

All folks, Enjoy it!

EOF
}
alias update-self=install_myself
alias upgrade-self=install_myself

#############
install_myself
