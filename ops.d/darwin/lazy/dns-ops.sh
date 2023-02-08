dns_ops() {
	local DNS_SERVER_KEY="${DNS_SERVER_KEY:-foreman:cWzWNjwEunNvojvvk/W86A==}" # a sample key here, you should replace it with your own.

	dns_entry() { commander $(strip_r $(fn_name) _entry) "$@"; }
	dns_usage() {
		cat <<-EOF
			Usage: $0 $self <sub-command> [...]
			Sub-commands:
			  ls [--all|-a|--cname|--txt|--one|-1] [string]   list all/most-of-all/generics matched dns-records
			  dump                    [RESERVED] dump dns-records [just for dns01]
				modify                  Modify ...
			  nsupdate                [DNS] [DYN] [MODIFY]
			  fix_nameservers         [ali] general fix nameservers, step 1
			  vpc_fix                 [ali] for VPC envir
			  profile                 [ali] make a query perf test and report
			  check                   [ali] check dns query is ok [version 1]
			  check_2                 [ali] check dns query is ok [version 2]
			  check_resolv_conf       [ali] check resolv.conf is right

			Examples:
			  $ ops dns ls          # just print the pyhsical ECS' A records
			  $ ops dns ls --all
			  $ ops dns ls --cname
			  $ ops dns ls --txt
			  $ ops dns ls sw0
			  $ ops dns nsupdate add sw0ttt00 10.0.24.30
			  $ ops dns nsupdate del sw0ttt00
			  $ ops dns nsupdate add mongo cname mgo.ops.local
			  $ ops dns nsupdate del mongo cname

		EOF
	}

	dns_check() {
		echo "dns check"
	}
	dns_check_2() {
		echo "dns check 2"
	}

	dns_ls() { dns_list "$@"; }

	dns_dump() {
		echo dump dns...
		rndc dumpdb -zones
		cat /var/named/data/cache-dump.db
	}
	dns_dump_hosts() {
		host -l ops.local # list all hosts of *.ops.local
	}

	dns_modify() {
		rndc freeze ops.local

		# TODO: (edit example.com zonefile)

		rndc reload ops.local
		rndc thaw ops.local
	}

	# sub of sub-commands
	dns_nsupdate() { dns_nsupdate_entry "$@"; }
	dns_nsupdate_entry() { commander $(strip_r $(fn_name) _entry) "$@"; }
	dns_nsupdate_usage() {
		cat <<-EOF
			Usage: $0 $self <sub-command> [...]
			Sub-commands:
			  add <hostname> <ip>            [DYN] Add one host (A) record
			  add <hostname> cname <text>    [DYN] Add host CNAME record
			  add <hostname> txt <text>      [DYN] Add host TXT record
			  del <hostname> [<ip>]          [DYN] Delete one host (A) record
			  del <hostname> cname           [DYN] Delete host CNAME record
			  del <hostname> txt             [DYN] Delete host TXT record

			Examples:
			  $ ops dns nsupdate add sw0ttt00 10.0.24.30
			  $ ops dns nsupdate add sw0ttt00 cname sw0demo01
			  $ ops dns nsupdate add sw0ttt00 txt "phy;just a sample;"
			  $ ops dns nsupdate del sw0ttt00
			  $ ops dns nsupdate add mongo cname mgo.ops.local
			  $ ops dns nsupdate del mongo cname

		EOF
	}
	# dns_nsupdate_add() { echo "$(fn_name) run."; }
	# dns_nsupdate_del() { echo "$(fn_name) run."; }

	dns_vpc_fix() {
		if_aliyun && if_aliyun_vpc &&
			[ -f /lib/resolvconf/list-records ] &&
			[ ! -f /lib/resolvconf/list-records.bak ] &&
			perl -0777 -i.bak -pe 's#s \"\$FLNM\" \] \&\& echo#s "\$FLNM" ] && \[ "\$FLNM" != "eth0.dhclient" ] && echo#' /lib/resolvconf/list-records

		RUN_DIR=/run/resolvconf
		ENABLE_UPDATES_FLAGFILE="${RUN_DIR}/enable-updates"
		POSTPONED_UPDATE_FLAGFILE="${RUN_DIR}/postponed-update"

		sudo resolvconf --enable-updates
	}
	dns_profile() { :; }
	dns_check_resolv_conf() { :; }

	# sub of sub-commands
	# dns_fix()        { dns_entry "$@"; }
	dns_fix_entry() { commander $(strip_r $(fn_name) _entry) "$@"; }
	dns_fix_usage() {
		cat <<-EOF
			Usage: $0 $self <sub-command> [...]
			Sub-commands:
			  nameservers             [ali] general fix nameservers, step 1
			  resolv_conf             [ali] for VPC envir

			Examples:
			  $ ops dns fix nameservers
			  $ ops dns fix resolv_conf

		EOF
	}
	dns_fix_nameservers() { echo dns_fix_nameservers; }
	dns_fix_resolv_conf() { echo dns_fix_resolv_conf; }

	dns_entry "$@"
}
alias dns-ops=dns_ops

#

#

dns_list() {
	case $1 in
	--all | -a)
		shift
		dns_list_all $*
		;;
	--cname | -c)
		shift
		dns_list_all "#CNAME#" $*
		;;
	--txt | -t)
		shift
		dns_list_all "#TXT#" $*
		;;
	--one | -1)
		shift
		dns_list_one $*
		;;
	*) dns_list_one $* ;; # |grep -vP 'cs\d+|p[as]\d+|puppet\-master'; ;;
	esac
}
dns_list_all() {
	local F="${1:-#A#CNAME#TXT#__}"
	echo "$F" | grep -q "#A#" &&
		/usr/bin/host -l ops.local | grep ' has address ' | awk '{print $1,$4;}'
	echo "$F" | grep -q "#TXT#" &&
		/usr/bin/host -t TXT -l ops.local | awk '{print $1,"TXT",$4;}'
	echo "$F" | grep -q "#CNAME#" >/ &&
		/usr/bin/host -t CNAME -l ops.local | awk '{print $1,"CNAME",$6;}'
}
dns_list_one() {
	# dig +multiline ops.local axfr
	# host -l ops.local | tail --lines=+2 | awk '{print $1,$4}' > /tmp/dns-records
	sudo touch /tmp/dns-records{,-1,-2} && sudo chmod a+x /tmp/dns-records*
	/usr/bin/host -l ops.local | grep ' has address ' | awk '{print $1,$4;}' | sort -u >/tmp/dns-records-2
	#\host -l -t TXT ops.local
	#echo ""
	#alias host
	# /usr/bin/host -t TXT -l ops.local
	eval '/usr/bin/host -t TXT -l ops.local' | grep -i 'phy;' | awk '{print $1,$4;}' | sort -u >/tmp/dns-records-1
	join -j 1 -o 2.1,1.2,2.2 /tmp/dns-records-2 /tmp/dns-records-1 2>/dev/null 1>/tmp/dns-records
	if [ $# -eq 0 ]; then
		cat /tmp/dns-records
	else
		grep -Pi "$@" /tmp/dns-records
	fi
}

#

dns_nsupdate_del() {
	#$gw $ip $mask $subnet
	#local ip=$2
	#local mask=$3
	#local subnet=$4
	#local gw=$1
	local x=$(hostname -f)
	local hn=${1:-$x}
	hn=${hn%.ops.local}
	local fqdn="$hn.ops.local"
	local iptail=${2:-}
	if [ "$iptail" != "" ]; then
		if [ "$iptail" == "cname" ]; then
			:
		elif [ "$iptail" == "txt" ]; then
			:
		elif [ "$iptail" == "srv" ]; then
			:
		else
			iptail=" a $iptail"
		fi
	fi

	nsupdate -y "$DNS_SERVER_KEY" -dv <<-EOF
		server ns1.ops.local
		update delete $fqdn. $iptail
		show
		send
		quit
	EOF
	echo "####\n#### querying dns for $fqdn ...\n####"
	dig $fqdn
}

dns_nsupdate_add() {
	#$hn $ip            : Add A
	#$hn cname xxxx     : Add CNAME

	local x=$(hostname -f)
	local ADDtail=$2
	local hn=${1:-$x}
	hn=${hn%.ops.local}
	local fqdn="$hn.ops.local"

	if [ "$ADDtail" == "txt" ]; then
		local desc=${3:-}
		ADDtail="${fqdn}.   300 IN TXT \"$3\""
		nsupdate -y "$DNS_SERVER_KEY" -dv <<-EOF
			server ns1.ops.local
			update del ${fqdn}. txt
			update add ${ADDtail}
			show
			send
			quit
		EOF

	elif [ "$ADDtail" == "srv" ]; then
		:

	elif [ "$ADDtail" == "cname" ]; then
		ADDtail="${fqdn}.   300 cname $3."

		nsupdate -y "$DNS_SERVER_KEY" -dv <<-EOF
			server ns1.ops.local
			update del ${fqdn}. cname
			update add ${ADDtail}
			show
			send
			quit
		EOF

	else
		local ip=$2
		local desc=${3:-phy;}
		local ip_rev=$(rev_ip $ip)
		echo -e "####\n#### sending ns updates for $fqdn (ip: $ip, rev: $ip_rev) ...\n####"
		ADDtail="${fqdn}.   300 A ${ip}"

		nsupdate -y "$DNS_SERVER_KEY" -dv <<-EOF
			server ns1.ops.local
			update add ${fqdn}.   300 A ${ip}
			update add ${fqdn}.   300 TXT "$desc"
			show
			send
			update add ${ip_rev}in-addr.arpa 300 ptr ${fqdn}.
			show
			send
			quit
		EOF
		echo "####\n#### querying dns for $fqdn ...\n####"
		dig $fqdn
		echo "####\n#### querying dns for $ip ...\n####"
		dig -x $ip
	fi
}
