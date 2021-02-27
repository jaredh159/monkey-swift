struct Repl {

  static func welcome() {
    print("Welcome to MONKEY".magenta)
    print("Try out the language below\n".gray)
    Repl.start()
  }

  static func start() {
    prompt()
    while let line = readLine() {
      let lexer = Lexer(line)
      var token = lexer.nextToken()
      while token.type != .EOF {
        print(token)
        token = lexer.nextToken()
      }
      prompt()
    }
  }

  private static func prompt() {
    print(">> ".cyan, terminator: "")
  }
}

func main() {
  Repl.welcome()
}
