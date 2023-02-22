#
# You may add more commands/functions here.
#

# 'dns' is a sample entry of a hierarchical command.
# It would forward the request to dns-ops.sh (or dns_ops.sh) in lazy folder
# by handling by lazy-loader.
#
dns() { dns_ops "$@"; }

# `status`: prints status or stats for apps.
# `status env`: prints env checks and debug-informations
#
# e.g.: status docker, status apache, ...
status() { status_lazy "$@"; }

# echo -e "\n\nmore-darwin-only.sh loaded\n" >>/tmp/sourced.list
