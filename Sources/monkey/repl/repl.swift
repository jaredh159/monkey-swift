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
      let parser = Parser(lexer)
      let program = parser.parseProgram()
      if parser.errors.count != 0 {
        print(" • \(parser.errors.joined(separator: "\n • "))".red)
        prompt()
        continue
      }
      if let evaluated = eval(program) {
        print(evaluated)
      }
      prompt()
    }
  }

  private static func prompt() {
    print(">> ".cyan, terminator: "")
  }
}
