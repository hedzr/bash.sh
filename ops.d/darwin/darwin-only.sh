cat <<-EOF >>/tmp/sourced.list



	----------------- $(date) ---- .zshenv >> bash.sh -----------------
	>> PATH.BEGIN:  $PATH
	>> path_helper: $(/usr/libexec/path_helper -s)
	>> CD:          $CD
	>> SCRIPT:      $SCRIPT

EOF

BSH_OS=darwin

#
#
#
if is_zsh; then
	dbg "ZSH_EVAL_CONTEXT: $ZSH_EVAL_CONTEXT"
	dbg "in_vscode: $(in_vscode && echo Y || echo .), in_jetbrains: $(in_jetbrains && echo Y || echo .)"
	dbg "in_wsl: $(in_wsl && echo Y || echo .)"
	dbg "stack: ${funcstack[@]}"
	echo

	local dir dir_saved f
	# $HOME/.rvm/bin $HOME/.r2env/bin
	for dir in /opt/local/bin /opt/bin $HOME/bin $HOME/.local/bin $HOME/go/bin $HOME/hack/bin; do
		[ -d $dir ] && {
			tip ".zshenv: checking $dir ..." >>/tmp/sourced.list
			try_prepend_path_ex "$dir"
			tip "   PATH: $PATH" >>/tmp/sourced.list
			# load .zsh/.zsh.*.sh from $dir and source into current zsh environment...
			# for example:
			#    ~/.local/bin/.zsh/.zsh.aliases.sh
			#    ~/.local/bin/.zsh/.zsh.pathes.sh
			#    ~/.local/bin/.zsh/.zsh.tools.sh
			dir_saved="$dir"
			if test -n "$(find $dir -maxdepth 1 -name '.zsh.*.sh' -print -quit)"; then
				for f in $dir/.zsh.*.sh; do source $f && echo "  sourced: $f" >>/tmp/sourced.list; done
				dir="$dir_saved"
			fi
			[ -d $dir/.zsh ] && {
				if test -n "$(find $dir/.zsh -maxdepth 1 -name '*.sh' -print -quit)"; then
					for f in $dir/.zsh/*.sh; do source $f && echo "  sourced .zsh/*: $f" >>/tmp/sourced.list; done
					dir="$dir_saved"
				fi
			}
		}
	done
	# try_append_path $VULS_HOME/bin $PY_USER_BIN $FLUTTER_HOME/bin
	echo '' >>/tmp/sourced.list
	# [ -f $HOME/work/bash.work/00-dot/docker-functions ] && source $HOME/work/bash.work/00-dot/docker-functions
	export PATH
	echo "   >> PATH exported: $PATH" >>/tmp/sourced.list
	unset dir f
fi
