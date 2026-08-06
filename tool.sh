#!/usr/bin/env bash
# -*- mode: bash; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: t-*-
# vi: set ft=bash noet ci pi sts=0 sw=2 ts=2:
# st:
#
#

# ----------------------------------------------

# ports() {
# 	local SUDO="${SUDO:-sudo}"
# 	[ "$(id -u)" = "0" ] && SUDO=
# 	if [[ $# -eq 0 ]]; then
# 		eval $SUDO lsof -Pni | grep -E "LISTEN|UDP"
# 	else
# 		local p='' i
# 		for i in "$@"; do
# 			if [[ "$i" -eq "$i" ]]; then
# 				p="$p -i :$i"
# 			else
# 				p="$p -i $i"
# 			fi
# 		done
# 		eval $SUDO lsof -Pn $p
# 	fi
# }
#function ports () { open-ports $*; }
ports() {
	local SUDO="${SUDO:-sudo}" && [ "$(id -u)" = "0" ] && SUDO=
	# set -x
	if [ $# -eq 0 ]; then
		if which lsof >/dev/null; then
			eval $SUDO lsof -Pni | grep -E "LISTEN|UDP"
		elif which sockstat >/dev/null; then
			sockstat -l -64
		elif which netstat >/dev/null; then
			eval $SUDO netstat -tulpn | grep LISTEN
			# eval netstat -aLnW | grep -E "${p#|}" # for freebsd
		elif which ss >/dev/null; then
			# sudo ss -tulpn | grep LISTEN
			# sudo ss -tulw | grep LISTEN
			# ss -4 state listen
			# https://www.cyberciti.biz/tips/linux-investigate-sockets-network-connections.html
			eval $SUDO ss -tulwn | grep LISTEN
		else
			:
			# sudo nmap -sTU -O IP-address-Here
		fi
	else
		if which lsof >/dev/null; then
			local p='' i prog
			for i in "$@"; do
				if [[ "$i" =~ '^[0-9]+$' ]]; then
					p="$p -i :$i"
				else
					prog="$i"
				fi
			done
			debug echo "lsof -Pn $p, prog = ${prog//\//|}"
			[ "$p" != "" ] && tip "listing ports '$p' ..." && eval $SUDO lsof -Pn "$p" | grep -E "LISTEN|UDP" || :
			[ "$prog" != "" ] && tip "listing programs '${prog//\//|}' ..." && eval $SUDO lsof -Pni | grep -Ei "${prog//\//|}" | grep -v grep || :
		elif which sockstat >/dev/null; then
			local p='' i
			for i in "$@"; do
				if [[ "$i" -eq "$i" ]]; then
					p="$p,$i"
				else
					p="$p,$i"
				fi
			done
			sockstat -l -64 -p "${p#,}"
		elif which netstat >/dev/null; then
			local p='' i
			for i in "$@"; do
				if [[ "$i" -eq "$i" ]]; then
					p="$p|$i"
				else
					p="$p|$i"
				fi
			done
			eval $SUDO netstat -tulpn | grep LISTEN | grep -E "${p#|}"
			# eval netstat -aLnW | grep -E "${p#|}" # for freebsd
		elif which ss >/dev/null; then
			local p='' i
			for i in "$@"; do
				if [[ "$i" -eq "$i" ]]; then
					p="$p|:$i"
				else
					p="$p|:$i"
				fi
			done
			eval $SUDO ss -tulwn | grep LISTEN | grep -E "${p#|}"
		else
			:
			# sudo nmap -sTU -O IP-address-Here
		fi
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
	local port="${PORT:-7890}"
	local link="${PROXY_LINK:-http://$pip:$port}"

	clash_proxy_set() {
		sudo networksetup -setwebproxy "Wi-Fi" 127.0.0.1 "$port"
		sudo networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 "$port"
		sudo networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 "$port"
		sudo networksetup -setproxybypassdomains "Wi-Fi" '127.0.0.1,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,100.64.0.0/10,127.0.1.1,localhost,*.local,mbp14,loaye16,laoye16,*.test,169.254.0.0/16,224.0.0.0/4,240.0.0.0/4,*.cn,*.crashlytics.com,22os.com,jycode.com,anos.biz,swt.im,yekeke.com,163.com,sina.com.cn,bing.com,sohu.com,*.22os.com,*.jycode.com,*.anos.biz,*.swt.im,*.yekeke.com,*.163.com,*.sina.com.cn,*.bing.com,*.sohu.com,*.zxcs.cme,*.microsoft.com,timestamp.apple.com,sequoia.apple.com,*.siri.apple.com,*.ntp.org,timestamp.windows.com,<local>'
	}

	proxy_print_st() { proxy_print_status "$@"; }
	proxy_print_stat() { proxy_print_status "$@"; }
	proxy_print_stats() { proxy_print_status "$@"; }
	proxy_print_status() {
		tip "The environment variables are:"
		[ "$http_proxy" != "" ] && echo "http_proxy=$http_proxy"
		[ "$HTTP_PROXY" != "" ] && echo "HTTP_PROXY=$HTTP_PROXY"
		[ "$https_proxy" != "" ] && echo "https_proxy=$https_proxy"
		[ "$HTTPS_PROXY" != "" ] && echo "HTTPS_PROXY=$HTTPS_PROXY"
		[ "$all_proxy" != "" ] && echo "all_proxy=$all_proxy"
		[ "$ALL_PROXY" != "" ] && echo "ALL_PROXY=$ALL_PROXY"
		tip "The system proxy is:"
		networksetup -getwebproxy "Wi-Fi"
	}
	proxy_set_off() {
		unset all_proxy ALL_PROXY http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
	}
	proxy_set_on() {
		export http_proxy="$link"
		export https_proxy="$http_proxy" HTTPS_PROXY="$http_proxy" HTTP_PROXY="$http_proxy" all_proxy="$http_proxy" ALL_PROXY="$http_proxy"
	}
	proxy_set_tog() { proxy_set_toggle "$@"; }
	proxy_set_toggle() {
		if [ "$HTTP_PROXY" = "" ]; then
			proxy_set_on "$@"
		else
			proxy_set_off "$@"
		fi
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
      export http_proxy=\"$link\"
      export https_proxy=\"\$http_proxy\" HTTPS_PROXY=\"\$http_proxy\" HTTP_PROXY=\"\$http_proxy\" all_proxy=\"\$http_proxy\" ALL_PROXY=\"\$http_proxy\"
    }
    trap proxy_set_off EXIT ERR
    proxy_set_on
    $*
    "
	}
	case $onoff in
	on | ON | 1 | yes | ok | enable | enabled | open | allow)
		proxy_set_on "$@"
		echo 'HTTP Proxy on (http)'
		;;
	off | OFF | 0 | no | bad | disable | disabled | close | disallow | deny)
		proxy_set_off "$@"
		echo 'HTTP Proxy off (http)'
		;;
	toggle | tog | t) proxy_set_toggle "$@" ;;
	status | st | stat | stats)
		proxy_print_status "$@"
		;;
	clash)
		is_darwin && clash_proxy_set "$@" || :
		;;
	usage | help | info)
		printf "${clr_italic}Usage: ${clr_reset_all}${clr_bold}proxy_set on|off|enable|disable|allow|deny|status|toggle|tog${clr_reset_all}\n"
		printf "${clr_italic}Or run proxy_set just like "tsock": ${clr_reset_all}${clr_bold}proxy_set curl -iL https://google.com/${clr_reset_all}\n"
		printf "${clr_italic}Type ${clr_reset_all}\"${clr_bold}proxy_set help\" ${clr_italic}for more information.${clr_reset_all}\n"
		printf "${clr_italic}Use envvar if LAN ip not detected: ${clr_reset_all}${clr_bold}PROXY_LINK=http://xx.xx.xx.xx:xxxx proxy_set on${clr_reset_all}\n"
		echo
		printf "${clr_dim}For clash verge rev mac, here is a patch to enable it at system proxy settings:${clr_reset_all}\n"
		echo '  proxy_set clash'
		echo
		proxy_print_status "$@"
		;;
	*)
		proxy_set_invoke "$@"
		;;
	esac
}
alias proxy-set=proxy_set

#alias proxy_set="export http_proxy=socks5://127.0.0.1:1081; export https_proxy=$http_proxy https_proxy=$http_proxy HTTPS_PROXY=$http_proxy; echo 'HTTP Proxy on (sock5)';"
#alias proxy_unset="unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; echo 'HTTP Proxy off (sock5)';"
#alias proxy_set_http="export http_proxy=http://127.0.0.1:8001; export https_proxy=$http_proxy https_proxy=$http_proxy HTTPS_PROXY=$http_proxy; echo 'HTTP Proxy on (http)';"
#alias proxy_unset_http="unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; echo 'HTTP Proxy off (http)';"
#alias proxy_set_all="export all_proxy=http://127.0.0.1:8001; echo 'HTTP Proxy on (all-proxy)';"
#alias proxy_unset_all="unset all_proxy http_proxy https_proxy HTTP_PROXY HTTPS_PROXY; echo 'HTTP Proxy off (all-proxy)';"

zsh_theme_set() {
	local theme_name=${1:-af-magic}
	perl -i -pe "s/ZSH_THEME=\".+\"/ZSH_THEME=\"$theme_name\"/" ~/.zshrc
}

print_path() { print -rl $path; }
print_fpath() { print -rl $fpath; }
#alias qq=$HOME/hzw/golang-dev/src/github.com/hedzr/cmdr-examples/bin/flags_darwin_amd64
#alias zz=$HOME/hzw/golang-dev/src/github.com/hedzr/cmdr/bin/fluent
alias reset_zsh_autocomp='rm ~/.zcompdump*; compinit'
reload_zsh_autocomp() {
	local f
	f=(~/.zsh.autocomp/i/*(.))
	unfunction $f:t 2>/dev/null
	autoload -U $f:t
	# from: gotchas at https://www.dolthub.com/blog/2021-11-15-zsh-completions-with-subcommands/
}
reload_zsh_autocomp_full() {
	autoload -U compinit
	compinit
}
alias zsh.child='[ -f ~/.zcompdump ] && rm ~/.zcompdump*; zsh -i'
ll_zsh_comp() { ll ~/.zsh.autocomp/i/; }
find_zsh_autocomp_script() {
	local f=${1:-git}
	for d in $(print_fpath); do
		[ -d $d ] && echo "---- $d" && ll $d | grep "$f"
	done
}
ls_zsh_autocomp_script() {
	local f=${1:-git}
	for d in $(print_fpath); do
		[ -d $d ] && echo "---- $d" && ll $d
	done
}
