---
typora-copy-images-to: ./_images
typora-root-url: ./_images
---
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

Copy [bash.sh](bash.sh) and rename as your main entry, and go ahead.



## Samples

![2018-02-22 12.30.11](/2018-02-22 12.30.11.png)

## License

MIT.

Enjoy It!