# `status`: prints status or stats for apps.
# `status env`: prints env checks and debug-informations
#
# e.g.: status docker, status apache, ...
status() { status_lazy "$@"; }
dns() { dns_lazy "$@"; }

# to make it work, you need to unalias the omz version.
# There are lots of aliases for go command in oh-my-zsh
# golang plugin, including `gob` (=`go build`).
# so we have an instruction `unalias gob` injected at
# end of ~/.zshrc, then this command and its lazy version
# would work properly.
#
# to get the help, run `gob --help` and `gob cmdr --help`, ...
gob() { gob_lazy "$@"; }
