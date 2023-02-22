#
# You may add more commands/functions here.
#

# 'dns' is a sample entry of a hierarchical command.
# It would forward the request to dns-ops.sh (or dns_ops.sh) in lazy folder
# by handling by lazy-loader.
#
dns() { dns_ops "$@"; }

# echo -e "\n\nmore-darwin-only.sh loaded\n" >>/tmp/sourced.list
