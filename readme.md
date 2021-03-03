# monkey-swift

my (second) bumbling attempt to write an intepreter for thorsten ball's monkey language,
this time in **Swift**

[https://interpreterbook.com/](https://interpreterbook.com/)

## usage

```bash
# start up the monkey REPL
$ swift run

# run ALL unit tests
$ swift run monkey test

# run individual test suites
$ swift run monkey test ast
$ swift run monkey test lexer
$ swift run monkey test parser

# build: if you're using SourceKit-LSP outside of Xcode
# this command helps SourceKit-LSP know about all source files
$ swift build
```

_Do you love C programs that call `malloc()` hundreds of times with nary a `free()` in
sight? Check out my
[implementation of Monkey in C!](https://github.com/jaredh159/monkey-c)_
