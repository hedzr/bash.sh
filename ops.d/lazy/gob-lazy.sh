# -*- mode: bash; c-basic-offset: 2; tab-width: 2; indent-tabs-mode: t-*-
# vi: set ft=bash noet ci pi sts=0 sw=2 ts=2:
# st:
#
#

gob_lazy() {
	gob_entry() { dbg "fn_name: $(fn_name), arg: $@" && commander $(strip_r $(fn_name) _entry) "$@"; }
	gob_usage() {
		cat <<-EOF
			Usage: $0 $self <sub-command> [...]

			Sub-commands:
			  color-table                   resize lvm vol and fs size (expand to 100%)
			  cmdr [subcmds]                cmdr subcmds
			  find-main                     find main packages
			  build-all                     build all main packages,
			                                loop for all platforms (darwin,linux,...riscv64)
			  cover                         coverage test
			  test [name]                   test or test for a case
			  bench                         benchmark test
			  lint                          lint
			  app-bundle-id                 find macOS app bundle id, eg: VSCodium
			  rpad                          test rpad()

			Examples:
			  $ gob cmdr push-all            # push all for all repos (cmdr-series.v2)
		EOF
	}

	gob_rpad() {
		dbg "running in try_rpad"
		rpad 32 - "something" && echo END
		rpad 32 - "yes" && echo END
		rpad 32 - 'Some file' && echo '723 bytes'
	}

	gob_color_table() { color_table_16m; }
	color_table_16m() {
		awk 'BEGIN{
    s="/\\/\\/\\/\\/\\"; s=s s s s s s s s;
    for (colnum = 0; colnum<77; colnum++) {
        r = 255-(colnum*255/76);
        g = (colnum*510/76);
        b = (colnum*255/76);
        if (g>255) g = 510-g;
        printf "\033[48;2;%d;%d;%dm", r,g,b;
        printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
        printf "%s\033[0m", substr(s,colnum+1,1);
    }
    printf "\n";
}'
	}

	gob_cmdr_entry() { commander $(strip_r $(fn_name) _entry) "$@"; }
	gob_cmdr_usage() {
		cat <<-"EOF"
			Usage: $0 $self <sub-command> [...]

			Sub-commands:
			  create-git-remotes <repo-name> [group-name]     cmdr-series: frama, codeberg, github
			  push-all                                        cmdr-series: push all for current repo
			  push-all-modules                                cmdr-series: push all for all repos

			Examples:
			  $ gob cmdr push-all
			    push all for all repos (cmdr-series.v2)
			  $ gob cmdr create-git-remotes mere1x merelab
			    create remotes to merelab/mere1x, for github, codeberg, and frama
		EOF
	}
	gob_cmdr_size() {
		__vms_reg
		du -sh "$HOME/.vagrant.d/boxes/"* | sort -rh | sed -re "s,$HOME,~,"
	}

	gob_cmdr_create_git_remotes() { cmdr_create_git_remotes "$@"; }
	cmdr_create_git_remotes() {
		local key repo="${1:-gsvc}" && (($#)) && shift
		local group="${1:-cmdr-series}" && (($#)) && shift
		local ghg="$group" && [ "$group" = 'cmdr-series' ] && ghg=hedzr || :
		local ghgroup="${1:-$ghg}" && (($#)) && shift || :
		for key in "github github.com ${ghgroup}" "frama framagit.org ${group}" "codeberg codeberg.org ${group}"; do
			eval "rr=($key)"
			tip "setting up remote repo / ${rr[1]} / ${rr[2]}"
			git remote add "${rr[1]}" "git@${rr[2]}:${rr[3]}/$repo.git" ||
				git remote set-url "${rr[1]}" "git@${rr[2]}:${rr[3]}/$repo.git"
		done
		echo
		git remote -v
	}
	gob_cmdr_push_all() { cmdr_push_all "$@"; }
	gob_cmdr_push_all_modules() { cmdr_push_all_modules "$@"; }
	cmdr_push_all() {
		# pushd ~work/godev/cmdr.v2/cmdr >/dev/null
		local repo
		for repo in github frama codeberg; do
			tip "pushing to remote repo '$repo'..."
			git push $repo --all && git push $repo --tags
		done
		# popd >/dev/null
	}
	cmdr_push_all_modules() {
		pushd ~work/godev/cmdr.v2/cmdr >/dev/null
		local repodir repo
		for repodir in ../{cmdr,cmdr.loaders,cmdr.addons,cmdr.tests,cmdr-docs,libs.is,libs.logg,libs.diff,libs.store}; do
			[ -d "$repodir" ] && cd "$repodir" && echo && tip "ENTERING $repodir ------------" && echo &&
				for repo in github frama codeberg; do
					tip "pushing to remote repo '$repo'..."
					git push $repo --all && git push $repo --tags
				done
		done
		cd ~work/godev/cmdr.work/cmdr-cli # ,go-template
		for repodir in ../../cmdr.work/{cmdr-cli,cmdr-go-starter,cmdr-templates}; do
			[ -d "$repodir" ] && cd "$repodir" && echo && tip "ENTERING $repodir ------------" && echo &&
				for repo in github frama codeberg; do
					tip "pushing to remote repo '$repo'..."
					git push $repo --all && git push $repo --tags
				done
		done
		popd >/dev/null
	}

	gob_find_main() {
		# 1. go list -f '{{.Main}} v{{.Version}} {{.Path}} {{.Dir}}' -m
		# 2.
		[ -f go.mod ] && {
			local mod
			# go list -f '{{.Dir}}' -m | tee /tmp/mod.list 1>/dev/null
			# for mod in $(cat /tmp/mod.list); do
			# 	tip "...checking module '$mod'..." 1>&2
			# 	if [ "$(pwd)" = "$mod" ]; then
			# 		go list -f '{{.Name}} {{.Dir}}' ./... | grep -Eo '^main[[:space:]]+(.*)' | awk '{print $2}'
			# 	elif [ "$mod" != "" ]; then
			# 		pushd "$mod" >/dev/null &&
			# 			go list -f '{{.Name}} {{.Dir}}' ./... | grep -Eo '^main[[:space:]]+(.*)' | awk '{print $2}' &&
			# 			popd >/dev/null
			# 	fi
			# done
			for mod in $(go list -f '{{.Dir}}' -m); do
				tip "...checking module '$mod'..." 1>&2
				if [ "$(pwd)" = "$mod" ]; then
					go mod tidy && go list -f '{{.Name}} {{.Dir}}' ./... | grep -Eo '^main[[:space:]]+(.*)' | awk '{print $2}'
				elif [ "$mod" != "" ]; then
					pushd "$mod" >/dev/null &&
						go mod tidy && go list -f '{{.Name}} {{.Dir}}' ./... | grep -Eo '^main[[:space:]]+(.*)' | awk '{print $2}' &&
						popd >/dev/null
				fi
			done
		}
	}
	gob_build_all() {
		local pkg="${1:-$(go_find_main | head -1)}" && (($#)) && shift
		for GOOS in darwin linux windows freebsd openbsd; do
			for GOARCH in amd64 arm64 riscv64 mips64; do
				go tool dist list | grep -qE "$GOOS/$GOARCH" &&
					tip "--- build for $GOOS/$GOARCH ---" &&
					GOOS=$GOOS GOARCH=$GOARCH go build -o ./bin/ $pkg "$@"
			done
		done
	}

	gob_cover() {
		local logdir=./logs
		go test ./... -v -race -cover -coverprofile=$logdir/coverage-cl.txt -covermode=atomic -test.short -vet=off 2>&1 | tee $logdir/cover-cl.log && echo "RET-CODE OF TESTING: $?"
	}
	# eg: go-test TestLogDefault
	# eg: go-test TestLogDefault ./slog/...
	gob_test() {
		local tname="$1" && (($#)) && shift
		local package="${1:-"./..."}" && (($#)) && shift
		if [[ $tname = "" ]]; then
			go test -v -test.v $package "$@" 2>&1 | tee -a ./logs/test.log
		else
			go test -v -test.v -test.run ^${tname}$ $package "$@" 2>&1 | tee ./logs/$tname.log
		fi
	}

	# go test -v -race $(go list ./...|grep -v /vendor/)
	# go test -v -race -coverprofile=coverage.txt ./...
	# go test -v -race -coverprofile=coverage.txt -covermode=atomic -timeout=20m ./... && go tool cover -html=coverage.txt -o cover.html && open cover.html
	# go test -v -race -test.run='^TestLeakyBucketLimiter$' ./leakybucket
	# go test -v -race -test.v -test.run='^TestLeakyBucketLimiter$' ./leakybucket
	# go test -v -test.v -test.run ^TestLogAllPredicates$ ./slog/...
	#
	# go test -v ./... -bench -benchmem -run ^$
	# go test -v ./... -bench -benchmem -memprofile mem.profile -run ^BenchSomething$
	#    pprof mem.profile
	#    (pprof) top 30
	#    (pprof) png
	#    (pprof) q

	# eg: go-bench
	# eg: go-bench ./...
	gob_bench() {
		local package="${1:-"./..."}" && (($#)) && shift
		go test -v $package -bench -benchmem -run ^$ "$@"
	}

	gob_lint() {
		local v1="${1:--v}" && (($#)) && shift
		$HOME/go/bin/golangci-lint run --fast --print-issued-lines=false --out-format=colored-line-number --issues-exit-code=0 $v1 "$@"
	}

	gob_app_bundle_id() {
		local APP="${1:-VSCodium}"
		local bundle=$(mdfind -onlyin / kMDItemKind==Application | grep -i "/$APP.app$" | head -1)
		defaults read "$bundle/Contents/Info" CFBundleIdentifier
	}

	# alias cmdr-push-all-modules=cmdr_push_all_modules \
	# 	git-push-all=cmdr_push_all \
	# 	git-create-remotes=cmdr_create_git_remotes \
	# 	go-find-main=go_find_main \
	# 	go-build-all=go_build_all \
	# 	go-test=go_test go-cover=go_cover go-bench=go_bench \
	# 	go-lint=golint \
	# 	app-bundle-id=app_bundle_id

	# set -x
	gob_entry "$@"
}
