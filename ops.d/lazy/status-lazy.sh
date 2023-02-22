status_lazy() {
	status_entry() { dbg "fn_name: $(fn_name), arg: $@" && commander $(strip_r $(fn_name) _entry) "$@"; }
	status_usage() {
		cat <<-EOF
			Usage: $0 $self <sub-command> [...]

			Sub-commands:
			  env                             prints env / env-check / check-env

		EOF
	}

	status_env() { check_env && debug_info; } # debug_info defined in bash.config
	status_rpad() {                           # a dummy subcommand for testing
		dbg "running in try_rpad"
		rpad 32 - "something" && echo END
		rpad 32 - "yes" && echo END
		rpad 32 - 'Some file' && echo '723 bytes'
	}

	dbg "status_lazy: $@"
	status_entry "$@"
}

check_env() {
	cat <<-EOC
		############### Checks
		        centos: $(if_centos && echo Y)
		        ubuntu: $(if_ubuntu && echo Y)
		           mac: $(if_mac && echo Y)
		       vagrant: $(if_vagrant && echo Y)

		        aliyun: $(if_aliyun && echo Y)
		    aliyun vpc: $(if_aliyun_vpc && echo Y)
		           aws: $(if_aws && echo Y)
		        aws_cn: $(if_aws_cn && echo Y)
		        aws_us: $(if_aws_us && echo Y)
		 aws_linux_ami: $(if_aws_linux_ami && echo Y)
		        qcloud: $(if_qcloud && echo Y)
	EOC
}
alias check-env='check_env'
