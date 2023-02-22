# `status`: prints status or stats for apps.
# `status env`: prints env checks and debug-informations
#
# e.g.: status docker, status apache, ...
status() { status_lazy "$@"; }
