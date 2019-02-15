# bash.sh



`bash.sh` is a template for shell developing.



## Usages

### Command Line Options

```bash
$ ./bash.sh cool
$ DEBUG=1 ./bash.sh

$ ./bash.sh debug-info

$ ./bash.sh 'is_root && echo Y'
$ sudo ./bash.sh 'is_root && echo Y'
$ sudo DEBUG=1 ./bash.sh 'is_root && echo y'

$ HAS_END=: ./bash.sh
$ HAS_END=false ./bash.sh
```



### Use It

#### 1. Simple

Copy [bash.sh](bash.sh) and rename as your main entry, and go ahead.

> Modify `_my_main.do.sth()` as you want.

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
debug 'I am buggy but you don't know'
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
dns-entry () { commander dns "$@";}
dns-usage () {
  cat <<EOF
Usage: $0 $self <sub-command> [...]
Sub-commands:
  ls [--all|-a|--cname|--txt|--one|-1] [string]   list all/most-of-all/generics matched dns-records
  dump                    [RESERVED] dump dns-records [just for dns01]
  nsupdate                [DNS] [DYN] [MODIFY]
  fix-nameservers         [ali] general fix nameservers, step 1
  vpc-fix                 [ali] for VPC envir
  profile                 [ali] make a query perf test and report
  check                   [ali] check dns query is ok [version 1]
  check-2                 [ali] check dns query is ok [version 2]
  check-resolv-conf       [ali] check resolv.conf is right

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

dns-check(){
    echo "dns check"
}
dns-check-2(){
    echo "dns check 2"
}
```

and the usage of `ops` command will be:

```bash
ops dns ls
ops dns check
ops dns check-2
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
