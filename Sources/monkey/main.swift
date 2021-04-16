import Foundation

if CommandLine.arguments.count == 1 {
  Repl.welcome()
}

if CommandLine.arguments[1] == "eval" {
  let input = CommandLine.arguments[2]
  let parser = Parser(Lexer(input))
  let program = parser.parseProgram()
  let evaluated = eval(program, Environment())
  print(evaluated)
  exit(evaluated.isError ? 1 : 0)
}

if CommandLine.arguments[1] != "test" {
  fatalError("Incorrect usage")
}

var success = true

if CommandLine.arguments.count == 2 || CommandLine.arguments[2] == "all" {
  success =
    testEval()
    && testLexer()
    && testParser()
    && testAst()
    && testCode()
    && testCompiler()
    && testVm()
    && testSymbolTable()
} else {
  switch CommandLine.arguments[2] {
    case "lexer", "l":
      success = testLexer()
    case "parser", "p":
      success = testParser()
    case "ast", "a":
      success = testAst()
    case "eval", "evaluator", "e":
      success = testEval()
    case "symbol", "s":
      success = testSymbolTable()
    case "code":
      success = testCode()
    case "vm", "v":
      success = testVm()
    case "compile", "compiler":
      success = testCompiler()
    case "c":
      success =
        testCode()
        && testCompiler()
        && testVm()
        && testSymbolTable()
    default:
      fatalError("unknown test target")
  }
}

if !success {
  print("\nTEST FAILURE\n".red)
  exit(EXIT_FAILURE)
}
