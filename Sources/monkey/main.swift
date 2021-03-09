if CommandLine.arguments.count == 1 {
  Repl.welcome()
}

if CommandLine.arguments[1] != "test" {
  fatalError("Incorrect usage")
}

if CommandLine.arguments.count == 2 {
  testEval()
  testLexer()
  testParser()
  testAst()
} else {
  switch CommandLine.arguments[2] {
    case "lexer":
      testLexer()
    case "parser":
      testParser()
    case "ast":
      testAst()
    case "eval", "evaluator":
      testEval()
    default:
      fatalError("unknown test target")
  }
}
