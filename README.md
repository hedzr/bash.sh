# bash.sh

`bash.sh` is a starter template for shell developing.

File `bash.config` can be applied and sourced into your zshell environment directly. See [Import bash.config into your zsh env](#3-import-bashconfig-into-your-zsh-env).
Why? Because we will have a clean zsh initializing environment and many tools can be lazy-loaded now.

## History

- v20230206:
  - improved `pad`, added `pad3`
  - improved bash-lite.sh

- v20230126:
  - improved lazy-loader to load kebab case func and files
  - improved `commander()`

- [CHANGELOG](./CHANGELOG)

## Usages

### Command Line Options

```bash
# internal commands
$ ./bash.sh cool
$ ./bash.sh sleep

# see debug-info (environment checks)
$ DEBUG=1 ./bash.sh
$ ./bash.sh debug-info

# internal helpers
$ ./bash.sh 'is_root && echo Y'
$ sudo ./bash.sh 'is_root && echo Y'
$ sudo DEBUG=1 ./bash.sh 'is_root && echo y'

# at end of the execution
$ HAS_END=: ./bash.sh
$ HAS_END=false ./bash.sh
```

### Use It

#### 1. Simple

Copy [bash.sh](bash.sh) and rename as your main entry (such as: `mgr`), and go ahead.

> Modify `_my_main_do_sth()` as you want.

Example:

```bash
wget https://raw.githubusercontent.com/hedzr/bash.sh/master/bash.sh
mv bash.sh installsamba
DEBUG=1 ./installsamba
```

#### 2. Global

##### Use OLD `installer`: [~~**DEPRECATED**~~]

```bash
curl -sSL https://hedzr.com/bash/bash.sh/installer | sudo bash -s
```

> The old <https://hedzr.com/bash.sh/installer> has been obseleted.

~~`installer` will copy `bash.config` to `/usr/local/bin`~~.

##### Manually

Copy `bash.config` to `/usr/local/bin/` or anywhere, and `source` it from your script file:

Some examples [here](./examples/).

#### 3. Import `bash.config` into your zsh env

You may import `bash.config` into your local zshell environment. This brings a extensible structure to you: the bash.sh loader (in `darwin-only.sh`) will source in the scripts at these places (macOS only):

1. `/path/to/bash.sh/ops.d/*.sh`
2. `/path/to/bash.sh/ops.d/{darwin,windows,ubuntu,...}/*.sh`
3. `/path/to/bash.sh/ops.d/{brew,apt,dnf,yum,...}*.sh`
4. `$HOME/.local/bin/.zsh/*.sh`

Since we shipped `bash.sh` with `./ops.d/darwin/*.sh`, so the
features above will be available. As an extra feature, `Lazy loading`
machanism is available too. Just put your .sh tool
into this folder:

1. `$HOME/.local/bin/.zsh/lazy/`

It will be loaded and invoked on-demand.

> As a sample, you could save [`vm.sh`](https://gist.github.com/hedzr/ea2626fb290e5ca74687967d0d768cdb) into `~/.local/bin/.zsh`,
> and save [`vagrant_run.sh`](https://gist.github.com/hedzr/a24592879ac90239be6c8b1746feebd4) into `~/.local/bin/.zsh/lazy`,
> and run it:
>
> ```bash
> vm ls
> vm run u20s.local
> vm sizes
> ```
>
> function `vm` (in vm.sh) will be invoked directly, and
> function `vagrant_run` will be lazy-loaded and invoked
> implicitly.
>
> Do same action on [`vmware_run.sh`](https://gist.github.com/hedzr/956cb892069b0353f915b395a9504ebf).
>
> We have serveral posts in chinese to introduce `vm()` ([HERE](https://hedzr.com/devops/linux/manage-vms-from-command-line/)).

##### How?

Put these codes in your `$HOME/.zshenv`:

```bash
### BASH.SH/.CONFIG ####################################
{
  local dir f="/path/to/bash.sh/bash.config"
  [ -f "$f" ] && DEBUG=1 VERBOSE=0 source "$f" >>/tmp/sourced.list
  unset cool sleeping _my_main_do_sth main_do_sth dir f DEBUG VERBOSE
}
### BASH.SH/.CONFIG END ################################
```

It can be simplified to one-liner:

```bash
. "/path/to/bash.sh/bash.config" && unset cool sleeping _my_main_do_sth main_do_sth DEBUG VERBOSE
```

## Samples

![Sample](./_images/2018-02-22_12.30.11.png)

## Knives Document

### `in_debug`

in debug mode?

toggle environment variable `DEBUG` to switch between `normal_mode` and `debug_mode`.

```bash
is_debug && echo 'debug mode' || echo 'normal mode'
```

### `debug` $\*, `dbg`, `tip`, `err`

Prints string as darker text for debugging (if env var `DEBUG` == 1). In normal mode, the string message will be stripped.

```bash
debug I am buggy but you don't know
debug 'I am buggy but you don'''t know'
debug "I am buggy but you don't know"

dbg "debug line"

tip "A simple message to tip you something happened: $event"
err "Error occurred whlie executed the command line: $cmd '$@'"
```

- `tip` and `err` will always prints message.
- `err` will prints message to stderr device.
- `dbg` available on DEBUG=1, it's slight differant with `debug`

You may use the splitted version: `debug_begin` and `debug_end`:

```bash
if ((DEBUG)); then
  debug_begin
  cat /etc/os_release # this file will be printed with darker color.
  debug_end
fi
```

### `headline` $\*

print a hilight message string.

```bash
headline here is the hilighted title
```

### `is_bash` & `is_zsh`

check if running under bash/zsh interpretor or not

```bash
is_bash && echo 'in bash'
is_zsh && echo 'in zsh'
```

### `is_linux`, `is_darwin`

check if running in Linux/macOS shell.

```bash
is_linux && echo 'in linux'
is_darwin && grep -E 'LISTEN|UDP' somefile || grep -P 'LISTEN|UDP' somefile
```

> **UPDATED**
>
> More testers added:
> is_yum, is_dnf, is_apt,  
> is_debian_series, is_redhat_series,  
> is_debian, is_ubuntu, is_centod, is_fedora, is_redhat,  
> is_nix, ...

### `realpathx`

cross impl for linux `realpath`.

## Use `commander()` in your scripts

`commander` provides a multi-level subcommands skeleton for you.

Here is a example code fragment in an `ops`:

```bash
dns() {
 dns_entry() { commander $(strip_r $(fn_name) _entry) "$@"; }
 dns_usage() {
  cat <<-EOF
   Usage: $0 $self <sub-command> [...]
   Sub-commands:
     ls [--all|-a|--cname|--txt|--one|-1] [string]   list all/most-of-all/generics matched dns-records
     dump                    [RESERVED] dump dns-records [just for dns01]
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
     $ ops dns nsupdate-add sw0ttt00 10.0.24.30
     $ ops dns nsupdate-del sw0ttt00
     $ ops dns nsupdate-add mongo cname mgo.ops.local
     $ ops dns nsupdate-del mongo cname

  EOF
 }

 dns_check() {
  echo "dns check"
 }
 dns_check_2() {
  echo "dns check 2"
 }
 dns_ls() { :; }
 dns_dump() { echo dump dns; }
 dns_nsupdate() { :; }
 dns_ls() { :; }
 dns_vpc_fix() { :; }
 dns_profile() { :; }
 dns_check_resolv_conf() { :; }

 # sub of sub-commands
 #dns_fix()        { dns_entry "$@"; }
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
```

and the usage of `ops` command will be:

```bash
ops dns ls
ops dns check
ops dns check_2
ops dns dump

# sub of sub-commands
ops dns fix nameservers
ops dns fix resolv_conf
ops dns fix_nameservers
ops dns fix-nameservers
```

> See also [example/dns-tool](https://github.com/hedzr/bash.sh/blob/master/example/dns-tool), Or [./ops.d/darwin/lazy/dns-ops.sh](https://github.com/hedzr/bash.sh/blob/master/ops.d/darwin/lazy/dns-ops.sh).

### Environment Variables

#### `DEBUG` = {1|0}

#### `HAS_END` = {true|:|false}

#### `CD`: directory of `bash.sh`

#### `SCRIPT`: full path of `bash.sh`

## Under zsh Shell

advantage.

## License

MIT for free.

Enjoy It!
