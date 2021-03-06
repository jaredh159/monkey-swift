# monkey-swift

my [second time](https://github.com/jaredh159/monkey-c) writing an intepreter for thorsten
ball's monkey language, this time in **Swift**

[https://interpreterbook.com/](https://interpreterbook.com/)

## usage

```bash
# start up the monkey REPL
$ swift run

# evaluate a fragment of monkey code and exit
$ swift run monkey eval "1 + 2"
# > 3

# run ALL unit tests
$ swift run monkey test all

# run individual test suites
$ swift run monkey test ast
$ swift run monkey test lexer
$ swift run monkey test parser
$ swift run monkey test eval
$ swift run monkey test symbol
$ swift run monkey test code
$ swift run monkey test vm
$ swift run monkey test compiler

# run binary unit test
$ swift test

# build: if you're using SourceKit-LSP outside of Xcode
# this command helps SourceKit-LSP know about all source files
$ swift build
```

_Do you love C programs that call `malloc()` hundreds of times with nary a `free()` in
sight? Check out my
[implementation of Monkey in C!](https://github.com/jaredh159/monkey-c)_
