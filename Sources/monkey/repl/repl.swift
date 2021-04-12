struct Repl {

  static func welcome() {
    print("Welcome to MONKEY".magenta)
    print("Try out the language below\n".gray)
    Repl.start()
  }

  static func start() {
    prompt()
    let constants: [Object] = []
    let symbolTable = SymbolTable()
    let compiler = Compiler(symbolTable: symbolTable, constants: constants)
    let globals = [Object?](repeating: nil, count: GLOBALS_SIZE)

    while let line = readLine() {
      let lexer = Lexer(line)
      let parser = Parser(lexer)
      let program = parser.parseProgram()
      if parser.errors.count != 0 {
        print(" • \(parser.errors.joined(separator: "\n • "))".red)
        prompt()
        continue
      }

      if let err = compiler.compile(program) {
        print("Whoops! Compilation failed\n \(err)\n")
        continue
      }

      let machine = VirtualMachine(compiler.bytecode(), globals: globals)
      if let err = machine.run() {
        print("Whoops! Executing bytecode failed\n \(err)\n")
        continue
      }
      print(machine.lastPoppedStackElem?.inspect ?? "")
      prompt()
    }
  }

  private static func prompt() {
    print(">> ".cyan, terminator: "")
  }
}
