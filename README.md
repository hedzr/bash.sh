# bash.sh



`bash.sh` is a starting template for shell developing.



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

##### Use `installer`:

```bash
curl -sSL https://hedzr.com/bash/bash.sh/installer | sudo bash -s
```

> The old <https://hedzr.com/bash.sh/installer> has been obseleted.

`installer` will copy `bash.config` to `/usr/local/bin`.

##### Manually:

Copy `bash.config` to `/usr/local/bin/` or anywhere, and `source` it from your script file:

Some examples [here](./examples/).

## Samples

![](./_images/2018-02-22_12.30.11.png)



## Knives Document

### `in_debug`

in debug mode?

toggle environment variable `DEBUG` to switch between `normal_mode` and `debug_mode`.

```bash
is_debug && echo 'debug mode' || echo 'normal mode'
```



### `debug` $*

print string for debug. In normal mode, the string message will be stripped.

```bash
debug I am buggy but you don't know
debug 'I am buggy but you don'''t know'
debug "I am buggy but you don't know"
```



### `headline` $*

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



### `realpathx`

cross impl for linux `realpath`.


## Use `commander()` in your scripts

here is a example file `ops`:

```bash

dns()        { dns-entry "$@"; }
dns_entry () { commander dns "$@";}
dns_usage () {
  cat <<EOF
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

dns_check(){
    echo "dns check"
}
dns_check_2(){
    echo "dns check 2"
}
dns_ls(){ :; }
dns_dump(){ :; }
dns_nsupdate(){ :; }
dns_ls(){ :; }
dns_vpc_fix(){ :; }
dns_profile(){ :; }
dns_check_resolv_conf(){ :; }

# sub of sub-commands
dns_fix()        { dns-entry "$@"; }
dns_fix_entry () { commander dns "$@";}
dns_fix_usage () {
  cat <<EOF
Usage: $0 $self <sub-command> [...]
Sub-commands:
  nameservers             [ali] general fix nameservers, step 1
  resolv_conf             [ali] for VPC envir

Examples:
  $ ops dns fix nameservers
  $ ops dns fix resolv_conf

EOF
}
dns_fix_nameservers(){ :; }
dns_fix_resolv_conf(){ :; }
```

and the usage of `ops` command will be:

```bash
ops dns ls
ops dns check
ops dns check_2

# sub of sub-commands
ops dns fix nameservers
ops dns fix resolv_conf
ops dns fix_nameservers
```


### Environment Variables

#### `DEBUG` = {1|0}



#### `HAS_END` = {true|:|false}



#### `CD`: directory of `bash.sh`



#### `SCRIPT`: full path of `bash.sh`


## Under zsh Shell

advantage.

## Changelog

### 20190215

### 20180509



## License

MIT for free.

Enjoy It!
