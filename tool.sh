#!/usr/bin/env bash
# -*- mode: bash; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: t-*-
# vi: set ft=bash noet ci pi sts=0 sw=2 ts=2:
# st:
#
#

# ----------------------------------------------

ports() {
	local SUDO=${SUDO:-sudo}
	[ "$(id -u)" = "0" ] && SUDO=
	if [[ $# -eq 0 ]]; then
		eval $SUDO lsof -Pni | grep -E "LISTEN|UDP"
	else
		local p='' i
		for i in "$@"; do
			if [[ "$i" -eq "$i" ]]; then
				p="$p -i :$i"
			else
				p="$p -i $i"
			fi
		done
		eval $SUDO lsof -Pn $p
	fi
}
#function ports () { open-ports $*; }

# ----------------------------------------------

wan_ip() { host myip.opendns.com resolver1.opendns.com | tail -1 | awk '{print $NF;}'; }
if is_darwin; then
	wifi_ip() { ipconfig getifaddr en0; }
	lan_ip() { ipconfig getifaddr en1; }
	local_ip() { ipconfig getifaddr en1 || ipconfig getifaddr en0; }
else
	wifi_ip() { hostname -I | cut -d' ' -f1; }
	lan_ip() { hostname -I | awk '{print $1}'; }
	local_ip() { hostname -I | awk '{print $1}'; }
	# wan_ip()   { ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'; }
fi

# To find the wan ip:
#    https://stackoverflow.com/questions/21336126/linux-bash-script-to-extract-ip-address
#    https://www.cyberciti.biz/faq/how-to-find-my-public-ip-address-from-command-line-on-a-linux/
#
# dig +short myip.opendns.com @resolver1.opendns.com
# dig TXT +short o-o.myaddr.l.google.com @ns1.google.com
# dig +short txt ch whoami.cloudflare @1.0.0.1
# dig -6 TXT +short o-o.myaddr.l.google.com @ns1.google.com  # find ipv6 on linux
#
# host myip.opendns.com resolver1.opendns.com
# dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}'
#
# ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'
# ip route get 8.8.8.8 | awk 'match($0,/src (\S*)/,a)&&$0=a[1]'
# ip route get 8.8.8.8 | awk '{for(i=1;i<=NF;i++)if($i~/src/)$0=$(i+1)}NR==1'
#
# ip route get 8.8.8.8 | sed -E 's/.*src (\S+) .*/\1/;t;d'
# ip route get 8.8.8.8 | sed 's/.*src \([^ ]*\).*/\1/;t;d'
# ip route get 8.8.8.8 | sed  -nE '1{s/.*?src (\S+) .*/\1/;p}'
#
# ip route get 8.8.8.8 | grep -oP 'src \K[^ ]+'

# ----------------------------------------------

proxy_set() {
	local onoff=${1:-usage}
	if is_darwin; then
		local pip=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
	else
		local pip=$(hostname -I | awk '{print $1}')
	fi
	local link=${PROXY_LINK:-http://$pip:7890}
	proxy_print_status() {
		[ "$http_proxy" != "" ] && echo "http_proxy=$http_proxy"
		[ "$HTTP_PROXY" != "" ] && echo "HTTP_PROXY=$HTTP_PROXY"
		[ "$https_proxy" != "" ] && echo "https_proxy=$https_proxy"
		[ "$HTTPS_PROXY" != "" ] && echo "HTTPS_PROXY=$HTTPS_PROXY"
		[ "$all_proxy" != "" ] && echo "all_proxy=$all_proxy"
		[ "$ALL_PROXY" != "" ] && echo "ALL_PROXY=$ALL_PROXY"
	}
	proxy_set_off() {
		unset all_proxy ALL_PROXY http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
	}
	proxy_set_on() {
		export http_proxy=$link
		export https_proxy=$http_proxy HTTPS_PROXY=$http_proxy HTTP_PROXY=$http_proxy all_proxy=$http_proxy ALL_PROXY=$http_proxy
	}
	proxy_set_invoke() {
		# for better compatibilities under macOS we assumed a child shell for cleanup the envvars.
		# but its can be simplify to these following:
		# proxy_set_on && eval "$@" && proxy_set_off
		bash -c "
    set -e
    proxy_set_off() {
      unset all_proxy ALL_PROXY http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    }
    proxy_set_on() {
      export http_proxy=$link
      export https_proxy=\$http_proxy HTTPS_PROXY=\$http_proxy HTTP_PROXY=\$http_proxy all_proxy=\$http_proxy ALL_PROXY=\$http_proxy
    }
    trap 'proxy_set_off' EXIT ERR
    proxy_set_on
    $*
    "
	}
	case $onoff in
	on | ON | 1 | yes | ok | enable | enabled | open | allow)
		proxy_set_on
		echo 'HTTP Proxy on (http)'
		;;
	off | OFF | 0 | no | bad | disable | disabled | close | disallow | deny)
		proxy_set_off
		echo 'HTTP Proxy off (http)'
		;;
	status | st)
		proxy_print_status
		;;
	usage | help | info)
		echo 'Usage: proxy_set on|off|enable|disable|allow|deny|status'
		echo 'Or run proxy_set just like "tsock": proxy_set curl -iL https://google.com/'
		echo 'Type "proxy_set help" for more information.'
		proxy_print_status
		;;
	*)
		proxy_set_invoke "$@"
		;;
	esac
}

#alias proxy_set="export http_proxy=socks5://127.0.0.1:1081; export https_proxy=$http_proxy https_proxy=$http_proxy HTTPS_PROXY=$http_proxy; echo 'HTTP Proxy on (sock5)';"
#alias proxy_unset="unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; echo 'HTTP Proxy off (sock5)';"
#alias proxy_set_http="export http_proxy=http://127.0.0.1:8001; export https_proxy=$http_proxy https_proxy=$http_proxy HTTPS_PROXY=$http_proxy; echo 'HTTP Proxy on (http)';"
#alias proxy_unset_http="unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; echo 'HTTP Proxy off (http)';"
#alias proxy_set_all="export all_proxy=http://127.0.0.1:8001; echo 'HTTP Proxy on (all-proxy)';"
#alias proxy_unset_all="unset all_proxy http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; echo 'HTTP Proxy off (all-proxy)';"
