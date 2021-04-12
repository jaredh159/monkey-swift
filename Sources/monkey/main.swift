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

if CommandLine.arguments.count == 2 || CommandLine.arguments[2] == "all" {
  testEval()
  testLexer()
  testParser()
  testAst()
  testCode()
  testCompiler()
  testVm()
  testSymbolTable()
} else {
  switch CommandLine.arguments[2] {
    case "lexer", "l":
      testLexer()
    case "parser", "p":
      testParser()
    case "ast", "a":
      testAst()
    case "eval", "evaluator", "e":
      testEval()
    case "symbol", "s":
      testSymbolTable()
    case "code":
      testCode()
    case "vm", "v":
      testVm()
    case "compile", "compiler":
      testCompiler()
    case "c":
      testCode()
      testCompiler()
      testVm()
      testSymbolTable()
    default:
      fatalError("unknown test target")
  }
}
