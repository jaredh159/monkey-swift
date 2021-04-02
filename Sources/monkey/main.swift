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

if CommandLine.arguments.count == 2 {
  testEval()
  testLexer()
  testParser()
  testAst()
  testCode()
  testCompiler()
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
    case "code":
      testCode()
    case "compile", "compiler", "c":
      testCode()
      testCompiler()
    default:
      fatalError("unknown test target")
  }
}
