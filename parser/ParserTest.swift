func main() {
  Test.reset(suiteName: "ParserTest")

  test("let statements") {
    let input = """
      let x = 5;
      let y = 10;
      let foobar = 838383;
      """

    let lexer = Lexer(input)
    let parser = Parser(lexer)
    let program = parser.parseProgram()

    guard noParserErrors(parser) else {
      return
    }

    guard expect(program.statements.count).toEqual(3) else {
      return
    }

    for (idx, expectedIdentifier) in ["x", "y", "foobar"].enumerated() {
      testLetStatement(program.statements[idx], expectedIdentifier)
    }
  }

  Test.report()
}

func testLetStatement(_ statement: Statement?, _ name: String) {
  guard let statement = expect(statement).toBe(Statement.self) else {
    return
  }

  guard let letStatement = expect(statement).toBe(LetStatement.self) else {
    return
  }

  if expect(letStatement.name?.value).toEqual(name) {
    return
  }

  expect(letStatement.name?.tokenLiteral()).toEqual(name)
}

func noParserErrors(_ parser: Parser) -> Bool {
  if parser.errors.isEmpty {
    Test.pushPass()
    return true
  }

  Test.pushFail("parser had \(parser.errors.count) errors")
  for err in parser.errors {
    Test.pushFail("parser error: \(err)")
  }
  return false
}
